// lib/features/menu/runtime/projection_reconciliation.dart
import '../domain/entities/menu_snapshot.dart';

class ProjectionReconciliation {
  /// Safely merges the base MenuSnapshot with the realtime availability overlay.
  /// If the availability map has an entry for a MenuItem, it overrides the MenuItem's `isAvailable` field.
  static MenuSnapshot reconcile({
    required MenuSnapshot snapshot,
    required Map<String, bool> availabilityOverlay,
  }) {
    final reconciledItems = snapshot.items.map((item) {
      if (availabilityOverlay.containsKey(item.id)) {
        return item.copyWith(isAvailable: availabilityOverlay[item.id]!);
      }
      return item;
    }).toList();

    return snapshot.copyWith(
      items: reconciledItems,
      availabilityOverlay: availabilityOverlay,
    );
  }
}
