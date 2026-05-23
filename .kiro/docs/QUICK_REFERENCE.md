# Quick Reference - Swappable Repository Architecture

## 🚀 Quick Start

### Run the App
```bash
flutter run -d chrome
```

### Switch Repository Mode
**File**: `lib/features/orders/data/providers/orders_repository_providers.dart`

```dart
final repositoryModeProvider = Provider<RepositoryMode>((ref) {
  return RepositoryMode.mock;  // ← Change this line
});
```

**Options**:
- `RepositoryMode.mock` - Development (current)
- `RepositoryMode.live` - Production API
- `RepositoryMode.hybrid` - Cache + API
- `RepositoryMode.offlineFirst` - Full offline

## 📁 Key Files

### Repository Interface (Stable Contract)
```
lib/features/orders/data/repositories/orders_repository_interface.dart
```
**Never changes!** UI and business logic depend on this.

### Repository Implementation
```
lib/features/orders/data/repositories/orders_repository_impl.dart
```
Orchestrates between data sources.

### Data Sources
```
lib/features/orders/data/datasources/
├── orders_mock_datasource.dart      ← Currently active
├── orders_local_datasource.dart     ← Cache/offline
└── orders_remote_datasource.dart    ← REST API (implement this)
```

### Business Logic
```
lib/features/orders/application/state/orders_notifier.dart
```
Uses `IOrdersRepository` - doesn't know which implementation.

### Providers
```
lib/features/orders/data/providers/orders_repository_providers.dart
```
Riverpod wiring - switch modes here.

## 🔧 Common Tasks

### Add a New Repository Method

1. **Add to interface**:
```dart
// In orders_repository_interface.dart
abstract class IOrdersRepository {
  Future<Result<Order, AppFailure>> getOrderById(String id);
  Future<Result<List<Order>, AppFailure>> searchOrders(String query); // ← New
}
```

2. **Implement in repository**:
```dart
// In orders_repository_impl.dart
@override
Future<Result<List<Order>, AppFailure>> searchOrders(String query) async {
  if (_isMockMode) {
    final dtos = await _mockDataSource!.mockSearch(query);
    return Result.success(dtos.map((dto) => dto.toDomain()).toList());
  }
  // Handle other modes...
}
```

3. **Add to data sources**:
```dart
// In orders_mock_datasource.dart
Future<List<OrderDto>> mockSearch(String query) async {
  await simulateLatency();
  return _mockOrders.where((o) => 
    o.tableLabel.contains(query) || o.notes?.contains(query) == true
  ).toList();
}
```

4. **Use in notifier**:
```dart
// In orders_notifier.dart
Future<void> searchOrders(String query) async {
  state = state.copyWith(status: LoadingStatus.loading);
  final result = await _repository.searchOrders(query);
  result.fold(
    (orders) => state = state.copyWith(orders: orders, status: LoadingStatus.success),
    (error) => state = state.copyWith(error: error, status: LoadingStatus.error),
  );
}
```

**Done!** Works in all modes.

### Implement REST Data Source

```dart
// In orders_remote_datasource.dart
class OrdersRestDataSourceImpl extends OrdersRestDataSource {
  final http.Client _client;
  final String _baseUrl;

  OrdersRestDataSourceImpl(this._client, this._baseUrl);

  @override
  Future<List<OrderDto>> fetchAll(Map<String, dynamic> params) async {
    final uri = Uri.parse('$_baseUrl/orders').replace(queryParameters: params);
    final response = await _client.get(uri);
    
    if (response.statusCode == 200) {
      final List<dynamic> json = jsonDecode(response.body);
      return json.map((e) => OrderDto.fromJson(e)).toList();
    }
    
    throw Exception('Failed to fetch orders: ${response.statusCode}');
  }

  @override
  Future<OrderDto> fetchById(String id) async {
    final response = await _client.get(Uri.parse('$_baseUrl/orders/$id'));
    
    if (response.statusCode == 200) {
      return OrderDto.fromJson(jsonDecode(response.body));
    }
    
    throw Exception('Failed to fetch order: ${response.statusCode}');
  }

  @override
  Future<OrderDto> create(OrderDto dto) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/orders'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(dto.toJson()),
    );
    
    if (response.statusCode == 201) {
      return OrderDto.fromJson(jsonDecode(response.body));
    }
    
    throw Exception('Failed to create order: ${response.statusCode}');
  }

  // Implement other methods...
}
```

Then switch mode:
```dart
return RepositoryMode.live;
```

### Add Caching

```dart
// In orders_local_datasource.dart
class OrdersHiveDataSource extends OrdersLocalDataSource {
  final Box<OrderDto> _box;

  OrdersHiveDataSource(this._box);

  @override
  Future<List<OrderDto>> getByTenant(String tenantId) async {
    return _box.values
        .where((dto) => dto.tenantId == tenantId)
        .toList();
  }

  @override
  Future<void> saveAll(List<OrderDto> dtos) async {
    for (final dto in dtos) {
      await _box.put(dto.id, dto);
    }
  }

  // Implement other methods...
}
```

Then switch mode:
```dart
return RepositoryMode.hybrid;
```

## 🧪 Testing

