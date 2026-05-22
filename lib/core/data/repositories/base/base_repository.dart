// ── Base Repository ──────────────────────────────────────────────────────────
// Generic repository interface for CRUD operations.
// All feature repositories should extend or implement similar patterns.

import '../../../../shared/models/result.dart';
import '../../../../shared/models/failures.dart';

/// Base repository interface for entities with CRUD operations
abstract class BaseRepository<T, ID> {
  /// Fetch a single entity by ID
  Future<Result<T, AppFailure>> getById(ID id);

  /// Fetch all entities (with optional filtering)
  Future<Result<List<T>, AppFailure>> getAll({Map<String, dynamic>? filters});

  /// Create a new entity
  Future<Result<T, AppFailure>> create(T entity);

  /// Update an existing entity
  Future<Result<T, AppFailure>> update(T entity);

  /// Delete an entity by ID
  Future<Result<void, AppFailure>> delete(ID id);
}

/// Base repository with real-time capabilities
abstract class StreamableRepository<T> {
  /// Watch for changes to entities
  Stream<List<T>> watch({Map<String, dynamic>? filters});

  /// Watch a single entity by ID
  Stream<T?> watchOne(String id);
}

/// Repository with pagination support
abstract class PaginatedRepository<T> {
  /// Fetch paginated results
  Future<Result<PaginatedResult<T>, AppFailure>> getPaginated({
    required int page,
    required int pageSize,
    Map<String, dynamic>? filters,
    String? sortBy,
    SortOrder? sortOrder,
  });
}

/// Paginated result wrapper
class PaginatedResult<T> {
  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final bool hasMore;

  const PaginatedResult({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });

  int get totalPages => (totalCount / pageSize).ceil();
}

/// Sort order enum
enum SortOrder {
  ascending,
  descending;

  String toJson() => name;
  static SortOrder fromJson(String json) => values.byName(json);
}
