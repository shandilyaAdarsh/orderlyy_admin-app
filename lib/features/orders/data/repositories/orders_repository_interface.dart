// ── Orders Repository Interface ──────────────────────────────────────────────
// Clean, stable contract that UI and business logic depend on.
// Implementation details (mock/live/offline) are hidden behind this interface.

import '../../../../shared/models/result.dart';
import '../../../../shared/models/failures.dart';
import '../../domain/models/order.dart';
import '../../domain/models/order_status.dart';

/// Orders repository interface
///
/// This contract remains stable regardless of implementation:
/// - MockOrdersRepository (development/testing)
/// - RemoteOrdersRepository (live API)
/// - OfflineFirstOrdersRepository (offline-capable)
/// - HybridOrdersRepository (local + remote orchestration)
abstract class IOrdersRepository {
  // ── Query Operations ──────────────────────────────────────────────────────

  /// Get all orders for a tenant
  Future<Result<List<Order>, AppFailure>> getOrders(
    String tenantId, {
    OrderStatus? status,
    String? tableId,
    DateTime? from,
    DateTime? to,
  });

  /// Get a single order by ID
  Future<Result<Order, AppFailure>> getOrderById(String orderId);

  /// Get orders by table
  Future<Result<List<Order>, AppFailure>> getOrdersByTable(String tableId);

  /// Get orders by status
  Future<Result<List<Order>, AppFailure>> getOrdersByStatus(
    String tenantId,
    OrderStatus status,
  );

  /// Get active orders (not served or cancelled)
  Future<Result<List<Order>, AppFailure>> getActiveOrders(String tenantId);

  // ── Mutation Operations ───────────────────────────────────────────────────

  /// Create a new order
  Future<Result<Order, AppFailure>> createOrder(Order order);

  /// Update order status
  Future<Result<Order, AppFailure>> updateOrderStatus(
    String orderId,
    OrderStatus newStatus,
  );

  /// Update entire order
  Future<Result<Order, AppFailure>> updateOrder(Order order);

  /// Cancel an order
  Future<Result<void, AppFailure>> cancelOrder(String orderId);

  /// Delete an order (soft delete)
  Future<Result<void, AppFailure>> deleteOrder(String orderId);

  // ── Real-time Operations ──────────────────────────────────────────────────

  /// Watch all orders for a tenant (real-time updates)
  Stream<Result<List<Order>, AppFailure>> watchOrders(String tenantId);

  /// Watch a single order (real-time updates)
  Stream<Result<Order, AppFailure>> watchOrder(String orderId);

  // ── Analytics Operations ──────────────────────────────────────────────────

  /// Get daily summary
  Future<Result<OrderSummary, AppFailure>> getDailySummary(
    String tenantId,
    DateTime date,
  );

  /// Get order statistics
  Future<Result<OrderStatistics, AppFailure>> getStatistics(
    String tenantId, {
    DateTime? from,
    DateTime? to,
  });

  // ── Sync Operations (for offline-first implementations) ───────────────────

  /// Sync pending changes (no-op for non-offline implementations)
  Future<Result<SyncResult, AppFailure>> syncPendingChanges() async {
    return Result.success(SyncResult.noChanges());
  }

  /// Check if there are pending changes
  Future<bool> hasPendingChanges() async => false;
}

/// Order summary for analytics
class OrderSummary {
  final int totalOrders;
  final int completedOrders;
  final int cancelledOrders;
  final int activeOrders;
  final double totalRevenue;
  final DateTime date;

  const OrderSummary({
    required this.totalOrders,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.activeOrders,
    required this.totalRevenue,
    required this.date,
  });
}

/// Order statistics
class OrderStatistics {
  final int totalOrders;
  final double averageOrderValue;
  final double totalRevenue;
  final Map<OrderStatus, int> ordersByStatus;
  final DateTime from;
  final DateTime to;

  const OrderStatistics({
    required this.totalOrders,
    required this.averageOrderValue,
    required this.totalRevenue,
    required this.ordersByStatus,
    required this.from,
    required this.to,
  });
}

/// Sync result
class SyncResult {
  final int synced;
  final int failed;
  final List<String> errors;

  const SyncResult({
    required this.synced,
    required this.failed,
    required this.errors,
  });

  factory SyncResult.noChanges() =>
      const SyncResult(synced: 0, failed: 0, errors: []);

  bool get hasErrors => errors.isNotEmpty;
  bool get isSuccess => failed == 0;
}
