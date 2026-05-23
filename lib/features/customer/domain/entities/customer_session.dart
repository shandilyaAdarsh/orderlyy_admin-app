// lib/features/customer/domain/entities/customer_session.dart
import 'package:equatable/equatable.dart';
import '../../../../shared/models/money.dart';
import '../../../menu/domain/entities/menu_snapshot.dart';

class CartItem extends Equatable {
  final String id;
  final MenuItem item;
  final int quantity;
  final List<ModifierOption> selectedModifiers;

  const CartItem({
    required this.id,
    required this.item,
    required this.quantity,
    required this.selectedModifiers,
  });

  Money get unitPrice {
    var price = item.price;
    for (final opt in selectedModifiers) {
      price = price + opt.price;
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

  CartItem copyWith({
    String? id,
    MenuItem? item,
    int? quantity,
    List<ModifierOption>? selectedModifiers,
  }) {
    return CartItem(
      id: id ?? this.id,
      item: item ?? this.item,
      quantity: quantity ?? this.quantity,
      selectedModifiers: selectedModifiers ?? this.selectedModifiers,
    );
  }

  @override
  List<Object?> get props => [id, item, quantity, selectedModifiers];
}

class CustomerSession extends Equatable {
  final String tenantId;
  final String branchId;
  final String tableId;
  final List<CartItem> cart;

  const CustomerSession({
    required this.tenantId,
    required this.branchId,
    required this.tableId,
    this.cart = const [],
  });

  CustomerSession copyWith({
    String? tenantId,
    String? branchId,
    String? tableId,
    List<CartItem>? cart,
  }) {
    return CustomerSession(
      tenantId: tenantId ?? this.tenantId,
      branchId: branchId ?? this.branchId,
      tableId: tableId ?? this.tableId,
      cart: cart ?? this.cart,
    );
  }

  Money get subtotal {
    var sum = const Money(amountInCents: 0);
    for (final item in cart) {
      sum = sum + item.totalPrice;
    }
    return sum;
  }

  @override
  List<Object?> get props => [tenantId, branchId, tableId, cart];
}
