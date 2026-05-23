// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'orders_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OrdersState _$OrdersStateFromJson(Map<String, dynamic> json) => _OrdersState(
  orders: (json['orders'] as List<dynamic>)
      .map((e) => Order.fromJson(e as Map<String, dynamic>))
      .toList(),
  status: $enumDecode(_$LoadingStatusEnumMap, json['status']),
  lastSyncedAt: DateTime.parse(json['lastSyncedAt'] as String),
  optimisticIds:
      (json['optimisticIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toSet() ??
      const {},
  failedIds:
      (json['failedIds'] as List<dynamic>?)?.map((e) => e as String).toSet() ??
      const {},
  error: json['error'] == null
      ? null
      : AppFailure.fromJson(json['error'] as Map<String, dynamic>),
);

Map<String, dynamic> _$OrdersStateToJson(_OrdersState instance) =>
    <String, dynamic>{
      'orders': instance.orders,
      'status': instance.status,
      'lastSyncedAt': instance.lastSyncedAt.toIso8601String(),
      'optimisticIds': instance.optimisticIds.toList(),
      'failedIds': instance.failedIds.toList(),
      'error': instance.error,
    };

const _$LoadingStatusEnumMap = {
  LoadingStatus.initial: 'initial',
  LoadingStatus.loading: 'loading',
  LoadingStatus.success: 'success',
  LoadingStatus.error: 'error',
};
