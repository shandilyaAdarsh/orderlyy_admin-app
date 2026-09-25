import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../dtos/order_dto.dart';
import '../repositories/orders_repository.dart';
import '../../network/dio_client.dart';
import '../../network/api_exception.dart';
import '../../constants/api_constants.dart';
import 'package:dio/dio.dart';

class ApiOrdersRepository implements OrdersRepository {
  final DioClient _dioClient;

  ApiOrdersRepository(this._dioClient);

  @override
  Future<Result<List<OrderDto>>> getOrdersPaginated({
    required String branchId,
    CancelToken? cancelToken,
    OrderStatus? status,
    String? tableId,
    int page = 1,
    int limit = 100,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'branchId': branchId,
        'page': page,
        'limit': limit,
        if (status != null) 'status': status.name,
        'table_id': ?tableId,
      };

      final response = await _dioClient.dio.get(
        ApiConstants.orders,
        queryParameters: queryParams,
        cancelToken: cancelToken,
      );

      if (response.data['status'] == 'success' || response.data['success'] == true) {
        final payload = response.data['data'];
        List<dynamic> dataList = [];
        if (payload is Map<String, dynamic> && payload.containsKey('orders')) {
          dataList = payload['orders'] as List<dynamic>? ?? [];
        } else if (payload is List<dynamic>) {
          dataList = payload;
        }
        final orders = dataList
            .map((json) => OrderDto.fromJson(json as Map<String, dynamic>))
            .toList();
        return Success(orders);
      } else {
        final errorMessage =
            response.data['error']?['message'] ?? 'Failed to fetch orders';
        return Failure(ApiFailure(errorMessage, ApiErrorCode.serverError));
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }

  @override
  Future<Result<OrderDto>> createOrderEntity(
    OrderDto order, {
    required String branchId,
    required String idempotencyKey,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.orders,
        queryParameters: {'branch_id': branchId},
        data: order.toJson(),
        options: Options(headers: {'Idempotency-Key': idempotencyKey}),
      );

      if (response.data['success'] == true) {
        return Success(OrderDto.fromJson(response.data['data']));
      } else {
        final errorMessage =
            response.data['error']?['message'] ?? 'Failed to create order';
        return Failure(ApiFailure(errorMessage, ApiErrorCode.serverError));
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }

  @override
  Future<Result<OrderDto>> transitionOrderStatus(
    String orderId,
    OrderStatus newStatus,
    int currentVersion, {
    required String branchId,
    required String idempotencyKey,
  }) async {
    try {
      final response = await _dioClient.dio.patch(
        '${ApiConstants.orders}/$orderId/status',
        queryParameters: {'branch_id': branchId},
        data: {'status': newStatus.name, 'version_num': currentVersion},
        options: Options(headers: {'Idempotency-Key': idempotencyKey}),
      );

      if (response.data['success'] == true) {
        return Success(OrderDto.fromJson(response.data['data']));
      } else {
        final errorMessage =
            response.data['error']?['message'] ??
            'Failed to transition order status';
        return Failure(ApiFailure(errorMessage, ApiErrorCode.serverError));
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }

  @override
  Future<Result<OrderDto>> updateOrderLineItems(
    String orderId,
    List<OrderItemDto> items,
    int currentVersion, {
    required String branchId,
    required String idempotencyKey,
  }) async {
    try {
      final response = await _dioClient.dio.patch(
        '${ApiConstants.orders}/$orderId/items',
        queryParameters: {'branch_id': branchId},
        data: {
          'items': items.map((i) => i.toJson()).toList(),
          'version_num': currentVersion,
        },
        options: Options(headers: {'Idempotency-Key': idempotencyKey}),
      );

      if (response.data['success'] == true) {
        return Success(OrderDto.fromJson(response.data['data']));
      } else {
        final errorMessage =
            response.data['error']?['message'] ??
            'Failed to update order items';
        return Failure(ApiFailure(errorMessage, ApiErrorCode.serverError));
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }

  // ── Deprecated Methods ──────────────────────────────────────────────────────

  @override
  Future<List<OrderDto>> getOrders(
    String tenantId, {
    OrderStatus? status,
    String? tableId,
    DateTime? from,
    DateTime? to,
  }) => throw UnimplementedError();

  @override
  Future<OrderDto?> getOrderById(String orderId) => throw UnimplementedError();

  @override
  Future<OrderDto> createOrder(OrderDto order) => throw UnimplementedError();

  @override
  Future<OrderDto> updateOrderStatus(String orderId, OrderStatus newStatus) =>
      throw UnimplementedError();

  @override
  Future<OrderDto> updateOrder(OrderDto order) => throw UnimplementedError();

  @override
  Future<void> cancelOrder(String orderId) => throw UnimplementedError();

  @override
  Stream<List<OrderDto>> watchOrders(String branchId) {
    final controller = StreamController<List<OrderDto>>.broadcast();
    final supabase = Supabase.instance.client;

    // Initial load via existing paginated method
    getOrdersPaginated(branchId: branchId, limit: 200).then((result) {
      if (!controller.isClosed) {
        if (result is Success<List<OrderDto>>) {
          controller.add(result.value);
        } else if (result is Failure<List<OrderDto>>) {
          controller.addError(result.error);
        }
      }
    });

    // Realtime updates — same pattern as KDS
    final channel = supabase
      .channel('admin_orders_watch_$branchId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'orders',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'branch_id',
          value: branchId,
        ),
        callback: (_) async {
          final result = await getOrdersPaginated(branchId: branchId, limit: 200);
          if (result is Success<List<OrderDto>> && !controller.isClosed) {
            controller.add(result.value);
          }
        },
      )
      .subscribe();

    controller.onCancel = () {
      supabase.removeChannel(channel);
      controller.close();
    };

    return controller.stream;
  }

  @override
  Future<Map<String, dynamic>> getDailySummary(
    String tenantId,
    DateTime date,
  ) => throw UnimplementedError();
}
