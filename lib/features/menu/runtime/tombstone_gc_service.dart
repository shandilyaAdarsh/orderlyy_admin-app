// lib/features/menu/runtime/tombstone_gc_service.dart
import 'package:talker_flutter/talker_flutter.dart';
import '../domain/entities/menu_snapshot.dart';

class TombstoneGCService {
  final Talker _talker;
  final Duration gcWindow;

  /// Default GC window is 7 days. This allows ample time for offline devices
  /// to sync and resolve modify-vs-delete conflicts safely before the tombstone
  /// is permanently erased.
  TombstoneGCService(this._talker, {this.gcWindow = const Duration(days: 7)});

  /// Purges expired tombstones from a snapshot, returning the clean snapshot.
  MenuSnapshot garbageCollect(MenuSnapshot snapshot) {
    final now = DateTime.now();

    bool isExpired(DateTime? deletedAt) {
      if (deletedAt == null) return false;
      return now.difference(deletedAt) > gcWindow;
    }

    final cleanCategories = snapshot.categories.where((c) => !isExpired(c.deletedAt)).toList();
    final cleanItems = snapshot.items.where((i) => !isExpired(i.deletedAt)).toList();
    final cleanGroups = snapshot.modifierGroups.where((g) => !isExpired(g.deletedAt)).toList();

    // Modifier options are nested
    final cleanGroupsWithOptions = cleanGroups.map((g) {
      final cleanOptions = g.options.where((o) => !isExpired(o.deletedAt)).toList();
      return g.options.length == cleanOptions.length
          ? g
          : ModifierGroup(id: g.id, name: g.name, options: cleanOptions, deletedAt: g.deletedAt);
    }).toList();

    final removedCount = (snapshot.categories.length - cleanCategories.length) +
        (snapshot.items.length - cleanItems.length) +
        (snapshot.modifierGroups.length - cleanGroups.length);

    if (removedCount > 0) {
      _talker.info('[TombstoneGC] Garbage collected $removedCount expired tombstones.');
    }

    return snapshot.copyWith(
      categories: cleanCategories,
      items: cleanItems,
      modifierGroups: cleanGroupsWithOptions,
    );
  }
}
