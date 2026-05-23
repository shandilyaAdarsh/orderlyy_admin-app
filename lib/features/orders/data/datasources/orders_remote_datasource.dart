// ── Orders Remote Data Source ────────────────────────────────────────────────
// Handles all remote API calls for orders.
// Can be implemented with REST, GraphQL, gRPC, etc.

import '../../../../core/data/datasources/base/base_datasource.dart';
import '../../../../core/data/dtos/order_dto.dart';

/// Remote data source for orders (API calls)
abstract class OrdersRemoteDataSource extends RemoteDataSource<OrderDto> {
  /// Fetch orders with filters
  @override
  Future<List<OrderDto>> fetchAll(Map<String, dynamic>? params);

  /// Fetch single order
  @override
  Future<OrderDto> fetchById(String id);

  /// Create order on server
  @override
  Future<OrderDto> create(OrderDto dto);

  /// Update order on server
  @override
  Future<OrderDto> update(OrderDto dto);

  /// Delete order on server
  @override
  Future<void> delete(String id);

  /// Update order status
  Future<OrderDto> updateStatus(String id, OrderStatus newStatus);

  /// Cancel order
  Future<void> cancel(String id);

  /// Get daily summary
  Future<Map<String, dynamic>> getDailySummary(String tenantId, DateTime date);

  /// Watch orders (WebSocket/SSE)
  @override
  Stream<List<OrderDto>>? watchAll(Map<String, dynamic>? params);
}

/// REST API implementation
class OrdersRestDataSource implements OrdersRemoteDataSource {
  // ignore: unused_field
  final dynamic _httpClient; // Dio, http, etc.
  // ignore: unused_field
  final String _baseUrl;

  OrdersRestDataSource(this._httpClient, this._baseUrl);

  @override
  Future<List<OrderDto>> fetchAll(Map<String, dynamic>? params) async {
    // Implementation with actual HTTP client
    throw UnimplementedError('REST implementation pending');
  }

  @override
  Future<OrderDto> fetchById(String id) async {
    throw UnimplementedError('REST implementation pending');
  }

  @override
  Future<OrderDto> create(OrderDto dto) async {
    throw UnimplementedError('REST implementation pending');
  }

  @override
  Future<OrderDto> update(OrderDto dto) async {
    throw UnimplementedError('REST implementation pending');
  }

  @override
  Future<void> delete(String id) async {
    throw UnimplementedError('REST implementation pending');
  }

  @override
  Future<OrderDto> updateStatus(String id, OrderStatus newStatus) async {
    throw UnimplementedError('REST implementation pending');
  }

  @override
  Future<void> cancel(String id) async {
    throw UnimplementedError('REST implementation pending');
  }

  @override
  Future<Map<String, dynamic>> getDailySummary(
    String tenantId,
    DateTime date,
  ) async {
    throw UnimplementedError('REST implementation pending');
  }

  @override
  Stream<List<OrderDto>>? watchAll(Map<String, dynamic>? params) {
    // WebSocket or SSE implementation
    return null;
  }

  @override
  Stream<OrderDto?>? watchOne(String id) {
    return null;
  }
}
