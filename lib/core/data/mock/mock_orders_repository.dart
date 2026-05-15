// ── MockOrdersRepository ──────────────────────────────────────────────────────
// Full mock implementation of OrdersRepository.
// • Loads from orders_fixtures.json on first access (lazy).
// • Mutations update in-memory state and push to stream.
// • watchOrders() simulates realtime by periodic polling + mutation events.
//
// MIGRATION PATH: Replace MockOrdersRepository with SupabaseOrdersRepository
// in repository_providers.dart. Zero UI changes required.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../repositories/orders_repository.dart';
import '../dtos/order_dto.dart';

class MockOrdersRepository implements OrdersRepository {
  List<OrderDto>? _orders;
  final _ordersController = StreamController<List<OrderDto>>.broadcast();

  // ── Lazy fixture loader ───────────────────────────────────────────────────
  Future<void> _ensureLoaded() async {
    if (_orders != null) return;
    final raw = await rootBundle.loadString(
      'lib/core/data/mock/fixtures/orders_fixtures.json',
    );
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _orders = (json['orders'] as List)
        .map((e) => OrderDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  void _broadcast() => _ordersController.add(List.from(_orders!));

  // ── Fetch orders ──────────────────────────────────────────────────────────
  @override
  Future<List<OrderDto>> getOrders(
    String tenantId, {
    OrderStatus? status,
    String? tableId,
    DateTime? from,
    DateTime? to,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    await _ensureLoaded();
    return _orders!.where((o) {
      if (o.tenantId != tenantId) return false;
      if (status != null && o.status != status) return false;
      if (tableId != null && o.tableId != tableId) return false;
      if (from != null && o.createdAt.isBefore(from)) return false;
      if (to != null && o.createdAt.isAfter(to)) return false;
      return true;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<OrderDto?> getOrderById(String orderId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    await _ensureLoaded();
    try {
      return _orders!.firstWhere((o) => o.id == orderId);
    } catch (_) {
      return null;
    }
  }

  // ── Mutations ─────────────────────────────────────────────────────────────
  @override
  Future<OrderDto> createOrder(OrderDto order) async {
    await Future.delayed(const Duration(milliseconds: 500));
    await _ensureLoaded();
    _orders!.add(order);
    _broadcast();
    return order;
  }

  @override
  Future<OrderDto> updateOrderStatus(
    String orderId,
    OrderStatus newStatus,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    await _ensureLoaded();
    final idx = _orders!.indexWhere((o) => o.id == orderId);
    if (idx == -1) throw Exception('Order not found: $orderId');
    final updated =
        _orders![idx].copyWith(status: newStatus, updatedAt: DateTime.now());
    _orders![idx] = updated;
    _broadcast();
    return updated;
  }

  @override
  Future<void> cancelOrder(String orderId) async {
    await updateOrderStatus(orderId, OrderStatus.cancelled);
  }

  // ── Realtime-like stream ──────────────────────────────────────────────────
  @override
  Stream<List<OrderDto>> watchOrders(String tenantId) async* {
    await _ensureLoaded();
    yield _orders!.where((o) => o.tenantId == tenantId).toList();
    yield* _ordersController.stream
        .map((orders) => orders.where((o) => o.tenantId == tenantId).toList());
  }

  // ── Daily summary ─────────────────────────────────────────────────────────
  @override
  Future<Map<String, dynamic>> getDailySummary(
    String tenantId,
    DateTime date,
  ) async {
    await Future.delayed(const Duration(milliseconds: 350));
    await _ensureLoaded();

    final dayOrders = _orders!.where((o) {
      return o.tenantId == tenantId &&
          o.createdAt.year == date.year &&
          o.createdAt.month == date.month &&
          o.createdAt.day == date.day &&
          o.status != OrderStatus.cancelled;
    }).toList();

    final revenue = dayOrders.fold<double>(0, (s, o) => s + o.totalAmount);

    return {
      'total_orders': dayOrders.length,
      'total_revenue': revenue,
      'pending': dayOrders.where((o) => o.status == OrderStatus.pending).length,
      'preparing':
          dayOrders.where((o) => o.status == OrderStatus.preparing).length,
      'ready': dayOrders.where((o) => o.status == OrderStatus.ready).length,
      'served': dayOrders.where((o) => o.status == OrderStatus.served).length,
    };
  }
}
