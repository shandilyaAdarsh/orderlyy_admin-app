// lib/features/menu/presentation/state/menu_providers.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../../../core/network/network_providers.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/network/sync_state.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/auth/mock_auth_provider.dart';
import '../../../../core/runtime/runtime_context.dart';
import '../../../orders/domain/entities/menu_product.dart' as orders_entities;
import '../../data/repositories/menu_repository_impl.dart';
import '../../domain/entities/menu_snapshot.dart';
import '../../domain/repositories/menu_repository.dart';
import '../../../customer/presentation/state/customer_providers.dart';

final menuSnapshotRepositoryProvider = Provider<MenuRepository>((ref) {
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
  int _lastOverlayRevision = 0;

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
      final customerSession = _ref.read(customerSessionProvider);
      if (customerSession == null) {
        throw RuntimeInitializationException(
          'Customer session is required before menu snapshot fetch.',
        );
      }
      final branchId = requireContextValue(
        value: customerSession.branchId,
        field: 'branchId',
        source: 'MenuSnapshotNotifier._fetch',
      );
      requireContextValue(
        value: customerSession.tenantId,
        field: 'tenantId',
        source: 'MenuSnapshotNotifier._fetch',
      );
      requireContextValue(
        value: customerSession.tableId,
        field: 'sessionId',
        source: 'MenuSnapshotNotifier._fetch',
      );
      final isConnected = await _ref.read(networkInfoProvider).isConnected;

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

void reconcileAvailability({
  required Map<String, bool> authoritativeAvailability,
  required int revision,
}) {
  if (revision <= _lastOverlayRevision) {
    _talker.info(
      '[MenuNotifier] Ignored stale overlay revision $revision (last=$_lastOverlayRevision).',
    );
    return;
  }

  state.whenData((snapshot) {
    final updatedItems = snapshot.items.map((item) {
      return item.copyWith(
        isAvailable: authoritativeAvailability[item.id] ?? false,
      );
    }).toList();

    state = AsyncValue.data(
      MenuSnapshot(
        categories: snapshot.categories,
        items: updatedItems,
        modifierGroups: snapshot.modifierGroups,
        taxConfig: snapshot.taxConfig,
      ),
    );

    _lastOverlayRevision = revision;
  });
}
}

final menuSnapshotNotifierProvider =
    StateNotifierProvider<MenuSnapshotNotifier, AsyncValue<MenuSnapshot>>((ref) {
  final repository = ref.watch(menuSnapshotRepositoryProvider);

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
  final repository = ref.watch(menuSnapshotRepositoryProvider);
  final notifier = ref.watch(menuSnapshotNotifierProvider.notifier);
  final talker = ref.watch(talkerProvider);
  final networkInfo = ref.watch(networkInfoProvider);
  final customerSession = ref.watch(customerSessionProvider);
  if (customerSession == null) {
    throw RuntimeInitializationException(
      'Customer session is required before availability polling can start.',
    );
  }

  final branchId = requireContextValue(
    value: customerSession.branchId,
    field: 'branchId',
    source: 'menuAvailabilityPollingProvider',
  );
  requireContextValue(
    value: customerSession.tenantId,
    field: 'tenantId',
    source: 'menuAvailabilityPollingProvider',
  );
  requireContextValue(
    value: customerSession.tableId,
    field: 'sessionId',
    source: 'menuAvailabilityPollingProvider',
  );

  talker.info(
    '[MenuPolling] Availability polling initialized for branch $branchId.',
  );

  final scheduler = _AvailabilityPollingScheduler(
    repository: repository,
    networkInfo: networkInfo,
    notifier: notifier,
    talker: talker,
    branchId: branchId,
  )..start();

  ref.onDispose(() {
    scheduler.dispose();
    talker.info('[MenuPolling] Availability polling stopped.');
  });
});

class _AvailabilityPollingScheduler {
  static const Duration _baseInterval = Duration(seconds: 15);
  static const Duration _maxRetryBackoff = Duration(seconds: 60);

  final MenuRepository repository;
  final NetworkInfo networkInfo;
  final MenuSnapshotNotifier notifier;
  final Talker talker;
  final String branchId;
  final Random _random = Random.secure();

  bool _disposed = false;
  bool _inFlight = false;
  int _revision = 0;
  int _retryCount = 0;
  Timer? _timer;

  _AvailabilityPollingScheduler({
    required this.repository,
    required this.networkInfo,
    required this.notifier,
    required this.talker,
    required this.branchId,
  });

  void start() {
    _scheduleNext(const Duration(milliseconds: 200));
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
  }

  void _scheduleNext(Duration delay) {
    if (_disposed) return;
    _timer?.cancel();
    _timer = Timer(delay, _runPoll);
  }

  Duration _nextHealthyInterval() {
    final jitterSeconds = 2 + _random.nextInt(4); // 2-5s
    final subtract = _random.nextBool();
    final jitter = Duration(seconds: jitterSeconds);
    return subtract ? (_baseInterval - jitter) : (_baseInterval + jitter);
  }

  Duration _nextRetryInterval() {
    final exp = 1 << _retryCount.clamp(0, 5);
    final backoff = Duration(seconds: 2 * exp);
    final bounded = backoff > _maxRetryBackoff ? _maxRetryBackoff : backoff;
    final jitterMs = _random.nextInt(1200);
    return bounded + Duration(milliseconds: jitterMs);
  }

  Future<void> _runPoll() async {
    if (_disposed || _inFlight) return;
    _inFlight = true;
    try {
      final isConnected = await networkInfo.isConnected;
      if (!isConnected) {
        _retryCount = (_retryCount + 1).clamp(0, 8);
        _scheduleNext(_nextRetryInterval());
        return;
      }

      final availability = await repository.getItemAvailability(branchId: branchId);
      _revision += 1;
      notifier.reconcileAvailability(
        authoritativeAvailability: availability,
        revision: _revision,
      );
      _retryCount = 0;
      _scheduleNext(_nextHealthyInterval());
    } catch (error) {
      _retryCount = (_retryCount + 1).clamp(0, 8);
      talker.warning('[MenuPolling] Poll failed, scheduling retry: $error');
      _scheduleNext(_nextRetryInterval());
    } finally {
      _inFlight = false;
    }
  }
}
