// ── Orders Repository Implementation ─────────────────────────────────────────
// Orchestrates between remote, local, and mock data sources.
// Implements the stable IOrdersRepository interface.

import '../../../../shared/models/result.dart';
import '../../../../shared/models/failures.dart';
import '../../domain/models/order.dart';
import '../../domain/models/order_status.dart';
import '../../../../core/data/dtos/order_dto.dart' as dto;
import '../mappers/order_mappers.dart';
import '../datasources/orders_remote_datasource.dart';
import '../datasources/orders_local_datasource.dart';
import '../datasources/orders_mock_datasource.dart';
import 'orders_repository_interface.dart';

/// Repository implementation that orchestrates data sources
class OrdersRepositoryImpl implements IOrdersRepository {
  final OrdersRemoteDataSource? _remoteDataSource;
  final OrdersLocalDataSource? _localDataSource;
  final OrdersMockDataSource? _mockDataSource;
  final bool _useCache;

  OrdersRepositoryImpl({
    OrdersRemoteDataSource? remoteDataSource,
    OrdersLocalDataSource? localDataSource,
    OrdersMockDataSource? mockDataSource,
    bool useCache = true,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource,
       _mockDataSource = mockDataSource,
       _useCache = useCache;

  // ── Helper to determine which source to use ──────────────────────────────

  bool get _isMockMode => _mockDataSource != null && _remoteDataSource == null;
  bool get _hasCache => _localDataSource != null && _useCache;

  // ── Query Operations ──────────────────────────────────────────────────────

  @override
  Future<Result<List<Order>, AppFailure>> getOrders(
    String tenantId, {
    OrderStatus? status,
    String? tableId,
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      List<Order> orders;

      if (_isMockMode) {
        // Mock mode
        final dtos = await _mockDataSource!.getMockByTenant(tenantId);
        orders = dtos.map((dto) => dto.toDomain()).toList();
      } else {
        // Try cache first if available
        if (_hasCache) {
          final cachedDtos = await _localDataSource!.getByTenant(tenantId);
          if (cachedDtos.isNotEmpty) {
            orders = cachedDtos.map((dto) => dto.toDomain()).toList();

            // Fetch from remote in background to update cache
            _fetchAndCacheOrders(tenantId);

            return Result.success(orders);
          }
        }

        // Fetch from remote
        final params = {
          'tenantId': tenantId,
          if (status != null) 'status': status.name,
          'tableId': ?tableId,
          if (from != null) 'from': from.toIso8601String(),
          if (to != null) 'to': to.toIso8601String(),
        };

        final dtos = await _remoteDataSource!.fetchAll(params);
        orders = dtos.map((dto) => dto.toDomain()).toList();

        // Cache the results
        if (_hasCache) {
          await _localDataSource!.saveAll(dtos);
        }
      }

      // Apply filters
      if (status != null) {
        orders = orders.where((o) => o.status == status).toList();
      }
      if (tableId != null) {
        orders = orders.where((o) => o.tableId == tableId).toList();
      }
      if (from != null) {
        orders = orders.where((o) => o.createdAt.isAfter(from)).toList();
      }
      if (to != null) {
        orders = orders.where((o) => o.createdAt.isBefore(to)).toList();
      }

      return Result.success(orders);
    } catch (e) {
      return Result.failure(AppFailure.unknown(message: e.toString()));
    }
  }

  Future<void> _fetchAndCacheOrders(String tenantId) async {
    try {
      final dtos = await _remoteDataSource!.fetchAll({'tenantId': tenantId});
      await _localDataSource!.saveAll(dtos);
    } catch (e) {
      // Silent failure - cache update is not critical
    }
  }

  @override
  Future<Result<Order, AppFailure>> getOrderById(String orderId) async {
    try {
      // Try cache first
      if (_hasCache) {
        final cachedDto = await _localDataSource!.getById(orderId);
        if (cachedDto != null) {
          return Result.success(cachedDto.toDomain());
        }
      }

      // Fetch from source
      if (_isMockMode) {
        final dto = await _mockDataSource!.getMockById(orderId);
        if (dto == null) {
          return Result.failure(
            AppFailure.notFound(message: 'Order not found: $orderId'),
          );
        }
        return Result.success(dto.toDomain());
      } else {
        final dto = await _remoteDataSource!.fetchById(orderId);

        // Cache the result
        if (_hasCache) {
          await _localDataSource!.save(dto);
        }

        return Result.success(dto.toDomain());
      }
    } catch (e) {
      return Result.failure(AppFailure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Result<List<Order>, AppFailure>> getOrdersByTable(
    String tableId,
  ) async {
    try {
      if (_isMockMode) {
        final dtos = await _mockDataSource!.getMockData();
        final filtered = dtos.where((dto) => dto.tableId == tableId).toList();
        return Result.success(filtered.map((dto) => dto.toDomain()).toList());
      } else {
        final dtos = await _remoteDataSource!.fetchAll({'tableId': tableId});
        return Result.success(dtos.map((dto) => dto.toDomain()).toList());
      }
    } catch (e) {
      return Result.failure(AppFailure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Result<List<Order>, AppFailure>> getOrdersByStatus(
    String tenantId,
    OrderStatus status,
  ) async {
    try {
      if (_isMockMode) {
        final dtos = await _mockDataSource!.getMockByStatus(
          dto.OrderStatus.fromString(status.name),
        );
        return Result.success(dtos.map((dto) => dto.toDomain()).toList());
      } else {
        final dtos = await _remoteDataSource!.fetchAll({
          'tenantId': tenantId,
          'status': status.name,
        });
        return Result.success(dtos.map((dto) => dto.toDomain()).toList());
      }
    } catch (e) {
      return Result.failure(AppFailure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Result<List<Order>, AppFailure>> getActiveOrders(
    String tenantId,
  ) async {
    final result = await getOrders(tenantId);
    return result.map((orders) => orders.where((o) => o.isActive).toList());
  }

  // ── Mutation Operations ───────────────────────────────────────────────────

  @override
  Future<Result<Order, AppFailure>> createOrder(Order order) async {
    try {
      final dto = order.toDto();

      if (_isMockMode) {
        final createdDto = await _mockDataSource!.mockCreate(dto);
        return Result.success(createdDto.toDomain());
      } else {
        final createdDto = await _remoteDataSource!.create(dto);

        // Cache the result
        if (_hasCache) {
          await _localDataSource!.save(createdDto);
        }

        return Result.success(createdDto.toDomain());
      }
    } catch (e) {
      return Result.failure(AppFailure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Result<Order, AppFailure>> updateOrderStatus(
    String orderId,
    OrderStatus newStatus,
  ) async {
    try {
      if (_isMockMode) {
        final updatedDto = await _mockDataSource!.mockUpdateStatus(
          orderId,
          dto.OrderStatus.fromString(newStatus.name),
        );
        return Result.success(updatedDto.toDomain());
      } else {
        final updatedDto = await _remoteDataSource!.updateStatus(
          orderId,
          dto.OrderStatus.fromString(newStatus.name),
        );

        // Update cache
        if (_hasCache) {
          await _localDataSource!.save(updatedDto);
        }

        return Result.success(updatedDto.toDomain());
      }
    } catch (e) {
      return Result.failure(AppFailure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Result<Order, AppFailure>> updateOrder(Order order) async {
    try {
      final dto = order.toDto();

      if (_isMockMode) {
        final updatedDto = await _mockDataSource!.mockUpdate(dto);
        return Result.success(updatedDto.toDomain());
      } else {
        final updatedDto = await _remoteDataSource!.update(dto);

        // Update cache
        if (_hasCache) {
          await _localDataSource!.save(updatedDto);
        }

        return Result.success(updatedDto.toDomain());
      }
    } catch (e) {
      return Result.failure(AppFailure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Result<void, AppFailure>> cancelOrder(String orderId) async {
    return updateOrderStatus(
      orderId,
      OrderStatus.cancelled,
    ).then((result) => result.map((_) {}));
  }

  @override
  Future<Result<void, AppFailure>> deleteOrder(String orderId) async {
    try {
      if (_isMockMode) {
        await _mockDataSource!.mockDelete(orderId);
      } else {
        await _remoteDataSource!.delete(orderId);
      }

      // Remove from cache
      if (_hasCache) {
        await _localDataSource!.delete(orderId);
      }

      return const Result.success(null);
    } catch (e) {
      return Result.failure(AppFailure.unknown(message: e.toString()));
    }
  }

  // ── Sync Operations (for offline-first implementations) ───────────────────

  @override
  Future<Result<SyncResult, AppFailure>> syncPendingChanges() async {
    // No-op for non-offline implementations
    return Result.success(SyncResult.noChanges());
  }

  @override
  Future<bool> hasPendingChanges() async {
    // No-op for non-offline implementations
    return false;
  }

  // ── Real-time Operations ──────────────────────────────────────────────────

  @override
  Stream<Result<List<Order>, AppFailure>> watchOrders(String tenantId) {
    if (_isMockMode) {
      return _mockDataSource!.mockWatch().map((dtos) {
        final orders = dtos
            .where((dto) => dto.tenantId == tenantId)
            .map((dto) => dto.toDomain())
            .toList();
        return Result.success(orders);
      });
    } else {
      final stream = _remoteDataSource!.watchAll({'tenantId': tenantId});
      if (stream == null) {
        return Stream.value(Result.success([]));
      }
      return stream.map((dtos) {
        final orders = dtos.map((dto) => dto.toDomain()).toList();
        return Result.success(orders);
      });
    }
  }

  @override
  Stream<Result<Order, AppFailure>> watchOrder(String orderId) {
    // Implementation depends on backend capabilities
    return Stream.empty();
  }

  // ── Analytics Operations ──────────────────────────────────────────────────

  @override
  Future<Result<OrderSummary, AppFailure>> getDailySummary(
    String tenantId,
    DateTime date,
  ) async {
    try {
      final ordersResult = await getOrders(
        tenantId,
        from: DateTime(date.year, date.month, date.day),
        to: DateTime(date.year, date.month, date.day, 23, 59, 59),
      );

      return ordersResult.map((orders) {
        final completed = orders
            .where((o) => o.status == OrderStatus.served)
            .length;
        final cancelled = orders
            .where((o) => o.status == OrderStatus.cancelled)
            .length;
        final active = orders.where((o) => o.isActive).length;
        final revenue = orders
            .where((o) => o.status == OrderStatus.served)
            .fold(0.0, (sum, o) => sum + o.totalAmount.amount);

        return OrderSummary(
          totalOrders: orders.length,
          completedOrders: completed,
          cancelledOrders: cancelled,
          activeOrders: active,
          totalRevenue: revenue,
          date: date,
        );
      });
    } catch (e) {
      return Result.failure(AppFailure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Result<OrderStatistics, AppFailure>> getStatistics(
    String tenantId, {
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final ordersResult = await getOrders(tenantId, from: from, to: to);

      return ordersResult.map((orders) {
        final totalRevenue = orders
            .where((o) => o.status == OrderStatus.served)
            .fold(0.0, (sum, o) => sum + o.totalAmount.amount);

        final avgOrderValue = orders.isEmpty
            ? 0.0
            : totalRevenue / orders.length;

        final ordersByStatus = <OrderStatus, int>{};
        for (final status in OrderStatus.values) {
          ordersByStatus[status] = orders
              .where((o) => o.status == status)
              .length;
        }

        return OrderStatistics(
          totalOrders: orders.length,
          averageOrderValue: avgOrderValue,
          totalRevenue: totalRevenue,
          ordersByStatus: ordersByStatus,
          from: from ?? DateTime.now(),
          to: to ?? DateTime.now(),
        );
      });
    } catch (e) {
      return Result.failure(AppFailure.unknown(message: e.toString()));
    }
  }
}
