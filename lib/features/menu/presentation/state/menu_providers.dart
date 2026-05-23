// lib/features/menu/presentation/state/menu_providers.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../../../core/network/network_providers.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/network/sync_state.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/auth/mock_auth_provider.dart';
import '../../../orders/domain/entities/menu_product.dart' as orders_entities;
import '../../data/repositories/menu_repository_impl.dart';
import '../../domain/entities/menu_snapshot.dart';
import '../../domain/repositories/menu_repository.dart';
import '../../../customer/presentation/state/customer_providers.dart';

import '../../runtime/projection_reconciliation.dart';
import '../../runtime/projection_integrity.dart';
import '../../runtime/modifier_resolver.dart';
import '../../runtime/snapshot_migration.dart';

final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  final cacheBox = ref.watch(apiCacheBoxProvider);
  final networkInfo = ref.watch(networkInfoProvider);
  final talker = ref.watch(talkerProvider);
  return MenuRepositoryImpl(
    dioClient: dioClient,
    apiCacheBox: cacheBox,
    networkInfo: networkInfo,
    talker: talker,
  );
});

// Core Providers
final branchIdProvider = Provider<String>((ref) {
  final session = ref.watch(customerSessionProvider);
  return session?.branchId ?? 'mock_branch';
});

final menuCacheProvider = Provider<MenuRepository>((ref) {
  return ref.watch(menuRepositoryProvider);
});

class MenuSnapshotNotifier extends StateNotifier<AsyncValue<MenuSnapshot>> {
  final MenuRepository _repository;
  final Ref _ref;
  final Talker _talker;
  bool _isOfflineCache = false;

  MenuSnapshotNotifier(this._repository, this._ref, this._talker)
      : super(const AsyncValue.loading()) {
    // Automatically load when initialized
    loadMenu();
  }

  bool get isOfflineCache => _isOfflineCache;

