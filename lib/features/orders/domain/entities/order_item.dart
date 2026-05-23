// lib/features/orders/domain/entities/order_item.dart
import 'package:equatable/equatable.dart';
import '../../../../shared/models/money.dart';
import 'menu_product.dart';

enum OrderItemStatus {
  queued,
  preparing,
  ready,
  served,
  cancelled,
}

class OrderItem extends Equatable {
  final String id;
  final MenuProduct product;
  final int quantity;
  final List<ModifierOption> selectedModifiers;
  final int seatNumber;
  final OrderItemStatus status;

  const OrderItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.selectedModifiers,
    required this.seatNumber,
    required this.status,
  });

  Money get unitPrice {
    var price = product.price;
    for (final modifier in selectedModifiers) {
      price = price + modifier.price;
    }
    return price;
  }

  Money get totalPrice {
    final singlePrice = unitPrice;
    return Money(
      amountInCents: singlePrice.amountInCents * quantity,
      currency: singlePrice.currency,
    );
  }

  OrderItem copyWith({
    String? id,
    MenuProduct? product,
    int? quantity,
    List<ModifierOption>? selectedModifiers,
    int? seatNumber,
    OrderItemStatus? status,
  }) {
    return OrderItem(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      selectedModifiers: selectedModifiers ?? this.selectedModifiers,
      seatNumber: seatNumber ?? this.seatNumber,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [id, product, quantity, selectedModifiers, seatNumber, status];
}