### Unit Test Repository
```dart
test('Repository returns orders', () async {
  final mockDataSource = MockOrdersDataSource();
  final repo = OrdersRepositoryImpl(mockDataSource: mockDataSource);
  
  final result = await repo.getOrders('tenant-1');
  
  expect(result.isSuccess, true);
  expect(result.value, isNotEmpty);
});
```

### Widget Test with Mock Repository
```dart
testWidgets('Orders screen displays orders', (tester) async {
  final mockRepo = MockOrdersRepository();
  when(() => mockRepo.getOrders(any()))
      .thenAnswer((_) async => Result.success([testOrder]));
  
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ordersRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: OrdersListScreen(),
    ),
  );
  
  expect(find.text('Test Order'), findsOneWidget);
});
```

### Integration Test
```dart
testWidgets('Can switch repository modes', (tester) async {
  // Test with mock
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        repositoryModeProvider.overrideWithValue(RepositoryMode.mock),
      ],
      child: MyApp(),
    ),
  );
  
  expect(find.byType(OrderCard), findsWidgets);
  
  // Switch to live (in real test, would use test server)
  // ...
});
```

## 🐛 Debugging

### Check Current Repository Mode
```dart
// In any widget
final mode = ref.watch(repositoryModeProvider);
print('Current mode: $mode');
```

### Check Repository Type
```dart
final repo = ref.watch(ordersRepositoryProvider);
print('Repository type: ${repo.runtimeType}');
```

### Monitor Repository Calls
Add logging to `OrdersRepositoryImpl`:
```dart
@override
Future<Result<List<Order>, AppFailure>> getOrders(String tenantId) async {
  print('📦 Repository: getOrders called for tenant: $tenantId');
  print('📦 Mode: ${_isMockMode ? "Mock" : "Live"}');
  
  // ... rest of implementation
}
```

### Check Data Source
```dart
// In orders_mock_datasource.dart
Future<List<OrderDto>> getMockData() async {
  print('🎭 Mock: Returning ${_mockOrders.length} orders');
  await simulateLatency();
  return List.from(_mockOrders);
}
```

## 📊 Performance Tips

### Mock Mode
- ✅ Instant startup
- ✅ No network calls
- ✅ Predictable latency
- ⚠️ No real data

### Live Mode
- ⚠️ Network dependent
- ⚠️ API rate limits
- ✅ Real data
- ⚠️ No offline support

### Hybrid Mode
- ✅ Fast cache hits
- ✅ Background refresh
- ✅ Offline capable
- ⚠️ Cache invalidation needed

### Offline-First Mode
- ✅ Fastest (local DB)
- ✅ Full offline
- ✅ Sync when online
- ⚠️ Conflict resolution needed

## 🔍 Troubleshooting

### Analyzer Errors
```bash
# Restart analysis server
Ctrl+Shift+P → "Dart: Restart Analysis Server"

# Or clean and rebuild
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### App Won't Compile
```bash
# Check generated files exist
Get-ChildItem -Path "lib\features\orders\domain\models\" -Filter "*.freezed.dart"

# Regenerate if missing
dart run build_runner build --delete-conflicting-outputs
```

### No Data Showing
```dart
// Check repository mode
final mode = ref.watch(repositoryModeProvider);
print('Mode: $mode');  // Should be RepositoryMode.mock

// Check mock data
final mockSource = OrdersMockDataSource();
final data = await mockSource.getMockData();
print('Mock orders: ${data.length}');  // Should be > 0
```

### State Not Persisting
```dart
// Check LocalStorage initialized
// In main.dart
await LocalStorage.initialize();

// Check state persistence provider
final persistence = ref.watch(statePersistenceProvider);
print('Persistence: ${persistence != null}');  // Should be true
```

## 📚 Documentation

- **Architecture**: `.kiro/docs/architecture/SWAPPABLE_REPOSITORY_ARCHITECTURE.md`
- **Implementation**: `.kiro/docs/architecture/REPOSITORY_IMPLEMENTATION_SUMMARY.md`
- **Status**: `.kiro/docs/architecture/INTEGRATION_STATUS.md`
- **Complete**: `.kiro/docs/architecture/INTEGRATION_COMPLETE.md`
- **Troubleshooting**: `.kiro/docs/TROUBLESHOOTING.md`

## 🎯 Cheat Sheet

| Task | Command/Location |
|------|------------------|
| Run app | `flutter run -d chrome` |
| Switch mode | `orders_repository_providers.dart` line 18 |
| Add method | 1. Interface → 2. Impl → 3. Data sources |
| Test | `flutter test` |
| Analyze | `flutter analyze` |
| Format | `dart format .` |
| Generate | `dart run build_runner build` |
| Clean | `flutter clean` |

## 💡 Pro Tips

1. **Always update interface first** - Ensures contract stability
2. **Use Result type** - Better error handling than exceptions
3. **Optimistic updates** - Better UX, rollback on error
4. **Mock latency** - Realistic development experience
5. **Test mode switching** - Verify architecture flexibility

---

**Quick Help**: See `.kiro/docs/TROUBLESHOOTING.md`
**Full Docs**: See `.kiro/docs/architecture/`