  Future<void> loadMenu({bool forceRefresh = false}) async {
    state = const AsyncValue.loading();
    try {
      final branchId = _ref.read(branchIdProvider);
      
      // Perform schema verification and migration before fetching/serving
      final migration = SnapshotMigration(repository: _repository, talker: _talker);
      await migration.verifyAndMigrate(branchId);

      final isConnected = await _ref.read(networkInfoProvider).isConnected;
      _isOfflineCache = !isConnected;

      // Hydrate from cache first if not forced refresh to ensure instant load
      if (!forceRefresh) {
        final cached = await _repository.getCachedMenuSnapshot(branchId);
        if (cached != null) {
          state = AsyncValue.data(cached);
          // Fetch fresh from network in the background
          _fetch(branchId: branchId, forceRefresh: false).catchError((_) {});
          return;
        }
      }

      await _fetch(branchId: branchId, forceRefresh: forceRefresh);
    } catch (e, stack) {
      _talker.error('[MenuSnapshotNotifier] Failed: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> _fetch({required String branchId, bool forceRefresh = false}) async {
    try {
      final snapshot = await _repository.getMenuSnapshot(
        branchId: branchId,
        forceRefresh: forceRefresh,
      );
      state = AsyncValue.data(snapshot);
    } catch (e, stack) {
      _talker.error('[MenuSnapshotNotifier] Fetch failed: $e');
      if (state.value == null) {
        state = AsyncValue.error(e, stack);
      }
    }
  }
}

final menuSnapshotProvider = StateNotifierProvider<MenuSnapshotNotifier, AsyncValue<MenuSnapshot>>((ref) {
  final repository = ref.watch(menuRepositoryProvider);
  final talker = ref.watch(talkerProvider);
  // Re-run if branch changes
  ref.watch(branchIdProvider);
  return MenuSnapshotNotifier(repository, ref, talker);
});

class MenuAvailabilityNotifier extends StateNotifier<Map<String, bool>> {
  final MenuRepository _repository;
  final Ref _ref;

  MenuAvailabilityNotifier(this._repository, this._ref) : super(const {}) {
    hydrate();
  }

  Future<void> hydrate() async {
    final branchId = _ref.read(branchIdProvider);
    final cached = await _repository.getCachedAvailabilityOverlay(branchId);
    state = cached;
  }

  void updateAvailability(Map<String, bool> availabilityMap) {
    state = {...state, ...availabilityMap};
    final branchId = _ref.read(branchIdProvider);
    _repository.saveAvailabilityOverlay(branchId, state).catchError((_) {});
  }
}

final menuAvailabilityProvider = StateNotifierProvider<MenuAvailabilityNotifier, Map<String, bool>>((ref) {
  final repository = ref.watch(menuRepositoryProvider);
  // Re-run if branch changes
  ref.watch(branchIdProvider);
  return MenuAvailabilityNotifier(repository, ref);
});

final menuProjectionProvider = Provider<AsyncValue<MenuSnapshot>>((ref) {
  final snapshotAsync = ref.watch(menuSnapshotProvider);
  final availability = ref.watch(menuAvailabilityProvider);

  return snapshotAsync.whenData((snapshot) {
    // Perform reconciliation
    final reconciled = ProjectionReconciliation.reconcile(
      snapshot: snapshot,
      availabilityOverlay: availability,
    );

    // Perform validation
    final integrityResult = ProjectionIntegrity.validate(reconciled);
    if (!integrityResult.isValid) {
      final talker = ref.read(talkerProvider);
      talker.error('[MenuProjection] Reconciled menu failed integrity check: ${integrityResult.errors.join(", ")}');
    }

    return reconciled;
  });
});

final menuSyncProvider = Provider<void>((ref) {
  final repository = ref.watch(menuRepositoryProvider);
  final availabilityNotifier = ref.watch(menuAvailabilityProvider.notifier);
  final talker = ref.watch(talkerProvider);
  final networkInfo = ref.watch(networkInfoProvider);
  
  Timer? etagTimer;
  Timer? availabilityTimer;

  void startTimers() {
    etagTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      final isConnected = await networkInfo.isConnected;
      if (!isConnected) return;

      try {
        final branchId = ref.read(branchIdProvider);
        
        talker.info('[MenuSync] Triggering background ETag validation for branch $branchId...');
        final fresh = await repository.getMenuSnapshot(branchId: branchId);
        ref.read(menuSnapshotProvider.notifier).state = AsyncValue.data(fresh);
      } catch (e) {
        talker.error('[MenuSync] Background ETag sync failed: $e');
      }
    });

    availabilityTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      final isConnected = await networkInfo.isConnected;
      if (!isConnected) return;

      try {
        final branchId = ref.read(branchIdProvider);

        talker.info('[MenuSync] Polling lightweight availability map...');
        final availability = await repository.getItemAvailability(branchId: branchId);
        if (availability.isNotEmpty) {
          availabilityNotifier.updateAvailability(availability);
        }
      } catch (e) {
        talker.error('[MenuSync] Availability polling failed: $e');
      }
    });
  }

  startTimers();

  ref.onDispose(() {
    etagTimer?.cancel();
    availabilityTimer?.cancel();
    talker.info('[MenuSync] Background sync timers cancelled.');
  });
});

final menuHydrationProvider = FutureProvider<MenuSnapshot?>((ref) async {
  final branchId = ref.read(branchIdProvider);
  final repository = ref.read(menuRepositoryProvider);
  
  final snapshot = await repository.getCachedMenuSnapshot(branchId);
  if (snapshot != null) {
    ref.read(menuSnapshotProvider.notifier).state = AsyncValue.data(snapshot);
  }

  await ref.read(menuAvailabilityProvider.notifier).hydrate();
  return snapshot;
});

