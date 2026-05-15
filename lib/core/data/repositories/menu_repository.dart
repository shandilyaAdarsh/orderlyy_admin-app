// ── MenuRepository interface ───────────────────────────────────────────────────
// The UI layer ONLY depends on this contract.
// Implementations: MockMenuRepository (dev) | SupabaseMenuRepository (prod)

import '../dtos/menu_dto.dart';

abstract class MenuRepository {
  // ── Categories ────────────────────────────────────────────────────────────
  Future<List<MenuCategoryDto>> getCategories(String tenantId);

  Future<MenuCategoryDto> createCategory(MenuCategoryDto category);

  Future<MenuCategoryDto> updateCategory(MenuCategoryDto category);

  Future<void> deleteCategory(String categoryId);

  // ── Menu items ────────────────────────────────────────────────────────────
  Future<List<MenuItemDto>> getMenuItems(String tenantId, {String? categoryId});

  Future<MenuItemDto> createMenuItem(MenuItemDto item);

  Future<MenuItemDto> updateMenuItem(MenuItemDto item);

  Future<void> deleteMenuItem(String itemId);

  Future<void> toggleItemAvailability(String itemId, bool isAvailable);

  // ── Realtime-like stream (fake events in mock) ────────────────────────────
  Stream<List<MenuItemDto>> watchMenuItems(String tenantId);
}
