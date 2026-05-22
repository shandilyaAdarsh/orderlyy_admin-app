// ── Orders State ─────────────────────────────────────────────────────────────
// Immutable, serializable state for orders feature.
// Follows offline-first architecture principles.

import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../shared/models/failures.dart';
import '../../domain/models/order.dart';

part 'orders_state.freezed.dart';
part 'orders_state.g.dart';

@freezed
abstract class OrdersState with _$OrdersState {
  const factory OrdersState({
    required List<Order> orders,
    required LoadingStatus status,
    required DateTime lastSyncedAt,
    @Default({}) Set<String> optimisticIds,
    @Default({}) Set<String> failedIds,
    AppFailure? error,
  }) = _OrdersState;

  factory OrdersState.fromJson(Map<String, dynamic> json) =>
      _$OrdersStateFromJson(json);

  factory OrdersState.initial() => OrdersState(
    orders: [],
    status: LoadingStatus.initial,
    lastSyncedAt: DateTime.now(),
  );
}

enum LoadingStatus {
  initial,
  loading,
  success,
  error;

  String toJson() => name;
  static LoadingStatus fromJson(String json) => values.byName(json);
}
