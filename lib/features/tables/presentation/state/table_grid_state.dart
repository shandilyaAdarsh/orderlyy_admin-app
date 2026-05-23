// lib/features/tables/presentation/state/table_grid_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/restaurant_table.dart';

part 'table_grid_state.freezed.dart';

@freezed
abstract class TableGridState with _$TableGridState {
  const factory TableGridState({
    @Default([]) List<RestaurantTable> tables,
    @Default(false) bool isLoading,
    String? errorMessage,
  }) = _TableGridState;
}
