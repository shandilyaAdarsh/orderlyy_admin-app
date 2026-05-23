// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OrderItem _$OrderItemFromJson(Map<String, dynamic> json) => _OrderItem(
  id: json['id'] as String,
  menuItemId: json['menuItemId'] as String,
  menuItemName: json['menuItemName'] as String,
  quantity: (json['quantity'] as num).toInt(),
  unitPrice: Money.fromJson(json['unitPrice'] as Map<String, dynamic>),
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$OrderItemToJson(_OrderItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'menuItemId': instance.menuItemId,
      'menuItemName': instance.menuItemName,
      'quantity': instance.quantity,
      'unitPrice': instance.unitPrice,
      'notes': instance.notes,
    };
