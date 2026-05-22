// ── Menu Providers ────────────────────────────────────────────────────────────
// All menu data access goes through these providers.
// Screens MUST NOT import supabase_flutter or call Supabase.instance.client.
//
// Data flow:
//   MenuRepository (interface)
//     └─ MockMenuRepository        (kUseMockRepositories = true)
//     └─ SupabaseMenuRepository    (future, kUseMockRepositories = false)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dtos/menu_dto.dart';
import 'repository_providers.dart';

import '../auth/mock_auth_provider.dart';

// ── Menu items stream ─────────────────────────────────────────────────────────
// Emits every time the underlying repository pushes an update.
final menuItemsStreamProvider = StreamProvider<List<MenuItemDto>>((ref) async* {
  final profile = await ref.watch(userProfileProvider.future);
  final tenantId = profile?['tenant_id'];

  if (tenantId == null) {
    if (kUseMockRepositories) {
      yield* ref
          .watch(menuRepositoryProvider)
          .watchMenuItems('mock-tenant-001');
    } else {
      yield [];
    }
    return;
  }

  final repo = ref.watch(menuRepositoryProvider);
  yield* repo.watchMenuItems(tenantId);
});

// ── Toggle availability ───────────────────────────────────────────────────────
final toggleMenuItemAvailabilityProvider =
    Provider<Future<void> Function(String itemId, bool isAvailable)>((ref) {
      final repo = ref.read(menuRepositoryProvider);
      return (itemId, isAvailable) async =>
          repo.toggleItemAvailability(itemId, isAvailable);
    });

// ── Create menu item ──────────────────────────────────────────────────────────
final createMenuItemProvider =
    Provider<Future<MenuItemDto> Function(MenuItemDto item)>((ref) {
      final repo = ref.read(menuRepositoryProvider);
      return (item) async => repo.createMenuItem(item);
    });

// ── Update menu item ──────────────────────────────────────────────────────────
final updateMenuItemProvider =
    Provider<Future<MenuItemDto> Function(MenuItemDto item)>((ref) {
      final repo = ref.read(menuRepositoryProvider);
      return (item) async => repo.updateMenuItem(item);
    });

// ── Delete menu item ──────────────────────────────────────────────────────────
final deleteMenuItemProvider = Provider<Future<void> Function(String itemId)>((
  ref,
) {
  final repo = ref.read(menuRepositoryProvider);
  return (itemId) async => repo.deleteMenuItem(itemId);
});

// ── Menu categories ───────────────────────────────────────────────────────────
final menuCategoriesFutureProvider = FutureProvider<List<MenuCategoryDto>>((
  ref,
) async {
  final profile = await ref.watch(userProfileProvider.future);
  final tenantId = profile?['tenant_id'] ?? 'mock-tenant-001';
  final repo = ref.watch(menuRepositoryProvider);
  return repo.getCategories(tenantId);
});
