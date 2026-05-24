// lib/features/orders/runtime/cart_runtime.dart
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';
import '../../menu/domain/entities/menu_snapshot.dart';
import 'mutation_journal_service.dart';

class CartItem {
  final String id;
  final MenuItem menuItem;
  final List<ModifierOption> selectedOptions;
  final int quantity;

  const CartItem({
    required this.id,
    required this.menuItem,
    required this.selectedOptions,
    required this.quantity,
  });

  CartItem copyWith({int? quantity}) {
    return CartItem(
      id: id,
      menuItem: menuItem,
      selectedOptions: selectedOptions,
      quantity: quantity ?? this.quantity,
    );
  }
}

class CartState {
  final List<CartItem> items;
  final MenuSnapshot? frozenSnapshot;
  final bool isFrozen;

  const CartState({
    this.items = const [],
    this.frozenSnapshot,
    this.isFrozen = false,
  });

  CartState copyWith({
    List<CartItem>? items,
    MenuSnapshot? frozenSnapshot,
    bool? isFrozen,
  }) {
    return CartState(
      items: items ?? this.items,
      frozenSnapshot: frozenSnapshot ?? this.frozenSnapshot,
      isFrozen: isFrozen ?? this.isFrozen,
    );
  }
}

class CartRuntime extends StateNotifier<CartState> {
  final MutationJournalService _journal;
  final Talker _talker;

  CartRuntime(this._journal, this._talker) : super(const CartState());

  /// Optimistically adds an item to the cart and queues a mutation.
  Future<void> addItem(CartItem item) async {
    if (state.isFrozen) {
      _talker.warning('[CartRuntime] Cannot modify frozen cart.');
      return;
    }

    final mutationId = 'mutation_${DateTime.now().millisecondsSinceEpoch}';
    final payload = jsonEncode({'action': 'ADD_ITEM', 'itemId': item.id});

    // Write to SQLite journal immediately
    await _journal.appendMutation(mutationId: mutationId, payload: payload);

    // Apply optimistic local state
    state = state.copyWith(items: [...state.items, item]);
  }

  /// Freezes the cart against a specific authoritative snapshot version.
  /// Prevents any further mutations and anchors pricing against the snapshot.
  void freezeForCheckout(MenuSnapshot authoritativeSnapshot) {
    _talker.info(
      '[CartRuntime] Freezing cart against snapshot version: '
      '${authoritativeSnapshot.snapshotVersion}'
    );
    state = state.copyWith(
      isFrozen: true,
      frozenSnapshot: authoritativeSnapshot,
    );
  }

  /// Unfreezes the cart, usually if checkout fails or is cancelled.
  void unfreeze() {
    _talker.info('[CartRuntime] Unfreezing cart.');
    state = state.copyWith(isFrozen: false, frozenSnapshot: null);
  }

  /// Clears the cart safely.
  void clear() {
    state = const CartState();
  }
}
