// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:orderlli_admin/core/data/dtos/order_dto.dart';
import 'package:orderlli_admin/core/data/local/offline_sync_queue.dart';
import 'package:orderlli_admin/core/data/repositories/offline_first_orders_repository.dart';
import 'package:orderlli_admin/core/data/mock/mock_orders_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Offline POS Sync Tests', () {
    late OfflineSyncQueue queue;
    late MockOrdersRepository delegateRepo;
    late OfflineFirstOrdersRepository offlineRepo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      queue = OfflineSyncQueue(prefs);
      delegateRepo = MockOrdersRepository();
      offlineRepo = OfflineFirstOrdersRepository(delegate: delegateRepo, queue: queue);
    });

    test('should cache orders locally when live stream emits', () async {
      // First, check that cache is empty
      final initialCache = await queue.getCachedOrders();
      expect(initialCache, isEmpty);

      // Wait for the stream to emit a non-empty list (loaded from delegate)
      final list = await offlineRepo.watchOrders('mock-tenant-001')
          .firstWhere((orders) => orders.isNotEmpty);
      expect(list, isNotEmpty);

      // Check cache again: it should now be populated
      final cached = await queue.getCachedOrders();
      expect(cached, isNotEmpty);
      expect(cached.length, list.length);
      print('✅ Cached orders populated correctly: ${cached.length} items');
    });

    test('should queue mutations and apply optimistic updates when offline', () async {
      // 1. Populate cache from stream first
      final initialList = await offlineRepo.watchOrders('mock-tenant-001')
          .firstWhere((orders) => orders.isNotEmpty);
      final originalLength = initialList.length;

      // Set to offline
      await queue.setOnlineStatus(false);
      expect(queue.isOnline(), isFalse);

      // Create a new order offline
      final newOrder = OrderDto(
        id: 'offline-test-order-999',
        tenantId: 'mock-tenant-001',
        tableId: 'tbl-01',
        tableLabel: 'T01',
        status: OrderStatus.preparing,
        items: [],
        totalAmount: 100.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await offlineRepo.createOrder(newOrder);

      // Verify that the action is in the queue
      final pendingActions = await queue.getQueue();
      expect(pendingActions, hasLength(1));
      expect(pendingActions.first.type, 'createOrder');

      // Verify optimistic update is applied to stream output immediately
      final updatedList = await offlineRepo.watchOrders('mock-tenant-001')
          .firstWhere((orders) => orders.length == originalLength + 1);
      expect(updatedList.any((o) => o.id == 'offline-test-order-999'), isTrue);

      print('✅ Optimistic creation and offline action queueing succeeded');
    });

    test('should synchronize pending queue when going online', () async {
      // 1. Populate cache from stream first
      final initialList = await offlineRepo.watchOrders('mock-tenant-001')
          .firstWhere((orders) => orders.isNotEmpty);
      final targetOrder = initialList.first;

      // Set to offline
      await queue.setOnlineStatus(false);

      // Modify status of an order offline
      await offlineRepo.updateOrderStatus(targetOrder.id, OrderStatus.served);

      // Verify offline change is optimistically reflected
      final offlineList = await offlineRepo.watchOrders('mock-tenant-001')
          .firstWhere((orders) => orders.firstWhere((o) => o.id == targetOrder.id).status == OrderStatus.served);
      final offlineOrder = offlineList.firstWhere((o) => o.id == targetOrder.id);
      expect(offlineOrder.status, OrderStatus.served);

      // Verify delegate (remote) repository is NOT updated yet (since we are offline)
      final delegateList = await delegateRepo.watchOrders('mock-tenant-001').first;
      final delegateOrder = delegateList.firstWhere((o) => o.id == targetOrder.id);
      expect(delegateOrder.status, isNot(OrderStatus.served));

      // Now set back to online and synchronize
      await queue.setOnlineStatus(true);
      await offlineRepo.syncPendingQueue();

      // Verify that the queue is empty
      final finalQueue = await queue.getQueue();
      expect(finalQueue, isEmpty);

      // Verify that changes are fully synchronized to delegate repository
      final finalDelegateList = await delegateRepo.watchOrders('mock-tenant-001').first;
      final finalDelegateOrder = finalDelegateList.firstWhere((o) => o.id == targetOrder.id);
      expect(finalDelegateOrder.status, OrderStatus.served);

      print('✅ Background sync successfully propagated offline mutations and cleared the queue');
    });
  });
}
