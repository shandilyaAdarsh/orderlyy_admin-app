# Offline-First Architecture Specification
## Enterprise-Grade Flutter Restaurant Management System

**Document Version:** 1.0.0  
**Last Updated:** 2026-05-21  
**Architecture Risk:** HIGH  
**Production Priority:** HIGH  
**Target Environment:** Flutter + Riverpod + Real-time Restaurant Workflows

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Architecture Philosophy](#2-architecture-philosophy)
3. [Recommended Architecture Style](#3-recommended-architecture-style)
4. [State Management Strategy](#4-state-management-strategy)
5. [Serializable State Rules](#5-serializable-state-rules)
6. [Immutable Domain Model Design](#6-immutable-domain-model-design)
7. [Event-Driven State Flow](#7-event-driven-state-flow)
8. [Offline-Ready Data Flow](#8-offline-ready-data-flow)
9. [Repository Architecture](#9-repository-architecture)
10. [Riverpod Production Guidelines](#10-riverpod-production-guidelines)
11. [UI State vs Business State](#11-ui-state-vs-business-state)
12. [Real-Time Event Architecture](#12-real-time-event-architecture)
13. [Failure Recovery Design](#13-failure-recovery-design)
14. [Serialization Strategy](#14-serialization-strategy)
15. [Debugging & Observability](#15-debugging--observability)
16. [Performance Architecture](#16-performance-architecture)
17. [Testing Strategy](#17-testing-strategy)
18. [Code Standards](#18-code-standards)
19. [Anti-Patterns to Avoid](#19-anti-patterns-to-avoid)
20. [Production Checklist](#20-production-checklist)
21. [Final Recommendations](#21-final-recommendations)

---

## 1. Executive Summary

### Mission-Critical Context

This architecture specification defines a **production-ready, offline-friendly, serializable-by-design** Flutter application architecture for a real-time restaurant management system. The system must handle mission-critical workflows where network failures, app crashes, or state corruption can directly impact restaurant operations and revenue.

### Core Architectural Goals

1. **Serializable State**: ALL application state must be serializable to JSON for persistence, hydration, and debugging
2. **Deterministic Behavior**: State transitions must be predictable and reproducible
3. **Offline-First Ready**: Architecture must support future offline capabilities without major refactoring
4. **Resilient Operations**: System must recover gracefully from crashes, network failures, and data corruption
5. **Event Replay**: Support debugging through event replay and time-travel capabilities

### Business Impact

- **Prevents Revenue Loss**: Resilient architecture prevents order loss during network outages
- **Improves Reliability**: Deterministic state reduces bugs and unexpected behavior
- **Enables Scaling**: Clean architecture supports multi-location deployments
- **Simplifies Debugging**: Serializable state enables production issue reproduction
- **Future-Proofs**: Offline-ready design supports evolving business requirements

### Key Architectural Decisions

| Decision | Rationale | Trade-off |
|----------|-----------|-----------|
| Immutable State Only | Prevents race conditions, enables time-travel debugging | Slightly more verbose code |
| DTO-Driven Architecture | Clean separation, serialization-ready | Additional mapping layer |
| Event-Driven Updates | Deterministic, replayable, auditable | More complex than direct mutations |
| Riverpod StateNotifiers | Predictable state management, testable | Learning curve for team |
| No Streams in State | Serializable, persistable state | Requires event normalization |

---


## 2. Architecture Philosophy

### 2.1 Offline-Friendly Architecture Principles

**Definition**: An offline-friendly architecture is one where the application can function (at least partially) without network connectivity, and can seamlessly synchronize when connectivity is restored.

**Core Principles**:

1. **Local-First Thinking**: Treat local state as the source of truth, sync to server as secondary operation
2. **Optimistic Updates**: Apply changes immediately to local state, reconcile with server asynchronously
3. **Event Sourcing**: Store actions/events, not just final state, enabling replay and conflict resolution
4. **Idempotent Operations**: All operations must be safely repeatable without side effects
5. **Conflict Resolution**: Design for eventual consistency with clear conflict resolution strategies

### 2.2 Serializable State Philosophy

**Why Serialization Matters**:

```
Serializable State = Persistable = Debuggable = Testable = Offline-Ready
```

**Benefits**:
- **Crash Recovery**: Restore exact app state after crashes
- **State Hydration**: Load previous session state on app restart
- **Time-Travel Debugging**: Replay state transitions to reproduce bugs
- **Offline Sync**: Persist pending actions for later synchronization
- **Testing**: Create deterministic test scenarios with known state
- **Audit Trail**: Log state changes for compliance and debugging

**Anti-Pattern Example** (Non-Serializable):
```dart
// ❌ BAD: Non-serializable state
class OrderState {
  final Stream<Order> orderStream;  // Cannot serialize
  final TextEditingController noteController;  // Widget dependency
  final Function() onComplete;  // Closure
  final BuildContext context;  // Widget reference
}
```

**Correct Pattern** (Serializable):
```dart
// ✅ GOOD: Fully serializable state
@freezed
class OrderState with _$OrderState {
  const factory OrderState({
    required String orderId,
    required OrderStatus status,
    required List<OrderItemDto> items,
    required double totalAmount,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? notes,
  }) = _OrderState;
  
  factory OrderState.fromJson(Map<String, dynamic> json) => 
      _$OrderStateFromJson(json);
}
```

### 2.3 Deterministic State Flow

**Definition**: Given the same initial state and sequence of events, the system always produces the same final state.

**Why Determinism Matters**:
- **Reproducible Bugs**: Replay exact sequence that caused production issues
- **Predictable Behavior**: Reduces "works on my machine" problems
- **Testability**: Write reliable tests with known outcomes
- **Debugging**: Understand exactly how state evolved
- **Confidence**: Deploy with certainty about system behavior

**Deterministic Flow Pattern**:
```
Initial State + Event Sequence → Deterministic Reducer → Final State
```

**Example**:
```dart
// Deterministic state transition
OrderState reduceOrderEvent(OrderState state, OrderEvent event) {
  return event.when(
    itemAdded: (item) => state.copyWith(
      items: [...state.items, item],
      totalAmount: state.totalAmount + item.price,
      updatedAt: event.timestamp,  // From event, not DateTime.now()
    ),
    itemRemoved: (itemId) => state.copyWith(
      items: state.items.where((i) => i.id != itemId).toList(),
      totalAmount: _recalculateTotal(state.items, itemId),
      updatedAt: event.timestamp,
    ),
  );
}
```

### 2.4 Real-World Restaurant Failure Scenarios

**Scenario 1: Network Outage During Peak Hours**
- **Problem**: WiFi fails during dinner rush, orders cannot be sent to kitchen
- **Without Offline Architecture**: Orders lost, customers wait indefinitely, revenue lost
- **With Offline Architecture**: Orders queued locally, kitchen display shows pending, auto-sync when network returns

**Scenario 2: App Crash Mid-Transaction**
- **Problem**: Waiter's tablet crashes while taking a large order
- **Without Serializable State**: Order data lost, must re-enter everything
- **With Serializable State**: App restores exact state on restart, order intact

**Scenario 3: Conflicting Updates**
- **Problem**: Manager updates order on POS while waiter updates on tablet
- **Without Event Sourcing**: Last write wins, changes lost
- **With Event Sourcing**: Both changes preserved, conflict resolution applied

**Scenario 4: Partial Sync Failure**
- **Problem**: 5 orders sent to server, 3 succeed, 2 fail, network drops
- **Without Idempotency**: Retry causes duplicate orders
- **With Idempotency**: Safe retry, no duplicates, clear pending state

### 2.5 Architectural Goals

| Goal | Description | Success Metric |
|------|-------------|----------------|
| **Zero Data Loss** | No orders/transactions lost due to technical failures | 100% order persistence |
| **Predictable State** | State transitions always follow defined rules | Zero "impossible state" bugs |
| **Fast Recovery** | App recovers from crashes in <2 seconds | <2s cold start with state restoration |
| **Offline Capable** | Core workflows function without network | 80% features work offline |
| **Debuggable** | Production issues reproducible in development | 100% state transitions logged |
| **Testable** | All state logic unit testable | >90% coverage on state logic |

### 2.6 Architectural Tradeoffs

| Tradeoff | Benefit | Cost | Mitigation |
|----------|---------|------|------------|
| **Immutability** | Thread-safe, predictable | More object creation | Use const constructors, Freezed |
| **Event Sourcing** | Auditable, replayable | Storage overhead | Compact event format, periodic snapshots |
| **DTO Mapping** | Clean boundaries | Boilerplate code | Code generation (Freezed, json_serializable) |
| **Strict Serialization** | Offline-ready | Cannot use Streams/Controllers in state | Normalize events, use providers |
| **Deterministic Reducers** | Testable, predictable | More complex than direct mutation | Clear event types, well-documented reducers |

### 2.7 Scalability Considerations

**Horizontal Scaling**:
- Stateless backend services
- Event-driven architecture supports distributed systems
- Local-first approach reduces server load

**Data Volume**:
- Efficient serialization (Protocol Buffers consideration for future)
- Periodic state snapshots to reduce event replay time
- Automatic cleanup of old events

**Multi-Location**:
- Tenant-isolated state
- Per-location sync boundaries
- Conflict resolution per restaurant

### 2.8 Future Offline-Sync Readiness

**Phase 1: Current (Online-First with Resilience)**
- Serializable state architecture
- Event-driven updates
- Local caching
- Crash recovery

**Phase 2: Offline-Capable (Future)**
- Persistent event queue
- Background sync service
- Conflict resolution UI
- Offline mode indicator

**Phase 3: Offline-First (Future)**
- Local database (Drift/Hive)
- CRDTs for automatic conflict resolution
- Peer-to-peer sync between devices
- Full offline operation

**Key Insight**: By building with serializable, event-driven architecture NOW, Phase 2 and 3 require minimal refactoring—primarily adding persistence and sync layers, not restructuring core state management.

---


## 3. Recommended Architecture Style

### 3.1 Feature-First Architecture

**Structure**: Organize code by business feature, not technical layer.

**Benefits**:
- **Cohesion**: Related code stays together
- **Scalability**: Easy to add new features without touching existing code
- **Team Ownership**: Teams can own entire features
- **Modularity**: Features can be extracted into packages

**Feature Boundaries**:
```
lib/
├── features/
│   ├── orders/           # Order management feature
│   ├── tables/           # Table management feature
│   ├── billing/          # Billing feature
│   ├── menu/             # Menu management feature
│   ├── staff/            # Staff management feature
│   └── analytics/        # Analytics feature
├── core/                 # Shared infrastructure
└── shared/               # Shared business logic
```

### 3.2 Clean Architecture Adaptation

**Layers** (from outer to inner):

1. **Presentation Layer** (UI)
   - Widgets
   - Screens
   - View Models (Riverpod Providers)

2. **Application Layer** (Use Cases)
   - Business logic
   - State management
   - Event handlers

3. **Domain Layer** (Entities)
   - Domain models
   - Business rules
   - Value objects

4. **Data Layer** (Infrastructure)
   - Repositories
   - Data sources
   - DTOs

**Dependency Rule**: Inner layers never depend on outer layers.

```
UI → Application → Domain ← Data
     (Providers)   (Models)  (Repos)
```

### 3.3 Complete Folder Structure

```
lib/
├── main.dart
├── app.dart
│
├── core/                                    # Shared infrastructure
│   ├── router/
│   │   ├── app_router.dart
│   │   └── route_guards.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   └── app_colors.dart
│   ├── constants/
│   │   ├── api_constants.dart
│   │   └── app_constants.dart
│   ├── errors/
│   │   ├── failures.dart
│   │   └── exceptions.dart
│   ├── network/
│   │   ├── network_info.dart
│   │   └── api_client.dart
│   ├── storage/
│   │   ├── local_storage.dart
│   │   └── secure_storage.dart
│   └── utils/
│       ├── logger.dart
│       └── date_utils.dart
│
├── shared/                                  # Shared across features
│   ├── models/
│   │   ├── result.dart                     # Result<T, E> type
│   │   └── paginated_response.dart
│   ├── widgets/
│   │   ├── loading_indicator.dart
│   │   └── error_view.dart
│   └── providers/
│       ├── auth_provider.dart              # Global auth state
│       └── connectivity_provider.dart      # Network status
│
├── features/
│   ├── orders/
│   │   ├── data/
│   │   │   ├── dtos/
│   │   │   │   ├── order_dto.dart          # API contract
│   │   │   │   └── order_item_dto.dart
│   │   │   ├── repositories/
│   │   │   │   ├── orders_repository.dart  # Interface
│   │   │   │   └── orders_repository_impl.dart
│   │   │   └── datasources/
│   │   │       ├── orders_remote_datasource.dart
│   │   │       └── orders_local_datasource.dart
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   │   ├── order.dart              # Domain model
│   │   │   │   └── order_item.dart
│   │   │   ├── events/
│   │   │   │   └── order_events.dart       # Event definitions
│   │   │   └── usecases/
│   │   │       ├── create_order.dart
│   │   │       └── update_order_status.dart
│   │   ├── application/
│   │   │   ├── providers/
│   │   │   │   ├── orders_provider.dart    # State provider
│   │   │   │   └── order_detail_provider.dart
│   │   │   └── state/
│   │   │       ├── orders_state.dart       # State definition
│   │   │       └── orders_notifier.dart    # State logic
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── orders_list_screen.dart
│   │       │   └── order_detail_screen.dart
│   │       └── widgets/
│   │           ├── order_card.dart
│   │           └── order_status_badge.dart
│   │
│   ├── tables/
│   │   ├── data/
│   │   ├── domain/
│   │   ├── application/
│   │   └── presentation/
│   │
│   └── [other features follow same structure]
│
└── bootstrap.dart                           # App initialization
```

### 3.4 Riverpod Layering Strategy

**Provider Organization**:

```dart
// 1. Repository Providers (Data Layer)
final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return OrdersRepositoryImpl(
    remoteDataSource: ref.watch(ordersRemoteDataSourceProvider),
    localDataSource: ref.watch(ordersLocalDataSourceProvider),
  );
});

// 2. State Providers (Application Layer)
final ordersStateProvider = StateNotifierProvider<OrdersNotifier, OrdersState>((ref) {
  return OrdersNotifier(
    repository: ref.watch(ordersRepositoryProvider),
  );
});

// 3. Derived Providers (Computed State)
final activeOrdersProvider = Provider<List<Order>>((ref) {
  final state = ref.watch(ordersStateProvider);
  return state.orders.where((o) => o.status != OrderStatus.completed).toList();
});

// 4. Family Providers (Parameterized)
final orderByIdProvider = Provider.family<Order?, String>((ref, orderId) {
  final state = ref.watch(ordersStateProvider);
  return state.orders.firstWhereOrNull((o) => o.id == orderId);
});
```

### 3.5 Event-Driven Architecture

**Event Flow**:
```
User Action → Event → Reducer → New State → UI Update
```

**Event Types**:
```dart
@freezed
class OrderEvent with _$OrderEvent {
  // User Actions
  const factory OrderEvent.createRequested({
    required String tableId,
    required List<OrderItemDto> items,
  }) = OrderCreateRequested;
  
  const factory OrderEvent.statusUpdateRequested({
    required String orderId,
    required OrderStatus newStatus,
  }) = OrderStatusUpdateRequested;
  
  // Network Events
  const factory OrderEvent.syncSucceeded({
    required String orderId,
    required DateTime syncedAt,
  }) = OrderSyncSucceeded;
  
  const factory OrderEvent.syncFailed({
    required String orderId,
    required String error,
  }) = OrderSyncFailed;
  
  // Real-time Events
  const factory OrderEvent.receivedFromServer({
    required OrderDto order,
    required DateTime receivedAt,
  }) = OrderReceivedFromServer;
}
```

### 3.6 Repository Boundaries

**Interface Definition**:
```dart
abstract class OrdersRepository {
  // Query Methods (return immutable data)
  Future<Result<List<Order>, Failure>> getOrders(String tenantId);
  Future<Result<Order, Failure>> getOrderById(String orderId);
  
  // Command Methods (return success/failure)
  Future<Result<Order, Failure>> createOrder(CreateOrderDto dto);
  Future<Result<void, Failure>> updateOrderStatus(String orderId, OrderStatus status);
  
  // Stream Methods (for real-time updates)
  Stream<List<Order>> watchOrders(String tenantId);
}
```

**Implementation Separation**:
- **Remote Data Source**: API calls
- **Local Data Source**: Cache/database
- **Repository**: Coordinates between sources, handles offline logic

### 3.7 DTO Mapping Layers

**Purpose**: Separate API contracts from domain models.

**Mapping Strategy**:
```dart
// DTO (Data Transfer Object) - matches API
@freezed
class OrderDto with _$OrderDto {
  const factory OrderDto({
    required String id,
    required String tenant_id,  // snake_case from API
    required String status,
    required List<OrderItemDto> items,
    required double total_amount,
  }) = _OrderDto;
  
  factory OrderDto.fromJson(Map<String, dynamic> json) => 
      _$OrderDtoFromJson(json);
}

// Domain Model - business logic optimized
@freezed
class Order with _$Order {
  const factory Order({
    required String id,
    required String tenantId,  // camelCase for Dart
    required OrderStatus status,  // Enum, not string
    required List<OrderItem> items,
    required Money totalAmount,  // Value object
    required DateTime createdAt,
  }) = _Order;
  
  // Business logic methods
  bool get canBeCancelled => status == OrderStatus.pending;
  bool get isComplete => status == OrderStatus.served;
}

// Mapper
extension OrderDtoMapper on OrderDto {
  Order toDomain() {
    return Order(
      id: id,
      tenantId: tenant_id,
      status: OrderStatus.fromString(status),
      items: items.map((dto) => dto.toDomain()).toList(),
      totalAmount: Money(total_amount),
      createdAt: DateTime.parse(created_at),
    );
  }
}
```

### 3.8 Domain Separation

**Domain Layer Responsibilities**:
- Define business entities
- Enforce business rules
- Contain no framework dependencies
- Pure Dart code (testable without Flutter)

**Example**:
```dart
// domain/models/order.dart
class Order {
  final String id;
  final OrderStatus status;
  final List<OrderItem> items;
  
  // Business rule enforcement
  Order addItem(OrderItem item) {
    if (status != OrderStatus.pending) {
      throw OrderModificationException('Cannot modify non-pending order');
    }
    return copyWith(items: [...items, item]);
  }
  
  // Business logic
  Money calculateTotal() {
    return items.fold(
      Money.zero(),
      (total, item) => total + item.subtotal,
    );
  }
}
```

---


## 4. State Management Strategy

### 4.1 Riverpod Provider Architecture

**Provider Hierarchy**:

```dart
// Level 1: Infrastructure Providers (Singleton, never disposed)
final httpClientProvider = Provider<Dio>((ref) => Dio());
final localStorageProvider = Provider<LocalStorage>((ref) => LocalStorage());

// Level 2: Repository Providers (Singleton, never disposed)
final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return OrdersRepositoryImpl(
    remoteDataSource: ref.watch(ordersRemoteDataSourceProvider),
    localDataSource: ref.watch(ordersLocalDataSourceProvider),
  );
});

// Level 3: State Providers (Auto-dispose when not watched)
final ordersStateProvider = StateNotifierProvider.autoDispose<OrdersNotifier, OrdersState>((ref) {
  return OrdersNotifier(
    repository: ref.watch(ordersRepositoryProvider),
    tenantId: ref.watch(currentTenantIdProvider),
  );
});

// Level 4: Derived Providers (Computed from state)
final activeOrdersCountProvider = Provider.autoDispose<int>((ref) {
  final state = ref.watch(ordersStateProvider);
  return state.orders.where((o) => o.status.isActive).length;
});

// Level 5: Family Providers (Parameterized queries)
final orderByIdProvider = Provider.autoDispose.family<Order?, String>((ref, orderId) {
  final state = ref.watch(ordersStateProvider);
  return state.orders.firstWhereOrNull((o) => o.id == orderId);
});
```

### 4.2 Provider Naming Conventions

**Standard Naming Pattern**:
```
{domain}{Type}Provider
```

**Examples**:
```dart
// State Providers
final ordersStateProvider = ...
final tablesStateProvider = ...
final billingStateProvider = ...

// Repository Providers
final ordersRepositoryProvider = ...
final tablesRepositoryProvider = ...

// Derived Providers
final activeOrdersProvider = ...
final availableTablesProvider = ...

// Family Providers
final orderByIdProvider = ...
final tableByIdProvider = ...

// Stream Providers
final ordersStreamProvider = ...
final tablesStreamProvider = ...
```

### 4.3 StateNotifier vs AsyncNotifier Usage

**Use StateNotifier When**:
- State is synchronously computed
- State transitions are immediate
- No async operations in state logic

```dart
class OrdersNotifier extends StateNotifier<OrdersState> {
  OrdersNotifier() : super(OrdersState.initial());
  
  void addOrder(Order order) {
    state = state.copyWith(
      orders: [...state.orders, order],
    );
  }
}
```

**Use AsyncNotifier When**:
- Initial state requires async loading
- State depends on async operations
- Need built-in loading/error states

```dart
class OrdersNotifier extends AsyncNotifier<List<Order>> {
  @override
  Future<List<Order>> build() async {
    final repository = ref.watch(ordersRepositoryProvider);
    final result = await repository.getOrders();
    return result.fold(
      (orders) => orders,
      (error) => throw error,
    );
  }
  
  Future<void> addOrder(Order order) async {
    state = const AsyncValue.loading();
    final result = await repository.createOrder(order);
    state = result.fold(
      (newOrder) => AsyncValue.data([...state.value!, newOrder]),
      (error) => AsyncValue.error(error, StackTrace.current),
    );
  }
}
```

### 4.4 Family Providers

**When to Use**:
- Parameterized queries
- Per-item state
- Dynamic provider creation

```dart
// Single parameter
final orderByIdProvider = Provider.family<Order?, String>((ref, orderId) {
  return ref.watch(ordersStateProvider).orders.firstWhereOrNull(
    (o) => o.id == orderId,
  );
});

// Multiple parameters (use record)
final orderItemProvider = Provider.family<OrderItem?, ({String orderId, String itemId})>((ref, params) {
  final order = ref.watch(orderByIdProvider(params.orderId));
  return order?.items.firstWhereOrNull((i) => i.id == params.itemId);
});

// Usage
final order = ref.watch(orderByIdProvider('order-123'));
final item = ref.watch(orderItemProvider((orderId: 'order-123', itemId: 'item-456')));
```

### 4.5 Derived Providers

**Purpose**: Compute values from existing state without duplication.

```dart
// Filtered lists
final pendingOrdersProvider = Provider.autoDispose<List<Order>>((ref) {
  final state = ref.watch(ordersStateProvider);
  return state.orders.where((o) => o.status == OrderStatus.pending).toList();
});

// Aggregations
final totalRevenueProvider = Provider.autoDispose<double>((ref) {
  final orders = ref.watch(ordersStateProvider).orders;
  return orders.fold(0.0, (sum, order) => sum + order.totalAmount);
});

// Combinations
final orderSummaryProvider = Provider.autoDispose<OrderSummary>((ref) {
  final orders = ref.watch(ordersStateProvider).orders;
  final tables = ref.watch(tablesStateProvider).tables;
  
  return OrderSummary(
    totalOrders: orders.length,
    activeOrders: orders.where((o) => o.status.isActive).length,
    occupiedTables: tables.where((t) => t.hasActiveOrder).length,
  );
});
```

### 4.6 State Hydration Patterns

**Hydration Strategy**:

```dart
@freezed
class OrdersState with _$OrdersState {
  const factory OrdersState({
    required List<Order> orders,
    required DateTime lastSyncedAt,
    required SyncStatus syncStatus,
    @Default([]) List<PendingAction> pendingActions,
  }) = _OrdersState;
  
  factory OrdersState.fromJson(Map<String, dynamic> json) => 
      _$OrdersStateFromJson(json);
}

class OrdersNotifier extends StateNotifier<OrdersState> {
  final LocalStorage _storage;
  
  OrdersNotifier(this._storage) : super(OrdersState.initial()) {
    _hydrate();
  }
  
  Future<void> _hydrate() async {
    try {
      final json = await _storage.read('orders_state');
      if (json != null) {
        state = OrdersState.fromJson(json);
      }
    } catch (e) {
      // Log error, continue with initial state
    }
  }
  
  @override
  set state(OrdersState value) {
    super.state = value;
    _persist();
  }
  
  Future<void> _persist() async {
    try {
      await _storage.write('orders_state', state.toJson());
    } catch (e) {
      // Log error, don't block state update
    }
  }
}
```

### 4.7 Scoped Provider Usage

**Use Case**: Feature-specific state that shouldn't be global.

```dart
// Scoped to order detail screen
final orderDetailStateProvider = StateNotifierProvider.autoDispose
    .family<OrderDetailNotifier, OrderDetailState, String>((ref, orderId) {
  return OrderDetailNotifier(
    orderId: orderId,
    repository: ref.watch(ordersRepositoryProvider),
  );
});

// Usage in widget
class OrderDetailScreen extends ConsumerWidget {
  final String orderId;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(orderDetailStateProvider(orderId));
    // Widget automatically disposes provider when unmounted
  }
}
```

### 4.8 Avoiding Provider Dependency Chaos

**Anti-Pattern** (Tight Coupling):
```dart
// ❌ BAD: Provider directly reads another provider's state
class OrdersNotifier extends StateNotifier<OrdersState> {
  final Ref ref;
  
  void updateOrder(String orderId) {
    // Tightly coupled to tables provider
    final table = ref.read(tablesStateProvider).tables.first;
    // ...
  }
}
```

**Correct Pattern** (Dependency Injection):
```dart
// ✅ GOOD: Dependencies injected via constructor
class OrdersNotifier extends StateNotifier<OrdersState> {
  final OrdersRepository _repository;
  final String _tenantId;
  
  OrdersNotifier({
    required OrdersRepository repository,
    required String tenantId,
  }) : _repository = repository,
       _tenantId = tenantId,
       super(OrdersState.initial());
}

// Provider setup
final ordersStateProvider = StateNotifierProvider<OrdersNotifier, OrdersState>((ref) {
  return OrdersNotifier(
    repository: ref.watch(ordersRepositoryProvider),
    tenantId: ref.watch(currentTenantIdProvider),
  );
});
```

---

## 5. Serializable State Rules

### 5.1 Allowed State Types

**✅ Primitives**:
```dart
String, int, double, bool, DateTime
```

**✅ Immutable Collections**:
```dart
List<T>, Map<K, V>, Set<T>  // Where T, K, V are serializable
```

**✅ Enums**:
```dart
enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  served,
  cancelled;
  
  String toJson() => name;
  static OrderStatus fromJson(String json) => values.byName(json);
}
```

**✅ Serializable DTOs**:
```dart
@freezed
class OrderDto with _$OrderDto {
  const factory OrderDto({
    required String id,
    required String tenantId,
    required OrderStatus status,
    required List<OrderItemDto> items,
    required double totalAmount,
    required DateTime createdAt,
  }) = _OrderDto;
  
  factory OrderDto.fromJson(Map<String, dynamic> json) => 
      _$OrderDtoFromJson(json);
}
```

**✅ Value Objects**:
```dart
@freezed
class Money with _$Money {
  const factory Money({
    required double amount,
    @Default('INR') String currency,
  }) = _Money;
  
  factory Money.fromJson(Map<String, dynamic> json) => 
      _$MoneyFromJson(json);
}
```

### 5.2 Forbidden State Types

**❌ Streams**:
```dart
// ❌ BAD
class OrdersState {
  final Stream<Order> orderStream;  // Cannot serialize
}

// ✅ GOOD: Use provider to expose stream
final ordersStreamProvider = StreamProvider<List<Order>>((ref) {
  return ref.watch(ordersRepositoryProvider).watchOrders();
});
```

**❌ Controllers**:
```dart
// ❌ BAD
class FormState {
  final TextEditingController nameController;  // Widget dependency
  final AnimationController animController;
}

// ✅ GOOD: Store values, not controllers
@freezed
class FormState with _$FormState {
  const factory FormState({
    required String nameValue,
    required bool isAnimating,
  }) = _FormState;
}
```

**❌ Futures**:
```dart
// ❌ BAD
class OrdersState {
  final Future<List<Order>> ordersFuture;  // Not serializable
}

// ✅ GOOD: Use AsyncValue or load data in provider
@freezed
class OrdersState with _$OrdersState {
  const factory OrdersState({
    required List<Order> orders,
    required LoadingStatus status,
  }) = _OrdersState;
}
```

**❌ BuildContext**:
```dart
// ❌ BAD
class NavigationState {
  final BuildContext context;  // Widget reference
}

// ✅ GOOD: Use GoRouter or navigation service
class NavigationService {
  final GoRouter _router;
  void navigateTo(String route) => _router.go(route);
}
```

**❌ Functions/Closures**:
```dart
// ❌ BAD
class OrdersState {
  final VoidCallback onComplete;  // Cannot serialize
}

// ✅ GOOD: Use events
@freezed
class OrderEvent with _$OrderEvent {
  const factory OrderEvent.completed(String orderId) = OrderCompleted;
}
```

### 5.3 Serialization Strategy

**Freezed + json_serializable**:

```dart
// pubspec.yaml
dependencies:
  freezed_annotation: ^2.4.1
  json_annotation: ^4.8.1

dev_dependencies:
  build_runner: ^2.4.6
  freezed: ^2.4.5
  json_serializable: ^6.7.1

// Model definition
@freezed
class Order with _$Order {
  const factory Order({
    required String id,
    required String tenantId,
    required OrderStatus status,
    required List<OrderItem> items,
    required Money totalAmount,
    required DateTime createdAt,
    DateTime? completedAt,
  }) = _Order;
  
  factory Order.fromJson(Map<String, dynamic> json) => 
      _$OrderFromJson(json);
}

// Generate code
// flutter pub run build_runner build --delete-conflicting-outputs
```

### 5.4 JSON Persistence Readiness

**Storage Interface**:
```dart
abstract class LocalStorage {
  Future<void> write(String key, Map<String, dynamic> json);
  Future<Map<String, dynamic>?> read(String key);
  Future<void> delete(String key);
  Future<void> clear();
}

// Usage
class OrdersNotifier extends StateNotifier<OrdersState> {
  final LocalStorage _storage;
  
  Future<void> persist() async {
    await _storage.write('orders_state', state.toJson());
  }
  
  Future<void> hydrate() async {
    final json = await _storage.read('orders_state');
    if (json != null) {
      state = OrdersState.fromJson(json);
    }
  }
}
```

### 5.5 Hydration Compatibility

**Version-Safe Serialization**:
```dart
@freezed
class OrdersState with _$OrdersState {
  const factory OrdersState({
    @Default(1) int version,  // Schema version
    required List<Order> orders,
    required DateTime lastSyncedAt,
  }) = _OrdersState;
  
  factory OrdersState.fromJson(Map<String, dynamic> json) {
    final version = json['version'] as int? ?? 1;
    
    // Handle migration
    if (version < 2) {
      json = _migrateV1ToV2(json);
    }
    
    return _$OrdersStateFromJson(json);
  }
  
  static Map<String, dynamic> _migrateV1ToV2(Map<String, dynamic> json) {
    // Migration logic
    return {
      ...json,
      'version': 2,
      'lastSyncedAt': DateTime.now().toIso8601String(),
    };
  }
}
```

### 5.6 Snapshot Safety

**Immutable Snapshots**:
```dart
class StateSnapshot {
  final String stateKey;
  final Map<String, dynamic> json;
  final DateTime timestamp;
  
  const StateSnapshot({
    required this.stateKey,
    required this.json,
    required this.timestamp,
  });
  
  // Create snapshot
  static StateSnapshot capture(String key, Object state) {
    if (state is! dynamic) {
      throw StateSnapshotException('State must have toJson method');
    }
    
    return StateSnapshot(
      stateKey: key,
      json: Map<String, dynamic>.from(state.toJson()),
      timestamp: DateTime.now(),
    );
  }
  
  // Restore snapshot
  T restore<T>(T Function(Map<String, dynamic>) fromJson) {
    return fromJson(Map<String, dynamic>.from(json));
  }
}
```

---


## 6. Immutable Domain Model Design

### 6.1 Entity Structure with Freezed

**Complete Order Entity Example**:

```dart
@freezed
class Order with _$Order {
  const Order._();  // Private constructor for methods
  
  const factory Order({
    required String id,
    required String tenantId,
    required String tableId,
    required String tableLabel,
    required OrderStatus status,
    required List<OrderItem> items,
    required Money totalAmount,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? staffId,
    String? staffName,
    String? notes,
    DateTime? completedAt,
  }) = _Order;
  
  factory Order.fromJson(Map<String, dynamic> json) => 
      _$OrderFromJson(json);
  
  // Business logic methods
  bool get canBeModified => status == OrderStatus.pending;
  bool get canBeCancelled => status != OrderStatus.served && 
                             status != OrderStatus.cancelled;
  bool get isComplete => status == OrderStatus.served;
  
  Money calculateSubtotal() {
    return items.fold(
      Money.zero(),
      (total, item) => total + item.subtotal,
    );
  }
  
  Order addItem(OrderItem item) {
    if (!canBeModified) {
      throw OrderModificationException('Cannot modify non-pending order');
    }
    
    return copyWith(
      items: [...items, item],
      totalAmount: totalAmount + item.subtotal,
      updatedAt: DateTime.now(),
    );
  }
}
```

### 6.2 Value Objects

**Money Value Object**:
```dart
@freezed
class Money with _$Money implements Comparable<Money> {
  const Money._();
  
  const factory Money({
    required double amount,
    @Default('INR') String currency,
  }) = _Money;
  
  factory Money.fromJson(Map<String, dynamic> json) => 
      _$MoneyFromJson(json);
  
  factory Money.zero() => const Money(amount: 0.0);
  
  Money operator +(Money other) {
    _assertSameCurrency(other);
    return Money(amount: amount + other.amount, currency: currency);
  }
  
  Money operator -(Money other) {
    _assertSameCurrency(other);
    return Money(amount: amount - other.amount, currency: currency);
  }
  
  Money operator *(double multiplier) {
    return Money(amount: amount * multiplier, currency: currency);
  }
  
  @override
  int compareTo(Money other) {
    _assertSameCurrency(other);
    return amount.compareTo(other.amount);
  }
  
  void _assertSameCurrency(Money other) {
    if (currency != other.currency) {
      throw CurrencyMismatchException('Cannot operate on different currencies');
    }
  }
  
  String format() {
    return '₹${amount.toStringAsFixed(2)}';
  }
}
```

**Table State Entity**:
```dart
@freezed
class TableState with _$TableState {
  const TableState._();
  
  const factory TableState({
    required String id,
    required String tenantId,
    required String label,
    required TableStatus status,
    required int capacity,
    String? currentOrderId,
    DateTime? occupiedSince,
    String? assignedStaffId,
  }) = _TableState;
  
  factory TableState.fromJson(Map<String, dynamic> json) => 
      _$TableStateFromJson(json);
  
  bool get isAvailable => status == TableStatus.available;
  bool get isOccupied => status == TableStatus.occupied;
  bool get hasActiveOrder => currentOrderId != null;
  
  Duration? get occupiedDuration {
    if (occupiedSince == null) return null;
    return DateTime.now().difference(occupiedSince!);
  }
  
  TableState occupy(String orderId, String staffId) {
    if (!isAvailable) {
      throw TableOccupationException('Table is not available');
    }
    
    return copyWith(
      status: TableStatus.occupied,
      currentOrderId: orderId,
      occupiedSince: DateTime.now(),
      assignedStaffId: staffId,
    );
  }
  
  TableState release() {
    return copyWith(
      status: TableStatus.available,
      currentOrderId: null,
      occupiedSince: null,
      assignedStaffId: null,
    );
  }
}
```

### 6.3 Nested Object Management

**Order with Nested Items**:
```dart
@freezed
class Order with _$Order {
  const Order._();
  
  const factory Order({
    required String id,
    required List<OrderItem> items,
    required Money totalAmount,
  }) = _Order;
  
  // Update nested item
  Order updateItem(String itemId, OrderItem updatedItem) {
    final updatedItems = items.map((item) {
      return item.id == itemId ? updatedItem : item;
    }).toList();
    
    return copyWith(
      items: updatedItems,
      totalAmount: _recalculateTotal(updatedItems),
    );
  }
  
  // Remove nested item
  Order removeItem(String itemId) {
    final updatedItems = items.where((item) => item.id != itemId).toList();
    
    return copyWith(
      items: updatedItems,
      totalAmount: _recalculateTotal(updatedItems),
    );
  }
  
  Money _recalculateTotal(List<OrderItem> items) {
    return items.fold(Money.zero(), (sum, item) => sum + item.subtotal);
  }
}

@freezed
class OrderItem with _$OrderItem {
  const OrderItem._();
  
  const factory OrderItem({
    required String id,
    required String menuItemId,
    required String menuItemName,
    required int quantity,
    required Money unitPrice,
    String? notes,
  }) = _OrderItem;
  
  factory OrderItem.fromJson(Map<String, dynamic> json) => 
      _$OrderItemFromJson(json);
  
  Money get subtotal => unitPrice * quantity.toDouble();
  
  OrderItem updateQuantity(int newQuantity) {
    if (newQuantity < 1) {
      throw InvalidQuantityException('Quantity must be at least 1');
    }
    return copyWith(quantity: newQuantity);
  }
}
```

### 6.4 Billing State Example

```dart
@freezed
class BillingState with _$BillingState {
  const BillingState._();
  
  const factory BillingState({
    required String id,
    required String orderId,
    required String tenantId,
    required Money subtotal,
    required Money taxAmount,
    required Money discountAmount,
    required Money totalAmount,
    required BillingStatus status,
    required PaymentMethod? paymentMethod,
    required DateTime createdAt,
    DateTime? paidAt,
    String? transactionId,
  }) = _BillingState;
  
  factory BillingState.fromJson(Map<String, dynamic> json) => 
      _$BillingStateFromJson(json);
  
  factory BillingState.fromOrder(Order order, double taxRate) {
    final subtotal = order.totalAmount;
    final taxAmount = subtotal * (taxRate / 100);
    final totalAmount = subtotal + taxAmount;
    
    return BillingState(
      id: 'bill-${order.id}',
      orderId: order.id,
      tenantId: order.tenantId,
      subtotal: subtotal,
      taxAmount: taxAmount,
      discountAmount: Money.zero(),
      totalAmount: totalAmount,
      status: BillingStatus.pending,
      paymentMethod: null,
      createdAt: DateTime.now(),
    );
  }
  
  bool get isPaid => status == BillingStatus.paid;
  bool get isPending => status == BillingStatus.pending;
  
  BillingState applyDiscount(Money discount) {
    if (discount > subtotal) {
      throw InvalidDiscountException('Discount cannot exceed subtotal');
    }
    
    final newTotal = subtotal + taxAmount - discount;
    
    return copyWith(
      discountAmount: discount,
      totalAmount: newTotal,
    );
  }
  
  BillingState markAsPaid(PaymentMethod method, String transactionId) {
    if (isPaid) {
      throw BillingException('Bill is already paid');
    }
    
    return copyWith(
      status: BillingStatus.paid,
      paymentMethod: method,
      transactionId: transactionId,
      paidAt: DateTime.now(),
    );
  }
}

enum BillingStatus {
  pending,
  paid,
  cancelled,
  refunded;
  
  String toJson() => name;
  static BillingStatus fromJson(String json) => values.byName(json);
}

enum PaymentMethod {
  cash,
  card,
  upi,
  wallet;
  
  String toJson() => name;
  static PaymentMethod fromJson(String json) => values.byName(json);
}
```

### 6.5 Session State Example

```dart
@freezed
class SessionState with _$SessionState {
  const SessionState._();
  
  const factory SessionState({
    required String id,
    required String tenantId,
    required String userId,
    required UserRole role,
    required DateTime startedAt,
    DateTime? endedAt,
    required SessionStatus status,
    @Default({}) Map<String, dynamic> metadata,
  }) = _SessionState;
  
  factory SessionState.fromJson(Map<String, dynamic> json) => 
      _$SessionStateFromJson(json);
  
  bool get isActive => status == SessionStatus.active;
  bool get isExpired => endedAt != null && DateTime.now().isAfter(endedAt!);
  
  Duration get duration {
    final end = endedAt ?? DateTime.now();
    return end.difference(startedAt);
  }
  
  SessionState end() {
    return copyWith(
      status: SessionStatus.ended,
      endedAt: DateTime.now(),
    );
  }
}

enum SessionStatus {
  active,
  ended,
  expired;
  
  String toJson() => name;
  static SessionStatus fromJson(String json) => values.byName(json);
}
```

### 6.6 Sync State Example

```dart
@freezed
class SyncState with _$SyncState {
  const SyncState._();
  
  const factory SyncState({
    required DateTime lastSyncedAt,
    required SyncStatus status,
    @Default([]) List<PendingAction> pendingActions,
    @Default([]) List<SyncError> errors,
    int? pendingCount,
  }) = _SyncState;
  
  factory SyncState.fromJson(Map<String, dynamic> json) => 
      _$SyncStateFromJson(json);
  
  factory SyncState.initial() => SyncState(
    lastSyncedAt: DateTime.now(),
    status: SyncStatus.idle,
  );
  
  bool get isSyncing => status == SyncStatus.syncing;
  bool get hasPendingActions => pendingActions.isNotEmpty;
  bool get hasErrors => errors.isNotEmpty;
  
  SyncState addPendingAction(PendingAction action) {
    return copyWith(
      pendingActions: [...pendingActions, action],
      pendingCount: (pendingCount ?? 0) + 1,
    );
  }
  
  SyncState removePendingAction(String actionId) {
    return copyWith(
      pendingActions: pendingActions.where((a) => a.id != actionId).toList(),
      pendingCount: (pendingCount ?? 0) - 1,
    );
  }
  
  SyncState markSyncing() {
    return copyWith(status: SyncStatus.syncing);
  }
  
  SyncState markSynced() {
    return copyWith(
      status: SyncStatus.synced,
      lastSyncedAt: DateTime.now(),
      errors: [],
    );
  }
  
  SyncState addError(SyncError error) {
    return copyWith(
      status: SyncStatus.error,
      errors: [...errors, error],
    );
  }
}

@freezed
class PendingAction with _$PendingAction {
  const factory PendingAction({
    required String id,
    required String type,
    required Map<String, dynamic> payload,
    required DateTime createdAt,
    required int retryCount,
  }) = _PendingAction;
  
  factory PendingAction.fromJson(Map<String, dynamic> json) => 
      _$PendingActionFromJson(json);
}

@freezed
class SyncError with _$SyncError {
  const factory SyncError({
    required String actionId,
    required String message,
    required DateTime occurredAt,
  }) = _SyncError;
  
  factory SyncError.fromJson(Map<String, dynamic> json) => 
      _$SyncErrorFromJson(json);
}

enum SyncStatus {
  idle,
  syncing,
  synced,
  error;
  
  String toJson() => name;
  static SyncStatus fromJson(String json) => values.byName(json);
}
```

### 6.7 Equality Handling

**Freezed Automatic Equality**:
```dart
@freezed
class Order with _$Order {
  const factory Order({
    required String id,
    required List<OrderItem> items,
  }) = _Order;
}

// Freezed generates:
// - operator ==
// - hashCode
// - toString

void example() {
  final order1 = Order(id: '1', items: []);
  final order2 = Order(id: '1', items: []);
  
  print(order1 == order2);  // true (deep equality)
  print(order1.hashCode == order2.hashCode);  // true
}
```

**Custom Equality**:
```dart
@freezed
class Order with _$Order {
  const Order._();
  
  const factory Order({
    required String id,
    required List<OrderItem> items,
    required DateTime updatedAt,
  }) = _Order;
  
  // Custom equality ignoring updatedAt
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is Order &&
            other.id == id &&
            const ListEquality().equals(other.items, items));
  }
  
  @override
  int get hashCode => Object.hash(id, const ListEquality().hash(items));
}
```

---

## 7. Event-Driven State Flow

### 7.1 Event Sourcing Concepts

**Definition**: Store state changes as a sequence of events rather than just the current state.

**Benefits**:
- **Audit Trail**: Complete history of what happened
- **Replay**: Reproduce any state by replaying events
- **Debugging**: Understand exactly how state evolved
- **Conflict Resolution**: Merge concurrent changes
- **Time Travel**: Navigate through state history

**Event Store Pattern**:
```dart
@freezed
class OrderEvent with _$OrderEvent {
  const factory OrderEvent.created({
    required String orderId,
    required String tableId,
    required DateTime timestamp,
  }) = OrderCreated;
  
  const factory OrderEvent.itemAdded({
    required String orderId,
    required OrderItem item,
    required DateTime timestamp,
  }) = OrderItemAdded;
  
  const factory OrderEvent.statusChanged({
    required String orderId,
    required OrderStatus oldStatus,
    required OrderStatus newStatus,
    required DateTime timestamp,
  }) = OrderStatusChanged;
  
  factory OrderEvent.fromJson(Map<String, dynamic> json) => 
      _$OrderEventFromJson(json);
}
```

### 7.2 Action-Driven Updates

**Action Pattern**:
```dart
// User actions trigger events
abstract class OrderAction {
  const OrderAction();
}

class CreateOrderAction extends OrderAction {
  final String tableId;
  final List<OrderItemDto> items;
  
  const CreateOrderAction({
    required this.tableId,
    required this.items,
  });
}

class UpdateOrderStatusAction extends OrderAction {
  final String orderId;
  final OrderStatus newStatus;
  
  const UpdateOrderStatusAction({
    required this.orderId,
    required this.newStatus,
  });
}

// Notifier handles actions
class OrdersNotifier extends StateNotifier<OrdersState> {
  final OrdersRepository _repository;
  
  OrdersNotifier(this._repository) : super(OrdersState.initial());
  
  Future<void> dispatch(OrderAction action) async {
    if (action is CreateOrderAction) {
      await _handleCreateOrder(action);
    } else if (action is UpdateOrderStatusAction) {
      await _handleUpdateStatus(action);
    }
  }
  
  Future<void> _handleCreateOrder(CreateOrderAction action) async {
    // Optimistic update
    final tempOrder = Order.temp(
      tableId: action.tableId,
      items: action.items.map((dto) => dto.toDomain()).toList(),
    );
    
    state = state.copyWith(
      orders: [...state.orders, tempOrder],
    );
    
    // Persist to server
    final result = await _repository.createOrder(action.toDto());
    
    result.fold(
      (order) {
        // Replace temp with real order
        state = state.copyWith(
          orders: state.orders.map((o) => 
            o.id == tempOrder.id ? order : o
          ).toList(),
        );
      },
      (error) {
        // Rollback on error
        state = state.copyWith(
          orders: state.orders.where((o) => o.id != tempOrder.id).toList(),
        );
      },
    );
  }
}
```

### 7.3 UI Event Handling

**Widget to Action Flow**:
```dart
class OrderDetailScreen extends ConsumerWidget {
  final String orderId;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderByIdProvider(orderId));
    final notifier = ref.read(ordersStateProvider.notifier);
    
    return Scaffold(
      body: Column(
        children: [
          // UI displays state
          Text('Status: ${order?.status}'),
          
          // User action triggers event
          ElevatedButton(
            onPressed: () {
              notifier.dispatch(
                UpdateOrderStatusAction(
                  orderId: orderId,
                  newStatus: OrderStatus.confirmed,
                ),
              );
            },
            child: Text('Confirm Order'),
          ),
        ],
      ),
    );
  }
}
```

### 7.4 Side-Effect Isolation

**Pure Reducers**:
```dart
// ✅ GOOD: Pure reducer (no side effects)
OrdersState reduceOrderEvent(OrdersState state, OrderEvent event) {
  return event.when(
    created: (orderId, tableId, timestamp) {
      final newOrder = Order(
        id: orderId,
        tableId: tableId,
        status: OrderStatus.pending,
        items: [],
        totalAmount: Money.zero(),
        createdAt: timestamp,
        updatedAt: timestamp,
      );
      
      return state.copyWith(
        orders: [...state.orders, newOrder],
      );
    },
    itemAdded: (orderId, item, timestamp) {
      final updatedOrders = state.orders.map((order) {
        if (order.id == orderId) {
          return order.copyWith(
            items: [...order.items, item],
            totalAmount: order.totalAmount + item.subtotal,
            updatedAt: timestamp,
          );
        }
        return order;
      }).toList();
      
      return state.copyWith(orders: updatedOrders);
    },
    statusChanged: (orderId, oldStatus, newStatus, timestamp) {
      final updatedOrders = state.orders.map((order) {
        if (order.id == orderId) {
          return order.copyWith(
            status: newStatus,
            updatedAt: timestamp,
          );
        }
        return order;
      }).toList();
      
      return state.copyWith(orders: updatedOrders);
    },
  );
}
```

**Side Effects in Notifier**:
```dart
class OrdersNotifier extends StateNotifier<OrdersState> {
  final OrdersRepository _repository;
  final Logger _logger;
  
  // Reducer is pure
  void _reduce(OrderEvent event) {
    state = reduceOrderEvent(state, event);
  }
  
  // Side effects isolated here
  Future<void> createOrder(CreateOrderAction action) async {
    // 1. Generate event
    final event = OrderEvent.created(
      orderId: _generateId(),
      tableId: action.tableId,
      timestamp: DateTime.now(),
    );
    
    // 2. Apply to state (pure)
    _reduce(event);
    
    // 3. Side effects (logging, persistence, network)
    _logger.info('Order created: ${event.orderId}');
    await _persistEvent(event);
    await _syncToServer(event);
  }
  
  Future<void> _persistEvent(OrderEvent event) async {
    // Save event to local storage
  }
  
  Future<void> _syncToServer(OrderEvent event) async {
    // Send to backend
  }
}
```

### 7.5 Event Reducers

**Reducer Architecture**:
```dart
// Base reducer interface
typedef Reducer<S, E> = S Function(S state, E event);

// Order reducer
Reducer<OrdersState, OrderEvent> orderReducer = (state, event) {
  return event.when(
    created: (orderId, tableId, timestamp) => _handleCreated(state, orderId, tableId, timestamp),
    itemAdded: (orderId, item, timestamp) => _handleItemAdded(state, orderId, item, timestamp),
    statusChanged: (orderId, old, new_, timestamp) => _handleStatusChanged(state, orderId, old, new_, timestamp),
  );
};

// Composable reducers
Reducer<AppState, AppEvent> appReducer = (state, event) {
  return state.copyWith(
    orders: orderReducer(state.orders, event as OrderEvent),
    tables: tableReducer(state.tables, event as TableEvent),
    billing: billingReducer(state.billing, event as BillingEvent),
  );
};
```

### 7.6 User Actions

**Action Definitions**:
```dart
@freezed
class UserAction with _$UserAction {
  // Order actions
  const factory UserAction.createOrder({
    required String tableId,
    required List<OrderItemDto> items,
  }) = CreateOrderAction;
  
  const factory UserAction.addOrderItem({
    required String orderId,
    required OrderItemDto item,
  }) = AddOrderItemAction;
  
  const factory UserAction.updateOrderStatus({
    required String orderId,
    required OrderStatus newStatus,
  }) = UpdateOrderStatusAction;
  
  // Table actions
  const factory UserAction.occupyTable({
    required String tableId,
    required String orderId,
  }) = OccupyTableAction;
  
  const factory UserAction.releaseTable({
    required String tableId,
  }) = ReleaseTableAction;
  
  // Billing actions
  const factory UserAction.generateBill({
    required String orderId,
  }) = GenerateBillAction;
  
  const factory UserAction.processPay({
    required String billId,
    required PaymentMethod method,
  }) = ProcessPaymentAction;
}
```

### 7.7 Network Events

**Network Event Definitions**:
```dart
@freezed
class NetworkEvent with _$NetworkEvent {
  const factory NetworkEvent.syncStarted({
    required DateTime timestamp,
  }) = SyncStarted;
  
  const factory NetworkEvent.syncSucceeded({
    required String entityId,
    required String entityType,
    required DateTime timestamp,
  }) = SyncSucceeded;
  
  const factory NetworkEvent.syncFailed({
    required String entityId,
    required String entityType,
    required String error,
    required DateTime timestamp,
  }) = SyncFailed;
  
  const factory NetworkEvent.receivedUpdate({
    required String entityId,
    required String entityType,
    required Map<String, dynamic> data,
    required DateTime timestamp,
  }) = ReceivedUpdate;
  
  factory NetworkEvent.fromJson(Map<String, dynamic> json) => 
      _$NetworkEventFromJson(json);
}
```

### 7.8 Sync Events

**Sync Event Handling**:
```dart
class SyncNotifier extends StateNotifier<SyncState> {
  final OrdersRepository _ordersRepo;
  final TablesRepository _tablesRepo;
  
  SyncNotifier(this._ordersRepo, this._tablesRepo) : super(SyncState.initial());
  
  Future<void> syncAll() async {
    state = state.markSyncing();
    
    try {
      // Sync pending actions
      for (final action in state.pendingActions) {
        await _syncAction(action);
      }
      
      // Pull updates from server
      await _pullUpdates();
      
      state = state.markSynced();
    } catch (e) {
      state = state.addError(
        SyncError(
          actionId: 'sync-all',
          message: e.toString(),
          occurredAt: DateTime.now(),
        ),
      );
    }
  }
  
  Future<void> _syncAction(PendingAction action) async {
    try {
      // Execute action
      await _executeAction(action);
      
      // Remove from pending
      state = state.removePendingAction(action.id);
    } catch (e) {
      // Increment retry count
      final updatedAction = action.copyWith(
        retryCount: action.retryCount + 1,
      );
      
      if (updatedAction.retryCount >= 3) {
        // Max retries reached, add error
        state = state.addError(
          SyncError(
            actionId: action.id,
            message: 'Max retries exceeded: ${e.toString()}',
            occurredAt: DateTime.now(),
          ),
        );
      }
    }
  }
}
```

### 7.9 Conflict Events

**Conflict Detection**:
```dart
@freezed
class ConflictEvent with _$ConflictEvent {
  const factory ConflictEvent.detected({
    required String entityId,
    required String entityType,
    required Map<String, dynamic> localVersion,
    required Map<String, dynamic> serverVersion,
    required DateTime detectedAt,
  }) = ConflictDetected;
  
  const factory ConflictEvent.resolved({
    required String entityId,
    required ConflictResolutionStrategy strategy,
    required Map<String, dynamic> resolvedVersion,
    required DateTime resolvedAt,
  }) = ConflictResolved;
  
  factory ConflictEvent.fromJson(Map<String, dynamic> json) => 
      _$ConflictEventFromJson(json);
}

enum ConflictResolutionStrategy {
  useLocal,
  useServer,
  merge,
  manual;
  
  String toJson() => name;
  static ConflictResolutionStrategy fromJson(String json) => values.byName(json);
}
```

### 7.10 Rehydration Events

**State Restoration**:
```dart
@freezed
class RehydrationEvent with _$RehydrationEvent {
  const factory RehydrationEvent.started({
    required DateTime timestamp,
  }) = RehydrationStarted;
  
  const factory RehydrationEvent.succeeded({
    required List<String> restoredStates,
    required DateTime timestamp,
  }) = RehydrationSucceeded;
  
  const factory RehydrationEvent.failed({
    required String error,
    required DateTime timestamp,
  }) = RehydrationFailed;
  
  factory RehydrationEvent.fromJson(Map<String, dynamic> json) => 
      _$RehydrationEventFromJson(json);
}

class AppNotifier extends StateNotifier<AppState> {
  final LocalStorage _storage;
  
  AppNotifier(this._storage) : super(AppState.initial()) {
    _rehydrate();
  }
  
  Future<void> _rehydrate() async {
    try {
      final ordersJson = await _storage.read('orders_state');
      final tablesJson = await _storage.read('tables_state');
      
      if (ordersJson != null && tablesJson != null) {
        state = state.copyWith(
          orders: OrdersState.fromJson(ordersJson),
          tables: TablesState.fromJson(tablesJson),
        );
      }
    } catch (e) {
      // Log error, continue with initial state
    }
  }
}
```

### 7.11 State Transition Diagrams

**Order State Transitions**:
```
[Pending] --confirm--> [Confirmed] --prepare--> [Preparing] --ready--> [Ready] --serve--> [Served]
    |                                                                                         ^
    |                                                                                         |
    +-------------------------cancel------------------------------------------------------>  [Cancelled]
```

**Table State Transitions**:
```
[Available] --occupy--> [Occupied] --release--> [Available]
                |                        ^
                |                        |
                +-------clean-----------+
```

### 7.12 Event Processing Flow

**Event Pipeline**:
```
User Action → Validate → Generate Event → Reduce State → Side Effects → Persist
                ↓                                                          ↓
              Reject                                                   Sync Queue
```

**Implementation**:
```dart
class EventProcessor {
  final StateNotifier notifier;
  final EventStore eventStore;
  final SyncQueue syncQueue;
  
  Future<Result<void, Failure>> process(UserAction action) async {
    // 1. Validate
    final validation = _validate(action);
    if (validation.isFailure) {
      return validation;
    }
    
    // 2. Generate event
    final event = _generateEvent(action);
    
    // 3. Reduce state
    notifier.reduce(event);
    
    // 4. Side effects
    await _executeSideEffects(event);
    
    // 5. Persist
    await eventStore.append(event);
    await syncQueue.enqueue(event);
    
    return Result.success(null);
  }
}
```

---

## 8. Offline-Ready Data Flow

### 8.1 Local Cache Boundaries

**Cache Strategy**:
```dart
abstract class CachePolicy {
  Duration get ttl;  // Time to live
  bool get persistOnDisk;
  bool get syncOnWrite;
}

class OrdersCachePolicy implements CachePolicy {
  @override
  Duration get ttl => Duration(hours: 24);
  
  @override
  bool get persistOnDisk => true;
  
  @override
  bool get syncOnWrite => true;
}

class LocalCache<T> {
  final String key;
  final CachePolicy policy;
  final LocalStorage storage;
  
  T? _memoryCache;
  DateTime? _cachedAt;
  
  Future<T?> get() async {
    // Check memory cache first
    if (_isValid(_memoryCache, _cachedAt)) {
      return _memoryCache;
    }
    
    // Check disk cache
    if (policy.persistOnDisk) {
      final json = await storage.read(key);
      if (json != null) {
        _memoryCache = _deserialize(json);
        _cachedAt = DateTime.now();
        return _memoryCache;
      }
    }
    
    return null;
  }
  
  Future<void> set(T value) async {
    _memoryCache = value;
    _cachedAt = DateTime.now();
    
    if (policy.persistOnDisk) {
      await storage.write(key, _serialize(value));
    }
  }
  
  bool _isValid(T? cache, DateTime? cachedAt) {
    if (cache == null || cachedAt == null) return false;
    return DateTime.now().difference(cachedAt) < policy.ttl;
  }
}
```

### 8.2 Sync Queue Preparation

**Pending Actions Queue**:
```dart
@freezed
class PendingAction with _$PendingAction {
  const factory PendingAction({
    required String id,
    required ActionType type,
    required Map<String, dynamic> payload,
    required DateTime createdAt,
    required int retryCount,
    required ActionPriority priority,
    DateTime? scheduledFor,
  }) = _PendingAction;
  
  factory PendingAction.fromJson(Map<String, dynamic> json) => 
      _$PendingActionFromJson(json);
}

enum ActionType {
  createOrder,
  updateOrder,
  deleteOrder,
  createBill,
  processPayment;
  
  String toJson() => name;
  static ActionType fromJson(String json) => values.byName(json);
}

enum ActionPriority {
  low,
  normal,
  high,
  critical;
  
  String toJson() => name;
  static ActionPriority fromJson(String json) => values.byName(json);
}

class SyncQueue {
  final LocalStorage _storage;
  final List<PendingAction> _queue = [];
  
  Future<void> enqueue(PendingAction action) async {
    _queue.add(action);
    _queue.sort((a, b) => b.priority.index.compareTo(a.priority.index));
    await _persist();
  }
  
  Future<PendingAction?> dequeue() async {
    if (_queue.isEmpty) return null;
    
    final action = _queue.removeAt(0);
    await _persist();
    return action;
  }
  
  Future<void> _persist() async {
    await _storage.write(
      'sync_queue',
      {'actions': _queue.map((a) => a.toJson()).toList()},
    );
  }
  
  Future<void> hydrate() async {
    final json = await _storage.read('sync_queue');
    if (json != null) {
      final actions = (json['actions'] as List)
          .map((a) => PendingAction.fromJson(a))
          .toList();
      _queue.addAll(actions);
    }
  }
}
```

### 8.3 Optimistic Updates

**Optimistic UI Pattern**:
```dart
class OrdersNotifier extends StateNotifier<OrdersState> {
  final OrdersRepository _repository;
  final SyncQueue _syncQueue;
  
  Future<void> createOrder(CreateOrderDto dto) async {
    // 1. Generate temporary ID
    final tempId = 'temp-${DateTime.now().millisecondsSinceEpoch}';
    
    // 2. Create optimistic order
    final optimisticOrder = Order(
      id: tempId,
      tenantId: dto.tenantId,
      tableId: dto.tableId,
      status: OrderStatus.pending,
      items: dto.items.map((i) => i.toDomain()).toList(),
      totalAmount: _calculateTotal(dto.items),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    // 3. Update UI immediately
    state = state.copyWith(
      orders: [...state.orders, optimisticOrder],
      optimisticIds: {...state.optimisticIds, tempId},
    );
    
    // 4. Queue for sync
    await _syncQueue.enqueue(
      PendingAction(
        id: tempId,
        type: ActionType.createOrder,
        payload: dto.toJson(),
        createdAt: DateTime.now(),
        retryCount: 0,
        priority: ActionPriority.high,
      ),
    );
    
    // 5. Sync to server (background)
    _syncToServer(tempId, dto);
  }
  
  Future<void> _syncToServer(String tempId, CreateOrderDto dto) async {
    final result = await _repository.createOrder(dto);
    
    result.fold(
      (realOrder) {
        // Replace temp with real order
        state = state.copyWith(
          orders: state.orders.map((o) => 
            o.id == tempId ? realOrder : o
          ).toList(),
          optimisticIds: state.optimisticIds.difference({tempId}),
        );
        
        // Remove from sync queue
        _syncQueue.remove(tempId);
      },
      (error) {
        // Mark as failed, keep in queue for retry
        state = state.copyWith(
          failedIds: {...state.failedIds, tempId},
        );
      },
    );
  }
}
```

### 8.4 Retry Systems

**Exponential Backoff Retry**:
```dart
class RetryPolicy {
  final int maxRetries;
  final Duration initialDelay;
  final double backoffMultiplier;
  final Duration maxDelay;
  
  const RetryPolicy({
    this.maxRetries = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
    this.maxDelay = const Duration(minutes: 5),
  });
  
  Duration getDelay(int retryCount) {
    final delay = initialDelay * pow(backoffMultiplier, retryCount);
    return delay > maxDelay ? maxDelay : delay;
  }
}

class RetryExecutor {
  final RetryPolicy policy;
  
  const RetryExecutor(this.policy);
  
  Future<Result<T, Failure>> execute<T>(
    Future<Result<T, Failure>> Function() operation,
  ) async {
    int retryCount = 0;
    
    while (retryCount <= policy.maxRetries) {
      final result = await operation();
      
      if (result.isSuccess) {
        return result;
      }
      
      // Check if error is retryable
      if (!_isRetryable(result.error)) {
        return result;
      }
      
      if (retryCount < policy.maxRetries) {
        final delay = policy.getDelay(retryCount);
        await Future.delayed(delay);
        retryCount++;
      } else {
        return result;
      }
    }
    
    return Result.failure(MaxRetriesExceededFailure());
  }
  
  bool _isRetryable(Failure? error) {
    return error is NetworkFailure || 
           error is TimeoutFailure ||
           error is ServerFailure && error.statusCode >= 500;
  }
}
```

### 8.5 Conflict Resolution Preparation

**Conflict Detection**:
```dart
class ConflictDetector {
  ConflictResult detect(Order local, Order server) {
    // Same version, no conflict
    if (local.updatedAt == server.updatedAt) {
      return ConflictResult.noConflict(server);
    }
    
    // Local is newer
    if (local.updatedAt.isAfter(server.updatedAt)) {
      return ConflictResult.localNewer(local, server);
    }
    
    // Server is newer
    if (server.updatedAt.isAfter(local.updatedAt)) {
      return ConflictResult.serverNewer(local, server);
    }
    
    // Concurrent modifications
    return ConflictResult.conflict(local, server);
  }
}

@freezed
class ConflictResult with _$ConflictResult {
  const factory ConflictResult.noConflict(Order resolved) = NoConflict;
  const factory ConflictResult.localNewer(Order local, Order server) = LocalNewer;
  const factory ConflictResult.serverNewer(Order local, Order server) = ServerNewer;
  const factory ConflictResult.conflict(Order local, Order server) = Conflict;
}

class ConflictResolver {
  Order resolve(Order local, Order server, ConflictResolutionStrategy strategy) {
    return strategy.when(
      useLocal: () => local,
      useServer: () => server,
      merge: () => _merge(local, server),
      manual: () => throw ManualResolutionRequiredException(),
    );
  }
  
  Order _merge(Order local, Order server) {
    // Last-write-wins for simple fields
    // Merge collections intelligently
    return Order(
      id: local.id,
      tenantId: local.tenantId,
      tableId: server.tableId,  // Server wins for table
      status: _mergeStatus(local.status, server.status),
      items: _mergeItems(local.items, server.items),
      totalAmount: _recalculateTotal(local.items, server.items),
      createdAt: local.createdAt,
      updatedAt: DateTime.now(),
    );
  }
  
  OrderStatus _mergeStatus(OrderStatus local, OrderStatus server) {
    // Status progression: pending -> confirmed -> preparing -> ready -> served
    // Use the more advanced status
    final progression = [
      OrderStatus.pending,
      OrderStatus.confirmed,
      OrderStatus.preparing,
      OrderStatus.ready,
      OrderStatus.served,
    ];
    
    final localIndex = progression.indexOf(local);
    final serverIndex = progression.indexOf(server);
    
    return localIndex > serverIndex ? local : server;
  }
  
  List<OrderItem> _mergeItems(List<OrderItem> local, List<OrderItem> server) {
    final merged = <String, OrderItem>{};
    
    // Add all local items
    for (final item in local) {
      merged[item.id] = item;
    }
    
    // Merge server items
    for (final item in server) {
      if (merged.containsKey(item.id)) {
        // Item exists in both, use newer
        final localItem = merged[item.id]!;
        merged[item.id] = localItem.updatedAt.isAfter(item.updatedAt) 
            ? localItem 
            : item;
      } else {
        // New item from server
        merged[item.id] = item;
      }
    }
    
    return merged.values.toList();
  }
}
```

### 8.6 Pending Action Queues

**Action Queue Management**:
```dart
@freezed
class ActionQueueState with _$ActionQueueState {
  const factory ActionQueueState({
    @Default([]) List<PendingAction> pending,
    @Default([]) List<PendingAction> inProgress,
    @Default([]) List<CompletedAction> completed,
    @Default([]) List<FailedAction> failed,
  }) = _ActionQueueState;
  
  factory ActionQueueState.fromJson(Map<String, dynamic> json) => 
      _$ActionQueueStateFromJson(json);
}

class ActionQueueNotifier extends StateNotifier<ActionQueueState> {
  final RetryExecutor _retryExecutor;
  final OrdersRepository _repository;
  
  ActionQueueNotifier(this._retryExecutor, this._repository) 
      : super(ActionQueueState());
  
  Future<void> processQueue() async {
    while (state.pending.isNotEmpty) {
      final action = state.pending.first;
      
      // Move to in-progress
      state = state.copyWith(
        pending: state.pending.skip(1).toList(),
        inProgress: [...state.inProgress, action],
      );
      
      // Execute with retry
      final result = await _retryExecutor.execute(() => _execute(action));
      
      result.fold(
        (_) {
          // Success
          state = state.copyWith(
            inProgress: state.inProgress.where((a) => a.id != action.id).toList(),
            completed: [...state.completed, CompletedAction.from(action)],
          );
        },
        (error) {
          // Failure
          state = state.copyWith(
            inProgress: state.inProgress.where((a) => a.id != action.id).toList(),
            failed: [...state.failed, FailedAction.from(action, error)],
          );
        },
      );
    }
  }
  
  Future<Result<void, Failure>> _execute(PendingAction action) async {
    return action.type.when(
      createOrder: () => _repository.createOrder(
        CreateOrderDto.fromJson(action.payload),
      ),
      updateOrder: () => _repository.updateOrder(
        UpdateOrderDto.fromJson(action.payload),
      ),
      // ... other action types
    );
  }
}
```

### 8.7 Event Persistence Readiness

**Event Store**:
```dart
class EventStore {
  final LocalStorage _storage;
  final List<StoredEvent> _events = [];
  
  Future<void> append(OrderEvent event) async {
    final storedEvent = StoredEvent(
      id: _generateId(),
      type: event.runtimeType.toString(),
      payload: event.toJson(),
      timestamp: DateTime.now(),
    );
    
    _events.add(storedEvent);
    await _persist();
  }
  
  Future<List<StoredEvent>> getEvents({
    String? entityId,
    DateTime? since,
  }) async {
    var filtered = _events;
    
    if (entityId != null) {
      filtered = filtered.where((e) => 
        e.payload['orderId'] == entityId ||
        e.payload['tableId'] == entityId
      ).toList();
    }
    
    if (since != null) {
      filtered = filtered.where((e) => 
        e.timestamp.isAfter(since)
      ).toList();
    }
    
    return filtered;
  }
  
  Future<OrdersState> replay(List<StoredEvent> events) async {
    var state = OrdersState.initial();
    
    for (final event in events) {
      final orderEvent = _deserializeEvent(event);
      state = reduceOrderEvent(state, orderEvent);
    }
    
    return state;
  }
  
  Future<void> _persist() async {
    await _storage.write(
      'event_store',
      {'events': _events.map((e) => e.toJson()).toList()},
    );
  }
}

@freezed
class StoredEvent with _$StoredEvent {
  const factory StoredEvent({
    required String id,
    required String type,
    required Map<String, dynamic> payload,
    required DateTime timestamp,
  }) = _StoredEvent;
  
  factory StoredEvent.fromJson(Map<String, dynamic> json) => 
      _$StoredEventFromJson(json);
}
```

### 8.8 Future Offline Sync Integration Points

**Sync Service Interface** (for future implementation):
```dart
abstract class SyncService {
  // Push local changes to server
  Future<SyncResult> pushChanges();
  
  // Pull server changes to local
  Future<SyncResult> pullChanges();
  
  // Bidirectional sync
  Future<SyncResult> sync();
  
  // Conflict resolution
  Future<void> resolveConflicts(List<Conflict> conflicts);
  
  // Sync status
  Stream<SyncStatus> get syncStatus;
}

// Future implementation placeholder
class OfflineSyncService implements SyncService {
  final EventStore _eventStore;
  final ActionQueueNotifier _actionQueue;
  final ConflictResolver _conflictResolver;
  
  @override
  Future<SyncResult> sync() async {
    // 1. Push pending actions
    await _actionQueue.processQueue();
    
    // 2. Pull server updates
    final serverEvents = await _fetchServerEvents();
    
    // 3. Detect conflicts
    final conflicts = await _detectConflicts(serverEvents);
    
    // 4. Resolve conflicts
    if (conflicts.isNotEmpty) {
      await resolveConflicts(conflicts);
    }
    
    // 5. Apply server events
    await _applyServerEvents(serverEvents);
    
    return SyncResult.success();
  }
  
  // Implementation details...
}
```

---

## 9. Repository Architecture

### 9.1 Repository Interfaces

**Base Repository Pattern**:
```dart
abstract class Repository<T, ID> {
  Future<Result<T, Failure>> getById(ID id);
  Future<Result<List<T>, Failure>> getAll();
  Future<Result<T, Failure>> create(T entity);
  Future<Result<T, Failure>> update(T entity);
  Future<Result<void, Failure>> delete(ID id);
}

// Orders Repository
abstract class OrdersRepository {
  // Queries
  Future<Result<Order, Failure>> getOrderById(String orderId);
  Future<Result<List<Order>, Failure>> getOrdersByTenant(String tenantId);
  Future<Result<List<Order>, Failure>> getOrdersByTable(String tableId);
  Future<Result<List<Order>, Failure>> getOrdersByStatus(OrderStatus status);
  
  // Commands
  Future<Result<Order, Failure>> createOrder(CreateOrderDto dto);
  Future<Result<Order, Failure>> updateOrderStatus(String orderId, OrderStatus status);
  Future<Result<Order, Failure>> addOrderItem(String orderId, OrderItemDto item);
  Future<Result<void, Failure>> cancelOrder(String orderId);
  
  // Real-time
  Stream<List<Order>> watchOrders(String tenantId);
  Stream<Order> watchOrder(String orderId);
}

// Tables Repository
abstract class TablesRepository {
  Future<Result<TableState, Failure>> getTableById(String tableId);
  Future<Result<List<TableState>, Failure>> getTablesByTenant(String tenantId);
  Future<Result<List<TableState>, Failure>> getAvailableTables(String tenantId);
  
  Future<Result<TableState, Failure>> occupyTable(String tableId, String orderId);
  Future<Result<TableState, Failure>> releaseTable(String tableId);
  
  Stream<List<TableState>> watchTables(String tenantId);
}
```

### 9.2 Data Source Separation

**Remote Data Source**:
```dart
abstract class OrdersRemoteDataSource {
  Future<OrderDto> getOrderById(String orderId);
  Future<List<OrderDto>> getOrdersByTenant(String tenantId);
  Future<OrderDto> createOrder(CreateOrderDto dto);
  Future<OrderDto> updateOrder(UpdateOrderDto dto);
  Future<void> deleteOrder(String orderId);
}

class OrdersRemoteDataSourceImpl implements OrdersRemoteDataSource {
  final Dio _client;
  final String _baseUrl;
  
  OrdersRemoteDataSourceImpl(this._client, this._baseUrl);
  
  @override
  Future<OrderDto> getOrderById(String orderId) async {
    try {
      final response = await _client.get('$_baseUrl/orders/$orderId');
      return OrderDto.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(e.message);
    }
  }
  
  @override
  Future<OrderDto> createOrder(CreateOrderDto dto) async {
    try {
      final response = await _client.post(
        '$_baseUrl/orders',
        data: dto.toJson(),
      );
      return OrderDto.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(e.message);
    }
  }
  
  // ... other methods
}
```

**Local Data Source**:
```dart
abstract class OrdersLocalDataSource {
  Future<OrderDto?> getOrderById(String orderId);
  Future<List<OrderDto>> getOrdersByTenant(String tenantId);
  Future<void> cacheOrder(OrderDto order);
  Future<void> cacheOrders(List<OrderDto> orders);
  Future<void> deleteOrder(String orderId);
  Future<void> clear();
}

class OrdersLocalDataSourceImpl implements OrdersLocalDataSource {
  final LocalStorage _storage;
  final String _cacheKey = 'orders_cache';
  
  OrdersLocalDataSourceImpl(this._storage);
  
  @override
  Future<OrderDto?> getOrderById(String orderId) async {
    final cache = await _getCache();
    return cache[orderId];
  }
  
  @override
  Future<List<OrderDto>> getOrdersByTenant(String tenantId) async {
    final cache = await _getCache();
    return cache.values
        .where((order) => order.tenantId == tenantId)
        .toList();
  }
  
  @override
  Future<void> cacheOrder(OrderDto order) async {
    final cache = await _getCache();
    cache[order.id] = order;
    await _saveCache(cache);
  }
  
  @override
  Future<void> cacheOrders(List<OrderDto> orders) async {
    final cache = await _getCache();
    for (final order in orders) {
      cache[order.id] = order;
    }
    await _saveCache(cache);
  }
  
  Future<Map<String, OrderDto>> _getCache() async {
    final json = await _storage.read(_cacheKey);
    if (json == null) return {};
    
    final list = (json['orders'] as List)
        .map((o) => OrderDto.fromJson(o))
        .toList();
    
    return {for (var order in list) order.id: order};
  }
  
  Future<void> _saveCache(Map<String, OrderDto> cache) async {
    await _storage.write(_cacheKey, {
      'orders': cache.values.map((o) => o.toJson()).toList(),
    });
  }
}
```

### 9.3 Repository Implementation

**Orders Repository Implementation**:
```dart
class OrdersRepositoryImpl implements OrdersRepository {
  final OrdersRemoteDataSource _remoteDataSource;
  final OrdersLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;
  
  OrdersRepositoryImpl({
    required OrdersRemoteDataSource remoteDataSource,
    required OrdersLocalDataSource localDataSource,
    required NetworkInfo networkInfo,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _networkInfo = networkInfo;
  
  @override
  Future<Result<Order, Failure>> getOrderById(String orderId) async {
    try {
      // Try remote first if online
      if (await _networkInfo.isConnected) {
        final dto = await _remoteDataSource.getOrderById(orderId);
        
        // Cache for offline use
        await _localDataSource.cacheOrder(dto);
        
        return Result.success(dto.toDomain());
      }
      
      // Fallback to cache if offline
      final cachedDto = await _localDataSource.getOrderById(orderId);
      if (cachedDto != null) {
        return Result.success(cachedDto.toDomain());
      }
      
      return Result.failure(CacheFailure('Order not found in cache'));
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }
  
  @override
  Future<Result<Order, Failure>> createOrder(CreateOrderDto dto) async {
    try {
      if (await _networkInfo.isConnected) {
        // Online: create on server
        final orderDto = await _remoteDataSource.createOrder(dto);
        await _localDataSource.cacheOrder(orderDto);
        return Result.success(orderDto.toDomain());
      } else {
        // Offline: create locally with temp ID
        final tempOrder = _createTempOrder(dto);
        await _localDataSource.cacheOrder(tempOrder);
        
        // Queue for sync
        // (handled by SyncQueue in calling code)
        
        return Result.success(tempOrder.toDomain());
      }
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }
  
  OrderDto _createTempOrder(CreateOrderDto dto) {
    return OrderDto(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      tenantId: dto.tenantId,
      tableId: dto.tableId,
      tableLabel: dto.tableLabel,
      status: OrderStatus.pending.toJson(),
      items: dto.items,
      totalAmount: dto.items.fold(0.0, (sum, item) => sum + item.subtotal),
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );
  }
  
  @override
  Stream<List<Order>> watchOrders(String tenantId) {
    // Implementation depends on real-time backend (WebSocket, SSE, etc.)
    // For now, return empty stream
    return Stream.empty();
  }
}
```

### 9.4 Mock Repository Compatibility

**Mock Repository**:
```dart
class MockOrdersRepository implements OrdersRepository {
  final Map<String, Order> _orders = {};
  final StreamController<List<Order>> _ordersController = 
      StreamController.broadcast();
  
  MockOrdersRepository() {
    _seedData();
  }
  
  void _seedData() {
    final mockOrders = [
      Order(
        id: 'order-1',
        tenantId: 'tenant-1',
        tableId: 'table-1',
        tableLabel: 'Table 1',
        status: OrderStatus.pending,
        items: [],
        totalAmount: Money(amount: 500.0),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
    
    for (final order in mockOrders) {
      _orders[order.id] = order;
    }
    
    _notifyListeners();
  }
  
  @override
  Future<Result<Order, Failure>> getOrderById(String orderId) async {
    await Future.delayed(Duration(milliseconds: 100)); // Simulate network
    
    final order = _orders[orderId];
    if (order != null) {
      return Result.success(order);
    }
    
    return Result.failure(NotFoundFailure('Order not found'));
  }
  
  @override
  Future<Result<Order, Failure>> createOrder(CreateOrderDto dto) async {
    await Future.delayed(Duration(milliseconds: 200));
    
    final order = Order(
      id: 'order-${DateTime.now().millisecondsSinceEpoch}',
      tenantId: dto.tenantId,
      tableId: dto.tableId,
      tableLabel: dto.tableLabel,
      status: OrderStatus.pending,
      items: dto.items.map((i) => i.toDomain()).toList(),
      totalAmount: Money(amount: dto.items.fold(0.0, (sum, i) => sum + i.subtotal)),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    _orders[order.id] = order;
    _notifyListeners();
    
    return Result.success(order);
  }
  
  @override
  Stream<List<Order>> watchOrders(String tenantId) {
    return _ordersController.stream.map((orders) =>
        orders.where((o) => o.tenantId == tenantId).toList());
  }
  
  void _notifyListeners() {
    _ordersController.add(_orders.values.toList());
  }
  
  void dispose() {
    _ordersController.close();
  }
}
```

### 9.5 DTO Mapping Strategy

**DTO to Domain Mapping**:
```dart
// DTO (API contract)
@freezed
class OrderDto with _$OrderDto {
  const factory OrderDto({
    required String id,
    required String tenant_id,
    required String table_id,
    required String table_label,
    required String status,
    required List<OrderItemDto> items,
    required double total_amount,
    required String created_at,
    required String updated_at,
    String? staff_id,
    String? notes,
  }) = _OrderDto;
  
  factory OrderDto.fromJson(Map<String, dynamic> json) => 
      _$OrderDtoFromJson(json);
}

// Mapper extension
extension OrderDtoMapper on OrderDto {
  Order toDomain() {
    return Order(
      id: id,
      tenantId: tenant_id,
      tableId: table_id,
      tableLabel: table_label,
      status: OrderStatus.fromString(status),
      items: items.map((dto) => dto.toDomain()).toList(),
      totalAmount: Money(amount: total_amount),
      createdAt: DateTime.parse(created_at),
      updatedAt: DateTime.parse(updated_at),
      staffId: staff_id,
      notes: notes,
    );
  }
}

extension OrderMapper on Order {
  OrderDto toDto() {
    return OrderDto(
      id: id,
      tenant_id: tenantId,
      table_id: tableId,
      table_label: tableLabel,
      status: status.toJson(),
      items: items.map((item) => item.toDto()).toList(),
      total_amount: totalAmount.amount,
      created_at: createdAt.toIso8601String(),
      updated_at: updatedAt.toIso8601String(),
      staff_id: staffId,
      notes: notes,
    );
  }
}
```

### 9.6 Error Wrapping

**Failure Types**:
```dart
@freezed
class Failure with _$Failure {
  const factory Failure.server({
    required String message,
    int? statusCode,
  }) = ServerFailure;
  
  const factory Failure.network({
    required String message,
  }) = NetworkFailure;
  
  const factory Failure.cache({
    required String message,
  }) = CacheFailure;
  
  const factory Failure.notFound({
    required String message,
  }) = NotFoundFailure;
  
  const factory Failure.validation({
    required String message,
    Map<String, List<String>>? errors,
  }) = ValidationFailure;
  
  const factory Failure.unauthorized({
    required String message,
  }) = UnauthorizedFailure;
  
  const factory Failure.unknown({
    required String message,
  }) = UnknownFailure;
}

// Exception to Failure mapping
Failure mapExceptionToFailure(Exception exception) {
  if (exception is ServerException) {
    return Failure.server(
      message: exception.message,
      statusCode: exception.statusCode,
    );
  } else if (exception is NetworkException) {
    return Failure.network(message: exception.message);
  } else if (exception is CacheException) {
    return Failure.cache(message: exception.message);
  } else {
    return Failure.unknown(message: exception.toString());
  }
}
```

### 9.7 Result Types

**Result Type**:
```dart
@freezed
class Result<T, E> with _$Result<T, E> {
  const Result._();
  
  const factory Result.success(T value) = Success<T, E>;
  const factory Result.failure(E error) = Failure<T, E>;
  
  bool get isSuccess => this is Success<T, E>;
  bool get isFailure => this is Failure<T, E>;
  
  T? get valueOrNull => when(
    success: (value) => value,
    failure: (_) => null,
  );
  
  E? get errorOrNull => when(
    success: (_) => null,
    failure: (error) => error,
  );
  
  R fold<R>(
    R Function(T value) onSuccess,
    R Function(E error) onFailure,
  ) {
    return when(
      success: onSuccess,
      failure: onFailure,
    );
  }
  
  Result<R, E> map<R>(R Function(T value) transform) {
    return when(
      success: (value) => Result.success(transform(value)),
      failure: (error) => Result.failure(error),
    );
  }
  
  Future<Result<R, E>> mapAsync<R>(
    Future<R> Function(T value) transform,
  ) async {
    return await when(
      success: (value) async => Result.success(await transform(value)),
      failure: (error) async => Result.failure(error),
    );
  }
}

// Usage
Future<Result<Order, Failure>> getOrder(String id) async {
  final result = await repository.getOrderById(id);
  
  return result.fold(
    (order) => Result.success(order),
    (error) => Result.failure(error),
  );
}
```

### 9.8 Retry Handling

**Repository-Level Retry**:
```dart
class ResilientOrdersRepository implements OrdersRepository {
  final OrdersRepository _delegate;
  final RetryExecutor _retryExecutor;
  
  ResilientOrdersRepository(this._delegate, this._retryExecutor);
  
  @override
  Future<Result<Order, Failure>> getOrderById(String orderId) async {
    return await _retryExecutor.execute(() => _delegate.getOrderById(orderId));
  }
  
  @override
  Future<Result<Order, Failure>> createOrder(CreateOrderDto dto) async {
    // Don't retry creates (not idempotent without idempotency key)
    return await _delegate.createOrder(dto);
  }
  
  @override
  Future<Result<Order, Failure>> updateOrderStatus(
    String orderId,
    OrderStatus status,
  ) async {
    // Retry updates (idempotent)
    return await _retryExecutor.execute(
      () => _delegate.updateOrderStatus(orderId, status),
    );
  }
}
```

### 9.9 Serialization-Safe Repositories

**Repository Provider**:
```dart
// ✅ GOOD: Repository is NOT stored in state
final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  final remoteDataSource = ref.watch(ordersRemoteDataSourceProvider);
  final localDataSource = ref.watch(ordersLocalDataSourceProvider);
  final networkInfo = ref.watch(networkInfoProvider);
  
  return OrdersRepositoryImpl(
    remoteDataSource: remoteDataSource,
    localDataSource: localDataSource,
    networkInfo: networkInfo,
  );
});

// ✅ GOOD: State only contains serializable data
@freezed
class OrdersState with _$OrdersState {
  const factory OrdersState({
    required List<Order> orders,
    required LoadingStatus status,
  }) = _OrdersState;
  
  factory OrdersState.fromJson(Map<String, dynamic> json) => 
      _$OrdersStateFromJson(json);
}

// ✅ GOOD: Notifier uses repository via dependency injection
class OrdersNotifier extends StateNotifier<OrdersState> {
  final OrdersRepository _repository;  // Injected, not stored in state
  
  OrdersNotifier(this._repository) : super(OrdersState.initial());
  
  Future<void> loadOrders(String tenantId) async {
    state = state.copyWith(status: LoadingStatus.loading);
    
    final result = await _repository.getOrdersByTenant(tenantId);
    
    result.fold(
      (orders) => state = state.copyWith(
        orders: orders,
        status: LoadingStatus.success,
      ),
      (error) => state = state.copyWith(
        status: LoadingStatus.error,
      ),
    );
  }
}
```

---

## 10. Riverpod Production Guidelines

### 10.1 Provider Lifecycle Management

**Provider Lifecycle Rules**:

1. **Infrastructure Providers**: Never auto-dispose
2. **Repository Providers**: Never auto-dispose
3. **State Providers**: Auto-dispose when appropriate
4. **Derived Providers**: Always auto-dispose
5. **Family Providers**: Always auto-dispose

```dart
// ❌ BAD: Repository with autoDispose
final ordersRepositoryProvider = Provider.autoDispose<OrdersRepository>((ref) {
  return OrdersRepositoryImpl(...);  // Will be disposed and recreated
});

// ✅ GOOD: Repository without autoDispose
final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return OrdersRepositoryImpl(...);  // Lives for app lifetime
});

// ✅ GOOD: State with autoDispose (screen-scoped)
final orderDetailStateProvider = StateNotifierProvider.autoDispose
    .family<OrderDetailNotifier, OrderDetailState, String>((ref, orderId) {
  return OrderDetailNotifier(
    orderId: orderId,
    repository: ref.watch(ordersRepositoryProvider),
  );
});

// ✅ GOOD: Derived provider with autoDispose
final activeOrdersCountProvider = Provider.autoDispose<int>((ref) {
  final orders = ref.watch(ordersStateProvider).orders;
  return orders.where((o) => o.status.isActive).length;
});
```

### 10.2 autoDispose Rules

**When to Use autoDispose**:

✅ **Use autoDispose for**:
- Screen-specific state
- Derived/computed values
- Family providers
- Temporary data
- UI-only state

❌ **Don't use autoDispose for**:
- Repositories
- Services
- HTTP clients
- Database connections
- Global app state
- Authentication state

**Example**:
```dart
// Global state - no autoDispose
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});

// Screen state - with autoDispose
final orderFormStateProvider = StateNotifierProvider.autoDispose<
    OrderFormNotifier, OrderFormState>((ref) {
  return OrderFormNotifier();
});

// Derived value - with autoDispose
final formValidationProvider = Provider.autoDispose<bool>((ref) {
  final form = ref.watch(orderFormStateProvider);
  return form.tableId.isNotEmpty && form.items.isNotEmpty;
});
```

### 10.3 Ref Usage Guidelines

**Ref Best Practices**:

```dart
class OrdersNotifier extends StateNotifier<OrdersState> {
  final Ref _ref;
  final OrdersRepository _repository;
  
  OrdersNotifier(this._ref, this._repository) : super(OrdersState.initial()) {
    // ✅ GOOD: Read other providers in constructor
    final tenantId = _ref.read(currentTenantIdProvider);
    _loadOrders(tenantId);
  }
  
  Future<void> createOrder(CreateOrderDto dto) async {
    // ✅ GOOD: Read providers in methods
    final userId = _ref.read(currentUserIdProvider);
    
    // ❌ BAD: Watch providers in notifier (causes rebuild loops)
    // final userId = _ref.watch(currentUserIdProvider);
    
    final result = await _repository.createOrder(dto.copyWith(
      staffId: userId,
    ));
    
    result.fold(
      (order) => state = state.copyWith(
        orders: [...state.orders, order],
      ),
      (error) => _handleError(error),
    );
  }
  
  void _handleError(Failure error) {
    // ✅ GOOD: Read error handler provider
    final errorHandler = _ref.read(errorHandlerProvider);
    errorHandler.handle(error);
  }
}

// Provider setup
final ordersStateProvider = StateNotifierProvider<OrdersNotifier, OrdersState>((ref) {
  return OrdersNotifier(
    ref,  // Pass ref for reading other providers
    ref.watch(ordersRepositoryProvider),
  );
});
```

### 10.4 Dependency Inversion

**Correct Dependency Flow**:

```dart
// ❌ BAD: Tight coupling
class OrdersNotifier extends StateNotifier<OrdersState> {
  OrdersNotifier(Ref ref) : super(OrdersState.initial()) {
    // Directly depends on concrete implementation
    final repository = OrdersRepositoryImpl(...);
  }
}

// ✅ GOOD: Dependency injection
class OrdersNotifier extends StateNotifier<OrdersState> {
  final OrdersRepository _repository;  // Depends on interface
  
  OrdersNotifier(this._repository) : super(OrdersState.initial());
}

final ordersStateProvider = StateNotifierProvider<OrdersNotifier, OrdersState>((ref) {
  return OrdersNotifier(
    ref.watch(ordersRepositoryProvider),  // Injected via provider
  );
});
```

**Provider Composition**:
```dart
// Low-level providers
final httpClientProvider = Provider<Dio>((ref) => Dio());
final localStorageProvider = Provider<LocalStorage>((ref) => LocalStorage());

// Mid-level providers (depend on low-level)
final ordersRemoteDataSourceProvider = Provider<OrdersRemoteDataSource>((ref) {
  return OrdersRemoteDataSourceImpl(
    ref.watch(httpClientProvider),
    'https://api.example.com',
  );
});

final ordersLocalDataSourceProvider = Provider<OrdersLocalDataSource>((ref) {
  return OrdersLocalDataSourceImpl(
    ref.watch(localStorageProvider),
  );
});

// High-level providers (depend on mid-level)
final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return OrdersRepositoryImpl(
    remoteDataSource: ref.watch(ordersRemoteDataSourceProvider),
    localDataSource: ref.watch(ordersLocalDataSourceProvider),
    networkInfo: ref.watch(networkInfoProvider),
  );
});

// Application providers (depend on high-level)
final ordersStateProvider = StateNotifierProvider<OrdersNotifier, OrdersState>((ref) {
  return OrdersNotifier(
    ref.watch(ordersRepositoryProvider),
  );
});
```

### 10.5 Async Handling

**AsyncValue Pattern**:
```dart
// Using AsyncValue for loading states
final ordersProvider = FutureProvider.autoDispose<List<Order>>((ref) async {
  final repository = ref.watch(ordersRepositoryProvider);
  final tenantId = ref.watch(currentTenantIdProvider);
  
  final result = await repository.getOrdersByTenant(tenantId);
  
  return result.fold(
    (orders) => orders,
    (error) => throw error,
  );
});

// Widget usage
class OrdersListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);
    
    return ordersAsync.when(
      data: (orders) => OrdersList(orders: orders),
      loading: () => LoadingIndicator(),
      error: (error, stack) => ErrorView(error: error),
    );
  }
}
```

**Manual Async State Management**:
```dart
@freezed
class OrdersState with _$OrdersState {
  const factory OrdersState({
    required List<Order> orders,
    required LoadingStatus status,
    Failure? error,
  }) = _OrdersState;
  
  factory OrdersState.fromJson(Map<String, dynamic> json) => 
      _$OrdersStateFromJson(json);
}

enum LoadingStatus {
  initial,
  loading,
  success,
  error;
  
  String toJson() => name;
  static LoadingStatus fromJson(String json) => values.byName(json);
}

class OrdersNotifier extends StateNotifier<OrdersState> {
  final OrdersRepository _repository;
  
  OrdersNotifier(this._repository) : super(OrdersState.initial());
  
  Future<void> loadOrders(String tenantId) async {
    state = state.copyWith(status: LoadingStatus.loading);
    
    final result = await _repository.getOrdersByTenant(tenantId);
    
    result.fold(
      (orders) => state = state.copyWith(
        orders: orders,
        status: LoadingStatus.success,
        error: null,
      ),
      (error) => state = state.copyWith(
        status: LoadingStatus.error,
        error: error,
      ),
    );
  }
}
```

### 10.6 Error Boundaries

**Error Handling Strategy**:
```dart
// Global error handler
final errorHandlerProvider = Provider<ErrorHandler>((ref) {
  return ErrorHandler(
    logger: ref.watch(loggerProvider),
    analytics: ref.watch(analyticsProvider),
  );
});

class ErrorHandler {
  final Logger _logger;
  final Analytics _analytics;
  
  ErrorHandler({
    required Logger logger,
    required Analytics analytics,
  })  : _logger = logger,
        _analytics = analytics;
  
  void handle(Failure failure) {
    failure.when(
      server: (message, statusCode) {
        _logger.error('Server error: $message (${statusCode ?? 'unknown'})');
        _analytics.logError('server_error', {'message': message});
      },
      network: (message) {
        _logger.warning('Network error: $message');
        // Don't log to analytics (expected in offline scenarios)
      },
      validation: (message, errors) {
        _logger.info('Validation error: $message');
        // User input error, don't log to analytics
      },
      unauthorized: (message) {
        _logger.warning('Unauthorized: $message');
        _analytics.logError('auth_error', {'message': message});
      },
      unknown: (message) {
        _logger.error('Unknown error: $message');
        _analytics.logError('unknown_error', {'message': message});
      },
      cache: (message) => _logger.debug('Cache error: $message'),
      notFound: (message) => _logger.debug('Not found: $message'),
    );
  }
}

// Usage in notifier
class OrdersNotifier extends StateNotifier<OrdersState> {
  final OrdersRepository _repository;
  final ErrorHandler _errorHandler;
  
  OrdersNotifier(this._repository, this._errorHandler) 
      : super(OrdersState.initial());
  
  Future<void> loadOrders(String tenantId) async {
    final result = await _repository.getOrdersByTenant(tenantId);
    
    result.fold(
      (orders) => state = state.copyWith(orders: orders),
      (error) {
        _errorHandler.handle(error);
        state = state.copyWith(error: error);
      },
    );
  }
}
```

### 10.7 Best Practices

**DO**:
- ✅ Keep providers focused and single-purpose
- ✅ Use dependency injection via providers
- ✅ Dispose resources in notifier's dispose method
- ✅ Use family providers for parameterized queries
- ✅ Use derived providers for computed values
- ✅ Keep state serializable
- ✅ Handle errors gracefully
- ✅ Use autoDispose for screen-scoped state

**DON'T**:
- ❌ Store non-serializable objects in state
- ❌ Use watch() inside StateNotifier methods
- ❌ Create circular provider dependencies
- ❌ Mutate state directly (always use copyWith)
- ❌ Perform side effects in provider builders
- ❌ Use autoDispose for global state
- ❌ Ignore error handling

### 10.8 Anti-Patterns

**Anti-Pattern 1: Watching in Notifier**:
```dart
// ❌ BAD: Causes rebuild loops
class OrdersNotifier extends StateNotifier<OrdersState> {
  final Ref _ref;
  
  void updateOrder(String orderId) {
    final user = _ref.watch(currentUserProvider);  // ❌ DON'T WATCH
    // ...
  }
}

// ✅ GOOD: Read instead
class OrdersNotifier extends StateNotifier<OrdersState> {
  final Ref _ref;
  
  void updateOrder(String orderId) {
    final user = _ref.read(currentUserProvider);  // ✅ READ
    // ...
  }
}
```

**Anti-Pattern 2: Circular Dependencies**:
```dart
// ❌ BAD: Circular dependency
final ordersProvider = Provider((ref) {
  final tables = ref.watch(tablesProvider);  // Depends on tables
  return OrdersService(tables);
});

final tablesProvider = Provider((ref) {
  final orders = ref.watch(ordersProvider);  // Depends on orders
  return TablesService(orders);
});

// ✅ GOOD: Shared dependency
final ordersProvider = Provider((ref) {
  final repository = ref.watch(ordersRepositoryProvider);
  return OrdersService(repository);
});

final tablesProvider = Provider((ref) {
  final repository = ref.watch(tablesRepositoryProvider);
  return TablesService(repository);
});
```

**Anti-Pattern 3: Side Effects in Builder**:
```dart
// ❌ BAD: Side effect in provider builder
final ordersProvider = Provider((ref) {
  final repository = ref.watch(ordersRepositoryProvider);
  repository.syncAll();  // ❌ Side effect
  return repository;
});

// ✅ GOOD: Side effects in notifier
final ordersStateProvider = StateNotifierProvider((ref) {
  final notifier = OrdersNotifier(ref.watch(ordersRepositoryProvider));
  notifier.initialize();  // ✅ Explicit initialization
  return notifier;
});
```

### 10.9 Performance Considerations

**Optimization Strategies**:

1. **Use select() for granular updates**:
```dart
// ❌ BAD: Rebuilds on any state change
final orderCount = ref.watch(ordersStateProvider).orders.length;

// ✅ GOOD: Only rebuilds when order count changes
final orderCount = ref.watch(
  ordersStateProvider.select((state) => state.orders.length),
);
```

2. **Use family providers for item-specific state**:
```dart
// ❌ BAD: Entire list rebuilds when one item changes
final orders = ref.watch(ordersStateProvider).orders;
for (final order in orders) {
  OrderCard(order: order);
}

// ✅ GOOD: Only affected item rebuilds
final orderIds = ref.watch(orderIdsProvider);
for (final orderId in orderIds) {
  OrderCard(orderId: orderId);  // Uses orderByIdProvider(orderId)
}
```

3. **Memoize expensive computations**:
```dart
final expensiveComputationProvider = Provider.autoDispose((ref) {
  final data = ref.watch(dataProvider);
  
  // Memoized - only recomputes when data changes
  return _expensiveComputation(data);
});
```

### 10.10 Debugging Strategy

**Provider Observer**:
```dart
class AppProviderObserver extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    print('''
Provider: ${provider.name ?? provider.runtimeType}
Previous: $previousValue
New: $newValue
''');
  }
  
  @override
  void providerDidFail(
    ProviderBase provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    print('''
Provider failed: ${provider.name ?? provider.runtimeType}
Error: $error
Stack: $stackTrace
''');
  }
}

// Usage in main.dart
void main() {
  runApp(
    ProviderScope(
      observers: [AppProviderObserver()],
      child: MyApp(),
    ),
  );
}
```

**DevTools Integration**:
```dart
// Enable Riverpod DevTools
import 'package:riverpod_annotation/riverpod_annotation.dart';

// Providers are automatically visible in Flutter DevTools
// Use Riverpod Inspector to:
// - View provider dependency graph
// - Inspect current provider values
// - Track provider lifecycle
// - Debug state changes
```

---

