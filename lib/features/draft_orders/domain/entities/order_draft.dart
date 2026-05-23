import 'package:equatable/equatable.dart';
import '../../../../shared/models/money.dart';

class DraftModifier extends Equatable {
  final String modifierOptionId;
  final String name;
  final Money price;

  const DraftModifier({
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

  factory DraftModifier.fromJson(Map<String, dynamic> json) {
    return DraftModifier(
      modifierOptionId: json['modifier_option_id'] as String,
      name: json['name'] as String,
      price: Money(
        amountInCents: json['price_cents'] as int,
        currency: json['currency'] as String? ?? 'USD',
      ),
    );
  }
}

class DraftItem extends Equatable {
  final String menuItemId;
  final String name;
  final int quantity;
  final Money unitPrice;
  final List<DraftModifier> modifiers;
  final String specialInstructions;

  const DraftItem({
    required this.menuItemId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.modifiers,
    required this.specialInstructions,
  });

  Money get lineTotal {
    final modSum = modifiers.fold<int>(0, (sum, mod) => sum + mod.price.amountInCents);
    return Money(
      amountInCents: (unitPrice.amountInCents + modSum) * quantity,
      currency: unitPrice.currency,
    );
  }

  @override
  List<Object?> get props => [
        menuItemId,
        name,
        quantity,
        unitPrice,
        modifiers,
        specialInstructions,
      ];

  Map<String, dynamic> toJson() {
    return {
      'menu_item_id': menuItemId,
      'name': name,
      'quantity': quantity,
      'unit_price_cents': unitPrice.amountInCents,
      'currency': unitPrice.currency,
      'modifiers': modifiers.map((e) => e.toJson()).toList(),
      'special_instructions': specialInstructions,
    };
  }

  factory DraftItem.fromJson(Map<String, dynamic> json) {
    return DraftItem(
      menuItemId: json['menu_item_id'] as String,
      name: json['name'] as String,
      quantity: json['quantity'] as int,
      unitPrice: Money(
        amountInCents: json['unit_price_cents'] as int,
        currency: json['currency'] as String? ?? 'USD',
      ),
      modifiers: (json['modifiers'] as List? ?? [])
          .map((e) => DraftModifier.fromJson(e as Map<String, dynamic>))
          .toList(),
      specialInstructions: json['special_instructions'] as String? ?? '',
    );
  }
}

class OrderDraft extends Equatable {
  final String draftId; // Client-side generated UUID
  final String tenantId;
  final String branchId;
  final String tableId;
  final String? tableLabel;
  final List<DraftItem> items;
  final Money calculatedSubtotal; // Authoritative local expectation
  final String menuSnapshotVersion;
  final String deviceSessionId;
  final DateTime createdAt;

  const OrderDraft({
    required this.draftId,
    required this.tenantId,
    required this.branchId,
    required this.tableId,
    this.tableLabel,
    required this.items,
    required this.calculatedSubtotal,
    required this.menuSnapshotVersion,
    required this.deviceSessionId,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        draftId,
        tenantId,
        branchId,
        tableId,
        tableLabel,
        items,
        calculatedSubtotal,
        menuSnapshotVersion,
        deviceSessionId,
        createdAt,
      ];

  Map<String, dynamic> toJson() {
    return {
      'draft_id': draftId,
      'tenant_id': tenantId,
      'branch_id': branchId,
      'table_id': tableId,
      'table_label': tableLabel,
      'items': items.map((e) => e.toJson()).toList(),
      'calculated_subtotal_cents': calculatedSubtotal.amountInCents,
      'currency': calculatedSubtotal.currency,
      'menu_snapshot_version': menuSnapshotVersion,
      'device_session_id': deviceSessionId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory OrderDraft.fromJson(Map<String, dynamic> json) {
    return OrderDraft(
      draftId: json['draft_id'] as String,
      tenantId: json['tenant_id'] as String,
      branchId: json['branch_id'] as String,
      tableId: json['table_id'] as String,
      tableLabel: json['table_label'] as String?,
      items: (json['items'] as List? ?? [])
          .map((e) => DraftItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      calculatedSubtotal: Money(
        amountInCents: json['calculated_subtotal_cents'] as int,
        currency: json['currency'] as String? ?? 'USD',
      ),
      menuSnapshotVersion: json['menu_snapshot_version'] as String? ?? '',
      deviceSessionId: json['device_session_id'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
