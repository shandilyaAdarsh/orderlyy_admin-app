// ── Orders Mock Data Source ──────────────────────────────────────────────────
// Provides mock data for development and testing.
// Simulates network latency and real-time updates.

import 'dart:async';
import 'dart:math';
import '../../../../core/data/datasources/base/base_datasource.dart';
import '../../../../core/data/dtos/order_dto.dart';
import '../../../../core/utils/uuid.dart';

/// Mock data source for orders
class OrdersMockDataSource extends MockDataSource<OrderDto> {
  final List<OrderDto> _mockOrders = [];
  final StreamController<List<OrderDto>> _controller =
      StreamController<List<OrderDto>>.broadcast();

  OrdersMockDataSource() {
    _initializeMockData();
  }

  void _initializeMockData() {
    // Initialize with some mock orders
    _mockOrders.addAll([
      OrderDto(
        id: 'order-1',
        tenantId: 'tenant-1',
        tableId: 'table-1',
        tableLabel: 'Table 1',
        status: OrderStatus.pending,
        items: [
          OrderItemDto(
            id: 'item-1',
            menuItemId: 'menu-1',
            menuItemName: 'Butter Chicken',
            quantity: 2,
            unitPrice: 350.0,
          ),
        ],
        totalAmount: 700.0,
        createdAt: DateTime.now().subtract(Duration(minutes: 10)),
        updatedAt: DateTime.now().subtract(Duration(minutes: 10)),
      ),
      OrderDto(
        id: 'order-2',
        tenantId: 'tenant-1',
        tableId: 'table-2',
        tableLabel: 'Table 2',
        status: OrderStatus.confirmed,
        items: [
          OrderItemDto(
            id: 'item-2',
            menuItemId: 'menu-2',
            menuItemName: 'Paneer Tikka',
            quantity: 1,
            unitPrice: 280.0,
          ),
        ],
        totalAmount: 280.0,
        createdAt: DateTime.now().subtract(Duration(minutes: 20)),
        updatedAt: DateTime.now().subtract(Duration(minutes: 15)),
      ),
    ]);
  }

  @override
  Future<List<OrderDto>> getMockData() async {
    await simulateLatency();
    return List.from(_mockOrders);
  }

  @override
  Future<OrderDto?> getMockById(String id) async {
    await simulateLatency();
    try {
      return _mockOrders.firstWhere((order) => order.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<OrderDto> mockCreate(OrderDto dto) async {
    await simulateLatency();

    final newOrder = OrderDto(
      id: UuidGenerator.generateRuntimeId(prefix: 'order'),
      tenantId: dto.tenantId,
      tableId: dto.tableId,
      tableLabel: dto.tableLabel,
      status: dto.status,
      items: dto.items,
      totalAmount: dto.totalAmount,
      staffId: dto.staffId,
      staffName: dto.staffName,
      notes: dto.notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _mockOrders.add(newOrder);
    _controller.add(List.from(_mockOrders));

    return newOrder;
  }

  @override
  Future<OrderDto> mockUpdate(OrderDto dto) async {
    await simulateLatency();

    final index = _mockOrders.indexWhere((order) => order.id == dto.id);
    if (index >= 0) {
      _mockOrders[index] = dto.copyWith(updatedAt: DateTime.now());
      _controller.add(List.from(_mockOrders));
      return _mockOrders[index];
    }

    throw Exception('Order not found: ${dto.id}');
  }

  @override
  Future<void> mockDelete(String id) async {
    await simulateLatency();

    _mockOrders.removeWhere((order) => order.id == id);
    _controller.add(List.from(_mockOrders));
  }

  @override
  Stream<List<OrderDto>> mockWatch() {
    return _controller.stream;
  }

  /// Get mock orders by tenant
  Future<List<OrderDto>> getMockByTenant(String tenantId) async {
    await simulateLatency();
    return _mockOrders.where((order) => order.tenantId == tenantId).toList();
  }

  /// Get mock orders by status
  Future<List<OrderDto>> getMockByStatus(OrderStatus status) async {
    await simulateLatency();
    return _mockOrders.where((order) => order.status == status).toList();
  }

  /// Update order status
  Future<OrderDto> mockUpdateStatus(String id, OrderStatus newStatus) async {
    await simulateLatency();

    final index = _mockOrders.indexWhere((order) => order.id == id);
    if (index >= 0) {
      _mockOrders[index] = _mockOrders[index].copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
      );
      _controller.add(List.from(_mockOrders));
      return _mockOrders[index];
    }

    throw Exception('Order not found: $id');
  }

  /// Simulate random order updates (for testing real-time)
  void simulateRandomUpdates() {
    Timer.periodic(Duration(seconds: 10), (timer) {
      if (_mockOrders.isEmpty) return;

      final random = Random();
      final index = random.nextInt(_mockOrders.length);
      final order = _mockOrders[index];

      // Randomly update status
      final statuses = OrderStatus.values;
      final newStatus = statuses[random.nextInt(statuses.length)];

      _mockOrders[index] = order.copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
      );

      _controller.add(List.from(_mockOrders));
    });
  }

  void dispose() {
    _controller.close();
  }
}
