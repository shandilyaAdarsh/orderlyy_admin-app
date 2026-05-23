// lib/features/menu/domain/repositories/menu_repository.dart
import '../entities/menu_snapshot.dart';

abstract class MenuRepository {
  /// Fetches the menu snapshot.
  /// If [forceRefresh] is true, ignores any ETag check and forces a full reload from the server.
  Future<MenuSnapshot> getMenuSnapshot({
    required String branchId,
    bool forceRefresh = false,
  });

  /// Fetches the lightweight item availability mapping from the server.
  Future<Map<String, bool>> getItemAvailability({
    required String branchId,
  });

  /// Saves a menu snapshot locally.
  Future<void> saveMenuSnapshot(MenuSnapshot snapshot);

  /// Retrieves a locally cached menu snapshot.
  Future<MenuSnapshot?> getCachedMenuSnapshot(String branchId);

  /// Saves the lightweight item availability overlay mapping locally.
  Future<void> saveAvailabilityOverlay(
    String branchId,
    Map<String, bool> overlay,
  );

  /// Retrieves the locally cached availability overlay mapping.
  Future<Map<String, bool>> getCachedAvailabilityOverlay(String branchId);

  /// Clears the cache for the given branch.
  Future<void> clearCache(String branchId);
}
