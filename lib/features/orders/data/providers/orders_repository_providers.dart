// ── Orders Repository Providers ──────────────────────────────────────────────
// Riverpod providers for swappable repository architecture.
// Change repository mode without touching business logic or UI.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/providers/repository_providers.dart' show sharedPreferencesProvider;
import '../repositories/orders_repository_interface.dart';
import '../repositories/orders_repository_factory.dart';
import '../datasources/orders_mock_datasource.dart';
import '../datasources/orders_local_datasource.dart';

// ── Configuration ─────────────────────────────────────────────────────────────

/// Repository mode provider (can be overridden for testing)
final repositoryModeProvider = Provider<RepositoryMode>((ref) {
  // Change this to switch modes:
  // - RepositoryMode.mock (development)
  // - RepositoryMode.live (production API)
  // - RepositoryMode.offlineFirst (offline-capable)
  // - RepositoryMode.hybrid (cache-first)
  return RepositoryMode.mock;
});

// ── Data Source Providers ─────────────────────────────────────────────────────

/// Mock data source provider
final ordersMockDataSourceProvider = Provider<OrdersMockDataSource>((ref) {
  final dataSource = OrdersMockDataSource();
  ref.onDispose(() => dataSource.dispose());
  return dataSource;
});

/// Local data source provider
final ordersLocalDataSourceProvider = Provider<OrdersLocalDatasource>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return OrdersLocalDatasourceImpl(prefs);
});

/// Remote data source provider (placeholder for future implementation)
final ordersRemoteDataSourceProvider = Provider((ref) {
  throw UnimplementedError('Remote data source not yet implemented');
});

// ── Repository Provider ───────────────────────────────────────────────────────

/// Main orders repository provider
///
/// This provider automatically creates the correct repository implementation
/// based on the configured mode. Business logic and UI depend only on this.
final ordersRepositoryProvider = Provider<IOrdersRepository>((ref) {
  final mode = ref.watch(repositoryModeProvider);
  final localStorage = ref.watch(localStorageProvider);

  switch (mode) {
    case RepositoryMode.mock:
      return OrdersRepositoryFactory.create(mode: RepositoryMode.mock);

    case RepositoryMode.live:
      // final remoteDataSource = ref.watch(ordersRemoteDataSourceProvider);
      return OrdersRepositoryFactory.create(
        mode: RepositoryMode.live,
        // remoteDataSource: remoteDataSource,
      );

    case RepositoryMode.offlineFirst:
      // final remoteDataSource = ref.watch(ordersRemoteDataSourceProvider);
      return OrdersRepositoryFactory.create(
        mode: RepositoryMode.offlineFirst,
        // remoteDataSource: remoteDataSource,
        localStorage: localStorage,
      );

    case RepositoryMode.hybrid:
      // final remoteDataSource = ref.watch(ordersRemoteDataSourceProvider);
      return OrdersRepositoryFactory.create(
        mode: RepositoryMode.hybrid,
        // remoteDataSource: remoteDataSource,
        localStorage: localStorage,
      );
  }
});
