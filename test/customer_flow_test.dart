// test/customer_flow_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:orderlyy_app/shared/models/money.dart';
import 'package:orderlyy_app/features/menu/domain/entities/menu_snapshot.dart';
import 'package:orderlyy_app/features/customer/presentation/state/customer_providers.dart';
import 'package:orderlyy_app/features/orders/domain/entities/order.dart';
import 'package:orderlyy_app/features/orders/domain/repositories/orders_repository.dart';
import 'package:orderlyy_app/features/orders/providers/orders_providers.dart';
import 'package:orderlyy_app/features/tables/domain/entities/restaurant_table.dart';
import 'package:orderlyy_app/features/tables/domain/repositories/tables_repository.dart';
import 'package:orderlyy_app/features/tables/providers/tables_providers.dart';
import 'package:orderlyy_app/bootstrap/bootstrap.dart';

class MockOrdersRepository implements OrdersRepository {
  final List<Order> _orders = [];
  bool saveOrderCalled = false;
  Order? lastSavedOrder;

  @override
  Future<Order?> getOrderById(String id) async {
    try {
      return _orders.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Order?> getActiveOrderForTable(String tableId) async {
    try {
      return _orders.firstWhere((o) => o.tableId == tableId && o.status != OrderStatus.completed);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Order> saveOrder(Order order) async {
    saveOrderCalled = true;
    lastSavedOrder = order;
    final index = _orders.indexWhere((o) => o.id == order.id);
    if (index != -1) {
      _orders[index] = order;
    } else {
      _orders.add(order);
    }
    return order;
  }

  @override
  Stream<List<Order>> watchActiveOrders() {
    return Stream.value(_orders);
  }

  @override
  Stream<Order?> watchOrderById(String orderId) {
    try {
      final order = _orders.firstWhere((o) => o.id == orderId);
      return Stream.value(order);
    } catch (_) {
      return Stream.value(null);
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockTablesRepository implements TablesRepository {
  final List<RestaurantTable> _tables = [
    const RestaurantTable(id: 'table_7', label: '7', capacity: 4, status: TableStatus.available),
  ];

  @override
  Future<List<RestaurantTable>> getTables() async => _tables;

  @override
  Future<RestaurantTable> updateTableStatus(String id, TableStatus status, {String? orderId}) async {
    final index = _tables.indexWhere((t) => t.id == id);
    if (index != -1) {
      _tables[index] = _tables[index].copyWith(status: status, activeOrderId: orderId);
      return _tables[index];
    }
    throw Exception('Table not found');
  }

  @override
  Future<void> mergeTables(List<String> sourceTableIds, String targetTableId) async {}

  @override
  Future<void> splitTable(String tableId, List<Map<String, dynamic>> splitPartitions) async {}

  @override
  Stream<List<RestaurantTable>> watchTables() {
    return Stream.value(_tables);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 3 - Customer Session & Cart State Management', () {
    late ProviderContainer container;
    late MockOrdersRepository mockOrdersRepo;
    late MockTablesRepository mockTablesRepo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      mockOrdersRepo = MockOrdersRepository();
      mockTablesRepo = MockTablesRepository();

      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          ordersRepositoryProvider.overrideWithValue(mockOrdersRepo),
          tablesRepositoryProvider.overrideWithValue(mockTablesRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('initializeSession sets the correct tenant, branch and table ID', () {
      final notifier = container.read(customerSessionProvider.notifier);
      notifier.initializeSession('tenant_123', 'branch_456', 'table_7');

      final session = container.read(customerSessionProvider);
      expect(session, isNotNull);
      expect(session!.tenantId, 'tenant_123');
      expect(session.branchId, 'branch_456');
      expect(session.tableId, 'table_7');
      expect(session.cart, isEmpty);
    });

    test('addToCart adds an item with correct quantity and modifier options', () {
      final notifier = container.read(customerSessionProvider.notifier);
      notifier.initializeSession('tenant_123', 'branch_456', 'table_7');

      const item = MenuItem(
        id: 'item_burger',
        categoryId: 'cat_1',
        name: 'Classic Burger',
        description: 'Tasty burger',
        price: Money(amountInCents: 850),
        isAvailable: true,
        modifierGroupIds: ['grp_1'],
      );

      const modifier = ModifierOption(id: 'mod_cheese', name: 'Cheese', price: Money(amountInCents: 100));

      notifier.addToCart(item, 2, const [modifier]);

      final session = container.read(customerSessionProvider);
      expect(session!.cart.length, 1);
      expect(session.cart[0].item.id, 'item_burger');
      expect(session.cart[0].quantity, 2);
      expect(session.cart[0].selectedModifiers.length, 1);
      expect(session.cart[0].selectedModifiers[0].name, 'Cheese');
      expect(session.subtotal.amountInCents, 1900); // (850 + 100) * 2 = 1900
    });

    test('updateQuantity increments and decrements quantity correctly', () {
      final notifier = container.read(customerSessionProvider.notifier);
      notifier.initializeSession('tenant_123', 'branch_456', 'table_7');

      const item = MenuItem(
        id: 'item_burger',
        categoryId: 'cat_1',
        name: 'Classic Burger',
        description: 'Tasty burger',
        price: Money(amountInCents: 850),
        isAvailable: true,
        modifierGroupIds: [],
      );

      notifier.addToCart(item, 1, const []);
      var cartItemId = container.read(customerSessionProvider)!.cart[0].id;

      // Increment
      notifier.updateQuantity(cartItemId, 2);
      expect(container.read(customerSessionProvider)!.cart[0].quantity, 3);

      // Decrement to remove
      notifier.updateQuantity(cartItemId, -3);
      expect(container.read(customerSessionProvider)!.cart, isEmpty);
    });

    test('checkout saves the cart items to an order and updates table status', () async {
      final notifier = container.read(customerSessionProvider.notifier);
      notifier.initializeSession('tenant_123', 'branch_456', 'table_7');

      const item = MenuItem(
        id: 'item_burger',
        categoryId: 'cat_1',
        name: 'Classic Burger',
        description: 'Tasty burger',
        price: Money(amountInCents: 850),
        isAvailable: true,
        modifierGroupIds: [],
      );

      notifier.addToCart(item, 1, const []);

      // Verify checkout
      await notifier.checkout();

      expect(mockOrdersRepo.saveOrderCalled, isTrue);
      expect(mockOrdersRepo.lastSavedOrder, isNotNull);
      expect(mockOrdersRepo.lastSavedOrder!.tableId, 'table_7');
      expect(mockOrdersRepo.lastSavedOrder!.status, OrderStatus.sent);
      expect(mockOrdersRepo.lastSavedOrder!.items.length, 1);
      expect(mockOrdersRepo.lastSavedOrder!.items[0].product.name, 'Classic Burger');

      // Verify table is set to occupied
      final table = (await mockTablesRepo.getTables())[0];
      expect(table.status, TableStatus.occupied);
      expect(table.activeOrderId, mockOrdersRepo.lastSavedOrder!.id);

      // Cart should be empty after checkout
      expect(container.read(customerSessionProvider)!.cart, isEmpty);
    });
  });
}
