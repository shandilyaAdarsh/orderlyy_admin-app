// ── API Implementation for Menu Recommendations Repository ────────────────────

library;

import '../dtos/menu_recommendation_dto.dart';
import '../repositories/menu_recommendations_repository.dart';
import '../../network/dio_client.dart';
import '../../network/api_exception.dart';
import '../../constants/api_constants.dart';

class ApiMenuRecommendationsRepository implements MenuRecommendationsRepository {
  final DioClient _dioClient;
  final String _tenantId;

  ApiMenuRecommendationsRepository(this._dioClient, this._tenantId);

  @override
  Future<Result<List<MenuItemRecommendationDto>>> getRecommendations(
    String itemId, {
    bool includeInactive = true,
  }) async {
    try {
      final response = await _dioClient.get(
        ApiConstants.itemRecommendations(_tenantId, itemId),
        queryParameters: {'include_inactive': includeInactive.toString()},
      );

      if (response.data['success'] == true) {
        final dynamic rawData = response.data['data'];
        final List<dynamic> dataList = rawData is List ? rawData : [];
        final items = dataList
            .map((json) => MenuItemRecommendationDto.fromJson(
                json as Map<String, dynamic>))
            .toList();
        return Success(items);
      } else {
        final msg = response.data['error']?['message'] ??
            'Failed to fetch recommendations';
        return Failure(ApiFailure(msg, ApiErrorCode.serverError));
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }

  @override
  Future<Result<MenuItemRecommendationDto>> createRecommendation({
    required String sourceItemId,
    required String recommendedMenuItemId,
    required String recommendationType,
    int priority = 2,
    String? branchId,
  }) async {
    try {
      final payload = <String, dynamic>{
        'recommended_menu_item_id': recommendedMenuItemId,
        'recommendation_type': recommendationType,
        'priority': priority,
        'branch_id': ?branchId,
      };

      final response = await _dioClient.post(
        ApiConstants.itemRecommendations(_tenantId, sourceItemId),
        data: payload,
      );

      if (response.data['success'] == true) {
        final rec = MenuItemRecommendationDto.fromJson(
            response.data['data'] as Map<String, dynamic>);
        return Success(rec);
      } else {
        final msg = response.data['error']?['message'] ??
            'Failed to create recommendation';
        return Failure(ApiFailure(msg, ApiErrorCode.badRequest));
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }

  @override
  Future<Result<MenuItemRecommendationDto>> updateRecommendation({
    required String recommendationId,
    String? recommendationType,
    int? priority,
    bool? isActive,
  }) async {
    try {
      final payload = <String, dynamic>{
        'recommendation_type': ?recommendationType,
        'priority': ?priority,
        'is_active': ?isActive,
      };

      final response = await _dioClient.patch(
        ApiConstants.recommendation(_tenantId, recommendationId),
        data: payload,
      );

      if (response.data['success'] == true) {
        final rec = MenuItemRecommendationDto.fromJson(
            response.data['data'] as Map<String, dynamic>);
        return Success(rec);
      } else {
        final msg = response.data['error']?['message'] ??
            'Failed to update recommendation';
        return Failure(ApiFailure(msg, ApiErrorCode.badRequest));
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }

  @override
  Future<Result<MenuItemRecommendationDto>> deactivateRecommendation(
    String recommendationId,
  ) async {
    try {
      final response = await _dioClient.post(
        ApiConstants.deactivateRecommendation(_tenantId, recommendationId),
      );

      if (response.data['success'] == true) {
        final rec = MenuItemRecommendationDto.fromJson(
            response.data['data'] as Map<String, dynamic>);
        return Success(rec);
      } else {
        final msg = response.data['error']?['message'] ??
            'Failed to deactivate recommendation';
        return Failure(ApiFailure(msg, ApiErrorCode.serverError));
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }

  @override
  Future<Result<MenuItemRecommendationDto>> reactivateRecommendation(
    String recommendationId,
  ) async {
    try {
      final response = await _dioClient.post(
        ApiConstants.reactivateRecommendation(_tenantId, recommendationId),
      );

      if (response.data['success'] == true) {
        final rec = MenuItemRecommendationDto.fromJson(
            response.data['data'] as Map<String, dynamic>);
        return Success(rec);
      } else {
        final msg = response.data['error']?['message'] ??
            'Failed to reactivate recommendation';
        return Failure(ApiFailure(msg, ApiErrorCode.serverError));
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteRecommendation(String recommendationId) async {
    try {
      final response = await _dioClient.delete(
        ApiConstants.recommendation(_tenantId, recommendationId),
      );

      if (response.statusCode == 204 || response.data?['success'] == true) {
        return const Success(null);
      } else {
        final msg = response.data?['error']?['message'] ??
            'Failed to delete recommendation';
        return Failure(ApiFailure(msg, ApiErrorCode.serverError));
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }
}
