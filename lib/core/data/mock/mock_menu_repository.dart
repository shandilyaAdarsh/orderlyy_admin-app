// ── MockMenuRepository ────────────────────────────────────────────────────────
// Full mock implementation of MenuRepository.
// • Loads from menu_fixtures.json on first access (lazy).
// • Mutations update in-memory state only.
// • watchMenuItems() emits periodically to simulate realtime.
//
// MIGRATION PATH: Replace MockMenuRepository with SupabaseMenuRepository
// in repository_providers.dart. Zero UI changes required.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../repositories/menu_repository.dart';
import '../dtos/menu_dto.dart';

class MockMenuRepository implements MenuRepository {
  List<MenuCategoryDto>? _categories;
  List<MenuItemDto>? _items;

  final _itemsController = StreamController<List<MenuItemDto>>.broadcast();

  // ── Lazy fixture loader ───────────────────────────────────────────────────
  Future<void> _ensureLoaded() async {
    if (_categories != null && _items != null) return;

    final raw = await rootBundle.loadString(
      'lib/core/data/mock/fixtures/menu_fixtures.json',
    );
    final json = jsonDecode(raw) as Map<String, dynamic>;

    _categories = (json['categories'] as List)
        .map((e) => MenuCategoryDto.fromJson(e as Map<String, dynamic>))
        .toList();

    _items = (json['items'] as List)
        .map((e) => MenuItemDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Categories ────────────────────────────────────────────────────────────
  @override
  Future<List<MenuCategoryDto>> getCategories(String tenantId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    await _ensureLoaded();
    return _categories!
        .where((c) => c.tenantId == tenantId && c.isActive)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  @override
  Future<MenuCategoryDto> createCategory(MenuCategoryDto category) async {
    await Future.delayed(const Duration(milliseconds: 400));
    await _ensureLoaded();
    _categories!.add(category);
    return category;
  }

  @override
  Future<MenuCategoryDto> updateCategory(MenuCategoryDto category) async {
    await Future.delayed(const Duration(milliseconds: 400));
    await _ensureLoaded();
    final idx = _categories!.indexWhere((c) => c.id == category.id);
    if (idx != -1) _categories![idx] = category;
    return category;
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    await _ensureLoaded();
    _categories!.removeWhere((c) => c.id == categoryId);
  }

  // ── Menu items ────────────────────────────────────────────────────────────
  @override
  Future<List<MenuItemDto>> getMenuItems(
    String tenantId, {
    String? categoryId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 350));
    await _ensureLoaded();
    return _items!
        .where(
          (i) =>
              i.tenantId == tenantId &&
              (categoryId == null || i.categoryId == categoryId),
        )
        .toList();
  }

  @override
  Future<MenuItemDto> createMenuItem(MenuItemDto item) async {
    await Future.delayed(const Duration(milliseconds: 400));
    await _ensureLoaded();
    _items!.add(item);
    _itemsController.add(List.from(_items!));
    return item;
  }

  @override
  Future<MenuItemDto> updateMenuItem(MenuItemDto item) async {
    await Future.delayed(const Duration(milliseconds: 400));
    await _ensureLoaded();
    final idx = _items!.indexWhere((i) => i.id == item.id);
    if (idx != -1) _items![idx] = item;
    _itemsController.add(List.from(_items!));
    return item;
  }

  @override
  Future<void> deleteMenuItem(String itemId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    await _ensureLoaded();
    _items!.removeWhere((i) => i.id == itemId);
    _itemsController.add(List.from(_items!));
  }

  @override
  Future<void> toggleItemAvailability(String itemId, bool isAvailable) async {
    await Future.delayed(const Duration(milliseconds: 250));
    await _ensureLoaded();
    final idx = _items!.indexWhere((i) => i.id == itemId);
    if (idx != -1) {
      final old = _items![idx];
      _items![idx] = MenuItemDto(
        id: old.id,
        tenantId: old.tenantId,
        categoryId: old.categoryId,
        name: old.name,
        description: old.description,
        price: old.price,
        imageUrl: old.imageUrl,
        isAvailable: isAvailable,
        isVegetarian: old.isVegetarian,
        prepTimeMinutes: old.prepTimeMinutes,
        tags: old.tags,
      );
      _itemsController.add(List.from(_items!));
    }
  }

  // ── Realtime-like stream ──────────────────────────────────────────────────
  @override
  Stream<List<MenuItemDto>> watchMenuItems(String tenantId) async* {
    await _ensureLoaded();
    yield _items!.where((i) => i.tenantId == tenantId).toList();
    yield* _itemsController.stream.map(
      (items) => items.where((i) => i.tenantId == tenantId).toList(),
    );
  }
}
