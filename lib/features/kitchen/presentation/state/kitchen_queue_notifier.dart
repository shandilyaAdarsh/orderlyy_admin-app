// lib/features/kitchen/presentation/state/kitchen_queue_notifier.dart
import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../orders/domain/entities/order_item.dart';
import '../../../orders/providers/orders_providers.dart';
import '../../../tables/domain/entities/restaurant_table.dart';
import '../../../tables/providers/tables_providers.dart';

part 'kitchen_queue_notifier.g.dart';

@riverpod
class KitchenQueueNotifier extends _$KitchenQueueNotifier {
  StreamSubscription<List<Order>>? _subscription;

  @override
  FutureOr<List<Order>> build() async {
    final repository = ref.watch(ordersRepositoryProvider);

    ref.onDispose(() {
      _subscription?.cancel();
    });

    _subscription = repository.watchActiveOrders().listen((orders) {
      final activePrepOrders = orders.where((o) => 
        o.status == OrderStatus.sent || 
        o.status == OrderStatus.preparing || 
        o.status == OrderStatus.ready
      ).toList();
      state = AsyncData(activePrepOrders);
    });

    // Seed initial from active stream
    try {
      final initial = await repository.watchActiveOrders().first;
      return initial.where((o) => 
        o.status == OrderStatus.sent || 
        o.status == OrderStatus.preparing || 
        o.status == OrderStatus.ready
      ).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> updateItemStatus(String orderId, String itemId, OrderItemStatus newStatus) async {
    final repository = ref.read(ordersRepositoryProvider);
    final order = await repository.getOrderById(orderId);
    if (order == null) return;

    final items = order.items.map((item) {
      if (item.id == itemId) {
        return item.copyWith(status: newStatus);
      }
      return item;
    }).toList();

    // Check overall order status:
    // If all items are ready or served, the order is ready for runners to dispatch.
    // If any item is preparing, the order is in preparation.
    var orderStatus = order.status;
    final activeItems = items.where((i) => i.status != OrderItemStatus.cancelled);
    
    if (activeItems.isEmpty) {
      orderStatus = OrderStatus.cancelled;
    } else if (activeItems.every((i) => i.status == OrderItemStatus.ready || i.status == OrderItemStatus.served)) {
      orderStatus = OrderStatus.ready;
      
      // Table status updates to needsAttention to notify runners to serve it
      final updateTableStatus = ref.read(updateTableStatusUseCaseProvider);
      await updateTableStatus(order.tableId, TableStatus.needsAttention);
    } else if (activeItems.any((i) => i.status == OrderItemStatus.preparing || i.status == OrderItemStatus.ready)) {
      orderStatus = OrderStatus.preparing;
    }

    final updated = order.copyWith(
      items: items,
      status: orderStatus,
      updatedAt: DateTime.now(),
    );

    await repository.saveOrder(updated);
  }
}
