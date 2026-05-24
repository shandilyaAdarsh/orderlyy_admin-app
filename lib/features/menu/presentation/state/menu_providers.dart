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

class MenuSnapshotNotifier extends StateNotifier<AsyncValue<MenuSnapshot>> {
  final MenuRepository _repository;
  final Ref _ref;
  final Talker _talker;
  bool _isOfflineCache = false;
  int _lastOverlayRevision = 0;

  MenuSnapshotNotifier(this._repository, this._ref, this._talker) : super(const AsyncValue.loading()) {
    // Automatically load when initialized
    loadMenu();
  }

  bool get isOfflineCache => _isOfflineCache;

  Future<void> loadMenu({bool forceRefresh = false}) async {
    state = const AsyncValue.loading();
    await _fetch(forceRefresh: forceRefresh);
  }

  Future<void> refresh() async {
    if (state.isLoading) return;
    await _fetch(forceRefresh: true);
  }

  Future<void> _fetch({bool forceRefresh = false}) async {
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

      _isOfflineCache = !isConnected;
      state = AsyncValue.data(snapshot);
    } catch (e, stack) {
      _talker.error('[MenuNotifier] Failed to load menu: $e');
      state = AsyncValue.error(e, stack);
    }
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

final menuSnapshotNotifierProvider = StateNotifierProvider<MenuSnapshotNotifier, AsyncValue<MenuSnapshot>>((ref) {
  final repository = ref.watch(menuRepositoryProvider);
  final talker = ref.watch(talkerProvider);
  return MenuSnapshotNotifier(repository, ref, talker);
});

/// Exposes the menu products mapped to the legacy domains for UI compatibility
final publicMenuProductsProvider = Provider<List<orders_entities.MenuProduct>>((ref) {
  final menuSnapshotAsync = ref.watch(menuSnapshotNotifierProvider);
  return menuSnapshotAsync.maybeWhen(
    data: (snapshot) => snapshot.toMenuProducts(),
    orElse: () => const [],
  );
});

/// Exposes the menu cache's sync state (fresh, stale, degraded)
final menuStalenessProvider = Provider<SyncState>((ref) {
  final notifierState = ref.watch(menuSnapshotNotifierProvider.notifier);

  // We check if notifier loaded cache while offline
  if (notifierState.isOfflineCache) {
    return SyncState.degraded; // offline mode
  }
  
  return SyncState.fresh;
});

/// Availability polling provider that triggers background polling when active
final menuAvailabilityPollingProvider = Provider.autoDispose<void>((ref) {
  final repository = ref.watch(menuRepositoryProvider);
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
