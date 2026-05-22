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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/repositories/auth_repository.dart';
import '../data/repositories/menu_repository.dart';
import '../data/repositories/orders_repository.dart';
import '../data/repositories/staff_repository.dart';
import '../data/repositories/tables_repository.dart';
import '../data/repositories/settings_repository.dart';

import '../data/mock/mock_auth_repository.dart';
import '../data/mock/mock_menu_repository.dart';
import '../data/mock/mock_orders_repository.dart';
import '../data/mock/mock_staff_repository.dart';
import '../data/mock/mock_tables_repository.dart';
import '../data/mock/mock_settings_repository.dart';

import '../data/supabase/supabase_auth_repository.dart';
import '../data/supabase/supabase_menu_repository.dart';
import '../data/supabase/supabase_orders_repository.dart';
import '../data/supabase/supabase_staff_repository.dart';
import '../data/supabase/supabase_tables_repository.dart';
import '../data/supabase/supabase_settings_repository.dart';

import '../data/local/offline_sync_queue.dart';
import '../data/repositories/offline_first_orders_repository.dart';

// ── Feature flag ──────────────────────────────────────────────────────────────
// Toggle this to switch between mock and live repositories.
const bool kUseMockRepositories = true;

// ── SharedPreferences Provider ────────────────────────────────────────────────
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main.dart',
  );
});

// ── Offline Sync Queue Provider ───────────────────────────────────────────────
final offlineSyncQueueProvider = Provider<OfflineSyncQueue>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return OfflineSyncQueue(prefs);
});

// ── Supabase Client Provider ──────────────────────────────────────────────────
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// ── Auth Repository Provider ──────────────────────────────────────────────────
// NOTE: In mock mode this is overridden in main.dart with a pre-seeded
// MockAuthRepository instance (session already restored from SharedPreferences).
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (kUseMockRepositories) return MockAuthRepository();
  final client = ref.watch(supabaseClientProvider);
  return SupabaseAuthRepository(client);
});

// ── Menu Repository Provider ──────────────────────────────────────────────────
final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  if (kUseMockRepositories) return MockMenuRepository();
  final client = ref.watch(supabaseClientProvider);
  return SupabaseMenuRepository(client);
});

// ── Orders Repository Provider ────────────────────────────────────────────────
final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  final delegate = ref.watch(_baseOrdersRepositoryProvider);
  final queue = ref.watch(offlineSyncQueueProvider);
  final repo = OfflineFirstOrdersRepository(delegate: delegate, queue: queue);
  // Dispose the internal broadcast StreamController when this provider is torn down
  // to prevent memory leaks after hot-reload or provider invalidation.
  ref.onDispose(repo.dispose);
  return repo;
});

final _baseOrdersRepositoryProvider = Provider<OrdersRepository>((ref) {
  if (kUseMockRepositories) return MockOrdersRepository();
  final client = ref.watch(supabaseClientProvider);
  return SupabaseOrdersRepository(client);
});

// ── Tables Repository Provider ────────────────────────────────────────────────
final tablesRepositoryProvider = Provider<TablesRepository>((ref) {
  if (kUseMockRepositories) return MockTablesRepository();
  final client = ref.watch(supabaseClientProvider);
  return SupabaseTablesRepository(client);
});

// ── Staff Repository Provider ─────────────────────────────────────────────────
final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  if (kUseMockRepositories) return MockStaffRepository();
  final client = ref.watch(supabaseClientProvider);
  return SupabaseStaffRepository(client);
});

// ── Settings Repository Provider ──────────────────────────────────────────────
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  if (kUseMockRepositories) return MockSettingsRepository();
  final client = ref.watch(supabaseClientProvider);
  return SupabaseSettingsRepository(client);
});
