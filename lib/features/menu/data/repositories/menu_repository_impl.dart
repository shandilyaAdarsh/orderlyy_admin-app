// lib/features/menu/data/repositories/menu_repository_impl.dart
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/menu_snapshot.dart';
import '../../domain/repositories/menu_repository.dart';
import '../dtos/menu_snapshot_dto.dart';

class MenuRepositoryImpl implements MenuRepository {
  final DioClient _dioClient;
  final Box<String> _apiCacheBox;
  final NetworkInfo _networkInfo;
  final Talker _talker;

  MenuRepositoryImpl({
    required DioClient dioClient,
    required Box<String> apiCacheBox,
    required NetworkInfo networkInfo,
    required Talker talker,
  })  : _dioClient = dioClient,
        _apiCacheBox = apiCacheBox,
        _networkInfo = networkInfo,
        _talker = talker;

  @override
  Future<MenuSnapshot> getMenuSnapshot({
    required String branchId,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'menu_snapshot_$branchId';
    final etagKey = 'menu_etag_$branchId';

    final isConnected = await _networkInfo.isConnected;
    _talker.info('[MenuRepo] Fetching menu snapshot for branch: $branchId. isConnected=$isConnected, forceRefresh=$forceRefresh');

    if (!isConnected) {
      _talker.warning('[MenuRepo] Offline. Attempting cache fallback...');
      final cachedJson = _apiCacheBox.get(cacheKey);
      if (cachedJson != null) {
        _talker.info('[MenuRepo] Serving menu snapshot from local cache.');
        final snapshotDto = MenuSnapshotDto.fromJson(jsonDecode(cachedJson) as Map<String, dynamic>);
        return snapshotDto.toDomain();
      }
      _talker.warning('[MenuRepo] No cached snapshot available. Falling back to default mock data...');
      return _getDefaultMockSnapshot();
    }

    try {
      final cachedEtag = forceRefresh ? null : _apiCacheBox.get(etagKey);
      final headers = <String, dynamic>{};
      if (cachedEtag != null) {
        headers['If-None-Match'] = cachedEtag;
      }

      final response = await _dioClient.get(
        '/snapshot/menu',
        queryParameters: {'branch_id': branchId},
        options: Options(
          headers: headers,
          validateStatus: (status) => status == 200 || status == 304,
        ),
      );

      if (response.statusCode == 304) {
        _talker.info('[MenuRepo] Received 304 Not Modified. Serving from local cache.');
        final cachedJson = _apiCacheBox.get(cacheKey);
        if (cachedJson != null) {
          final snapshotDto = MenuSnapshotDto.fromJson(jsonDecode(cachedJson) as Map<String, dynamic>);
          return snapshotDto.toDomain();
        }
        _talker.error('[MenuRepo] Server returned 304 but cache was empty! Fetching fresh...');
        return getMenuSnapshot(branchId: branchId, forceRefresh: true);
      }

      // StatusCode == 200
      final Map<String, dynamic> body = Map<String, dynamic>.from(response.data as Map);
      final newEtag = response.headers.value('etag') ?? response.headers.value('ETag');
      if (newEtag != null) {
        body['etag'] = newEtag;
      }
      body['branch_id'] = branchId;

      await _apiCacheBox.put(cacheKey, jsonEncode(body));
      if (newEtag != null) {
        await _apiCacheBox.put(etagKey, newEtag);
        _talker.info('[MenuRepo] Menu snapshot cache updated. ETag: $newEtag');
      } else {
        await _apiCacheBox.delete(etagKey);
      }

      final snapshotDto = MenuSnapshotDto.fromJson(body);
      return snapshotDto.toDomain();
    } catch (e) {
      _talker.error('[MenuRepo] Failed to fetch menu from server: $e. Checking cache fallback...');
      final cachedJson = _apiCacheBox.get(cacheKey);
      if (cachedJson != null) {
        final snapshotDto = MenuSnapshotDto.fromJson(jsonDecode(cachedJson) as Map<String, dynamic>);
        return snapshotDto.toDomain();
      }
      _talker.warning('[MenuRepo] Cache is empty. Serving mock menu snapshot.');
      return _getDefaultMockSnapshot();
    }
  }

  @override
  Future<Map<String, bool>> getItemAvailability({
    required String branchId,
  }) async {
    final isConnected = await _networkInfo.isConnected;
    if (!isConnected) {
      _talker.warning('[MenuRepo] Offline. Availability check skipped.');
      return {};
    }

    try {
      final response = await _dioClient.get(
        '/availability',
        queryParameters: {'branch_id': branchId},
      );

      if (response.statusCode == 200 && response.data is Map) {
        final rawMap = response.data as Map<String, dynamic>;
        final overlay = rawMap.map((key, value) => MapEntry(key, value as bool));
        // Cache overlay whenever we successfully fetch it
        await saveAvailabilityOverlay(branchId, overlay);
        return overlay;
      }
      return {};
    } catch (e) {
      _talker.error('[MenuRepo] Failed to fetch availability polling data: $e');
      return {};
    }
  }

  @override
  Future<void> saveMenuSnapshot(MenuSnapshot snapshot) async {
    final cacheKey = 'menu_snapshot_${snapshot.branchId}';
    final etagKey = 'menu_etag_${snapshot.branchId}';
    final dto = MenuSnapshotDto(
      categories: snapshot.categories.map((c) => MenuCategoryDto(id: c.id, name: c.name, sortOrder: c.sortOrder)).toList(),
      items: snapshot.items.map((i) => MenuItemDto(
        id: i.id,
        categoryId: i.categoryId,
        name: i.name,
        description: i.description,
        priceInCents: i.price.amountInCents,
        isAvailable: i.isAvailable,
        modifierGroupIds: i.modifierGroupIds,
      )).toList(),
      modifierGroups: snapshot.modifierGroups.map((g) => ModifierGroupDto(
        id: g.id,
        name: g.name,
        options: g.options.map((o) => ModifierOptionDto(id: o.id, name: o.name, priceInCents: o.price.amountInCents)).toList(),
      )).toList(),
      taxConfig: TaxConfigDto(vatRate: snapshot.taxConfig.vatRate, serviceChargeRate: snapshot.taxConfig.serviceChargeRate),
      metadata: snapshot.metadata,
      availabilityOverlay: snapshot.availabilityOverlay,
      etag: snapshot.etag,
      snapshotVersion: snapshot.snapshotVersion,
      generatedAt: snapshot.generatedAt,
      branchId: snapshot.branchId,
    );
    await _apiCacheBox.put(cacheKey, jsonEncode(dto.toJson()));
    if (snapshot.etag != null) {
      await _apiCacheBox.put(etagKey, snapshot.etag!);
    }
  }

  @override
  Future<MenuSnapshot?> getCachedMenuSnapshot(String branchId) async {
    final cacheKey = 'menu_snapshot_$branchId';
    final cachedJson = _apiCacheBox.get(cacheKey);
    if (cachedJson != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(cachedJson) as Map<String, dynamic>;
        final dto = MenuSnapshotDto.fromJson(decoded);
        return dto.toDomain();
      } catch (e) {
        _talker.error('[MenuRepo] Failed to parse cached snapshot for $branchId: $e');
        return null;
      }
    }
    return null;
  }

