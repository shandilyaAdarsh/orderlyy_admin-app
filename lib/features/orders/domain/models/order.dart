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
    @JsonKey(name: 'customer_payment_intent') String? customerPaymentIntent,
  }) = _Order;

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);

  // ── Business Logic ────────────────────────────────────────────────────────

  bool get canBeModified => status == OrderStatus.pending;

  bool get canBeCancelled =>
      status != OrderStatus.served && status != OrderStatus.cancelled;

  bool get isComplete => status == OrderStatus.served;

  bool get isActive =>
      status != OrderStatus.served && status != OrderStatus.cancelled;

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
