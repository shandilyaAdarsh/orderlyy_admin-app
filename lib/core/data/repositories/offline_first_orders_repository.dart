import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/dtos/order_dto.dart';
import '../../data/dtos/sync_action.dart';
import '../../data/local/offline_sync_queue.dart';
import '../../utils/uuid.dart';
import 'orders_repository.dart';

class OfflineFirstOrdersRepository implements OrdersRepository {
  final OrdersRepository _delegate;
  final OfflineSyncQueue _queue;
  // Broadcast controller signals the merged stream to re-emit on local queue changes.
  // Must be closed via dispose() when the provider is torn down.
  final StreamController<void> _updateController =
      StreamController<void>.broadcast();

  OfflineFirstOrdersRepository({
    required OrdersRepository delegate,
    required OfflineSyncQueue queue,
  }) : _delegate = delegate,
       _queue = queue;

  /// Called by the Riverpod provider via ref.onDispose — closes the internal
  /// broadcast stream so no StreamSubscription leaks after provider invalidation.
  void dispose() {
    if (!_updateController.isClosed) {
      _updateController.close();
    }
  }

  // Getter to inspect connection status externally
  bool get isOnline => _queue.isOnline();

  // Helper trigger to signal that offline/online status changed externally
  void notifyConnectionChanged() {
    _updateController.add(null);
    if (_queue.isOnline()) {
      syncPendingQueue().catchError((e) {
        debugPrint(
          '[OfflineFirstOrdersRepository] Auto-sync on reconnect failed: $e',
        );
      });
    }
  }

