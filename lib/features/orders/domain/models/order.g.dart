// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Order _$OrderFromJson(Map<String, dynamic> json) => _Order(
  id: json['id'] as String,
  tenantId: json['tenantId'] as String,
  tableId: json['tableId'] as String,
  tableLabel: json['tableLabel'] as String,
  status: $enumDecode(_$OrderStatusEnumMap, json['status']),
  items: (json['items'] as List<dynamic>)
      .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  totalAmount: Money.fromJson(json['totalAmount'] as Map<String, dynamic>),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  staffId: json['staffId'] as String?,
  staffName: json['staffName'] as String?,
  notes: json['notes'] as String?,
  completedAt: json['completedAt'] == null
      ? null
      : DateTime.parse(json['completedAt'] as String),
);

Map<String, dynamic> _$OrderToJson(_Order instance) => <String, dynamic>{
  'id': instance.id,
  'tenantId': instance.tenantId,
  'tableId': instance.tableId,
  'tableLabel': instance.tableLabel,
  'status': instance.status,
  'items': instance.items,
  'totalAmount': instance.totalAmount,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'staffId': instance.staffId,
  'staffName': instance.staffName,
  'notes': instance.notes,
  'completedAt': instance.completedAt?.toIso8601String(),
};

const _$OrderStatusEnumMap = {
  OrderStatus.pending: 'pending',
  OrderStatus.confirmed: 'confirmed',
  OrderStatus.preparing: 'preparing',
  OrderStatus.ready: 'ready',
  OrderStatus.served: 'served',
  OrderStatus.cancelled: 'cancelled',
};
