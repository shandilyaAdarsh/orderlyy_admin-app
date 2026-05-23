import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import '../../../menu/domain/entities/menu_snapshot.dart';
import '../../../menu/presentation/state/menu_providers.dart';
import '../../../persistence/data/datasources/cart_local_datasource.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/cart_state.dart';
import '../../domain/services/pricing_snapshot_engine.dart';
import '../../../../core/providers/repository_providers.dart';

// Provide CartLocalDataSource
final cartLocalDataSourceProvider = Provider<CartLocalDataSource>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return CartLocalDataSource(prefs);
});

// Provide CartState notifier
final cartStateProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  final branchId = ref.watch(branchIdProvider);
  final activeMenuAsync = ref.watch(menuProjectionProvider);
  final persistence = ref.watch(cartLocalDataSourceProvider);

  final activeVersion = activeMenuAsync.maybeWhen(
    data: (snapshot) => snapshot.snapshotVersion ?? 'v0',
    orElse: () => 'v0',
  );

  final notifier = CartNotifier(
    branchId: branchId,
    menuSnapshotVersion: activeVersion,
    persistence: persistence,
  );

  // Read snapshot if loaded
  activeMenuAsync.whenData((snapshot) {
    notifier.handleMenuUpdate(snapshot);
  });

  return notifier;
});

class CartNotifier extends StateNotifier<CartState> {
  final CartLocalDataSource _persistence;

  CartNotifier({
    required String branchId,
    required String menuSnapshotVersion,
    required CartLocalDataSource persistence,
  })  : _persistence = persistence,
        super(_loadInitialState(branchId, menuSnapshotVersion, persistence));

  static CartState _loadInitialState(
    String branchId,
    String menuSnapshotVersion,
    CartLocalDataSource persistence,
  ) {
    final cached = persistence.getCartSync();
    if (cached != null) {
      if (cached.branchId == branchId) {
        return cached;
      } else {
        // Discard if branch changed
        persistence.clearCart();
      }
    }
    return CartState.initial(branchId, menuSnapshotVersion);
  }

  /// Automatically called when menu projection is loaded or updated
  void handleMenuUpdate(MenuSnapshot snapshot) {
    if (state.items.isEmpty) {
      state = state.copyWith(menuSnapshotVersion: snapshot.snapshotVersion ?? 'v0');
      return;
    }

    // Detect drift
    final driftResult = PricingSnapshotEngine.detectDrift(
      cartState: state,
      currentProjection: snapshot,
    );

    state = state.copyWith(
      menuSnapshotVersion: snapshot.snapshotVersion ?? 'v0',
      hasStalePrices: driftResult.hasDrift,
    );
    _persistence.saveCart(state);
  }

  void addItem(
    MenuItem item,
    List<ModifierOption> modifiers, {
    String specialInstructions = '',
    int quantity = 1,
  }) {
    if (quantity <= 0) return;

    final sortedModIds = modifiers.map((m) => m.id).toList()..sort();
    final cartItemId = '${item.id}_${sortedModIds.join(",")}';

    final existingIndex = state.items.indexWhere((i) => i.cartItemId == cartItemId);

    List<CartItem> newItems;
    if (existingIndex != -1) {
      final existingItem = state.items[existingIndex];
      final newQuantity = (existingItem.quantity + quantity).clamp(1, 99);
      newItems = List<CartItem>.from(state.items);
      newItems[existingIndex] = existingItem.copyWith(quantity: newQuantity);
    } else {
      final selectedMods = modifiers
          .map((m) => SelectedModifier(
                modifierOptionId: m.id,
                name: m.name,
                price: m.price,
              ))
          .toList();

      final newItem = CartItem(
        cartItemId: cartItemId,
        menuItemId: item.id,
        name: item.name,
        snapshotUnitPrice: item.price,
        quantity: quantity.clamp(1, 99),
        selectedModifiers: selectedMods,
        specialInstructions: specialInstructions,
        snapshotVersion: state.menuSnapshotVersion,
      );

      newItems = List<CartItem>.from(state.items)..add(newItem);
    }

    state = state.copyWith(items: newItems, errorMessage: null);
    _persistence.saveCart(state);
  }

  void removeItem(String cartItemId) {
    final newItems = state.items.where((i) => i.cartItemId != cartItemId).toList();
    state = state.copyWith(items: newItems, errorMessage: null);

    // If cart becomes empty, reset stale pricing flag
    if (newItems.isEmpty) {
      state = state.copyWith(hasStalePrices: false);
    }
    _persistence.saveCart(state);
  }

  void updateQuantity(String cartItemId, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(cartItemId);
      return;
    }

    final existingIndex = state.items.indexWhere((i) => i.cartItemId == cartItemId);
    if (existingIndex == -1) return;

    final newItems = List<CartItem>.from(state.items);
    newItems[existingIndex] = newItems[existingIndex].copyWith(
      quantity: newQuantity.clamp(1, 99),
    );

    state = state.copyWith(items: newItems, errorMessage: null);
    _persistence.saveCart(state);
  }

  void clearCart() {
    state = CartState.initial(state.branchId, state.menuSnapshotVersion);
    _persistence.clearCart();
  }

  void reconcilePrices(MenuSnapshot newProjection) {
    final updatedItems = <CartItem>[];

    for (final item in state.items) {
      final activeItem = newProjection.items.firstWhereOrNull((i) => i.id == item.menuItemId);
      if (activeItem == null || !activeItem.isAvailable) {
        // Item is no longer available; remove it from reconciled cart
        continue;
      }

      final updatedMods = <SelectedModifier>[];
      for (final mod in item.selectedModifiers) {
        ModifierOption? activeOption;
        for (final group in newProjection.modifierGroups) {
          final opt = group.options.firstWhereOrNull((o) => o.id == mod.modifierOptionId);
          if (opt != null) {
            activeOption = opt;
            break;
          }
        }
        if (activeOption != null) {
          updatedMods.add(SelectedModifier(
            modifierOptionId: mod.modifierOptionId,
            name: mod.name,
            price: activeOption.price,
          ));
        }
      }

      updatedItems.add(item.copyWith(
        snapshotUnitPrice: activeItem.price,
        selectedModifiers: updatedMods,
        snapshotVersion: newProjection.snapshotVersion ?? 'v0',
      ));
    }

    state = state.copyWith(
      items: updatedItems,
      menuSnapshotVersion: newProjection.snapshotVersion ?? 'v0',
      hasStalePrices: false,
      errorMessage: null,
    );
    _persistence.saveCart(state);
  }
}
