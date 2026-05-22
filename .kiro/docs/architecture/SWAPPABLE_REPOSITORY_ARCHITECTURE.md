# Swappable Repository Architecture

## Executive Summary

This document describes the **enterprise-grade swappable repository architecture** that enables seamless switching between mock, live API, and offline-first data sources without requiring changes to business logic, state management, or UI layers.

### Key Benefits

✅ **Zero Refactoring** - Switch data sources without touching UI or business logic  
✅ **Offline-First Ready** - Architecture supports future offline capabilities  
✅ **Testable** - Easy to inject mock repositories for testing  
✅ **Scalable** - Clean separation enables team scalability  
✅ **Future-Proof** - New data sources can be added without breaking existing code  
✅ **Type-Safe** - Compile-time guarantees through interfaces  

---

## Architecture Overview

### Layer Separation

```
┌─────────────────────────────────────────────────────────────┐
│                     Presentation Layer                       │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  OrdersListScreen (ConsumerWidget)                   │   │
│  │  - Depends ONLY on IOrdersRepository interface      │   │
│  │  - No knowledge of data source type                 │   │
│  └─────────────────────────────────────────────────────┘   │
└────────────────────────┬────────────────────────────────────┘
                         │ ref.watch(ordersRepositoryProvider)
┌────────────────────────▼────────────────────────────────────┐
│                   Application Layer                          │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  OrdersNotifier                                       │  │
│  │  - Depends ONLY on IOrdersRepository interface       │  │
│  │  - Works with any repository implementation          │  │
│  └──────────────────────────────────────────────────────┘  │
└────────────────────────┬────────────────────────────────────┘
                         │ uses
┌────────────────────────▼────────────────────────────────────┐
│                    Repository Layer                          │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  IOrdersRepository (Interface)                        │  │
│  │  - Stable contract                                   │  │
│  │  - Multiple implementations                          │  │
│  └──────────────────────────────────────────────────────┘  │
│                           │                                  │
│         ┌─────────────────┼─────────────────┐              │
│         │                 │                 │              │
│  ┌──────▼──────┐   ┌──────▼──────┐   ┌──────▼──────┐     │
│  │   Mock      │   │    Live     │   │  Offline    │     │
│  │ Repository  │   │ Repository  │   │ Repository  │     │
│  └─────────────┘   └─────────────┘   └─────────────┘     │
└────────────────────────┬────────────────────────────────────┘
                         │ orchestrates
┌────────────────────────▼────────────────────────────────────┐
│                    Data Source Layer                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │    Mock      │  │   Remote     │  │    Local     │     │
│  │ Data Source  │  │ Data Source  │  │ Data Source  │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
```

---

## Repository Modes

### 1. Mock Mode (Development/Testing)

**Use Case**: Development, unit testing, UI prototyping

**Characteristics**:
- Uses in-memory mock data
- Simulates network latency
- Provides fake real-time updates
- Deterministic test scenarios

**Configuration**:
```dart
final repositoryModeProvider = Provider<RepositoryMode>((ref) {
  return RepositoryMode.mock;
});
```

**Benefits**:
- No backend required
- Fast development iteration
- Predictable test data
- Offline development

### 2. Live Mode (Production API)

**Use Case**: Production with stable internet connection

**Characteristics**:
- Direct API calls
- No local caching
- Real-time server data
- Requires network connectivity

**Configuration**:
```dart
final repositoryModeProvider = Provider<RepositoryMode>((ref) {
  return RepositoryMode.live;
});
```

**Benefits**:
- Always fresh data
- Simpler architecture
- No cache invalidation concerns

### 3. Offline-First Mode (Future)

**Use Case**: Production with offline support

**Characteristics**:
- Local database (Hive/Isar/SQLite)
- Sync queue for pending changes
- Conflict resolution
- Works offline

**Configuration**:
```dart
final repositoryModeProvider = Provider<RepositoryMode>((ref) {
  return RepositoryMode.offlineFirst;
});
```

**Benefits**:
- Works without internet
- Better UX (instant responses)
- Resilient to network issues
- Background sync

### 4. Hybrid Mode (Cache-First)

**Use Case**: Production with caching for performance

**Characteristics**:
- Cache-first strategy
- Background refresh
- Stale-while-revalidate pattern
- Requires network for writes

**Configuration**:
```dart
final repositoryModeProvider = Provider<RepositoryMode>((ref) {
  return RepositoryMode.hybrid;
});
```

**Benefits**:
- Fast initial load
- Reduced API calls
- Better performance
- Lower server costs

---

## File Structure

