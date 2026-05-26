// ── Orders Notifier ──────────────────────────────────────────────────────────
// Manages orders state with offline-first architecture.
// All state transitions are deterministic and serializable.
// Supports state persistence for crash recovery.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/orders_repository_interface.dart';
import '../../../../core/storage/state_persistence.dart';
import '../../../../core/utils/uuid.dart';
import '../../../../shared/models/result.dart';
import '../../../../shared/models/failures.dart';
import '../../domain/models/order.dart';
import '../../domain/models/order_status.dart' as domain;
import 'orders_state.dart';

class OrdersNotifier extends StateNotifier<OrdersState> {
  final IOrdersRepository _repository;
  final StatePersistence _persistence;
  final String _tenantId;
  static const String _stateKeyPrefix = 'orders_state';
  static const int _stateEnvelopeVersion = 1;

  OrdersNotifier({
    required IOrdersRepository repository,
    required StatePersistence persistence,
    required String tenantId,
  }) : _repository = repository,
       _persistence = persistence,
       _tenantId = tenantId,
       super(OrdersState.initial()) {
    _initialize();
  }

  // ── Initialize ────────────────────────────────────────────────────────────

  Future<void> _initialize() async {
    // Try to restore state from persistence
    await _hydrateState();

    // Load fresh data from repository
    await loadOrders();
  }

  // ── State Hydration ───────────────────────────────────────────────────────

  Future<void> _hydrateState() async {
    try {
      final json = await _persistence.loadState(_stateKey);
      if (json == null) return;

      final version = json['version'];
      final contextScope = json['contextScope'];
      final payload = json['payload'];

      // Legacy payload compatibility (no envelope/version).
      if (version == null) {
        state = OrdersState.fromJson(json);
        await _persistState();
        return;
      }

      if (version is! int || version > _stateEnvelopeVersion) {
        debugPrint(
          'Unsupported orders state version ($version) for $_stateKey. Falling back to fresh state.',
        );
        state = OrdersState.initial();
        return;
      }

      if (contextScope is! String || contextScope != _tenantId) {
        debugPrint(
          'Orders state context mismatch for $_stateKey. Expected=$_tenantId got=$contextScope.',
        );
        state = OrdersState.initial();
        return;
      }

      if (payload is Map) {
        state = OrdersState.fromJson(Map<String, dynamic>.from(payload));
      }
    } catch (e) {
      // If hydration fails, continue with initial state
      debugPrint('Failed to hydrate orders state: $e');
    }
  }

  // ── State Persistence ─────────────────────────────────────────────────────

  Future<void> _persistState() async {
    try {
      await _persistence.saveState(_stateKey, {
        'version': _stateEnvelopeVersion,
        'contextScope': _tenantId,
        'payload': state.toJson(),
      });
    } catch (e) {
      // Log but don't throw - persistence failure shouldn't crash app
      debugPrint('Failed to persist orders state: $e');
    }
  }

  @override
  set state(OrdersState value) {
    super.state = value;
    _persistState();
  }

  // ── Load Orders ───────────────────────────────────────────────────────────

  Future<void> loadOrders() async {
    state = state.copyWith(status: LoadingStatus.loading);

    final result = await _repository.getOrders(_tenantId);

    result.fold(
      (orders) {
        state = state.copyWith(
          orders: orders,
          status: LoadingStatus.success,
          lastSyncedAt: DateTime.now(),
          error: null,
        );
      },
      (failure) {
        state = state.copyWith(status: LoadingStatus.error, error: failure);
      },
    );
  }

  // ── Create Order ──────────────────────────────────────────────────────────

  Future<Result<Order, AppFailure>> createOrder(Order order) async {
    // Generate temporary ID for optimistic update
    final tempId = UuidGenerator.generateRuntimeId(prefix: 'temp-order');
    final optimisticOrder = order.copyWith(id: tempId);

    // Optimistic update
    state = state.copyWith(
      orders: [...state.orders, optimisticOrder],
      optimisticIds: {...state.optimisticIds, tempId},
    );

    final result = await _repository.createOrder(order);

    return result.fold(
      (createdOrder) {
        // Replace temp with real order
        state = state.copyWith(
          orders: state.orders
              .map((o) => o.id == tempId ? createdOrder : o)
              .toList(),
          optimisticIds: state.optimisticIds.difference({tempId}),
          lastSyncedAt: DateTime.now(),
        );
        return Result.success(createdOrder);
      },
      (failure) {
        // Rollback on error
        state = state.copyWith(
          orders: state.orders.where((o) => o.id != tempId).toList(),
          optimisticIds: state.optimisticIds.difference({tempId}),
          failedIds: {...state.failedIds, tempId},
        );
        return Result.failure(failure);
      },
    );
  }

  // ── Update Order Status ───────────────────────────────────────────────────

  Future<Result<Order, AppFailure>> updateOrderStatus(
    String orderId,
    domain.OrderStatus newStatus,
  ) async {
    // Find current order
    final currentOrder = state.orders.firstWhere(
      (o) => o.id == orderId,
      orElse: () => throw StateError('Order not found'),
    );

    // Optimistic update
    final updatedOrder = currentOrder.updateStatus(newStatus);
    state = state.copyWith(
      orders: state.orders
          .map((o) => o.id == orderId ? updatedOrder : o)
          .toList(),
    );

    final result = await _repository.updateOrderStatus(orderId, newStatus);

    return result.fold(
      (resultOrder) {
        // Update with server response
        state = state.copyWith(
          orders: state.orders
              .map((o) => o.id == orderId ? resultOrder : o)
              .toList(),
          lastSyncedAt: DateTime.now(),
        );
        return Result.success(resultOrder);
      },
      (failure) {
        // Rollback on error
        state = state.copyWith(
          orders: state.orders
              .map((o) => o.id == orderId ? currentOrder : o)
              .toList(),
        );
        return Result.failure(failure);
      },
    );
  }

  // ── Cancel Order ──────────────────────────────────────────────────────────

  Future<Result<void, AppFailure>> cancelOrder(String orderId) async {
    return updateOrderStatus(
      orderId,
      domain.OrderStatus.cancelled,
    ).then((result) => result.map((_) {}));
  }

  // ── Refresh ───────────────────────────────────────────────────────────────

  Future<void> refresh() async {
    await loadOrders();
  }

  // ── Filter Helpers ────────────────────────────────────────────────────────

  List<Order> getOrdersByStatus(domain.OrderStatus status) {
    return state.orders.where((o) => o.status == status).toList();
  }

  List<Order> getActiveOrders() {
    return state.orders.where((o) => o.isActive).toList();
  }

  Order? getOrderById(String orderId) {
    try {
      return state.orders.firstWhere((o) => o.id == orderId);
    } catch (e) {
      return null;
    }
  }

  String get _stateKey => '$_stateKeyPrefix:$_tenantId';
}
