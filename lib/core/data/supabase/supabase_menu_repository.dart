import 'package:supabase_flutter/supabase_flutter.dart';
import '../dtos/menu_dto.dart';
import '../repositories/menu_repository.dart';

class SupabaseMenuRepository implements MenuRepository {
  final SupabaseClient _client;

  SupabaseMenuRepository(this._client);

  // ── Categories ────────────────────────────────────────────────────────────
  @override
  Future<List<MenuCategoryDto>> getCategories(String tenantId) async {
    final response = await _client
        .from('menu_categories')
        .select()
        .eq('tenant_id', tenantId)
        .order('sort_order', ascending: true);

    return (response as List)
        .map((json) => MenuCategoryDto.fromJson(json))
        .toList();
  }

  @override
  Future<MenuCategoryDto> createCategory(MenuCategoryDto category) async {
    final response = await _client
        .from('menu_categories')
        .insert(category.toJson())
        .select()
        .single();

    return MenuCategoryDto.fromJson(response);
  }

  @override
  Future<MenuCategoryDto> updateCategory(MenuCategoryDto category) async {
    final response = await _client
        .from('menu_categories')
        .update(category.toJson())
        .eq('id', category.id)
        .select()
        .single();

    return MenuCategoryDto.fromJson(response);
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    await _client.from('menu_categories').delete().eq('id', categoryId);
  }

  // ── Menu items ────────────────────────────────────────────────────────────
  @override
  Future<List<MenuItemDto>> getMenuItems(
    String tenantId, {
    String? categoryId,
  }) async {
    var query = _client.from('menu_items').select().eq('tenant_id', tenantId);

    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }

    final response = await query.order('name', ascending: true);
    return (response as List)
        .map((json) => MenuItemDto.fromJson(json))
        .toList();
  }

  @override
  Future<MenuItemDto> createMenuItem(MenuItemDto item) async {
    final response = await _client
        .from('menu_items')
        .insert(item.toJson())
        .select()
        .single();

    return MenuItemDto.fromJson(response);
  }

  @override
  Future<MenuItemDto> updateMenuItem(MenuItemDto item) async {
    final response = await _client
        .from('menu_items')
        .update(item.toJson())
        .eq('id', item.id)
        .select()
        .single();

    return MenuItemDto.fromJson(response);
  }

  @override
  Future<void> deleteMenuItem(String itemId) async {
    await _client.from('menu_items').delete().eq('id', itemId);
  }

  @override
  Future<void> toggleItemAvailability(String itemId, bool isAvailable) async {
    await _client
        .from('menu_items')
        .update({'is_available': isAvailable})
        .eq('id', itemId);
  }

  // ── Realtime-like stream ──────────────────────────────────────────────────
  @override
  Stream<List<MenuItemDto>> watchMenuItems(String tenantId) {
    return _client
        .from('menu_items')
        .stream(primaryKey: ['id'])
        .eq('tenant_id', tenantId)
        .order('name', ascending: true)
        .map((event) => event.map((json) => MenuItemDto.fromJson(json)).toList());
  }
}
