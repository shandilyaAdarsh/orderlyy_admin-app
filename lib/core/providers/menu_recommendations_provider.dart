// ── Menu Recommendations Provider ─────────────────────────────────────────────
// Riverpod state management for Menu Item Recommendation CRUD

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dtos/menu_recommendation_dto.dart';
import '../data/repositories/menu_recommendations_repository.dart';
import '../network/api_exception.dart';
import 'repository_providers.dart';

class MenuItemRecommendationsState {
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final List<MenuItemRecommendationDto> recommendations;

  const MenuItemRecommendationsState({
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.recommendations = const [],
  });

  MenuItemRecommendationsState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool clearError = false,
    List<MenuItemRecommendationDto>? recommendations,
  }) {
    return MenuItemRecommendationsState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      recommendations: recommendations ?? this.recommendations,
    );
  }

  // ── Filters & Convenience Selectors ───────────────────────────────────────

  List<MenuItemRecommendationDto> get recommendedWith =>
      recommendations.where((r) => !r.isExclusion).toList();

  List<MenuItemRecommendationDto> get activeRecommendedWith =>
      recommendedWith.where((r) => r.isActive).toList();

  List<MenuItemRecommendationDto> get inactiveRecommendedWith =>
      recommendedWith.where((r) => !r.isActive).toList();

  List<MenuItemRecommendationDto> get dontRecommendWith =>
      recommendations.where((r) => r.isExclusion).toList();

  List<MenuItemRecommendationDto> get activeDontRecommendWith =>
      dontRecommendWith.where((r) => r.isActive).toList();

  List<MenuItemRecommendationDto> get inactiveDontRecommendWith =>
      dontRecommendWith.where((r) => !r.isActive).toList();
}

class MenuItemRecommendationsNotifier
    extends StateNotifier<MenuItemRecommendationsState> {
  final MenuRecommendationsRepository _repository;
  final String _sourceItemId;

  MenuItemRecommendationsNotifier(this._repository, this._sourceItemId)
      : super(const MenuItemRecommendationsState());

  Future<void> loadRecommendations({bool includeInactive = true}) async {
    if (_sourceItemId.isEmpty) return;

    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.getRecommendations(
      _sourceItemId,
      includeInactive: includeInactive,
    );

    if (result is Success<List<MenuItemRecommendationDto>>) {
      state = state.copyWith(
        isLoading: false,
        recommendations: result.value,
      );
    } else if (result is Failure<List<MenuItemRecommendationDto>>) {
      state = state.copyWith(
        isLoading: false,
        error: result.error.message,
      );
    }
  }

  Future<Result<MenuItemRecommendationDto>> addRecommendation({
    required String recommendedMenuItemId,
    required String recommendationType,
    int priority = 2,
    String? branchId,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);
    final result = await _repository.createRecommendation(
      sourceItemId: _sourceItemId,
      recommendedMenuItemId: recommendedMenuItemId,
      recommendationType: recommendationType,
      priority: priority,
      branchId: branchId,
    );

    if (result is Success<MenuItemRecommendationDto>) {
      // If it existed (reactivation) replace it, otherwise append
      final existingIndex = state.recommendations
          .indexWhere((r) => r.id == result.value.id);
      final updatedList = List<MenuItemRecommendationDto>.from(state.recommendations);
      if (existingIndex >= 0) {
        updatedList[existingIndex] = result.value;
      } else {
        updatedList.add(result.value);
      }
      state = state.copyWith(isSaving: false, recommendations: updatedList);
    } else if (result is Failure<MenuItemRecommendationDto>) {
      state = state.copyWith(isSaving: false, error: result.error.message);
    }

    return result;
  }

  Future<Result<MenuItemRecommendationDto>> updateRelationship({
    required String recommendationId,
    String? recommendationType,
    int? priority,
    bool? isActive,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);
    final result = await _repository.updateRecommendation(
      recommendationId: recommendationId,
      recommendationType: recommendationType,
      priority: priority,
      isActive: isActive,
    );

    if (result is Success<MenuItemRecommendationDto>) {
      final updatedList = state.recommendations.map<MenuItemRecommendationDto>((r) {
        return r.id == result.value.id ? result.value : r;
      }).toList();
      state = state.copyWith(isSaving: false, recommendations: updatedList);
    } else if (result is Failure<MenuItemRecommendationDto>) {
      state = state.copyWith(isSaving: false, error: result.error.message);
    }

    return result;
  }

  Future<Result<MenuItemRecommendationDto>> deactivateRelationship(
    String recommendationId,
  ) async {
    state = state.copyWith(isSaving: true, clearError: true);
    final result = await _repository.deactivateRecommendation(recommendationId);

    if (result is Success<MenuItemRecommendationDto>) {
      final updatedList = state.recommendations.map<MenuItemRecommendationDto>((r) {
        return r.id == result.value.id ? result.value : r;
      }).toList();
      state = state.copyWith(isSaving: false, recommendations: updatedList);
    } else if (result is Failure<MenuItemRecommendationDto>) {
      state = state.copyWith(isSaving: false, error: result.error.message);
    }

    return result;
  }

  Future<Result<MenuItemRecommendationDto>> reactivateRelationship(
    String recommendationId,
  ) async {
    state = state.copyWith(isSaving: true, clearError: true);
    final result = await _repository.reactivateRecommendation(recommendationId);

    if (result is Success<MenuItemRecommendationDto>) {
      final updatedList = state.recommendations.map<MenuItemRecommendationDto>((r) {
        return r.id == result.value.id ? result.value : r;
      }).toList();
      state = state.copyWith(isSaving: false, recommendations: updatedList);
    } else if (result is Failure<MenuItemRecommendationDto>) {
      state = state.copyWith(isSaving: false, error: result.error.message);
    }

    return result;
  }
}

// ── Family Provider ──────────────────────────────────────────────────────────

final itemRecommendationsProvider = StateNotifierProvider.family<
    MenuItemRecommendationsNotifier, MenuItemRecommendationsState, String>(
  (ref, sourceItemId) {
    final repo = ref.watch(menuRecommendationsRepositoryProvider);
    final notifier = MenuItemRecommendationsNotifier(repo, sourceItemId);
    if (sourceItemId.isNotEmpty) {
      notifier.loadRecommendations();
    }
    return notifier;
  },
);
