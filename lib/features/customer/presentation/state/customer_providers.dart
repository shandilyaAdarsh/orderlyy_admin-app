// lib/features/customer/presentation/state/customer_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/uuid.dart';
import '../../../menu/domain/entities/menu_snapshot.dart';
import '../../../orders/domain/entities/menu_product.dart' as orders_entities;
import '../../../orders/domain/entities/order.dart';
import '../../../orders/domain/entities/order_item.dart';
import '../../../orders/providers/orders_providers.dart';
import '../../../tables/domain/entities/restaurant_table.dart';
import '../../../tables/providers/tables_providers.dart';
import '../../domain/entities/customer_session.dart';

class CustomerSessionNotifier extends StateNotifier<CustomerSession?> {
  final Ref _ref;

  CustomerSessionNotifier(this._ref) : super(null);

  void initializeSession(String tenantId, String branchId, String tableId) {
    state = CustomerSession(
      tenantId: tenantId,
      branchId: branchId,
      tableId: tableId,
      cart: const [],
    );
  }

  void addToCart(MenuItem item, int quantity, List<ModifierOption> modifiers) {
    if (state == null) return;

    final currentCart = List<CartItem>.from(state!.cart);

    // Check if item with same ID and same modifiers already exists in cart
    final index = currentCart.indexWhere((ci) {
      if (ci.item.id != item.id) return false;
      if (ci.selectedModifiers.length != modifiers.length) return false;
      final modIds = modifiers.map((m) => m.id).toSet();
      final cartModIds = ci.selectedModifiers.map((m) => m.id).toSet();
      return modIds.difference(cartModIds).isEmpty;
    });

    if (index != -1) {
      currentCart[index] = currentCart[index].copyWith(
        quantity: currentCart[index].quantity + quantity,
      );
    } else {
      currentCart.add(CartItem(
        id: UuidGenerator.generateV4(),
        item: item,
        quantity: quantity,
        selectedModifiers: modifiers,
      ));
    }

    state = state!.copyWith(cart: currentCart);
  }

  void updateQuantity(String cartItemId, int change) {
    if (state == null) return;

    final currentCart = List<CartItem>.from(state!.cart);
    final index = currentCart.indexWhere((ci) => ci.id == cartItemId);
    if (index == -1) return;

    final newQuantity = currentCart[index].quantity + change;
    if (newQuantity <= 0) {
      currentCart.removeAt(index);
    } else {
      currentCart[index] = currentCart[index].copyWith(quantity: newQuantity);
    }

    state = state!.copyWith(cart: currentCart);
  }

  void clearCart() {
    if (state == null) return;
    state = state!.copyWith(cart: const []);
  }

  Future<void> checkout() async {
    if (state == null || state!.cart.isEmpty) return;

    final repository = _ref.read(ordersRepositoryProvider);
    final updateTableStatus = _ref.read(updateTableStatusUseCaseProvider);
    final tableId = state!.tableId;

    // Fetch existing active order or create new one
    var activeOrder = await repository.getActiveOrderForTable(tableId);
    bool isNewOrder = false;

    if (activeOrder == null) {
      isNewOrder = true;
      activeOrder = Order(
        id: UuidGenerator.generateV4(),
        tableId: tableId,
        items: const [],
        status: OrderStatus.sent,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    final newItems = List<OrderItem>.from(activeOrder.items);
    for (final cartItem in state!.cart) {
      // Map to legacy MenuProduct for system compatibility
      final menuProduct = orders_entities.MenuProduct(
        id: cartItem.item.id,
        name: cartItem.item.name,
        price: cartItem.item.price,
        category: '',
        availableModifiers: const [],
      );

      // Check if duplicate item exists in active order items
      final existingIndex = newItems.indexWhere((oi) {
        if (oi.product.id != menuProduct.id) return false;
        if (oi.selectedModifiers.length != cartItem.selectedModifiers.length) return false;
        final modIds = cartItem.selectedModifiers.map((m) => m.id).toSet();
        final orderModIds = oi.selectedModifiers.map((m) => m.id).toSet();
        return modIds.difference(orderModIds).isEmpty;
      });

      if (existingIndex != -1) {
        newItems[existingIndex] = newItems[existingIndex].copyWith(
          quantity: newItems[existingIndex].quantity + cartItem.quantity,
        );
      } else {
        newItems.add(OrderItem(
          id: UuidGenerator.generateV4(),
          product: menuProduct,
          quantity: cartItem.quantity,
          selectedModifiers: cartItem.selectedModifiers.map((m) => orders_entities.ModifierOption(
            id: m.id,
            name: m.name,
            price: m.price,
          )).toList(),
          seatNumber: 1, // Default customer seat
          status: OrderItemStatus.queued,
        ));
      }
    }

    // Save order with sent status (meaning it's dispatched to kitchen queue)
    final updatedOrder = activeOrder.copyWith(
      items: newItems,
      status: OrderStatus.sent,
      updatedAt: DateTime.now(),
    );

    await repository.saveOrder(updatedOrder);

    // If new order, update table status to occupied and link order ID
    if (isNewOrder) {
      await updateTableStatus(tableId, TableStatus.occupied, orderId: updatedOrder.id);
    } else {
      await updateTableStatus(tableId, TableStatus.occupied);
    }

    // Empty cart
    clearCart();
  }
}

final customerSessionProvider = StateNotifierProvider<CustomerSessionNotifier, CustomerSession?>((ref) {
  return CustomerSessionNotifier(ref);
});
