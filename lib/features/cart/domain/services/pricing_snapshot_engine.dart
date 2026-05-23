import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import '../../../../shared/models/money.dart';
import '../../../menu/domain/entities/menu_snapshot.dart';
import '../entities/cart_state.dart';

class PriceComparison extends Equatable {
  final Money localPrice;
  final Money serverPrice;
  final bool isAvailable;

  const PriceComparison({
    required this.localPrice,
    required this.serverPrice,
    required this.isAvailable,
  });

  @override
  List<Object?> get props => [localPrice, serverPrice, isAvailable];
}

class PriceDriftResult extends Equatable {
  final bool hasDrift;
  final Map<String, PriceComparison> comparisons;

  const PriceDriftResult({
    required this.hasDrift,
    required this.comparisons,
  });

  @override
  List<Object?> get props => [hasDrift, comparisons];
}

class PricingSnapshotEngine {
  /// Compares local cart prices with the latest menu projection.
  /// If price drift is found (either item price, modifier price, or availability),
  /// it flags the cart as stale.
  static PriceDriftResult detectDrift({
    required CartState cartState,
    required MenuSnapshot currentProjection,
  }) {
    final comparisons = <String, PriceComparison>{};
    bool hasDrift = false;

    for (final item in cartState.items) {
      final activeItem = currentProjection.items.firstWhereOrNull(
        (i) => i.id == item.menuItemId,
      );

      // 1. Availability check
      if (activeItem == null || !activeItem.isAvailable) {
        hasDrift = true;
        comparisons[item.cartItemId] = PriceComparison(
          localPrice: item.snapshotUnitPrice,
          serverPrice: Money(amountInCents: 0, currency: item.snapshotUnitPrice.currency),
          isAvailable: false,
        );
        continue;
      }

      // 2. Base item price comparison
      bool itemPriceDrift = activeItem.price.amountInCents != item.snapshotUnitPrice.amountInCents;
      bool modifierPriceDrift = false;

      // 3. Modifier price comparison
      for (final mod in item.selectedModifiers) {
        // Search through all modifier groups in the snapshot to find this option
        ModifierOption? activeOption;
        for (final group in currentProjection.modifierGroups) {
          final opt = group.options.firstWhereOrNull((o) => o.id == mod.modifierOptionId);
          if (opt != null) {
            activeOption = opt;
            break;
          }
        }

        if (activeOption == null) {
          // Modifier no longer exists
          modifierPriceDrift = true;
        } else if (activeOption.price.amountInCents != mod.price.amountInCents) {
          modifierPriceDrift = true;
        }
      }

      if (itemPriceDrift || modifierPriceDrift) {
        hasDrift = true;
        
        // Calculate the "server price" projection for this item unit
        final serverModifierSum = item.selectedModifiers.fold<int>(0, (sum, mod) {
          ModifierOption? activeOption;
          for (final group in currentProjection.modifierGroups) {
            final opt = group.options.firstWhereOrNull((o) => o.id == mod.modifierOptionId);
            if (opt != null) {
              activeOption = opt;
              break;
            }
          }
          return sum + (activeOption?.price.amountInCents ?? 0);
        });

        final totalServerPrice = Money(
          amountInCents: activeItem.price.amountInCents + serverModifierSum,
          currency: activeItem.price.currency,
        );

        final totalLocalUnitPrice = Money(
          amountInCents: item.snapshotUnitPrice.amountInCents + 
              item.selectedModifiers.fold<int>(0, (sum, mod) => sum + mod.price.amountInCents),
          currency: item.snapshotUnitPrice.currency,
        );

        comparisons[item.cartItemId] = PriceComparison(
          localPrice: totalLocalUnitPrice,
          serverPrice: totalServerPrice,
          isAvailable: true,
        );
      }
    }

    return PriceDriftResult(hasDrift: hasDrift, comparisons: comparisons);
  }
}
