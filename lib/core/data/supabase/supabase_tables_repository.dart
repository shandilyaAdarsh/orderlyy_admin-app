import 'package:supabase_flutter/supabase_flutter.dart';
import '../dtos/table_dto.dart';
import '../repositories/tables_repository.dart';

class SupabaseTablesRepository implements TablesRepository {
  final SupabaseClient _client;

  SupabaseTablesRepository(this._client);

  @override
  Future<List<RestaurantTableDto>> getTables(String tenantId) async {
    final response = await _client
        .from('tables')
        .select()
        .eq('tenant_id', tenantId)
        .order('label', ascending: true);

    return (response as List)
        .map((json) => RestaurantTableDto.fromJson(json))
        .toList();
  }

  @override
  Future<RestaurantTableDto?> getTableById(String tableId) async {
    final response = await _client
        .from('tables')
        .select()
        .eq('id', tableId)
        .maybeSingle();

    if (response == null) return null;
    return RestaurantTableDto.fromJson(response);
  }

  @override
  Future<RestaurantTableDto> createTable(RestaurantTableDto table) async {
    final response = await _client
        .from('tables')
        .insert(table.toJson())
        .select()
        .single();

    return RestaurantTableDto.fromJson(response);
  }

  @override
  Future<RestaurantTableDto> updateTableStatus(
    String tableId,
    TableStatus newStatus, {
    String? activeOrderId,
  }) async {
    final response = await _client
        .from('tables')
        .update({
          'status': newStatus.name,
          'active_order_id': activeOrderId,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', tableId)
        .select()
        .single();

    return RestaurantTableDto.fromJson(response);
  }

  @override
  Future<void> deleteTable(String tableId) async {
    await _client.from('tables').delete().eq('id', tableId);
  }

  @override
  Stream<List<RestaurantTableDto>> watchTables(String tenantId) {
    return _client
        .from('tables')
        .stream(primaryKey: ['id'])
        .eq('tenant_id', tenantId)
        .order('label', ascending: true)
        .map((event) => event.map((json) => RestaurantTableDto.fromJson(json)).toList());
  }
}
