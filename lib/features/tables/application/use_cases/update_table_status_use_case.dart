// lib/features/tables/application/use_cases/update_table_status_use_case.dart
import '../../domain/entities/restaurant_table.dart';
import '../../domain/repositories/tables_repository.dart';

class UpdateTableStatusUseCase {
  final TablesRepository _repository;

  UpdateTableStatusUseCase(this._repository);

  Future<RestaurantTable> call(String id, TableStatus status, {String? orderId}) async {
    return await _repository.updateTableStatus(id, status, orderId: orderId);
  }
}
