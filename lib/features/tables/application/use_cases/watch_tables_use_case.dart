// lib/features/tables/application/use_cases/watch_tables_use_case.dart
import '../../domain/entities/restaurant_table.dart';
import '../../domain/repositories/tables_repository.dart';

class WatchTablesUseCase {
  final TablesRepository _repository;

  WatchTablesUseCase(this._repository);

  Stream<List<RestaurantTable>> call() {
    return _repository.watchTables();
  }
}
