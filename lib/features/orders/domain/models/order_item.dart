// ── Order Item Domain Model ──────────────────────────────────────────────────
// Immutable, serializable model for order items.

import 'package:freezed_annotation/freezed_annotation.dart';
import 'money.dart';

part 'order_item.freezed.dart';
part 'order_item.g.dart';

@freezed
abstract class OrderItem with _$OrderItem {
  const OrderItem._();

  const factory OrderItem({
    required String id,
    required String menuItemId,
    required String menuItemName,
    required int quantity,
    required Money unitPrice,
    String? notes,
  }) = _OrderItem;

  factory OrderItem.fromJson(Map<String, dynamic> json) =>
      _$OrderItemFromJson(json);

  Money get subtotal => Money(amount: unitPrice.amount * quantity);

  OrderItem updateQuantity(int newQuantity) {
    if (newQuantity < 1) {
      throw ArgumentError('Quantity must be at least 1');
    }
    return copyWith(quantity: newQuantity);
  }

  OrderItem updateNotes(String? newNotes) {
    return copyWith(notes: newNotes);
  }
}