```
lib/
├── core/
│   └── data/
│       ├── repositories/
│       │   └── base/
│       │       └── base_repository.dart          # Generic interfaces
│       └── datasources/
│           └── base/
│               └── base_datasource.dart          # Data source interfaces
│
└── features/
    └── orders/
        ├── domain/
        │   └── models/
        │       ├── order.dart                    # Domain model
        │       ├── order_item.dart
        │       ├── order_status.dart
        │       └── money.dart
        │
        ├── data/
        │   ├── repositories/
        │   │   ├── orders_repository_interface.dart    # Stable contract
        │   │   ├── orders_repository_impl.dart         # Implementation
        │   │   └── orders_repository_factory.dart      # Factory
        │   │
        │   ├── datasources/
        │   │   ├── orders_remote_datasource.dart       # API calls
        │   │   ├── orders_local_datasource.dart        # Cache/DB
        │   │   └── orders_mock_datasource.dart         # Mock data
        │   │
        │   ├── mappers/
        │   │   └── order_mappers.dart                  # DTO ↔ Domain
        │   │
        │   └── providers/
        │       └── orders_repository_providers.dart    # Riverpod setup
        │
        └── application/
            ├── state/
            │   ├── orders_state.dart
            │   └── orders_notifier.dart
            └── providers/
                └── orders_providers.dart
```

---

## How to Switch Modes

### Method 1: Change Provider (Compile-Time)

```dart
// In orders_repository_providers.dart
final repositoryModeProvider = Provider<RepositoryMode>((ref) {
  return RepositoryMode.mock;  // Change this line
});
```

### Method 2: Environment Variable (Runtime)

```dart
final repositoryModeProvider = Provider<RepositoryMode>((ref) {
  const env = String.fromEnvironment('REPO_MODE', defaultValue: 'mock');
  
  switch (env) {
    case 'live':
      return RepositoryMode.live;
    case 'offline':
      return RepositoryMode.offlineFirst;
    case 'hybrid':
      return RepositoryMode.hybrid;
    default:
      return RepositoryMode.mock;
  }
});
```

Run with:
```bash
flutter run --dart-define=REPO_MODE=live
```

### Method 3: Feature Flag (Runtime)

```dart
final repositoryModeProvider = Provider<RepositoryMode>((ref) {
  final featureFlags = ref.watch(featureFlagsProvider);
  
  if (featureFlags.useOfflineMode) {
    return RepositoryMode.offlineFirst;
  } else if (featureFlags.useCaching) {
    return RepositoryMode.hybrid;
  } else {
    return RepositoryMode.live;
  }
});
```

### Method 4: Override for Testing

```dart
testWidgets('Orders list displays correctly', (tester) async {
  final mockRepo = MockOrdersRepository();
  
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ordersRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: MyApp(),
    ),
  );
  
  // Test with mock repository
});
```

---

## Usage Examples

### In UI Layer

```dart
class OrdersListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // UI depends ONLY on the interface
    // Works with any repository implementation
    final orders = ref.watch(ordersProvider);
    
    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) => OrderCard(order: orders[index]),
    );
  }
}
```

### In Business Logic Layer

```dart
class OrdersNotifier extends StateNotifier<OrdersState> {
  final IOrdersRepository _repository;  // Interface, not implementation
  
  OrdersNotifier(this._repository) : super(OrdersState.initial());
  
  Future<void> loadOrders(String tenantId) async {
    // Works with mock, live, or offline repository
    final result = await _repository.getOrders(tenantId);
    
    result.fold(
      (orders) => state = state.copyWith(orders: orders),
      (error) => state = state.copyWith(error: error),
    );
  }
}
```

### Creating Orders

```dart
// Same code works in all modes
final notifier = ref.read(ordersStateProvider.notifier);

final order = Order(
  id: '',
  tenantId: 'tenant-1',
  tableId: 'table-1',
  // ...
);

final result = await notifier.createOrder(order);

result.fold(
  (created) => print('Order created: ${created.id}'),
  (error) => print('Error: $error'),
);
```

---

## Migration Path

### Phase 1: Current (Mock Mode) ✅

```dart
RepositoryMode.mock
```

- Development with mock data
- No backend required
- Fast iteration

### Phase 2: Add Live API

```dart
RepositoryMode.live
```

1. Implement `OrdersRestDataSource`
2. Configure API base URL
3. Change mode to `live`
4. **Zero UI changes required**

### Phase 3: Add Caching

```dart
RepositoryMode.hybrid
```

1. Keep live API
2. Add local data source
3. Change mode to `hybrid`
4. **Zero UI changes required**

### Phase 4: Full Offline Support

```dart
RepositoryMode.offlineFirst
```

1. Implement sync queue
2. Add conflict resolution
3. Change mode to `offlineFirst`
4. **Zero UI changes required**

---

## Testing Strategy

### Unit Testing Repositories

