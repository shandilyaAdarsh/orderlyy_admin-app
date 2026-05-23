// ignore_for_file: avoid_print
// ── Repository Integration Tests ─────────────────────────────────────────────
// Tests all 4 refactored modules to ensure they work correctly with the
// repository/provider architecture.

import 'package:flutter_test/flutter_test.dart';
import 'package:orderlli_admin/core/data/dtos/menu_dto.dart';
import 'package:orderlli_admin/core/data/dtos/order_dto.dart';
import 'package:orderlli_admin/core/data/dtos/staff_dto.dart';
import 'package:orderlli_admin/core/data/dtos/table_dto.dart';
import 'package:orderlli_admin/core/data/mock/mock_menu_repository.dart';
import 'package:orderlli_admin/core/data/mock/mock_orders_repository.dart';
import 'package:orderlli_admin/core/data/mock/mock_staff_repository.dart';
import 'package:orderlli_admin/core/data/mock/mock_tables_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Task 1: Orders Repository Integration', () {
    late MockOrdersRepository repository;

    setUp(() {
      repository = MockOrdersRepository();
    });

    test('should load orders from fixtures with correct tenant ID', () async {
      final orders = await repository.watchOrders('mock-tenant-001').first;
      
      expect(orders, isNotEmpty);
      expect(orders.every((o) => o.tenantId == 'mock-tenant-001'), isTrue);
      print('✅ Orders loaded: ${orders.length} orders');
    });

    test('should update order status', () async {
      final orders = await repository.watchOrders('mock-tenant-001').first;
      final firstOrder = orders.first;
      
      await repository.updateOrderStatus(firstOrder.id, OrderStatus.preparing);
      
      final updatedOrders = await repository.watchOrders('mock-tenant-001').first;
      final updatedOrder = updatedOrders.firstWhere((o) => o.id == firstOrder.id);
      
      expect(updatedOrder.status, OrderStatus.preparing);
      print('✅ Order status updated: ${firstOrder.id} -> preparing');
    });

    test('should update order items and amount', () async {
      final orders = await repository.watchOrders('mock-tenant-001').first;
      final firstOrder = orders.first;
      
      final updatedOrder = OrderDto(
        id: firstOrder.id,
        tenantId: firstOrder.tenantId,
        tableId: firstOrder.tableId,
        tableLabel: firstOrder.tableLabel,
        status: firstOrder.status,
        items: [
          const OrderItemDto(
            id: 'test-item-1',
            menuItemId: 'item-001',
            menuItemName: 'Paneer Butter Masala',
            quantity: 3,
            unitPrice: 250.0,
          )
        ],
        totalAmount: 750.0,
        staffId: firstOrder.staffId,
        staffName: firstOrder.staffName,
        createdAt: firstOrder.createdAt,
        updatedAt: DateTime.now(),
      );
      
      await repository.updateOrder(updatedOrder);
      
      final updatedOrders = await repository.watchOrders('mock-tenant-001').first;
      final savedOrder = updatedOrders.firstWhere((o) => o.id == firstOrder.id);
      
      expect(savedOrder.totalAmount, 750.0);
      expect(savedOrder.items.length, 1);
      expect(savedOrder.items.first.quantity, 3);
      print('✅ Order items and totalAmount updated successfully');
    });

    test('should filter orders by tenant ID', () async {
      final orders = await repository.watchOrders('mock-tenant-001').first;
      final wrongTenantOrders = await repository.watchOrders('wrong-tenant').first;
      
      expect(orders, isNotEmpty);
      expect(wrongTenantOrders, isEmpty);
      print('✅ Tenant filtering works correctly');
    });
  });

  group('Task 2: Staff Repository Integration', () {
    late MockStaffRepository repository;

    setUp(() {
      repository = MockStaffRepository();
    });

    test('should load staff from fixtures with correct tenant ID', () async {
      final staff = await repository.watchStaff('mock-tenant-001').first;
      
      expect(staff, isNotEmpty);
      expect(staff.every((s) => s.tenantId == 'mock-tenant-001'), isTrue);
      expect(staff.length, 5); // 5 staff members in fixtures
      print('✅ Staff loaded: ${staff.length} members');
    });

    test('should create new staff member', () async {
      final newStaff = StaffDto(
        id: 'stf-test-001',
        tenantId: 'mock-tenant-001',
        name: 'Test Staff',
        role: StaffRole.waiter,
        pin: '9999',
        isActive: true,
      );
      
      await repository.createStaff(newStaff);
      
      final staff = await repository.watchStaff('mock-tenant-001').first;
      expect(staff.any((s) => s.id == 'stf-test-001'), isTrue);
      print('✅ Staff created: ${newStaff.name}');
    });

    test('should update staff member', () async {
      final staff = await repository.watchStaff('mock-tenant-001').first;
      final firstStaff = staff.first;
      
      final updated = firstStaff.copyWith(name: 'Updated Name');
      await repository.updateStaff(updated);
      
      final updatedStaff = await repository.watchStaff('mock-tenant-001').first;
      final updatedMember = updatedStaff.firstWhere((s) => s.id == firstStaff.id);
      
      expect(updatedMember.name, 'Updated Name');
      print('✅ Staff updated: ${firstStaff.id}');
    });

    test('should delete staff member', () async {
      final staff = await repository.watchStaff('mock-tenant-001').first;
      final initialCount = staff.length;
      final firstStaff = staff.first;
      
      await repository.deleteStaff(firstStaff.id);
      
      final updatedStaff = await repository.watchStaff('mock-tenant-001').first;
      expect(updatedStaff.length, initialCount - 1);
      expect(updatedStaff.any((s) => s.id == firstStaff.id), isFalse);
      print('✅ Staff deleted: ${firstStaff.id}');
    });
  });

  group('Task 2: Tables Repository Integration', () {
    late MockTablesRepository repository;

    setUp(() {
      repository = MockTablesRepository();
    });

    test('should load tables from fixtures with correct tenant ID', () async {
      final tables = await repository.watchTables('mock-tenant-001').first;
      
      expect(tables, isNotEmpty);
      expect(tables.every((t) => t.tenantId == 'mock-tenant-001'), isTrue);
      expect(tables.length, 10); // 10 tables in fixtures
      print('✅ Tables loaded: ${tables.length} tables');
    });

    test('should create new table', () async {
      final newTable = RestaurantTableDto(
        id: 'tbl-test-001',
        tenantId: 'mock-tenant-001',
        label: 'T-99',
        capacity: 4,
        status: TableStatus.available,
        updatedAt: DateTime.now(),
      );
      
      await repository.createTable(newTable);
      
      final tables = await repository.watchTables('mock-tenant-001').first;
      expect(tables.any((t) => t.id == 'tbl-test-001'), isTrue);
      print('✅ Table created: ${newTable.label}');
    });

    test('should update table status', () async {
      final tables = await repository.watchTables('mock-tenant-001').first;
      final firstTable = tables.first;
      
      await repository.updateTableStatus(
        firstTable.id,
        TableStatus.occupied,
        activeOrderId: 'ord-test-001',
      );
      
      final updatedTables = await repository.watchTables('mock-tenant-001').first;
      final updatedTable = updatedTables.firstWhere((t) => t.id == firstTable.id);
      
      expect(updatedTable.status, TableStatus.occupied);
      expect(updatedTable.activeOrderId, 'ord-test-001');
      print('✅ Table status updated: ${firstTable.id}');
    });

    test('should delete table', () async {
      final tables = await repository.watchTables('mock-tenant-001').first;
      final initialCount = tables.length;
      final firstTable = tables.first;
      
      await repository.deleteTable(firstTable.id);
      
      final updatedTables = await repository.watchTables('mock-tenant-001').first;
      expect(updatedTables.length, initialCount - 1);
      expect(updatedTables.any((t) => t.id == firstTable.id), isFalse);
      print('✅ Table deleted: ${firstTable.id}');
    });
  });

  group('Task 3: Menu Repository Integration', () {
    late MockMenuRepository repository;

    setUp(() {
      repository = MockMenuRepository();
    });

    test('should load menu items from fixtures with correct tenant ID', () async {
      final items = await repository.watchMenuItems('mock-tenant-001').first;
      
      expect(items, isNotEmpty);
      expect(items.every((i) => i.tenantId == 'mock-tenant-001'), isTrue);
      expect(items.length, 12); // 12 items in fixtures
      print('✅ Menu items loaded: ${items.length} items');
    });

    test('should toggle item availability', () async {
      final items = await repository.watchMenuItems('mock-tenant-001').first;
      final firstItem = items.first;
      final originalAvailability = firstItem.isAvailable;
      
      await repository.toggleItemAvailability(firstItem.id, !originalAvailability);
      
      final updatedItems = await repository.watchMenuItems('mock-tenant-001').first;
      final updatedItem = updatedItems.firstWhere((i) => i.id == firstItem.id);
      
      expect(updatedItem.isAvailable, !originalAvailability);
      print('✅ Item availability toggled: ${firstItem.id}');
    });

    test('should create new menu item', () async {
      final newItem = MenuItemDto(
        id: 'item-test-001',
        tenantId: 'mock-tenant-001',
        categoryId: 'cat-002',
        name: 'Test Dish',
        price: 299.0,
        isAvailable: true,
        isVegetarian: true,
        prepTimeMinutes: 15,
        tags: ['test'],
      );
      
      await repository.createMenuItem(newItem);
      
      final items = await repository.watchMenuItems('mock-tenant-001').first;
      expect(items.any((i) => i.id == 'item-test-001'), isTrue);
      print('✅ Menu item created: ${newItem.name}');
    });

    test('should update menu item', () async {
      final items = await repository.watchMenuItems('mock-tenant-001').first;
      final firstItem = items.first;
      
      final updated = MenuItemDto(
        id: firstItem.id,
        tenantId: firstItem.tenantId,
        categoryId: firstItem.categoryId,
        name: 'Updated Name',
        description: firstItem.description,
        price: 999.0,
        imageUrl: firstItem.imageUrl,
        isAvailable: firstItem.isAvailable,
        isVegetarian: firstItem.isVegetarian,
        prepTimeMinutes: firstItem.prepTimeMinutes,
        tags: firstItem.tags,
      );
      
      await repository.updateMenuItem(updated);
      
      final updatedItems = await repository.watchMenuItems('mock-tenant-001').first;
      final updatedItem = updatedItems.firstWhere((i) => i.id == firstItem.id);
      
      expect(updatedItem.name, 'Updated Name');
      expect(updatedItem.price, 999.0);
      print('✅ Menu item updated: ${firstItem.id}');
    });

    test('should delete menu item', () async {
      final items = await repository.watchMenuItems('mock-tenant-001').first;
      final initialCount = items.length;
      final firstItem = items.first;
      
      await repository.deleteMenuItem(firstItem.id);
      
      final updatedItems = await repository.watchMenuItems('mock-tenant-001').first;
      expect(updatedItems.length, initialCount - 1);
      expect(updatedItems.any((i) => i.id == firstItem.id), isFalse);
      print('✅ Menu item deleted: ${firstItem.id}');
    });
  });

  group('Task 4: Analytics Data Integration', () {
    late MockOrdersRepository repository;

    setUp(() {
      repository = MockOrdersRepository();
    });

    test('should provide order data for analytics', () async {
      final orders = await repository.watchOrders('mock-tenant-001').first;
      
      // Calculate analytics metrics
      final totalOrders = orders.length;
      final totalRevenue = orders.fold<double>(
        0,
        (sum, order) => sum + order.totalAmount,
      );
      final averageOrderValue = totalRevenue / totalOrders;
      
      expect(totalOrders, greaterThan(0));
      expect(totalRevenue, greaterThan(0));
      expect(averageOrderValue, greaterThan(0));
      
      print('✅ Analytics data available:');
      print('   - Total orders: $totalOrders');
      print('   - Total revenue: ₹${totalRevenue.toStringAsFixed(2)}');
      print('   - Average order value: ₹${averageOrderValue.toStringAsFixed(2)}');
    });

    test('should group orders by status for analytics', () async {
      final orders = await repository.watchOrders('mock-tenant-001').first;
      
      final ordersByStatus = <OrderStatus, int>{};
      for (final order in orders) {
        ordersByStatus[order.status] = (ordersByStatus[order.status] ?? 0) + 1;
      }
      
      expect(ordersByStatus, isNotEmpty);
      print('✅ Orders by status:');
      ordersByStatus.forEach((status, count) {
        print('   - ${status.toString().split('.').last}: $count orders');
      });
    });
  });

  group('Cross-Module Integration', () {
    test('should maintain data consistency across all modules', () async {
      final ordersRepo = MockOrdersRepository();
      final staffRepo = MockStaffRepository();
      final tablesRepo = MockTablesRepository();
      final menuRepo = MockMenuRepository();
      
      const tenantId = 'mock-tenant-001';
      
      final orders = await ordersRepo.watchOrders(tenantId).first;
      final staff = await staffRepo.watchStaff(tenantId).first;
      final tables = await tablesRepo.watchTables(tenantId).first;
      final menuItems = await menuRepo.watchMenuItems(tenantId).first;
      
      // All modules should have data for the same tenant
      expect(orders, isNotEmpty);
      expect(staff, isNotEmpty);
      expect(tables, isNotEmpty);
      expect(menuItems, isNotEmpty);
      
      // All data should use the same tenant ID
      expect(orders.every((o) => o.tenantId == tenantId), isTrue);
      expect(staff.every((s) => s.tenantId == tenantId), isTrue);
      expect(tables.every((t) => t.tenantId == tenantId), isTrue);
      expect(menuItems.every((m) => m.tenantId == tenantId), isTrue);
      
      print('✅ All modules maintain consistent tenant ID: $tenantId');
      print('   - Orders: ${orders.length}');
      print('   - Staff: ${staff.length}');
      print('   - Tables: ${tables.length}');
      print('   - Menu items: ${menuItems.length}');
    });
  });
}
