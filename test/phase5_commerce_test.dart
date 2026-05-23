import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:orderlli_admin/shared/models/money.dart';
import 'package:orderlli_admin/core/providers/repository_providers.dart';
import 'package:orderlli_admin/core/data/dtos/order_dto.dart';
import 'package:orderlli_admin/features/cart/domain/entities/cart_item.dart';
import 'package:orderlli_admin/features/cart/domain/entities/cart_state.dart';
import 'package:orderlli_admin/features/cart/domain/services/pricing_snapshot_engine.dart';
import 'package:orderlli_admin/features/cart/presentation/state/cart_notifier.dart';
import 'package:orderlli_admin/features/checkout/presentation/state/checkout_notifier.dart';
import 'package:orderlli_admin/features/polling/data/services/polling_bridge_service.dart';
import 'package:orderlli_admin/features/menu/domain/entities/menu_snapshot.dart';
import 'package:orderlli_admin/features/menu/presentation/state/menu_providers.dart';
import 'package:orderlli_admin/features/persistence/data/datasources/cart_local_datasource.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  final testMenuSnapshot = MenuSnapshot(
    categories: const [
      MenuCategory(id: 'cat_burgers', name: 'Burgers', sortOrder: 1),
    ],
    items: const [
      MenuItem(
        id: 'item_burger',
        categoryId: 'cat_burgers',
        name: 'Classic Cheeseburger',
        description: 'Cheesy and delicious',
        price: Money(amountInCents: 1000),
        isAvailable: true,
        modifierGroupIds: ['group_addons'],
      ),
      MenuItem(
        id: 'item_fries',
        categoryId: 'cat_burgers',
        name: 'French Fries',
        description: 'Crispy',
        price: Money(amountInCents: 300),
        isAvailable: true,
        modifierGroupIds: [],
      ),
    ],
    modifierGroups: const [
      ModifierGroup(
        id: 'group_addons',
        name: 'Add-ons',
        options: [
          ModifierOption(id: 'opt_cheese', name: 'Extra Cheese', price: Money(amountInCents: 150)),
          ModifierOption(id: 'opt_bacon', name: 'Extra Bacon', price: Money(amountInCents: 200)),
        ],
      ),
    ],
    taxConfig: const TaxConfig(vatRate: 0.1, serviceChargeRate: 0.05),
    snapshotVersion: 'v1_test',
    branchId: 'br_test',
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('Cart Item Entity & Model Tests', () {
    test('Calculates cart item line totals correctly with modifiers and quantity', () {
      final item = CartItem(
        cartItemId: 'item-123',
        menuItemId: 'item_burger',
        name: 'Classic Cheeseburger',
        snapshotUnitPrice: const Money(amountInCents: 1000),
        quantity: 2,
        selectedModifiers: const [
          SelectedModifier(modifierOptionId: 'opt_cheese', name: 'Extra Cheese', price: Money(amountInCents: 150)),
        ],
        specialInstructions: 'No onions',
        snapshotVersion: 'v1',
      );

      // (1000 + 150) * 2 = 2300 cents
      expect(item.itemTotal.amountInCents, 2300);
      expect(item.itemTotal.formatted, '\$23.00');
    });

    test('Serializes and deserializes CartItem accurately', () {
      final original = CartItem(
        cartItemId: 'item-123',
        menuItemId: 'item_burger',
        name: 'Classic Cheeseburger',
        snapshotUnitPrice: const Money(amountInCents: 1000),
        quantity: 1,
        selectedModifiers: const [
          SelectedModifier(modifierOptionId: 'opt_cheese', name: 'Extra Cheese', price: Money(amountInCents: 150)),
        ],
        specialInstructions: 'No onions',
        snapshotVersion: 'v1',
      );

      final json = original.toJson();
      final decoded = CartItem.fromJson(json);

      expect(decoded, original);
      expect(decoded.selectedModifiers[0].name, 'Extra Cheese');
      expect(decoded.selectedModifiers[0].price.amountInCents, 150);
    });
  });

  group('Pricing Snapshot Drift Engine Tests', () {
    test('Detects price drift when base menu price changes', () {
      final state = CartState(
        items: [
          CartItem(
            cartItemId: 'item-burger-cart',
            menuItemId: 'item_burger',
            name: 'Classic Cheeseburger',
            snapshotUnitPrice: const Money(amountInCents: 900), // Cart price is $9.00
            quantity: 1,
            selectedModifiers: const [],
            specialInstructions: '',
            snapshotVersion: 'v0',
          ),
        ],
        branchId: 'br_test',
        menuSnapshotVersion: 'v0',
        hasStalePrices: false,
      );

      final driftResult = PricingSnapshotEngine.detectDrift(
        cartState: state,
        currentProjection: testMenuSnapshot, // Snapshot price is $10.00
      );

      expect(driftResult.hasDrift, isTrue);
      expect(driftResult.comparisons['item-burger-cart']?.localPrice.amountInCents, 900);
      expect(driftResult.comparisons['item-burger-cart']?.serverPrice.amountInCents, 1000);
    });

    test('Detects price drift when modifier price changes', () {
      final state = CartState(
        items: [
          CartItem(
            cartItemId: 'item-burger-cart',
            menuItemId: 'item_burger',
            name: 'Classic Cheeseburger',
            snapshotUnitPrice: const Money(amountInCents: 1000),
            quantity: 1,
            selectedModifiers: const [
              SelectedModifier(modifierOptionId: 'opt_cheese', name: 'Extra Cheese', price: Money(amountInCents: 100)), // Cart price is $1.00
            ],
            specialInstructions: '',
            snapshotVersion: 'v0',
          ),
        ],
        branchId: 'br_test',
        menuSnapshotVersion: 'v0',
        hasStalePrices: false,
      );

      final driftResult = PricingSnapshotEngine.detectDrift(
        cartState: state,
        currentProjection: testMenuSnapshot, // Snapshot modifier price is $1.50
      );

      expect(driftResult.hasDrift, isTrue);
      expect(driftResult.comparisons['item-burger-cart']?.localPrice.amountInCents, 1100); // 1000 + 100
      expect(driftResult.comparisons['item-burger-cart']?.serverPrice.amountInCents, 1150); // 1000 + 150
    });

    test('Detects drift when menu item is no longer available', () {
      final state = CartState(
        items: [
          CartItem(
            cartItemId: 'item-burger-cart',
            menuItemId: 'non_existent_item',
            name: 'Old Burger',
            snapshotUnitPrice: const Money(amountInCents: 1000),
            quantity: 1,
            selectedModifiers: const [],
            specialInstructions: '',
            snapshotVersion: 'v0',
          ),
        ],
        branchId: 'br_test',
        menuSnapshotVersion: 'v0',
        hasStalePrices: false,
      );

      final driftResult = PricingSnapshotEngine.detectDrift(
        cartState: state,
        currentProjection: testMenuSnapshot,
      );

      expect(driftResult.hasDrift, isTrue);
      expect(driftResult.comparisons['item-burger-cart']?.isAvailable, isFalse);
    });
  });

  group('Cart Persistence & Hydration Tests', () {
    test('Saves and retrieves cart state successfully', () async {
      final dataSource = CartLocalDataSource(prefs);

      final state = CartState(
        items: [
          CartItem(
            cartItemId: 'item-1',
            menuItemId: 'item_burger',
            name: 'Classic Cheeseburger',
            snapshotUnitPrice: const Money(amountInCents: 1000),
            quantity: 2,
            selectedModifiers: const [],
            specialInstructions: 'Well done',
            snapshotVersion: 'v1_test',
          )
        ],
        branchId: 'br_test',
        menuSnapshotVersion: 'v1_test',
        hasStalePrices: false,
      );

      await dataSource.saveCart(state);
      final restored = await dataSource.getCart();

      expect(restored, isNotNull);
      expect(restored!.branchId, 'br_test');
      expect(restored.menuSnapshotVersion, 'v1_test');
      expect(restored.items.length, 1);
      expect(restored.items[0].name, 'Classic Cheeseburger');
      expect(restored.items[0].quantity, 2);
    });
  });

  group('CartNotifier State Transitions', () {
    test('AddItem handles identical items by incrementing quantity, different modifiers by creating new lines', () {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          menuProjectionProvider.overrideWithValue(AsyncValue.data(testMenuSnapshot)),
          branchIdProvider.overrideWithValue('br_test'),
        ],
      );

      final cartStateNotifier = container.read(cartStateProvider.notifier);

      final burger = testMenuSnapshot.items[0]; // item_burger
      final cheese = testMenuSnapshot.modifierGroups[0].options[0]; // opt_cheese
      final bacon = testMenuSnapshot.modifierGroups[0].options[1]; // opt_bacon

      // Add 1 Cheeseburger with no modifiers
      cartStateNotifier.addItem(burger, const []);
      expect(container.read(cartStateProvider).items.length, 1);
      expect(container.read(cartStateProvider).items[0].quantity, 1);

      // Add another identical cheeseburger
      cartStateNotifier.addItem(burger, const []);
      expect(container.read(cartStateProvider).items.length, 1);
      expect(container.read(cartStateProvider).items[0].quantity, 2);

      // Add cheeseburger with extra cheese modifier
      cartStateNotifier.addItem(burger, [cheese]);
      expect(container.read(cartStateProvider).items.length, 2);
      expect(container.read(cartStateProvider).items[1].quantity, 1);

      // Add cheeseburger with cheese + bacon modifiers
      cartStateNotifier.addItem(burger, [cheese, bacon]);
      expect(container.read(cartStateProvider).items.length, 3);
    });

    test('UpdateQuantity modifies quantities and removes item when quantity is 0', () {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          menuProjectionProvider.overrideWithValue(AsyncValue.data(testMenuSnapshot)),
          branchIdProvider.overrideWithValue('br_test'),
        ],
      );

      final cartStateNotifier = container.read(cartStateProvider.notifier);
      final burger = testMenuSnapshot.items[0];

      cartStateNotifier.addItem(burger, const [], quantity: 2);
      final cartItemId = container.read(cartStateProvider).items[0].cartItemId;

      cartStateNotifier.updateQuantity(cartItemId, 5);
      expect(container.read(cartStateProvider).items[0].quantity, 5);

      cartStateNotifier.updateQuantity(cartItemId, 0);
      expect(container.read(cartStateProvider).items.isEmpty, isTrue);
    });

    test('ReconcilePrices aligns cart prices to new menu projection and clears stale flag', () {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          menuProjectionProvider.overrideWithValue(AsyncValue.data(testMenuSnapshot)),
          branchIdProvider.overrideWithValue('br_test'),
        ],
      );

      final cartStateNotifier = container.read(cartStateProvider.notifier);
      final burger = testMenuSnapshot.items[0];

      // Cart price starts at $10.00
      cartStateNotifier.addItem(burger, const []);
      
      // Update menu snapshot where burger price becomes $12.00
      final updatedMenu = MenuSnapshot(
        categories: testMenuSnapshot.categories,
        modifierGroups: testMenuSnapshot.modifierGroups,
        taxConfig: const TaxConfig(vatRate: 0.1, serviceChargeRate: 0.05),
        snapshotVersion: 'v2_updated',
        branchId: 'br_test',
        items: [
          MenuItem(
            id: 'item_burger',
            categoryId: 'cat_burgers',
            name: 'Classic Cheeseburger',
            description: 'Cheesy and delicious',
            price: const Money(amountInCents: 1200), // Price updated to $12.00
            isAvailable: true,
            modifierGroupIds: const ['group_addons'],
          ),
        ],
      );

      // Trigger update and verify drift detected
      cartStateNotifier.handleMenuUpdate(updatedMenu);
      expect(container.read(cartStateProvider).hasStalePrices, isTrue);

      // Reconcile prices
      cartStateNotifier.reconcilePrices(updatedMenu);
      expect(container.read(cartStateProvider).hasStalePrices, isFalse);
      expect(container.read(cartStateProvider).items[0].snapshotUnitPrice.amountInCents, 1200);
    });
  });

  group('Checkout Preparation & Offline Queue Tests', () {
    test('Enqueues checkout in offline sync queue and updates status to enqueuedOffline when offline', () async {
      await prefs.setBool('offline_sync_is_online', false); // Force offline

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          menuProjectionProvider.overrideWithValue(AsyncValue.data(testMenuSnapshot)),
          branchIdProvider.overrideWithValue('br_test'),
        ],
      );

      // Add item to cart
      final burger = testMenuSnapshot.items[0];
      container.read(cartStateProvider.notifier).addItem(burger, const []);

      // Submit checkout
      await container.read(checkoutNotifierProvider.notifier).submitCheckout();

      final checkoutState = container.read(checkoutNotifierProvider);
      expect(checkoutState.status, 'enqueuedOffline');
      expect(container.read(cartStateProvider).items.isEmpty, isTrue); // Cart cleared on checkout

      // Verify it was enqueued in the offline outbox
      final queue = container.read(offlineSyncQueueProvider);
      final pending = await queue.getQueue();
      expect(pending.length, 1);
      expect(pending[0].type, 'createOrder');
      expect(pending[0].payload['id'], checkoutState.confirmedOrderId);
    });

    test('Stale pricing prevents checkout submission and sets error status', () async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          menuProjectionProvider.overrideWithValue(AsyncValue.data(testMenuSnapshot)),
          branchIdProvider.overrideWithValue('br_test'),
        ],
      );

      // Manually set hasStalePrices to true
      final burger = testMenuSnapshot.items[0];
      container.read(cartStateProvider.notifier).addItem(burger, const []);
      
      final currentCartState = container.read(cartStateProvider);
      container.read(cartStateProvider.notifier).state = currentCartState.copyWith(hasStalePrices: true);

      // Try checkout
      await container.read(checkoutNotifierProvider.notifier).submitCheckout();

      expect(container.read(checkoutNotifierProvider).status, 'error');
      expect(container.read(checkoutNotifierProvider).errorMessage, contains('Stale pricing'));
    });
  });

  group('Adaptive Polling Controller Delay Tests', () {
    test('Calculates adaptive delay based on order age, terminal states, and outage errors', () {
      final controller = PollingIntervalController();
      final now = DateTime.now();

      // Mock order within 5 minutes (Active phase) -> 10s delay
      final activeOrder = OrderDto(
        id: 'ord_1',
        tenantId: 't_1',
        tableId: 'tbl_1',
        tableLabel: 'Table 1',
        status: OrderStatus.preparing,
        items: const [],
        totalAmount: 10.0,
        createdAt: now.subtract(const Duration(minutes: 2)),
        updatedAt: now,
      );
      expect(controller.getCurrentDelay(activeOrder).inSeconds, 10);

      // Mock order between 5 and 15 minutes (Intermediate phase) -> 30s delay
      final intermediateOrder = OrderDto(
        id: 'ord_2',
        tenantId: 't_1',
        tableId: 'tbl_1',
        tableLabel: 'Table 1',
        status: OrderStatus.preparing,
        items: const [],
        totalAmount: 10.0,
        createdAt: now.subtract(const Duration(minutes: 8)),
        updatedAt: now,
      );
      expect(controller.getCurrentDelay(intermediateOrder).inSeconds, 30);

      // Mock order older than 15 minutes (Idle phase) -> 60s delay
      final idleOrder = OrderDto(
        id: 'ord_3',
        tenantId: 't_1',
        tableId: 'tbl_1',
        tableLabel: 'Table 1',
        status: OrderStatus.preparing,
        items: const [],
        totalAmount: 10.0,
        createdAt: now.subtract(const Duration(minutes: 20)),
        updatedAt: now,
      );
      expect(controller.getCurrentDelay(idleOrder).inSeconds, 60);

      // Mock terminal states (Served/Cancelled) -> 300s delay
      final servedOrder = OrderDto(
        id: 'ord_4',
        tenantId: 't_1',
        tableId: 'tbl_1',
        tableLabel: 'Table 1',
        status: OrderStatus.served,
        items: const [],
        totalAmount: 10.0,
        createdAt: now.subtract(const Duration(minutes: 2)),
        updatedAt: now,
      );
      expect(controller.getCurrentDelay(servedOrder).inSeconds, 300);

      // Degraded outage mode after 2 consecutive errors -> 120s delay
      controller.recordFailure();
      controller.recordFailure();
      expect(controller.getCurrentDelay(activeOrder).inSeconds, 120);

      // Success records reset failure state
      controller.recordSuccess();
      expect(controller.getCurrentDelay(activeOrder).inSeconds, 10);
    });
  });
}