```dart
void main() {
  group('OrdersRepositoryImpl', () {
    late OrdersRepositoryImpl repository;
    late MockOrdersMockDataSource mockDataSource;

    setUp(() {
      mockDataSource = MockOrdersMockDataSource();
      repository = OrdersRepositoryImpl(mockDataSource: mockDataSource);
    });

    test('getOrders returns orders from mock source', () async {
      // Arrange
      final mockOrders = [/* mock data */];
      when(() => mockDataSource.getMockByTenant(any()))
          .thenAnswer((_) async => mockOrders);

      // Act
      final result = await repository.getOrders('tenant-1');

      // Assert
      expect(result.isSuccess, true);
      expect(result.valueOrNull?.length, mockOrders.length);
    });
  });
}
```

### Widget Testing with Mock Repository

```dart
testWidgets('OrdersListScreen displays orders', (tester) async {
  final mockRepo = MockOrdersRepository();
  when(() => mockRepo.getOrders(any())).thenAnswer(
    (_) async => Result.success([/* test orders */]),
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ordersRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: MaterialApp(home: OrdersListScreen()),
    ),
  );

  await tester.pumpAndSettle();

  expect(find.byType(OrderCard), findsWidgets);
});
```

### Integration Testing

```dart
void main() {
  testWidgets('Full flow with mock repository', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryModeProvider.overrideWithValue(RepositoryMode.mock),
        ],
        child: MyApp(),
      ),
    );

    // Test complete user flow
    await tester.tap(find.text('Create Order'));
    await tester.pumpAndSettle();
    
    // Verify order was created
    expect(find.text('Order Created'), findsOneWidget);
  });
}
```

---

## Anti-Patterns to Avoid

### ❌ DON'T: Expose DTOs to UI

```dart
// BAD
class OrdersListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersDto = ref.watch(ordersDtoProvider);  // ❌ DTO in UI
    return ListView(/* ... */);
  }
}
```

### ✅ DO: Use Domain Models

```dart
// GOOD
class OrdersListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);  // ✅ Domain model
    return ListView(/* ... */);
  }
}
```

### ❌ DON'T: Hardcode Data Source

```dart
// BAD
class OrdersNotifier extends StateNotifier<OrdersState> {
  final mockRepo = MockOrdersRepository();  // ❌ Hardcoded
  
  Future<void> loadOrders() async {
    final orders = await mockRepo.getOrders();
  }
}
```

### ✅ DO: Inject via Constructor

```dart
// GOOD
class OrdersNotifier extends StateNotifier<OrdersState> {
  final IOrdersRepository _repository;  // ✅ Injected interface
  
  OrdersNotifier(this._repository) : super(OrdersState.initial());
  
  Future<void> loadOrders() async {
    final result = await _repository.getOrders();
  }
}
```

### ❌ DON'T: Mix Data Sources in UI

```dart
// BAD
class OrdersListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(networkStatusProvider);
    
    final orders = isOnline
        ? ref.watch(remoteOrdersProvider)  // ❌ UI knows about sources
        : ref.watch(localOrdersProvider);
    
    return ListView(/* ... */);
  }
}
```

### ✅ DO: Let Repository Handle It

```dart
// GOOD
class OrdersListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Repository handles source selection
    final orders = ref.watch(ordersProvider);  // ✅ Single source of truth
    
    return ListView(/* ... */);
  }
}
```

---

## Production Checklist

### Before Switching to Live Mode

- [ ] Implement `OrdersRestDataSource`
- [ ] Configure API base URL
- [ ] Add authentication headers
- [ ] Implement error handling
- [ ] Add retry logic
- [ ] Test with staging API
- [ ] Verify DTO mapping
- [ ] Test real-time updates (if applicable)
- [ ] Load test with production data volume
- [ ] Monitor API performance

### Before Enabling Offline Mode

- [ ] Implement local database (Hive/Isar/SQLite)
- [ ] Implement sync queue
- [ ] Add conflict resolution
- [ ] Test offline scenarios
- [ ] Test sync after reconnection
- [ ] Handle partial sync failures
- [ ] Test with large datasets
- [ ] Implement background sync
- [ ] Add sync status UI
- [ ] Test battery impact

---

## Benefits Achieved

✅ **Flexibility** - Switch data sources in seconds  
✅ **Testability** - Easy to mock for testing  
✅ **Maintainability** - Clear separation of concerns  
✅ **Scalability** - Add new sources without breaking existing code  
✅ **Team Velocity** - Frontend and backend can work independently  
✅ **Future-Proof** - Ready for offline-first evolution  
✅ **Type Safety** - Compile-time guarantees  
✅ **Clean Code** - Follows SOLID principles  

---

## Next Steps

1. ✅ **Current**: Mock mode working
2. **Next**: Implement REST data source
3. **Then**: Add caching layer
4. **Future**: Full offline support

The architecture is ready for all these phases without requiring refactoring!
