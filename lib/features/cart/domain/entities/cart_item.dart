import 'package:equatable/equatable.dart';
import '../../../../shared/models/money.dart';

class SelectedModifier extends Equatable {
  final String modifierOptionId;
  final String name;
  final Money price;

  const SelectedModifier({
    required this.modifierOptionId,
    required this.name,
    required this.price,
  });

  @override
  List<Object?> get props => [modifierOptionId, name, price];

  Map<String, dynamic> toJson() {
    return {
      'modifier_option_id': modifierOptionId,
      'name': name,
      'price_cents': price.amountInCents,
      'currency': price.currency,
    };
  }

  factory SelectedModifier.fromJson(Map<String, dynamic> json) {
    return SelectedModifier(
      modifierOptionId: json['modifier_option_id'] as String,
      name: json['name'] as String,
      price: Money(
        amountInCents: json['price_cents'] as int,
        currency: json['currency'] as String? ?? 'USD',
      ),
    );
  }
}

class CartItem extends Equatable {
  final String cartItemId; // Client-side generated unique UUID
  final String menuItemId;
  final String name;
  final Money snapshotUnitPrice; // Locked at selection time
  final int quantity;
  final List<SelectedModifier> selectedModifiers;
  final String specialInstructions;
  final String snapshotVersion; // Associated menu snapshot version

  const CartItem({
    required this.cartItemId,
    required this.menuItemId,
    required this.name,
    required this.snapshotUnitPrice,
    required this.quantity,
    required this.selectedModifiers,
    required this.specialInstructions,
    required this.snapshotVersion,
  });

  Money get itemTotal {
    final modifierSum = selectedModifiers.fold<int>(
      0,
      (sum, mod) => sum + mod.price.amountInCents,
    );
    return Money(
      amountInCents: (snapshotUnitPrice.amountInCents + modifierSum) * quantity,
      currency: snapshotUnitPrice.currency,
    );
  }

  CartItem copyWith({
    String? cartItemId,
    String? menuItemId,
    String? name,
    Money? snapshotUnitPrice,
    int? quantity,
    List<SelectedModifier>? selectedModifiers,
    String? specialInstructions,
    String? snapshotVersion,
  }) {
    return CartItem(
      cartItemId: cartItemId ?? this.cartItemId,
      menuItemId: menuItemId ?? this.menuItemId,
      name: name ?? this.name,
      snapshotUnitPrice: snapshotUnitPrice ?? this.snapshotUnitPrice,
      quantity: quantity ?? this.quantity,
      selectedModifiers: selectedModifiers ?? this.selectedModifiers,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      snapshotVersion: snapshotVersion ?? this.snapshotVersion,
    );
  }

  @override
  List<Object?> get props => [
        cartItemId,
        menuItemId,
        name,
        snapshotUnitPrice,
        quantity,
        selectedModifiers,
        specialInstructions,
        snapshotVersion,
      ];

  Map<String, dynamic> toJson() {
    return {
      'cart_item_id': cartItemId,
      'menu_item_id': menuItemId,
      'name': name,
      'snapshot_unit_price_cents': snapshotUnitPrice.amountInCents,
      'currency': snapshotUnitPrice.currency,
      'quantity': quantity,
      'selected_modifiers': selectedModifiers.map((e) => e.toJson()).toList(),
      'special_instructions': specialInstructions,
      'snapshot_version': snapshotVersion,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      cartItemId: json['cart_item_id'] as String,
      menuItemId: json['menu_item_id'] as String,
      name: json['name'] as String,
      snapshotUnitPrice: Money(
        amountInCents: json['snapshot_unit_price_cents'] as int,
        currency: json['currency'] as String? ?? 'USD',
      ),
      quantity: json['quantity'] as int,
      selectedModifiers: (json['selected_modifiers'] as List? ?? [])
          .map((e) => SelectedModifier.fromJson(e as Map<String, dynamic>))
          .toList(),
      specialInstructions: json['special_instructions'] as String? ?? '',
      snapshotVersion: json['snapshot_version'] as String? ?? '',
    );
  }
}
