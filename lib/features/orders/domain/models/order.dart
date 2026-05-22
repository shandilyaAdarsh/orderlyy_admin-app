// ── Order Domain Model ───────────────────────────────────────────────────────
// Immutable, serializable domain model for orders.
// Follows offline-first architecture principles.

import 'package:freezed_annotation/freezed_annotation.dart';
import 'order_item.dart';
import 'order_status.dart';
import 'money.dart';

part 'order.freezed.dart';
part 'order.g.dart';

@freezed
abstract class Order with _$Order {
  const Order._();

  const factory Order({
    required String id,
    required String tenantId,
    required String tableId,
    required String tableLabel,
    required OrderStatus status,
    required List<OrderItem> items,
    required Money totalAmount,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? staffId,
    String? staffName,
    String? notes,
    DateTime? completedAt,
  }) = _Order;

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);

  // ── Business Logic ────────────────────────────────────────────────────────

  bool get canBeModified => status == OrderStatus.pending;

  bool get canBeCancelled =>
      status != OrderStatus.served && status != OrderStatus.cancelled;

  bool get isComplete => status == OrderStatus.served;

  bool get isActive =>
      status != OrderStatus.served && status != OrderStatus.cancelled;

  Money calculateSubtotal() {
    return items.fold(
      Money.zero(),
      (total, item) => Money(amount: total.amount + item.subtotal.amount),
    );
  }

  Order addItem(OrderItem item) {
    if (!canBeModified) {
      throw StateError('Cannot modify non-pending order');
    }

    final newItems = [...items, item];
    final newTotal = _recalculateTotal(newItems);

    return copyWith(
      items: newItems,
      totalAmount: newTotal,
      updatedAt: DateTime.now(),
    );
  }

  Order removeItem(String itemId) {
    if (!canBeModified) {
      throw StateError('Cannot modify non-pending order');
    }

    final newItems = items.where((item) => item.id != itemId).toList();
    final newTotal = _recalculateTotal(newItems);

    return copyWith(
      items: newItems,
      totalAmount: newTotal,
      updatedAt: DateTime.now(),
    );
  }

  Order updateItem(String itemId, OrderItem updatedItem) {
    if (!canBeModified) {
      throw StateError('Cannot modify non-pending order');
    }

    final newItems = items.map((item) {
      return item.id == itemId ? updatedItem : item;
    }).toList();

    final newTotal = _recalculateTotal(newItems);

    return copyWith(
      items: newItems,
      totalAmount: newTotal,
      updatedAt: DateTime.now(),
    );
  }

  Order updateStatus(OrderStatus newStatus) {
    return copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
      completedAt: newStatus == OrderStatus.served
          ? DateTime.now()
          : completedAt,
    );
  }

  Money _recalculateTotal(List<OrderItem> items) {
    return items.fold(
      Money.zero(),
      (sum, item) => Money(amount: sum.amount + item.subtotal.amount),
    );
  }

  // ── Display Helpers ───────────────────────────────────────────────────────

  String get displayStatus => status.name.toUpperCase();

  String get displayTime {
    final dt = createdAt.toLocal();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${months[dt.month - 1]} ${dt.day} · $hour:$minute $ampm';
  }
}
