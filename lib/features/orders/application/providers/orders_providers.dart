// ── Orders Providers ─────────────────────────────────────────────────────────
// Riverpod providers for orders feature.
// Follows dependency injection and provider lifecycle best practices.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/orders_repository_providers.dart';
import '../../../../core/auth/mock_auth_provider.dart';
import '../../../../core/storage/state_persistence.dart';
import '../../../../core/runtime/runtime_context.dart';
import '../../domain/models/order.dart';
import '../../domain/models/order_status.dart';
import '../state/orders_state.dart';
import '../state/orders_notifier.dart';

// ── State Provider ───────────────────────────────────────────────────────────

final ordersStateProvider = StateNotifierProvider<OrdersNotifier, OrdersState>((
  ref,
) {
  final repository = ref.watch(ordersRepositoryProvider);
  final persistence = ref.watch(statePersistenceProvider);
  final tenantId = ref.watch(currentTenantIdProvider);

  return OrdersNotifier(
    repository: repository,
    persistence: persistence,
    tenantId: tenantId,
  );
});

// ── Derived Providers ────────────────────────────────────────────────────────

/// All orders
final ordersProvider = Provider.autoDispose<List<Order>>((ref) {
  return ref.watch(ordersStateProvider).orders;
});

/// Active orders (not served or cancelled)
final activeOrdersProvider = Provider.autoDispose<List<Order>>((ref) {
  final orders = ref.watch(ordersStateProvider).orders;
  return orders.where((o) => o.isActive).toList();
});

/// Orders by status
final ordersByStatusProvider = Provider.autoDispose
    .family<List<Order>, OrderStatus>((ref, status) {
      final orders = ref.watch(ordersStateProvider).orders;
      return orders.where((o) => o.status == status).toList();
    });

/// Pending orders count
final pendingOrdersCountProvider = Provider.autoDispose<int>((ref) {
  final orders = ref.watch(ordersStateProvider).orders;
  return orders.where((o) => o.status == OrderStatus.pending).length;
});

/// Active orders count
final activeOrdersCountProvider = Provider.autoDispose<int>((ref) {
  final orders = ref.watch(ordersStateProvider).orders;
  return orders.where((o) => o.isActive).length;
});

/// Order by ID
final orderByIdProvider = Provider.autoDispose.family<Order?, String>((
  ref,
  orderId,
) {
  final orders = ref.watch(ordersStateProvider).orders;
  try {
    return orders.firstWhere((o) => o.id == orderId);
  } catch (e) {
    return null;
  }
});

/// Loading status
final ordersLoadingStatusProvider = Provider.autoDispose<LoadingStatus>((ref) {
  return ref.watch(ordersStateProvider).status;
});

/// Is loading
final isLoadingOrdersProvider = Provider.autoDispose<bool>((ref) {
  return ref.watch(ordersStateProvider).status == LoadingStatus.loading;
});

/// Has error
final ordersErrorProvider = Provider.autoDispose<bool>((ref) {
  return ref.watch(ordersStateProvider).error != null;
});

// ── Tenant ID Provider ───────────────────────────────────────────────────────

final currentTenantIdProvider = Provider<String>((ref) {
  // Get from app context
  final appContext = ref.watch(appContextProvider);
  return requireContextValue(
    value: appContext?.tenant.id,
    field: 'tenantId',
    source: 'currentTenantIdProvider',
  );
});
