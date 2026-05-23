// ── Orders Providers ──────────────────────────────────────────────────────────
// All orders data access goes through these providers.
// Screens MUST NOT import supabase_flutter or call Supabase.instance.client.
//
// Data flow:
//   OrdersRepository (interface)
//     └─ MockOrdersRepository  (kUseMockRepositories = true)
//     └─ SupabaseOrdersRepository  (future, kUseMockRepositories = false)
//
//

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dtos/order_dto.dart';
import 'repository_providers.dart';
import '../auth/mock_auth_provider.dart';
import '../data/local/offline_sync_queue.dart';
import '../data/repositories/offline_first_orders_repository.dart';

// ── Orders stream ─────────────────────────────────────────────────────────────
// Emits every time the underlying repository pushes an update.
final ordersStreamProvider = StreamProvider<List<OrderDto>>((ref) async* {
  final profile = await ref.watch(userProfileProvider.future);
  final tenantId = profile?['tenant_id'];

  if (tenantId == null) {
    if (kUseMockRepositories) {
      yield* ref.watch(ordersRepositoryProvider).watchOrders('mock-tenant-001');
    } else {
      yield [];
    }
    return;
  }

  final repo = ref.watch(ordersRepositoryProvider);
  yield* repo.watchOrders(tenantId);
});

// ── Update order status ───────────────────────────────────────────────────────
// Call via: ref.read(updateOrderStatusProvider)(orderId, OrderStatus.served)
final updateOrderStatusProvider =
    Provider<Future<void> Function(String orderId, OrderStatus newStatus)>((
      ref,
    ) {
      final repo = ref.read(ordersRepositoryProvider);
      return (orderId, newStatus) async {
        await repo.updateOrderStatus(orderId, newStatus);
      };
    });

// ── Create order ─────────────────────────────────────────────────────────────
final createOrderProvider = Provider<Future<OrderDto> Function(OrderDto order)>(
  (ref) {
    final repo = ref.read(ordersRepositoryProvider);
    return (order) async {
      return repo.createOrder(order);
    };
  },
);

// ── Update order ─────────────────────────────────────────────────────────────
final updateOrderProvider = Provider<Future<OrderDto> Function(OrderDto order)>(
  (ref) {
    final repo = ref.read(ordersRepositoryProvider);
    return (order) async {
      return repo.updateOrder(order);
    };
  },
);

// ── Offline Connection State ──────────────────────────────────────────────────
final isOnlineProvider = StateNotifierProvider<IsOnlineNotifier, bool>((ref) {
  final queue = ref.watch(offlineSyncQueueProvider);
  return IsOnlineNotifier(queue, ref);
});

class IsOnlineNotifier extends StateNotifier<bool> {
  final OfflineSyncQueue _queue;
  final Ref _ref;

  IsOnlineNotifier(this._queue, this._ref) : super(_queue.isOnline());

  Future<void> toggleOnline() async {
    final newStatus = !state;
    await _queue.setOnlineStatus(newStatus);
    state = newStatus;

    final repo = _ref.read(ordersRepositoryProvider);
    if (repo is OfflineFirstOrdersRepository) {
      repo.notifyConnectionChanged();
    }
  }
}

// ── Pending Actions Queue Count ───────────────────────────────────────────────
final pendingActionsCountProvider = StreamProvider<int>((ref) async* {
  final queue = ref.watch(offlineSyncQueueProvider);
  while (true) {
    final list = await queue.getQueue();
    yield list.length;
    await Future.delayed(const Duration(seconds: 1));
  }
});
