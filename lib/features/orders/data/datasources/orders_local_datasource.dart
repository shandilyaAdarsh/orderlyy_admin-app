// ── Orders Local Data Source ─────────────────────────────────────────────────
// Handles local persistence for orders (cache, offline storage).
// Can be implemented with Hive, Isar, SQLite, SharedPreferences, etc.

import '../../../../core/data/datasources/base/base_datasource.dart';
import '../../../../core/data/dtos/order_dto.dart';
import '../../../../core/storage/local_storage.dart';

/// Local data source for orders (cache/offline storage)
abstract class OrdersLocalDataSource extends LocalDataSource<OrderDto> {
  /// Get all cached orders
  @override
  Future<List<OrderDto>> getAll();

  /// Get cached order by ID
  @override
  Future<OrderDto?> getById(String id);

  /// Save order to cache
  @override
  Future<void> save(OrderDto dto);

  /// Save multiple orders to cache
  @override
  Future<void> saveAll(List<OrderDto> dtos);

  /// Delete order from cache
  @override
  Future<void> delete(String id);

  /// Clear all cached orders
  @override
  Future<void> clear();

  /// Check if order exists in cache
  @override
  Future<bool> exists(String id);

  /// Get orders by tenant
  Future<List<OrderDto>> getByTenant(String tenantId);

  /// Get orders by status
  Future<List<OrderDto>> getByStatus(OrderStatus status);
}

/// SharedPreferences implementation (simple cache)
class OrdersSharedPrefsDataSource implements OrdersLocalDataSource {
  final LocalStorage _storage;
  static const String _cacheKey = 'orders_cache';

  OrdersSharedPrefsDataSource(this._storage);

  @override
  Future<List<OrderDto>> getAll() async {
    final json = await _storage.read(_cacheKey);
    if (json == null) return [];

    final list = (json['orders'] as List? ?? [])
        .map((item) => OrderDto.fromJson(item as Map<String, dynamic>))
        .toList();

    return list;
  }

  @override
  Future<OrderDto?> getById(String id) async {
    final all = await getAll();
    try {
      return all.firstWhere((order) => order.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> save(OrderDto dto) async {
    final all = await getAll();
    final index = all.indexWhere((order) => order.id == dto.id);

    if (index >= 0) {
      all[index] = dto;
    } else {
      all.add(dto);
    }

    await _saveAll(all);
  }

  @override
  Future<void> saveAll(List<OrderDto> dtos) async {
    await _saveAll(dtos);
  }

  Future<void> _saveAll(List<OrderDto> dtos) async {
    final json = {
      'orders': dtos.map((dto) => dto.toJson()).toList(),
      'lastUpdated': DateTime.now().toIso8601String(),
    };

    await _storage.write(_cacheKey, json);
  }

  @override
  Future<void> delete(String id) async {
    final all = await getAll();
    all.removeWhere((order) => order.id == id);
    await _saveAll(all);
  }

  @override
  Future<void> clear() async {
    await _storage.delete(_cacheKey);
  }

  @override
  Future<bool> exists(String id) async {
    final order = await getById(id);
    return order != null;
  }

  @override
  Future<List<OrderDto>> getByTenant(String tenantId) async {
    final all = await getAll();
    return all.where((order) => order.tenantId == tenantId).toList();
  }

  @override
  Future<List<OrderDto>> getByStatus(OrderStatus status) async {
    final all = await getAll();
    return all.where((order) => order.status == status).toList();
  }
}

/// Future: Hive implementation (for better performance)
class OrdersHiveDataSource implements OrdersLocalDataSource {
  // final Box<OrderDto> _box;

  // OrdersHiveDataSource(this._box);

  @override
  Future<List<OrderDto>> getAll() async {
    throw UnimplementedError('Hive implementation pending');
  }

  @override
  Future<OrderDto?> getById(String id) async {
    throw UnimplementedError('Hive implementation pending');
  }

  @override
  Future<void> save(OrderDto dto) async {
    throw UnimplementedError('Hive implementation pending');
  }

  @override
  Future<void> saveAll(List<OrderDto> dtos) async {
    throw UnimplementedError('Hive implementation pending');
  }

  @override
  Future<void> delete(String id) async {
    throw UnimplementedError('Hive implementation pending');
  }

  @override
  Future<void> clear() async {
    throw UnimplementedError('Hive implementation pending');
  }

  @override
  Future<bool> exists(String id) async {
    throw UnimplementedError('Hive implementation pending');
  }

  @override
  Future<List<OrderDto>> getByTenant(String tenantId) async {
    throw UnimplementedError('Hive implementation pending');
  }

  @override
  Future<List<OrderDto>> getByStatus(OrderStatus status) async {
    throw UnimplementedError('Hive implementation pending');
  }
}
