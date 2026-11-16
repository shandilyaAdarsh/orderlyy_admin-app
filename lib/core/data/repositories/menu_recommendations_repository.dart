// ── Menu Recommendations Repository Interface ───────────────────────────────

library;

import '../dtos/menu_recommendation_dto.dart';
import '../../network/api_exception.dart';

abstract class MenuRecommendationsRepository {
  /// Fetches recommendations configured for a given source menu item.
  Future<Result<List<MenuItemRecommendationDto>>> getRecommendations(
    String itemId, {
    bool includeInactive = true,
  });

  /// Creates or reactivates a recommendation relationship.
  Future<Result<MenuItemRecommendationDto>> createRecommendation({
    required String sourceItemId,
    required String recommendedMenuItemId,
    required String recommendationType,
    int priority = 2,
    String? branchId,
  });

  /// Updates recommendation relationship type, priority, or active status.
  Future<Result<MenuItemRecommendationDto>> updateRecommendation({
    required String recommendationId,
    String? recommendationType,
    int? priority,
    bool? isActive,
  });

  /// Soft deactivates a recommendation relationship.
  Future<Result<MenuItemRecommendationDto>> deactivateRecommendation(
    String recommendationId,
  );

  /// Reactivates an existing inactive recommendation relationship.
  Future<Result<MenuItemRecommendationDto>> reactivateRecommendation(
    String recommendationId,
  );

  /// Soft deletes a recommendation relationship.
  Future<Result<void>> deleteRecommendation(String recommendationId);
}