// Derived Providers
final availableItemsProvider = Provider<List<MenuItem>>((ref) {
  final projection = ref.watch(menuProjectionProvider);
  return projection.maybeWhen(
    data: (snapshot) => snapshot.items.where((i) => i.isAvailable).toList(),
    orElse: () => const [],
  );
});

final branchMenuProvider = Provider<List<MenuItem>>((ref) {
  final projection = ref.watch(menuProjectionProvider);
  return projection.maybeWhen(
    data: (snapshot) => snapshot.items,
    orElse: () => const [],
  );
});

final modifierGroupsProvider = Provider<List<ModifierGroup>>((ref) {
  final projection = ref.watch(menuProjectionProvider);
  return projection.maybeWhen(
    data: (snapshot) => snapshot.modifierGroups,
    orElse: () => const [],
  );
});

final taxProjectionProvider = Provider<TaxConfig?>((ref) {
  final projection = ref.watch(menuProjectionProvider);
  return projection.maybeWhen(
    data: (snapshot) => snapshot.taxConfig,
    orElse: () => null,
  );
});

class MenuStalenessInfo {
  final SyncState syncState;
  final DateTime? lastSyncTime;
  final double confidenceScore;

  const MenuStalenessInfo({
    required this.syncState,
    this.lastSyncTime,
    required this.confidenceScore,
  });
}

final staleMenuProvider = Provider<MenuStalenessInfo>((ref) {
  final snapshotState = ref.watch(menuSnapshotProvider);
  final isConnected = ref.watch(menuSnapshotProvider.notifier).isOfflineCache == false;

  final lastSync = snapshotState.maybeWhen(
    data: (s) => s.generatedAt ?? DateTime.now(),
    orElse: () => null,
  );

  if (!isConnected) {
    return MenuStalenessInfo(
      syncState: SyncState.degraded,
      lastSyncTime: lastSync,
      confidenceScore: 0.5,
    );
  }

  return MenuStalenessInfo(
    syncState: SyncState.fresh,
    lastSyncTime: lastSync ?? DateTime.now(),
    confidenceScore: 1.0,
  );
});

// Legacy compatibility providers
class LegacyMenuSnapshotNotifier extends StateNotifier<AsyncValue<MenuSnapshot>> {
  final Ref _ref;

  LegacyMenuSnapshotNotifier(this._ref) : super(const AsyncValue.loading()) {
    _ref.listen<AsyncValue<MenuSnapshot>>(menuProjectionProvider, (previous, next) {
      state = next;
    }, fireImmediately: true);
  }

  bool get isOfflineCache {
    return _ref.read(menuSnapshotProvider.notifier).isOfflineCache;
  }

  Future<void> loadMenu({bool forceRefresh = false}) async {
    await _ref.read(menuSnapshotProvider.notifier).loadMenu(forceRefresh: forceRefresh);
  }

  Future<void> refresh() async {
    await _ref.read(menuSnapshotProvider.notifier).loadMenu(forceRefresh: true);
  }

  void updateAvailability(Map<String, bool> availabilityMap) {
    _ref.read(menuAvailabilityProvider.notifier).updateAvailability(availabilityMap);
  }
}

final menuSnapshotNotifierProvider = StateNotifierProvider<LegacyMenuSnapshotNotifier, AsyncValue<MenuSnapshot>>((ref) {
  return LegacyMenuSnapshotNotifier(ref);
});

final publicMenuProductsProvider = Provider<List<orders_entities.MenuProduct>>((ref) {
  final menuSnapshotAsync = ref.watch(menuSnapshotNotifierProvider);
  return menuSnapshotAsync.maybeWhen(
    data: (snapshot) => snapshot.toMenuProducts(),
    orElse: () => const [],
  );
});

final menuStalenessProvider = Provider<SyncState>((ref) {
  final staleness = ref.watch(staleMenuProvider);
  return staleness.syncState;
});

final menuAvailabilityPollingProvider = Provider.autoDispose<void>((ref) {
  ref.watch(menuSyncProvider);
});