  // ── Fetch orders ──────────────────────────────────────────────────────────
  @override
  Future<List<OrderDto>> getOrders(
    String tenantId, {
    OrderStatus? status,
    String? tableId,
    DateTime? from,
    DateTime? to,
  }) async {
    if (_queue.isOnline()) {
      try {
        final list = await _delegate.getOrders(
          tenantId,
          status: status,
          tableId: tableId,
          from: from,
          to: to,
        );
        await _queue.cacheOrders(list);
        final queue = await _queue.getQueue();
        return _applyUpdates(list, queue);
      } catch (e) {
        debugPrint(
          '[OfflineFirstOrdersRepository] getOrders online failed, falling back to local cache: $e',
        );
      }
    }

    final cached = await _queue.getCachedOrders();
    final queue = await _queue.getQueue();
    final applied = _applyUpdates(cached, queue);
    return applied.where((o) {
      if (o.tenantId != tenantId) return false;
      if (status != null && o.status != status) return false;
      if (tableId != null && o.tableId != tableId) return false;
      if (from != null && o.createdAt.isBefore(from)) return false;
      if (to != null && o.createdAt.isAfter(to)) return false;
      return true;
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<OrderDto?> getOrderById(String orderId) async {
    if (_queue.isOnline()) {
      try {
        final order = await _delegate.getOrderById(orderId);
        if (order != null) {
          final cached = await _queue.getCachedOrders();
          final idx = cached.indexWhere((o) => o.id == orderId);
          if (idx != -1) {
            cached[idx] = order;
          } else {
            cached.add(order);
          }
          await _queue.cacheOrders(cached);
        }
        return order;
      } catch (e) {
        debugPrint(
          '[OfflineFirstOrdersRepository] getOrderById online failed, falling back to local cache: $e',
        );
      }
    }

    final cached = await _queue.getCachedOrders();
    final queue = await _queue.getQueue();
    final applied = _applyUpdates(cached, queue);
    try {
      return applied.firstWhere((o) => o.id == orderId);
    } catch (_) {
      return null;
    }
  }

  // ── Realtime-like stream ──────────────────────────────────────────────────
  @override
  Stream<List<OrderDto>> watchOrders(String tenantId) {
    final controller = StreamController<List<OrderDto>>();
    StreamSubscription? delegateSub;
    StreamSubscription? localSub;

    void emitCurrent() async {
      try {
        final cached = await _queue.getCachedOrders();
        final queue = await _queue.getQueue();
        final result = _applyUpdates(cached, queue);
        if (!controller.isClosed) {
          controller.add(result);
        }
      } catch (e) {
        debugPrint(
          '[OfflineFirstOrdersRepository] Error emitting combined state: $e',
        );
      }
    }

    // Emit initial cached data
    emitCurrent();

    // Listen to live stream
    delegateSub = _delegate
        .watchOrders(tenantId)
        .listen(
          (remoteList) async {
            await _queue.cacheOrders(remoteList);
            emitCurrent();
          },
          onError: (Object err) {
            if (!controller.isClosed) {
              controller.addError(err);
            }
          },
        );

    // Listen to local queue operations
    localSub = _updateController.stream.listen((_) {
      emitCurrent();
    });

    controller.onCancel = () {
      delegateSub?.cancel();
      localSub?.cancel();
      controller.close();
    };

    return controller.stream;
  }

  // ── Mutations ─────────────────────────────────────────────────────────────
  @override
  Future<OrderDto> createOrder(OrderDto order) async {
    final action = SyncAction(
      id: UuidGenerator.generateRuntimeId(prefix: 'act-create'),
      type: 'createOrder',
      payload: order.toJson(),
      timestamp: DateTime.now(),
      idempotencyKey: UuidGenerator.generateRuntimeId(prefix: 'idem-create'),
    );

    await _queue.enqueue(action);
    _updateController.add(null);

    if (_queue.isOnline()) {
      syncPendingQueue().catchError((e) {
        debugPrint('[OfflineFirstOrdersRepository] Immediate sync error: $e');
      });
    }

    return order;
  }

  @override
  Future<OrderDto> updateOrder(OrderDto order) async {
    final action = SyncAction(
      id: UuidGenerator.generateRuntimeId(prefix: 'act-update'),
      type: 'updateOrder',
      payload: order.toJson(),
      timestamp: DateTime.now(),
      idempotencyKey: UuidGenerator.generateRuntimeId(prefix: 'idem-update'),
    );

    await _queue.enqueue(action);
    _updateController.add(null);

    if (_queue.isOnline()) {
      syncPendingQueue().catchError((e) {
        debugPrint('[OfflineFirstOrdersRepository] Immediate sync error: $e');
      });
    }

    return order;
  }

  @override
  Future<OrderDto> updateOrderStatus(
    String orderId,
    OrderStatus newStatus,
  ) async {
    final cachedList = await _queue.getCachedOrders();
    final idx = cachedList.indexWhere((o) => o.id == orderId);
    final order = idx != -1
        ? cachedList[idx].copyWith(status: newStatus, updatedAt: DateTime.now())
        : (throw StateError(
            'Cannot update status for unknown order $orderId without resolved tenant/table context.',
          ));

    final action = SyncAction(
      id: UuidGenerator.generateRuntimeId(prefix: 'act-status'),
      type: 'updateOrderStatus',
      payload: {'orderId': orderId, 'status': newStatus.name},
      timestamp: DateTime.now(),
      idempotencyKey: UuidGenerator.generateRuntimeId(prefix: 'idem-status'),
    );

    await _queue.enqueue(action);
    _updateController.add(null);

    if (_queue.isOnline()) {
      syncPendingQueue().catchError((e) {
        debugPrint('[OfflineFirstOrdersRepository] Immediate sync error: $e');
      });
    }

    return order;
  }

  @override
  Future<void> cancelOrder(String orderId) async {
    final action = SyncAction(
      id: UuidGenerator.generateRuntimeId(prefix: 'act-cancel'),
      type: 'cancelOrder',
      payload: {'orderId': orderId},
      timestamp: DateTime.now(),
      idempotencyKey: UuidGenerator.generateRuntimeId(prefix: 'idem-cancel'),
    );

    await _queue.enqueue(action);
    _updateController.add(null);

    if (_queue.isOnline()) {
      syncPendingQueue().catchError((e) {
        debugPrint('[OfflineFirstOrdersRepository] Immediate sync error: $e');
      });
    }
  }

  // ── Sync Queue ─────────────────────────────────────────────────────────────
  // NOTE: Not part of OrdersRepository interface — called internally and by IsOnlineNotifier.
  Future<void> syncPendingQueue() async {
    if (!_queue.isOnline()) return;

    final queue = await _queue.getQueue();
    if (queue.isEmpty) return;

    debugPrint(
      '[OfflineFirstOrdersRepository] Syncing ${queue.length} pending actions...',
    );
    for (final action in queue) {
      try {
        if (action.type == 'createOrder') {
          final order = OrderDto.fromJson(action.payload);
          await _delegate.createOrder(order);
        } else if (action.type == 'updateOrder') {
          final order = OrderDto.fromJson(action.payload);
          await _delegate.updateOrder(order);
        } else if (action.type == 'updateOrderStatus') {
          final orderId = action.payload['orderId'] as String;
          final statusName = action.payload['status'] as String;
          final status = OrderStatus.values.firstWhere(
            (e) => e.name == statusName,
          );
          await _delegate.updateOrderStatus(orderId, status);
        } else if (action.type == 'cancelOrder') {
          final orderId = action.payload['orderId'] as String;
          await _delegate.cancelOrder(orderId);
        }

        // Successfully synchronized, remove from persistent queue
        await _queue.dequeue(action.id);
        _updateController.add(null);
      } catch (e) {
        debugPrint(
          '[OfflineFirstOrdersRepository] Action ${action.id} failed to sync: $e',
        );
        // Stop sequential processing if we hit network/connectivity issues to preserve order operations
        break;
      }
    }
  }

  // ── Apply Optimistic Updates ──────────────────────────────────────────────
  List<OrderDto> _applyUpdates(
    List<OrderDto> baseList,
    List<SyncAction> queue,
  ) {
    final list = List<OrderDto>.from(baseList);

    for (final action in queue) {
      if (action.type == 'createOrder') {
        final order = OrderDto.fromJson(action.payload);
        final idx = list.indexWhere((o) => o.id == order.id);
        if (idx != -1) {
          list[idx] = order;
        } else {
          list.add(order);
        }
      } else if (action.type == 'updateOrder') {
        final order = OrderDto.fromJson(action.payload);
        final idx = list.indexWhere((o) => o.id == order.id);
        if (idx != -1) {
          list[idx] = order;
        } else {
          list.add(order);
        }
      } else if (action.type == 'updateOrderStatus') {
        final orderId = action.payload['orderId'] as String;
        final statusName = action.payload['status'] as String;
        final status = OrderStatus.values.firstWhere(
          (e) => e.name == statusName,
        );
        final idx = list.indexWhere((o) => o.id == orderId);
        if (idx != -1) {
          list[idx] = list[idx].copyWith(status: status);
        }
      } else if (action.type == 'cancelOrder') {
        final orderId = action.payload['orderId'] as String;
        final idx = list.indexWhere((o) => o.id == orderId);
        if (idx != -1) {
          list[idx] = list[idx].copyWith(status: OrderStatus.cancelled);
        }
      }
    }

    return list;
  }

  // ── Daily summary ─────────────────────────────────────────────────────────
  @override
  Future<Map<String, dynamic>> getDailySummary(
    String tenantId,
    DateTime date,
  ) async {
    if (_queue.isOnline()) {
      try {
        return await _delegate.getDailySummary(tenantId, date);
      } catch (e) {
        debugPrint(
          '[OfflineFirstOrdersRepository] getDailySummary online failed, falling back to local calculation: $e',
        );
      }
    }

    final cached = await _queue.getCachedOrders();
    final queue = await _queue.getQueue();
    final applied = _applyUpdates(cached, queue);

    final dayOrders = applied.where((o) {
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
      'preparing': dayOrders
          .where((o) => o.status == OrderStatus.preparing)
          .length,
      'ready': dayOrders.where((o) => o.status == OrderStatus.ready).length,
      'served': dayOrders.where((o) => o.status == OrderStatus.served).length,
    };
  }
}
