# Offline-First Architecture - Quick Reference

## 📋 Document Status

**Main Specification**: `offline-first-architecture-spec.md` (Sections 1-3 Complete)

**Completed Sections**:
- ✅ Executive Summary
- ✅ Architecture Philosophy  
- ✅ Recommended Architecture Style

**Remaining Sections** (To be added):
- State Management Strategy
- Serializable State Rules
- Immutable Domain Model Design
- Event-Driven State Flow
- Offline-Ready Data Flow
- Repository Architecture
- Riverpod Production Guidelines
- UI State vs Business State
- Real-Time Event Architecture
- Failure Recovery Design
- Serialization Strategy
- Debugging & Observability
- Performance Architecture
- Testing Strategy
- Code Standards
- Anti-Patterns
- Production Checklist
- Final Recommendations

## 🎯 Key Architectural Principles

### 1. Serializable State ALWAYS
```dart
// ✅ GOOD
@freezed
class OrderState with _$OrderState {
  const factory OrderState({
    required String orderId,
    required OrderStatus status,
    required List<OrderItemDto> items,
  }) = _OrderState;
  
  factory OrderState.fromJson(Map<String, dynamic> json);
}

// ❌ BAD
class OrderState {
  final Stream<Order> stream;  // Not serializable
  final TextEditingController controller;  // Widget dependency
}
```

### 2. Immutable State ALWAYS
```dart
// ✅ GOOD
final newState = state.copyWith(status: OrderStatus.completed);

// ❌ BAD
state.status = OrderStatus.completed;  // Mutation
```

### 3. Event-Driven Updates
```dart
// ✅ GOOD
void handleEvent(OrderEvent event) {
  state = event.when(
    itemAdded: (item) => state.copyWith(items: [...state.items, item]),
    statusChanged: (status) => state.copyWith(status: status),
  );
}

// ❌ BAD
void addItem(OrderItem item) {
  state.items.add(item);  // Direct mutation
}
```

### 4. DTO Separation
```dart
// API Layer
class OrderDto { }  // Matches API contract

// Domain Layer  
class Order { }  // Business logic optimized

// Mapper
extension OrderDtoMapper on OrderDto {
  Order toDomain() => Order(...);
}
```

## 📁 Folder Structure

```
lib/
├── features/
│   └── orders/
│       ├── data/          # DTOs, repositories, datasources
│       ├── domain/        # Models, events, use cases
│       ├── application/   # Providers, state, notifiers
│       └── presentation/  # Screens, widgets
├── core/                  # Shared infrastructure
└── shared/                # Shared business logic
```

## 🔄 State Flow Pattern

```
User Action → Event → Reducer → New State → UI Update
```

## 🚫 Forbidden in State

- ❌ Streams
- ❌ Controllers (TextEditingController, AnimationController)
- ❌ Futures
- ❌ BuildContext
- ❌ Functions/Closures
- ❌ Widget references

## ✅ Allowed in State

- ✅ Primitives (String, int, double, bool)
- ✅ DTOs (with fromJson/toJson)
- ✅ Enums
- ✅ Immutable collections (List, Map, Set)
- ✅ DateTime
- ✅ Nested serializable objects

## 🎯 Provider Patterns

```dart
// 1. Repository Provider
final ordersRepositoryProvider = Provider<OrdersRepository>(...);

// 2. State Provider
final ordersStateProvider = StateNotifierProvider<OrdersNotifier, OrdersState>(...);

// 3. Derived Provider
final activeOrdersProvider = Provider<List<Order>>((ref) {
  return ref.watch(ordersStateProvider).orders.where(...).toList();
});

// 4. Family Provider
final orderByIdProvider = Provider.family<Order?, String>((ref, id) {
  return ref.watch(ordersStateProvider).orders.firstWhere(...);
});
```

## 🔍 Quick Checklist

Before committing code, verify:

- [ ] All state classes have `fromJson`/`toJson`
- [ ] No mutable state
- [ ] No Streams/Controllers in state
- [ ] Events defined for all state changes
- [ ] DTOs separated from domain models
- [ ] Providers follow naming conventions
- [ ] State transitions are deterministic
- [ ] Business logic in domain layer, not widgets

## 📚 Next Steps

1. Review completed sections in `offline-first-architecture-spec.md`
2. Request completion of remaining sections as needed
3. Implement architecture incrementally per feature
4. Use this as reference during code reviews

## 🆘 Need Help?

- **Full Spec**: See `offline-first-architecture-spec.md`
- **Questions**: Refer to specific sections
- **Examples**: Check existing `orders/` feature implementation
- **Updates**: Request additional sections as needed

---

**Last Updated**: 2026-05-21  
**Version**: 1.0.0
