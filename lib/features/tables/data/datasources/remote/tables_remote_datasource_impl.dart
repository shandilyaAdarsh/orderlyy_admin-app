// lib/features/tables/data/datasources/remote/tables_remote_datasource_impl.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../dtos/table_dto.dart';
import 'tables_remote_datasource.dart';

class TablesRemoteDatasourceImpl implements TablesRemoteDatasource {
  final SupabaseClient _client;

  TablesRemoteDatasourceImpl(this._client);

  @override
  Future<List<TableDto>> getTables() async {
    final response = await _client
        .from('tables')
        .select()
        .order('label', ascending: true);

    return (response as List)
        .map((json) => TableDto.fromJson(json))
        .toList();
  }

  @override
  Future<TableDto> updateTableStatus(String id, String status, {String? orderId}) async {
    final response = await _client
        .from('tables')
        .update({
          'status': status,
          'active_order_id': orderId,
        })
        .eq('id', id)
        .select()
        .single();

    return TableDto.fromJson(response);
  }

  @override
  Stream<List<TableDto>> watchTables() {
    return _client
        .from('tables')
        .stream(primaryKey: ['id'])
        .order('label', ascending: true)
        .map((event) => event.map((json) => TableDto.fromJson(json)).toList());
  }

  @override
  Future<void> mergeTables(List<String> sourceTableIds, String targetTableId) async {
    try {
      await _client
          .from('tables')
          .update({
            'status': 'occupied',
            'merged_table_ids': sourceTableIds,
          })
          .eq('id', targetTableId);

      for (final srcId in sourceTableIds) {
        await _client
            .from('tables')
            .update({
              'status': 'occupied',
              'active_order_id': null,
            })
            .eq('id', srcId);
      }
    } catch (_) {
      // Fallback: If DB columns don't exist, update status only
      try {
        await _client
            .from('tables')
            .update({'status': 'occupied'})
            .eq('id', targetTableId);
      } catch (_) {}
    }
  }

  @override
  Future<void> splitTable(String tableId, List<Map<String, dynamic>> splitPartitions) async {
    try {
      await _client
          .from('tables')
          .update({
            'occupied_seats': splitPartitions,
          })
          .eq('id', tableId);
    } catch (_) {
      // Fallback: ignore if column doesn't exist
    }
  }
}
