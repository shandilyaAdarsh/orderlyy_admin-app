// lib/features/menu/runtime/modifier_resolver.dart
import '../domain/entities/menu_snapshot.dart';

class ModifierResolver {
  /// Resolves the modifier groups and options assigned to a specific MenuItem.
  static List<ModifierGroup> resolveGroupsForItem({
    required MenuItem item,
    required List<ModifierGroup> allGroups,
  }) {
    final groupMap = {for (final group in allGroups) group.id: group};
    return item.modifierGroupIds
        .map((groupId) => groupMap[groupId])
        .whereType<ModifierGroup>()
        .toList();
  }

  /// Validates a selection of modifier options against the item's configured groups.
  /// Checks if:
  /// Each selected modifier option actually exists in one of the item's groups.
  static bool validateSelection({
    required MenuItem item,
    required List<ModifierGroup> allGroups,
    required List<String> selectedOptionIds,
  }) {
    final groups = resolveGroupsForItem(item: item, allGroups: allGroups);
    final allowedOptionIds = groups.expand((g) => g.options.map((o) => o.id)).toSet();

    for (final optionId in selectedOptionIds) {
      if (!allowedOptionIds.contains(optionId)) {
        return false; // Option selected is not allowed for this item
      }
    }
    return true;
  }
}
