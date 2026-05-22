// lib/features/orders/providers/orders_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../bootstrap/bootstrap.dart';
import '../../../../shared/models/money.dart';
import '../data/datasources/local/orders_local_datasource.dart';
import '../data/repositories/orders_repository_impl.dart';
import '../domain/entities/menu_product.dart';
import '../domain/repositories/orders_repository.dart';

final ordersLocalDatasourceProvider = Provider<OrdersLocalDatasource>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return OrdersLocalDatasourceImpl(prefs);
});

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  final local = ref.watch(ordersLocalDatasourceProvider);
  return OrdersRepositoryImpl(local: local);
});

final menuProductsProvider = Provider<List<MenuProduct>>((ref) {
  return const [
    MenuProduct(
      id: 'prod_burger',
      name: 'Classic Cheeseburger',
      price: Money(amountInCents: 1250),
      category: 'Mains',
      availableModifiers: [
        ModifierOption(id: 'mod_bacon', name: 'Extra Bacon', price: Money(amountInCents: 150)),
        ModifierOption(id: 'mod_cheddar', name: 'Cheddar Cheese', price: Money(amountInCents: 100)),
        ModifierOption(id: 'mod_avocado', name: 'Add Avocado', price: Money(amountInCents: 200)),
        ModifierOption(id: 'mod_gf_bun', name: 'Gluten-free Bun', price: Money(amountInCents: 150)),
      ],
    ),
    MenuProduct(
      id: 'prod_chicken',
      name: 'Spicy Chicken Sandwich',
      price: Money(amountInCents: 1300),
      category: 'Mains',
      availableModifiers: [
        ModifierOption(id: 'mod_jalapenos', name: 'Extra Jalapenos', price: Money(amountInCents: 75)),
        ModifierOption(id: 'mod_swiss', name: 'Swiss Cheese', price: Money(amountInCents: 100)),
        ModifierOption(id: 'mod_spicy_mayo', name: 'Spicy Mayo', price: Money(amountInCents: 50)),
      ],
    ),
    MenuProduct(
      id: 'prod_salad',
      name: 'Caesar Salad',
      price: Money(amountInCents: 950),
      category: 'Greens',
      availableModifiers: [
        ModifierOption(id: 'mod_chicken_breast', name: 'Add Grilled Chicken', price: Money(amountInCents: 300)),
        ModifierOption(id: 'mod_dressing', name: 'Extra Dressing', price: Money(amountInCents: 50)),
      ],
    ),
    MenuProduct(
      id: 'prod_fries',
      name: 'French Fries',
      price: Money(amountInCents: 450),
      category: 'Sides',
      availableModifiers: [
        ModifierOption(id: 'mod_parmesan', name: 'Garlic Parmesan', price: Money(amountInCents: 100)),
        ModifierOption(id: 'mod_truffle', name: 'Truffle Oil', price: Money(amountInCents: 150)),
      ],
    ),
    MenuProduct(
      id: 'prod_beer',
      name: 'Craft IPA Beer',
      price: Money(amountInCents: 650),
      category: 'Drinks',
      availableModifiers: [
        ModifierOption(id: 'mod_lime', name: 'Add Lime Slice', price: Money(amountInCents: 0)),
      ],
    ),
    MenuProduct(
      id: 'prod_soda',
      name: 'Fresh Lemon Soda',
      price: Money(amountInCents: 350),
      category: 'Drinks',
      availableModifiers: [
        ModifierOption(id: 'mod_less_sugar', name: 'Less Sugar', price: Money(amountInCents: 0)),
        ModifierOption(id: 'mod_ice', name: 'Extra Ice', price: Money(amountInCents: 0)),
      ],
    ),
  ];
});
