// ── Orders Repository Factory ────────────────────────────────────────────────
// Factory for creating different repository implementations.
// Enables easy swapping between mock/live/offline modes.

import '../../../../core/storage/local_storage.dart';
import '../datasources/orders_remote_datasource.dart';
import '../datasources/orders_local_datasource.dart';
import '../datasources/orders_mock_datasource.dart';
import 'orders_repository_interface.dart';
import 'orders_repository_impl.dart';

/// Repository mode enum
enum RepositoryMode {
  /// Mock data source (for development/testing)
  mock,

  /// Live API data source
  live,

  /// Offline-first (local + remote with sync)
  offlineFirst,

  /// Hybrid (cache-first, then remote)
  hybrid,
}

/// Factory for creating orders repositories
class OrdersRepositoryFactory {
  /// Create repository based on mode
  static IOrdersRepository create({
    required RepositoryMode mode,
    OrdersRemoteDataSource? remoteDataSource,
    LocalStorage? localStorage,
    dynamic httpClient,
    String? baseUrl,
  }) {
    switch (mode) {
      case RepositoryMode.mock:
        return _createMockRepository();

      case RepositoryMode.live:
        return _createLiveRepository(
          remoteDataSource: remoteDataSource,
          httpClient: httpClient,
          baseUrl: baseUrl,
        );

      case RepositoryMode.offlineFirst:
        return _createOfflineFirstRepository(
          remoteDataSource: remoteDataSource,
          localStorage: localStorage,
          httpClient: httpClient,
          baseUrl: baseUrl,
        );

      case RepositoryMode.hybrid:
        return _createHybridRepository(
          remoteDataSource: remoteDataSource,
          localStorage: localStorage,
          httpClient: httpClient,
          baseUrl: baseUrl,
        );
    }
  }

  /// Create mock repository
  static IOrdersRepository _createMockRepository() {
    final mockDataSource = OrdersMockDataSource();

    return OrdersRepositoryImpl(
      mockDataSource: mockDataSource,
      useCache: false,
    );
  }

  /// Create live repository (API only, no cache)
  static IOrdersRepository _createLiveRepository({
    OrdersRemoteDataSource? remoteDataSource,
    dynamic httpClient,
    String? baseUrl,
  }) {
    final remote =
        remoteDataSource ??
        OrdersRestDataSource(
          httpClient ?? _createDefaultHttpClient(),
          baseUrl ?? _getDefaultBaseUrl(),
        );

    return OrdersRepositoryImpl(remoteDataSource: remote, useCache: false);
  }

  /// Create offline-first repository (local + remote with sync)
  static IOrdersRepository _createOfflineFirstRepository({
    OrdersRemoteDataSource? remoteDataSource,
    LocalStorage? localStorage,
    dynamic httpClient,
    String? baseUrl,
  }) {
    if (localStorage == null) {
      throw ArgumentError('localStorage is required for offline-first mode');
    }

    final remote =
        remoteDataSource ??
        OrdersRestDataSource(
          httpClient ?? _createDefaultHttpClient(),
          baseUrl ?? _getDefaultBaseUrl(),
        );

    final local = OrdersSharedPrefsDataSource(localStorage);

    return OrdersRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: local,
      useCache: true,
    );
  }

  /// Create hybrid repository (cache-first, then remote)
  static IOrdersRepository _createHybridRepository({
    OrdersRemoteDataSource? remoteDataSource,
    LocalStorage? localStorage,
    dynamic httpClient,
    String? baseUrl,
  }) {
    if (localStorage == null) {
      throw ArgumentError('localStorage is required for hybrid mode');
    }

    final remote =
        remoteDataSource ??
        OrdersRestDataSource(
          httpClient ?? _createDefaultHttpClient(),
          baseUrl ?? _getDefaultBaseUrl(),
        );

    final local = OrdersSharedPrefsDataSource(localStorage);

    return OrdersRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: local,
      useCache: true,
    );
  }

  // ── Helper Methods ────────────────────────────────────────────────────────

  static dynamic _createDefaultHttpClient() {
    // Return default HTTP client (Dio, http, etc.)
    throw UnimplementedError('Default HTTP client not configured');
  }

  static String _getDefaultBaseUrl() {
    // Return default API base URL
    return 'https://api.example.com';
  }
}

/// Extension for easy repository creation
extension RepositoryModeExtension on RepositoryMode {
  /// Create repository with this mode
  IOrdersRepository createRepository({
    OrdersRemoteDataSource? remoteDataSource,
    LocalStorage? localStorage,
    dynamic httpClient,
    String? baseUrl,
  }) {
    return OrdersRepositoryFactory.create(
      mode: this,
      remoteDataSource: remoteDataSource,
      localStorage: localStorage,
      httpClient: httpClient,
      baseUrl: baseUrl,
    );
  }
}
