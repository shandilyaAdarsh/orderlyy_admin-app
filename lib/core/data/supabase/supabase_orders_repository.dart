import 'package:supabase_flutter/supabase_flutter.dart';
import '../dtos/order_dto.dart';
import '../repositories/orders_repository.dart';

class SupabaseOrdersRepository implements OrdersRepository {
  final SupabaseClient _client;

  SupabaseOrdersRepository(this._client);

  @override
  Future<List<OrderDto>> getOrders(
    String tenantId, {
    OrderStatus? status,
    String? tableId,
    DateTime? from,
    DateTime? to,
  }) async {
    var query = _client.from('orders').select().eq('tenant_id', tenantId);

    if (status != null) {
      query = query.eq('status', status.name);
    }
    if (tableId != null) {
      query = query.eq('table_id', tableId);
    }
    if (from != null) {
      query = query.gte('created_at', from.toUtc().toIso8601String());
    }
    if (to != null) {
      query = query.lte('created_at', to.toUtc().toIso8601String());
    }

    final response = await query.order('created_at', ascending: false);
    return (response as List).map((json) => OrderDto.fromJson(json)).toList();
  }

  @override
  Future<OrderDto?> getOrderById(String orderId) async {
    final response = await _client
        .from('orders')
        .select()
        .eq('id', orderId)
        .maybeSingle();

    if (response == null) return null;
    return OrderDto.fromJson(response);
  }

  @override
  Future<OrderDto> createOrder(OrderDto order) async {
    final response = await _client
        .from('orders')
        .insert(order.toJson())
        .select()
        .single();

    return OrderDto.fromJson(response);
  }

  @override
  Future<OrderDto> updateOrderStatus(
    String orderId,
    OrderStatus newStatus,
  ) async {
    final response = await _client
        .from('orders')
        .update({
          'status': newStatus.name,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', orderId)
        .select()
        .single();

    return OrderDto.fromJson(response);
  }

  @override
  Future<OrderDto> updateOrder(OrderDto order) async {
    final response = await _client
        .from('orders')
        .update(order.toJson())
        .eq('id', order.id)
        .select()
        .single();

    return OrderDto.fromJson(response);
  }

  @override
  Future<void> cancelOrder(String orderId) async {
    await updateOrderStatus(orderId, OrderStatus.cancelled);
  }

  @override
  Stream<List<OrderDto>> watchOrders(String tenantId) {
    return _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('tenant_id', tenantId)
        .map((rows) => rows.map((r) => OrderDto.fromJson(r)).toList());
  }

  @override
  Future<Map<String, dynamic>> getDailySummary(
    String tenantId,
    DateTime date,
  ) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final orders = await getOrders(tenantId, from: startOfDay, to: endOfDay);

    // Filter out cancelled orders exactly like the mock does.
    final dayOrders = orders
        .where((o) => o.status != OrderStatus.cancelled)
        .toList();

    final totalOrders = dayOrders.length;
    final totalRevenue = dayOrders.fold(0.0, (sum, o) => sum + o.totalAmount);

    return {
      'total_orders': totalOrders,
      'total_revenue': totalRevenue,
      'pending': dayOrders.where((o) => o.status == OrderStatus.pending).length,
      'preparing': dayOrders
          .where((o) => o.status == OrderStatus.preparing)
          .length,
      'ready': dayOrders.where((o) => o.status == OrderStatus.ready).length,
      'served': dayOrders.where((o) => o.status == OrderStatus.served).length,
    };
  }
}
