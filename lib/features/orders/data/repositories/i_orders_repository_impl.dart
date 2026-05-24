import 'dart:async';
import '../../../../shared/models/failures.dart';
import '../../../../shared/models/result.dart';
import '../../../../core/data/dtos/order_dto.dart' as dto;
import '../../domain/models/order.dart';
import '../../domain/models/order_status.dart' as domain;
import '../datasources/orders_mock_datasource.dart';
import '../datasources/orders_remote_datasource.dart';
import '../mappers/order_mappers.dart';
import 'orders_repository_interface.dart';

/// Orders repository implementation.
///
/// Supports mock and remote (live) modes.
/// Offline-first persistence is now handled by the Drift-backed
/// MutationJournalService and CartRuntime (see orders/runtime/).
class IOrdersRepositoryImpl implements IOrdersRepository {
  final OrdersRemoteDataSource? remoteDataSource;
  final OrdersMockDataSource? mockDataSource;
  // NOTE: localDataSource (SharedPrefs) has been deprecated.
  // Offline order persistence is now governed by Drift via MutationJournalService.
  final dynamic localDataSource;
  final bool useCache;

  IOrdersRepositoryImpl({
    this.remoteDataSource,
    this.mockDataSource,
    this.localDataSource,
    required this.useCache,
  });

  @override
  Future<Result<List<Order>, AppFailure>> getOrders(
    String tenantId, {
    domain.OrderStatus? status,
    String? tableId,
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      if (mockDataSource != null) {
        final list = await mockDataSource!.getMockByTenant(tenantId);
        var domainList = list.map((e) => e.toDomain()).toList();
        if (status != null) {
          domainList = domainList.where((o) => o.status == status).toList();
        }
        if (tableId != null) {
          domainList = domainList.where((o) => o.tableId == tableId).toList();
        }
        return Result.success(domainList);
      }
      return Result.failure(const AppFailure.unknown(message: 'No data source configured'));
    } catch (e) {
      return Result.failure(AppFailure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Result<Order, AppFailure>> getOrderById(String orderId) async {
    try {
      if (mockDataSource != null) {
        final o = await mockDataSource!.getMockById(orderId);
        if (o != null) return Result.success(o.toDomain());
      }
      return Result.failure(const AppFailure.notFound(message: 'Order not found'));
    } catch (e) {
      return Result.failure(AppFailure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Result<List<Order>, AppFailure>> getOrdersByTable(String tableId) async {
    try {
      if (mockDataSource != null) {
        final list = await mockDataSource!.getMockData();
        final domainList = list
            .where((e) => e.tableId == tableId)
            .map((e) => e.toDomain())
            .toList();
        return Result.success(domainList);
      }
      return Result.failure(const AppFailure.unknown(message: 'No data source configured'));
    } catch (e) {
      return Result.failure(AppFailure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Result<List<Order>, AppFailure>> getOrdersByStatus(
    String tenantId,
    domain.OrderStatus status,
  ) async {
    return getOrders(tenantId, status: status);
  }

  @override
  Future<Result<List<Order>, AppFailure>> getActiveOrders(String tenantId) async {
    try {
      if (mockDataSource != null) {
        final list = await mockDataSource!.getMockByTenant(tenantId);
        final domainList = list
            .map((e) => e.toDomain())
            .where((o) => o.isActive)
            .toList();
        return Result.success(domainList);
      }
      return Result.failure(const AppFailure.unknown(message: 'No data source configured'));
    } catch (e) {
      return Result.failure(AppFailure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Result<Order, AppFailure>> createOrder(Order order) async {
    try {
      final orderDto = order.toDto();
      if (mockDataSource != null) {
        final res = await mockDataSource!.mockCreate(orderDto);
        return Result.success(res.toDomain());
      }
      return Result.failure(const AppFailure.unknown(message: 'No data source configured'));
    } catch (e) {
      return Result.failure(AppFailure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Result<Order, AppFailure>> updateOrderStatus(
    String orderId,
    domain.OrderStatus newStatus,
  ) async {
    try {
      if (mockDataSource != null) {
        final orderDto = await mockDataSource!.getMockById(orderId);
        if (orderDto != null) {
          final res = await mockDataSource!.mockUpdate(
            orderDto.copyWith(
              status: dto.OrderStatus.values.firstWhere((e) => e.name == newStatus.name),
            ),
          );
          return Result.success(res.toDomain());
        }
      }
      return Result.failure(const AppFailure.notFound(message: 'Order not found'));
    } catch (e) {
      return Result.failure(AppFailure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Result<Order, AppFailure>> updateOrder(Order order) async {
    try {
      final orderDto = order.toDto();
      if (mockDataSource != null) {
        final res = await mockDataSource!.mockUpdate(orderDto);
        return Result.success(res.toDomain());
      }
      return Result.failure(const AppFailure.unknown(message: 'No data source configured'));
    } catch (e) {
      return Result.failure(AppFailure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Result<void, AppFailure>> cancelOrder(String orderId) async {
    final res = await updateOrderStatus(orderId, domain.OrderStatus.cancelled);
    return res.map((_) {});
  }

  @override
  Future<Result<void, AppFailure>> deleteOrder(String orderId) async {
    try {
      if (mockDataSource != null) {
        await mockDataSource!.mockDelete(orderId);
        return const Result.success(null);
      }
      return Result.failure(const AppFailure.unknown(message: 'No data source configured'));
    } catch (e) {
      return Result.failure(AppFailure.unknown(message: e.toString()));
    }
  }

  @override
  Stream<Result<List<Order>, AppFailure>> watchOrders(String tenantId) {
    if (mockDataSource != null) {
      return mockDataSource!.mockWatch().map((list) {
        return Result.success(
          list
              .where((e) => e.tenantId == tenantId)
              .map((e) => e.toDomain())
              .toList(),
        );
      });
    }
    return Stream.value(Result.failure(const AppFailure.unknown(message: 'No data source configured')));
  }

  @override
  Stream<Result<Order, AppFailure>> watchOrder(String orderId) {
    if (mockDataSource != null) {
      return mockDataSource!.mockWatch().map((list) {
        final idx = list.indexWhere((o) => o.id == orderId);
        if (idx != -1) {
          return Result.success(list[idx].toDomain());
        }
        return Result.failure(const AppFailure.notFound(message: 'Order not found'));
      });
    }
    return Stream.value(Result.failure(const AppFailure.unknown(message: 'No data source configured')));
  }

  @override
  Future<Result<OrderSummary, AppFailure>> getDailySummary(
    String tenantId,
    DateTime date,
  ) async {
    return Result.success(OrderSummary(
      totalOrders: 0,
      completedOrders: 0,
      cancelledOrders: 0,
      activeOrders: 0,
      totalRevenue: 0.0,
      date: date,
    ));
  }

  @override
  Future<Result<OrderStatistics, AppFailure>> getStatistics(
    String tenantId, {
    DateTime? from,
    DateTime? to,
  }) async {
    return Result.success(OrderStatistics(
      totalOrders: 0,
      averageOrderValue: 0.0,
      totalRevenue: 0.0,
      ordersByStatus: const {},
      from: from ?? DateTime.now(),
      to: to ?? DateTime.now(),
    ));
  }

  @override
  Future<Result<SyncResult, AppFailure>> syncPendingChanges() async {
    return Result.success(SyncResult.noChanges());
  }

  @override
  Future<bool> hasPendingChanges() async => false;
}
