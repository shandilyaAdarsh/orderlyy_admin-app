import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dtos/menu_dto.dart';
import '../data/repositories/categories_repository.dart';
import '../network/api_exception.dart';
import 'repository_providers.dart';
import 'branch_context_service.dart';
import '../../features/organization/presentation/state/branch_providers.dart';

// ── Category Tree Node ────────────────────────────────────────────────────────
class CategoryNode {
  final MenuCategoryDto category;
  final List<CategoryNode> children;

  CategoryNode(this.category, this.children);
}

// ── Categories State ──────────────────────────────────────────────────────────
class CategoriesState {
  final bool isLoading;
  final String? error;
  // Normalized store: categoryId -> MenuCategoryDto
  final Map<String, MenuCategoryDto> byId;
  final bool isInitialized;

  const CategoriesState({
    this.isLoading = false,
    this.error,
    this.byId = const {},
    this.isInitialized = false,
  });

  CategoriesState copyWith({
    bool? isLoading,
    String? error,
    Map<String, MenuCategoryDto>? byId,
    bool? isInitialized,
  }) {
    return CategoriesState(
      isLoading: isLoading ?? this.isLoading,
      error: error, // intentionally overwriting to allow clearing
      byId: byId ?? this.byId,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  // Derived Tree Builder
  List<CategoryNode> buildTree() {
    // 1. Filter out soft-deleted categories
    final activeCategories = byId.values
        .where((c) => c.deletedAt == null)
        .toList();

    // 2. Sort by sort_order
    activeCategories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    // 3. Build lookup map
    final nodeMap = <String, CategoryNode>{};
    for (final cat in activeCategories) {
      nodeMap[cat.id] = CategoryNode(cat, []);
    }

    // 4. Assemble tree
    final rootNodes = <CategoryNode>[];
    for (final cat in activeCategories) {
      final node = nodeMap[cat.id]!;
      if (cat.parentId == null) {
        rootNodes.add(node);
      } else {
        final parent = nodeMap[cat.parentId];
        if (parent != null) {
          parent.children.add(node);
        } else {
          // Parent might be deleted or not loaded.
          // Depending on rules, we might put it at root or ignore. We'll ignore (orphan visibility handling).
        }
      }
    }

    return rootNodes;
  }
}

// ── Categories Notifier ───────────────────────────────────────────────────────
class CategoriesNotifier extends StateNotifier<CategoriesState> {
  final CategoriesRepository _repository;
  final Ref _ref;

  CategoriesNotifier(this._repository, this._ref) : super(const CategoriesState());

  /// Loads the entire category list. Server handles pagination internally if limit > items.
  Future<void> loadCategories({bool forceRefresh = false}) async {
    if (state.isLoading) return;
    if (state.isInitialized && !forceRefresh) return;

    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getCategories();
    if (!mounted) return;

    if (result is Success<List<MenuCategoryDto>>) {
      final newById = <String, MenuCategoryDto>{};
      for (final cat in result.value) {
        newById[cat.id] = cat;
      }
      state = state.copyWith(
        isLoading: false,
        byId: newById,
        isInitialized: true,
      );
    } else if (result is Failure<List<MenuCategoryDto>>) {
      state = state.copyWith(isLoading: false, error: result.error.message);
    }
  }

  Future<Result<MenuCategoryDto>> createCategory(
    MenuCategoryDto category,
  ) async {
    final result = await _repository.createCategory(category);

    if (result is Success<MenuCategoryDto>) {
      final newCat = result.value;

      try {
        final currentBranch = _ref.read(currentBranchProvider).value;
        if (currentBranch != null) {
          final branches = _ref.read(branchesProvider).value ?? [];
          for (final branch in branches) {
            if (branch.id != currentBranch.id) {
              await _repository.setCategoryVisibility(
                categoryId: newCat.id,
                branchId: branch.id,
                isVisible: false,
              );
            }
          }
        }
      } catch (e) {
        // Log or handle gracefully
      }

      final newById = Map<String, MenuCategoryDto>.from(state.byId);
      newById[newCat.id] = newCat;
      state = state.copyWith(byId: newById);
    }

    return result;
  }

  Future<Result<MenuCategoryDto>> updateCategory(
    MenuCategoryDto category,
  ) async {
    final result = await _repository.updateCategory(category);

    if (result is Success<MenuCategoryDto>) {
      final updatedCat = result.value;
      final newById = Map<String, MenuCategoryDto>.from(state.byId);
      newById[updatedCat.id] = updatedCat;
      state = state.copyWith(byId: newById);
    } else if (result is Failure<MenuCategoryDto>) {
      // Deterministic reload on OCC Conflict
      if (result.error.code == ApiErrorCode.conflict) {
        await loadCategories(forceRefresh: true);
      }
    }

    return result;
  }

  Future<Result<void>> deleteCategory(String categoryId) async {
    final cat = state.byId[categoryId];
    if (cat == null) return Failure(ApiFailure('Category not found locally'));

    final result = await _repository.deleteCategory(categoryId, cat.versionNum);

    if (result is Success<void>) {
      // Soft-delete locally or remove completely. Since backend uses soft-delete,
      // it's best to refresh to get updated deleted_at, or just mark it locally.
      final newById = Map<String, MenuCategoryDto>.from(state.byId);
      newById.remove(categoryId);
      state = state.copyWith(byId: newById);

      // Optionally we can trigger a loadCategories to ensure descendant tree cleanup
      // if backend cascading soft-deletes children.
      loadCategories(forceRefresh: true);
    } else if (result is Failure<void>) {
      if (result.error.code == ApiErrorCode.conflict) {
        await loadCategories(forceRefresh: true);
      }
    }

    return result;
  }

  /// Realtime reconciliation method. Call this when a realtime event is received.
  void reconcileRemoteUpdate(MenuCategoryDto remoteCategory) {
    final newById = Map<String, MenuCategoryDto>.from(state.byId);
    if (remoteCategory.deletedAt != null) {
      newById.remove(remoteCategory.id);
    } else {
      newById[remoteCategory.id] = remoteCategory;
    }
    state = state.copyWith(byId: newById);
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────
final categoriesProvider =
    StateNotifierProvider<CategoriesNotifier, CategoriesState>((ref) {
      final repo = ref.watch(categoriesRepositoryProvider);
      return CategoriesNotifier(repo, ref)..loadCategories();
    });

// Derived Provider for Tree
final categoryTreeProvider = Provider<List<CategoryNode>>((ref) {
  final state = ref.watch(categoriesProvider);
  return state.buildTree();
});