  @override
  Future<void> saveAvailabilityOverlay(String branchId, Map<String, bool> overlay) async {
    final cacheKey = 'menu_availability_$branchId';
    await _apiCacheBox.put(cacheKey, jsonEncode(overlay));
  }

  @override
  Future<Map<String, bool>> getCachedAvailabilityOverlay(String branchId) async {
    final cacheKey = 'menu_availability_$branchId';
    final cachedJson = _apiCacheBox.get(cacheKey);
    if (cachedJson != null) {
      try {
        final Map<dynamic, dynamic> decoded = jsonDecode(cachedJson) as Map;
        return decoded.map((k, v) => MapEntry(k.toString(), v as bool));
      } catch (e) {
        _talker.error('[MenuRepo] Failed to parse cached availability overlay for $branchId: $e');
        return {};
      }
    }
    return {};
  }

  @override
  Future<void> clearCache(String branchId) async {
    await _apiCacheBox.delete('menu_snapshot_$branchId');
    await _apiCacheBox.delete('menu_etag_$branchId');
    await _apiCacheBox.delete('menu_availability_$branchId');
  }

  /// Default mock snapshot payload corresponding to initial static products
  MenuSnapshot _getDefaultMockSnapshot() {
    return const MenuSnapshotDto(
      categories: [
        MenuCategoryDto(id: 'cat_mains', name: 'Mains', sortOrder: 1),
        MenuCategoryDto(id: 'cat_greens', name: 'Greens', sortOrder: 2),
        MenuCategoryDto(id: 'cat_sides', name: 'Sides', sortOrder: 3),
        MenuCategoryDto(id: 'cat_drinks', name: 'Drinks', sortOrder: 4),
      ],
      items: [
        MenuItemDto(
          id: 'prod_burger',
          categoryId: 'cat_mains',
          name: 'Classic Cheeseburger',
          description: 'A flame-grilled beef patty with cheddar cheese, lettuce, and pickles.',
          priceInCents: 1250,
          isAvailable: true,
          modifierGroupIds: ['grp_burger_mods'],
        ),
        MenuItemDto(
          id: 'prod_chicken',
          categoryId: 'cat_mains',
          name: 'Spicy Chicken Sandwich',
          description: 'Crispy spicy chicken breast with swiss cheese and spicy mayo.',
          priceInCents: 1300,
          isAvailable: true,
          modifierGroupIds: ['grp_chicken_mods'],
        ),
        MenuItemDto(
          id: 'prod_salad',
          categoryId: 'cat_greens',
          name: 'Caesar Salad',
          description: 'Romaine lettuce tossed with Caesar dressing, croutons, and parmesan.',
          priceInCents: 950,
          isAvailable: true,
          modifierGroupIds: ['grp_salad_mods'],
        ),
        MenuItemDto(
          id: 'prod_fries',
          categoryId: 'cat_sides',
          name: 'French Fries',
          description: 'Golden crispy fries seasoned with sea salt.',
          priceInCents: 450,
          isAvailable: true,
          modifierGroupIds: ['grp_fries_mods'],
        ),
        MenuItemDto(
          id: 'prod_beer',
          categoryId: 'cat_drinks',
          name: 'Craft IPA Beer',
          description: 'Local craft IPA with hoppy, citrus aromas.',
          priceInCents: 650,
          isAvailable: true,
          modifierGroupIds: ['grp_beer_mods'],
        ),
        MenuItemDto(
          id: 'prod_soda',
          categoryId: 'cat_drinks',
          name: 'Fresh Lemon Soda',
          description: 'Sparkling lemon soda served ice-cold.',
          priceInCents: 350,
          isAvailable: true,
          modifierGroupIds: ['grp_soda_mods'],
        ),
      ],
      modifierGroups: [
        ModifierGroupDto(
          id: 'grp_burger_mods',
          name: 'Burger Add-ons',
          options: [
            ModifierOptionDto(id: 'mod_bacon', name: 'Extra Bacon', priceInCents: 150),
            ModifierOptionDto(id: 'mod_cheddar', name: 'Cheddar Cheese', priceInCents: 100),
            ModifierOptionDto(id: 'mod_avocado', name: 'Add Avocado', priceInCents: 200),
            ModifierOptionDto(id: 'mod_gf_bun', name: 'Gluten-free Bun', priceInCents: 150),
          ],
        ),
        ModifierGroupDto(
          id: 'grp_chicken_mods',
          name: 'Chicken Sandwich Add-ons',
          options: [
            ModifierOptionDto(id: 'mod_jalapenos', name: 'Extra Jalapenos', priceInCents: 75),
            ModifierOptionDto(id: 'mod_swiss', name: 'Swiss Cheese', priceInCents: 100),
            ModifierOptionDto(id: 'mod_spicy_mayo', name: 'Spicy Mayo', priceInCents: 50),
          ],
        ),
        ModifierGroupDto(
          id: 'grp_salad_mods',
          name: 'Salad Add-ons',
          options: [
            ModifierOptionDto(id: 'mod_chicken_breast', name: 'Add Grilled Chicken', priceInCents: 300),
            ModifierOptionDto(id: 'mod_dressing', name: 'Extra Dressing', priceInCents: 50),
          ],
        ),
        ModifierGroupDto(
          id: 'grp_fries_mods',
          name: 'Fries Flavorings',
          options: [
            ModifierOptionDto(id: 'mod_parmesan', name: 'Garlic Parmesan', priceInCents: 100),
            ModifierOptionDto(id: 'mod_truffle', name: 'Truffle Oil', priceInCents: 150),
          ],
        ),
        ModifierGroupDto(
          id: 'grp_beer_mods',
          name: 'Beer Accompaniments',
          options: [
            ModifierOptionDto(id: 'mod_lime', name: 'Add Lime Slice', priceInCents: 0),
          ],
        ),
        ModifierGroupDto(
          id: 'grp_soda_mods',
          name: 'Soda Adjustments',
          options: [
            ModifierOptionDto(id: 'mod_less_sugar', name: 'Less Sugar', priceInCents: 0),
            ModifierOptionDto(id: 'mod_ice', name: 'Extra Ice', priceInCents: 0),
          ],
        ),
      ],
      taxConfig: TaxConfigDto(vatRate: 0.10, serviceChargeRate: 0.05),
    ).toDomain();
  }
}
