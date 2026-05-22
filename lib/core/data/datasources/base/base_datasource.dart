// ── Base Data Source ─────────────────────────────────────────────────────────
// Abstract data source interfaces for different source types.
// Repositories orchestrate between these sources.

/// Remote data source (API, WebSocket, etc.)
abstract class RemoteDataSource<DTO> {
  /// Fetch data from remote source
  Future<List<DTO>> fetchAll(Map<String, dynamic>? params);

  /// Fetch single item from remote source
  Future<DTO> fetchById(String id);

  /// Create item on remote source
  Future<DTO> create(DTO dto);

  /// Update item on remote source
  Future<DTO> update(DTO dto);

  /// Delete item on remote source
  Future<void> delete(String id);

  /// Watch for real-time updates (optional)
  Stream<List<DTO>>? watchAll(Map<String, dynamic>? params) => null;

  /// Watch single item for real-time updates (optional)
  Stream<DTO?>? watchOne(String id) => null;
}

/// Local data source (cache, database, etc.)
abstract class LocalDataSource<DTO> {
  /// Fetch all items from local storage
  Future<List<DTO>> getAll();

  /// Fetch single item from local storage
  Future<DTO?> getById(String id);

  /// Save item to local storage
  Future<void> save(DTO dto);

  /// Save multiple items to local storage
  Future<void> saveAll(List<DTO> dtos);

  /// Delete item from local storage
  Future<void> delete(String id);

  /// Clear all items from local storage
  Future<void> clear();

  /// Check if item exists in local storage
  Future<bool> exists(String id);
}

/// Mock data source (for testing/development)
abstract class MockDataSource<DTO> {
  /// Get mock data
  Future<List<DTO>> getMockData();

  /// Get single mock item
  Future<DTO?> getMockById(String id);

  /// Simulate create operation
  Future<DTO> mockCreate(DTO dto);

  /// Simulate update operation
  Future<DTO> mockUpdate(DTO dto);

  /// Simulate delete operation
  Future<void> mockDelete(String id);

  /// Simulate real-time updates
  Stream<List<DTO>> mockWatch();

  /// Simulate network latency
  Future<void> simulateLatency([Duration? duration]) async {
    await Future.delayed(duration ?? const Duration(milliseconds: 300));
  }
}

/// Network info interface
abstract class NetworkInfo {
  Future<bool> get isConnected;
  Stream<bool> get connectivityStream;
}
