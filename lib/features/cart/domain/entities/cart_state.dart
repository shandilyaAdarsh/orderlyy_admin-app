import 'package:equatable/equatable.dart';
import 'cart_item.dart';

class CartState extends Equatable {
  final List<CartItem> items;
  final String branchId;
  final String menuSnapshotVersion;
  final bool hasStalePrices;
  final String? errorMessage;

  const CartState({
    required this.items,
    required this.branchId,
    required this.menuSnapshotVersion,
    required this.hasStalePrices,
    this.errorMessage,
  });

  factory CartState.initial(String branchId, String version) => CartState(
        items: const [],
        branchId: branchId,
        menuSnapshotVersion: version,
        hasStalePrices: false,
        errorMessage: null,
      );

  CartState copyWith({
    List<CartItem>? items,
    String? branchId,
    String? menuSnapshotVersion,
    bool? hasStalePrices,
    String? errorMessage,
  }) {
    return CartState(
      items: items ?? this.items,
      branchId: branchId ?? this.branchId,
      menuSnapshotVersion: menuSnapshotVersion ?? this.menuSnapshotVersion,
      hasStalePrices: hasStalePrices ?? this.hasStalePrices,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        items,
        branchId,
        menuSnapshotVersion,
        hasStalePrices,
        errorMessage,
      ];

  Map<String, dynamic> toJson() {
    return {
      'cart_state_version': 1,
      'branch_id': branchId,
      'menu_snapshot_version': menuSnapshotVersion,
      'has_stale_prices': hasStalePrices,
      'error_message': errorMessage,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }

  factory CartState.fromJson(Map<String, dynamic> json) {
    return CartState(
      branchId: json['branch_id'] as String? ?? 'mock_branch',
      menuSnapshotVersion: json['menu_snapshot_version'] as String? ?? '',
      hasStalePrices: json['has_stale_prices'] as bool? ?? false,
      errorMessage: json['error_message'] as String?,
      items: (json['items'] as List? ?? [])
          .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
