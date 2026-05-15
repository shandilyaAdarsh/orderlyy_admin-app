// ── OrdersRepository interface ─────────────────────────────────────────────────
// The UI layer ONLY depends on this contract.
// Implementations: MockOrdersRepository (dev) | SupabaseOrdersRepository (prod)

import '../dtos/order_dto.dart';

abstract class OrdersRepository {
  // ── Fetch orders ──────────────────────────────────────────────────────────
  Future<List<OrderDto>> getOrders(
    String tenantId, {
    OrderStatus? status,
    String? tableId,
    DateTime? from,
    DateTime? to,
  });

  Future<OrderDto?> getOrderById(String orderId);

  // ── Mutations ─────────────────────────────────────────────────────────────
  Future<OrderDto> createOrder(OrderDto order);

  Future<OrderDto> updateOrderStatus(String orderId, OrderStatus newStatus);

  Future<void> cancelOrder(String orderId);

  // ── Realtime-like stream (fake events in mock) ────────────────────────────
  Stream<List<OrderDto>> watchOrders(String tenantId);

  // ── Summary/analytics ─────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getDailySummary(String tenantId, DateTime date);
}
