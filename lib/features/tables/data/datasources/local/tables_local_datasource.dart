// lib/features/tables/data/datasources/local/tables_local_datasource.dart
import '../../dtos/table_dto.dart';

abstract class TablesLocalDatasource {
  Future<List<TableDto>> getCachedTables();
  Future<void> cacheTables(List<TableDto> tables);
  Future<void> cacheTable(TableDto table);
  Stream<List<TableDto>> watchCachedTables();
}
