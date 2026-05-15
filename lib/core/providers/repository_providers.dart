// ── Repository Providers ──────────────────────────────────────────────────────
// Single source of truth for which implementation is wired.
//
// MOCK MODE (current): All repositories use Mock* implementations.
// No Supabase calls are made anywhere in the app.
//
// PRODUCTION MIGRATION CHECKLIST:
//   1. Set kUseMockRepositories = false
//   2. Implement SupabaseAuthRepository, SupabaseMenuRepository, etc.
//   3. Wire them in the `else` branch below.
//   4. Remove the mock imports.
//   Zero UI code changes needed.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/auth_repository.dart';
import '../data/repositories/menu_repository.dart';
import '../data/repositories/orders_repository.dart';
import '../data/repositories/tables_repository.dart';
import '../data/mock/mock_auth_repository.dart';
import '../data/mock/mock_menu_repository.dart';
import '../data/mock/mock_orders_repository.dart';
import '../data/mock/mock_tables_repository.dart';

// ── Feature flag ──────────────────────────────────────────────────────────────
// Toggle this to switch between mock and live repositories.
const bool kUseMockRepositories = true;

// ── Auth Repository Provider ──────────────────────────────────────────────────
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (kUseMockRepositories) return MockAuthRepository();
  // return SupabaseAuthRepository();
  throw UnimplementedError('Live auth repository not yet implemented.');
});

// ── Menu Repository Provider ──────────────────────────────────────────────────
final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  if (kUseMockRepositories) return MockMenuRepository();
  // return SupabaseMenuRepository();
  throw UnimplementedError('Live menu repository not yet implemented.');
});

// ── Orders Repository Provider ────────────────────────────────────────────────
final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  if (kUseMockRepositories) return MockOrdersRepository();
  // return SupabaseOrdersRepository();
  throw UnimplementedError('Live orders repository not yet implemented.');
});

// ── Tables Repository Provider ────────────────────────────────────────────────
final tablesRepositoryProvider = Provider<TablesRepository>((ref) {
  if (kUseMockRepositories) return MockTablesRepository();
  // return SupabaseTablesRepository();
  throw UnimplementedError('Live tables repository not yet implemented.');
});
