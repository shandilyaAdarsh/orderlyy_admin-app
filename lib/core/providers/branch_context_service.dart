import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dtos/restaurant_context_dto.dart';
import '../auth/app_auth_provider.dart';
import 'branch_persistence_store.dart';
import '../network/network_providers.dart'; // contains dioClientProvider

final branchEpochProvider = StateProvider<int>((ref) => 0);

class BranchContextService extends AsyncNotifier<BranchDto?> {
  List<BranchDto> availableBranches = [];
  @override
  FutureOr<BranchDto?> build() async {
    final ctx = ref.watch(appContextProvider);
    if (ctx == null) return null;

    final store = ref.read(branchPersistenceStoreProvider);
    final persistedId = await store.getPersistedBranchId();

    final dio = ref.read(dioClientProvider);
    try {
      final response = await dio.get('/api/v1/tenants/${ctx.tenant.id}/branches');
      availableBranches = (response.data['data'] as List).map((e) => BranchDto.fromJson(e)).toList();
    } catch (e) {
      debugPrint('[BranchContextService] Error fetching branches: $e');
    }

    if (availableBranches.isEmpty) {
      await store.clearPersistedBranchId();
      return null;
    }

    if (availableBranches.length == 1) {
      final single = availableBranches.first;
      await store.persistBranchId(single.id);
      return single;
    }

    if (persistedId != null) {
      try {
        final matched = availableBranches.firstWhere((b) => b.id == persistedId && b.isActive);
        return matched;
      } catch (_) {
        // Fallback below
      }
    }

    final fallback = availableBranches.firstWhere((b) => b.isActive, orElse: () => availableBranches.first);
    await store.persistBranchId(fallback.id);
    return fallback;
  }

  Future<void> setBranch(String branchId) async {
    final ctx = ref.read(appContextProvider);
    if (ctx == null) return;
    
    if (availableBranches.isEmpty) {
      final dio = ref.read(dioClientProvider);
      try {
        final response = await dio.get('/api/v1/tenants/${ctx.tenant.id}/branches');
        availableBranches = (response.data['data'] as List).map((e) => BranchDto.fromJson(e)).toList();
      } catch (e) {
        debugPrint('[BranchContextService] Error fetching branches: $e');
      }
    }
    
    try {
      final matched = availableBranches.firstWhere((b) => b.id == branchId);
      final store = ref.read(branchPersistenceStoreProvider);
      await store.persistBranchId(branchId);
      
      // Increment epoch to invalidate stale async/realtime data
      ref.read(branchEpochProvider.notifier).update((state) => state + 1);
      
      state = AsyncData(matched);
    } catch (e) {
      debugPrint('[BranchContextService] Failed to set branch $branchId: $e');
    }
  }
}

final currentBranchProvider = AsyncNotifierProvider<BranchContextService, BranchDto?>(() {
  return BranchContextService();
});
