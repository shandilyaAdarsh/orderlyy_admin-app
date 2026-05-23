import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/money.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../../core/data/dtos/order_dto.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/data/repositories/offline_first_orders_repository.dart';
import '../../../cart/presentation/state/cart_notifier.dart';
import '../../../draft_orders/domain/entities/order_draft.dart';

final activeTableIdProvider = StateProvider<String>((ref) => 'tbl-001');
final activeTableLabelProvider = StateProvider<String>((ref) => 'Table 1');
final deviceSessionIdProvider = Provider<String>((ref) => 'session-${DateTime.now().millisecondsSinceEpoch}');

final draftOrderProvider = Provider<OrderDraft?>((ref) {
  final cart = ref.watch(cartStateProvider);
  if (cart.items.isEmpty) return null;

  final tableId = ref.watch(activeTableIdProvider);
  final tableLabel = ref.watch(activeTableLabelProvider);
  
  final profileAsync = ref.watch(userProfileProvider);
  final tenantId = profileAsync.maybeWhen(
    data: (profile) => profile?['tenant_id'],
    orElse: () => null,
  ) ?? 'mock-tenant-001';

  final deviceSessionId = ref.watch(deviceSessionIdProvider);

  final draftItems = cart.items.map((i) {
    return DraftItem(
      menuItemId: i.menuItemId,
      name: i.name,
      quantity: i.quantity,
      unitPrice: i.snapshotUnitPrice,
      modifiers: i.selectedModifiers.map((m) {
        return DraftModifier(
          modifierOptionId: m.modifierOptionId,
          name: m.name,
          price: m.price,
        );
      }).toList(),
      specialInstructions: i.specialInstructions,
    );
  }).toList();

  final subtotal = draftItems.fold<Money>(
    Money(amountInCents: 0, currency: cart.items.first.snapshotUnitPrice.currency),
    (sum, item) => sum + item.lineTotal,
  );

  return OrderDraft(
    draftId: cart.items.first.cartItemId,
    tenantId: tenantId,
    branchId: cart.branchId,
    tableId: tableId,
    tableLabel: tableLabel,
    items: draftItems,
    calculatedSubtotal: subtotal,
    menuSnapshotVersion: cart.menuSnapshotVersion,
    deviceSessionId: deviceSessionId,
    createdAt: DateTime.now(),
  );
});

class CheckoutState extends Equatable {
  final String status; // 'idle', 'submitting', 'enqueuedOffline', 'success', 'error'
  final String? errorMessage;
  final String? confirmedOrderId;

  const CheckoutState({
    required this.status,
    this.errorMessage,
    this.confirmedOrderId,
  });

  @override
  List<Object?> get props => [status, errorMessage, confirmedOrderId];
}

final checkoutNotifierProvider = StateNotifierProvider<CheckoutNotifier, CheckoutState>((ref) {
  return CheckoutNotifier(ref);
});

class CheckoutNotifier extends StateNotifier<CheckoutState> {
  final Ref _ref;

  CheckoutNotifier(this._ref) : super(const CheckoutState(status: 'idle'));

  OrderDto mapDraftToOrderDto(OrderDraft draft) {
    final items = draft.items.map((item) {
      final id = 'item-${item.menuItemId}-${DateTime.now().millisecondsSinceEpoch}';
      return OrderItemDto(
        id: id,
        menuItemId: item.menuItemId,
        menuItemName: item.name,
        quantity: item.quantity,
        unitPrice: item.unitPrice.asDouble,
        notes: item.specialInstructions.isEmpty ? null : item.specialInstructions,
      );
    }).toList();

    return OrderDto(
      id: draft.draftId,
      tenantId: draft.tenantId,
      tableId: draft.tableId,
      tableLabel: draft.tableLabel ?? 'Table',
      status: OrderStatus.pending,
      items: items,
      totalAmount: draft.calculatedSubtotal.asDouble,
      createdAt: draft.createdAt,
      updatedAt: draft.createdAt,
    );
  }

  Future<void> submitCheckout() async {
    final draft = _ref.read(draftOrderProvider);
    if (draft == null) {
      state = const CheckoutState(status: 'error', errorMessage: 'Cart is empty');
      return;
    }

    final cart = _ref.read(cartStateProvider);
    if (cart.hasStalePrices) {
      state = const CheckoutState(status: 'error', errorMessage: 'Stale pricing detected. Reconcile cart first.');
      return;
    }

    state = const CheckoutState(status: 'submitting');

    final order = mapDraftToOrderDto(draft);
    final repo = _ref.read(ordersRepositoryProvider);
    final queue = _ref.read(offlineSyncQueueProvider);

    final isOnline = queue.isOnline();
    if (isOnline) {
      try {
        await repo.createOrder(order);
        if (repo is OfflineFirstOrdersRepository) {
          await repo.syncPendingQueue();
          
          final pending = await queue.getQueue();
          final stillEnqueued = pending.any((a) => a.idempotencyKey == 'idem-create-${order.id}');
          if (stillEnqueued) {
            state = const CheckoutState(
              status: 'error',
              errorMessage: 'Submission failed on server. Kept in offline queue.',
            );
          } else {
            state = CheckoutState(status: 'success', confirmedOrderId: order.id);
            _ref.read(cartStateProvider.notifier).clearCart();
          }
        } else {
          state = CheckoutState(status: 'success', confirmedOrderId: order.id);
          _ref.read(cartStateProvider.notifier).clearCart();
        }
      } catch (e) {
        state = CheckoutState(status: 'error', errorMessage: e.toString());
      }
    } else {
      try {
        await repo.createOrder(order);
        state = CheckoutState(status: 'enqueuedOffline', confirmedOrderId: order.id);
        _ref.read(cartStateProvider.notifier).clearCart();
      } catch (e) {
        state = CheckoutState(status: 'error', errorMessage: e.toString());
      }
    }
  }

  void reset() {
    state = const CheckoutState(status: 'idle');
  }
}
