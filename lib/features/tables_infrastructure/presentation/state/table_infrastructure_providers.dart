import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/app_auth_provider.dart';
import '../../../../core/providers/branch_context_service.dart';
import '../../data/dtos/table_dto.dart';
import '../../data/dtos/floor_dto.dart';
import '../../data/repositories/table_infrastructure_repository.dart';

final tablesFutureProvider =
    AsyncNotifierProvider<TablesNotifier, List<TableDto>>(() {
      return TablesNotifier();
    });

class TablesNotifier extends AsyncNotifier<List<TableDto>> {
  @override
  Future<List<TableDto>> build() async {
    final ctx = ref.watch(appContextProvider);
    if (ctx == null) return [];

    final branchAsync = ref.watch(currentBranchProvider);
    final branch = branchAsync.value;
    if (branch == null) return [];

    final repo = ref.watch(tableInfrastructureRepositoryProvider);
    return repo.getTables(ctx.tenant.id, branch.id);
  }

  Future<void> addTable(
    String tableNumber,
    int capacity, {
    String? floorId,
  }) async {
    final ctx = ref.read(appContextProvider);
    if (ctx == null) return;

    final branch = ref.read(currentBranchProvider).value;
    if (branch == null) return;

    final repo = ref.read(tableInfrastructureRepositoryProvider);

    final dto = TableDto(
      id: '', // Empty, backend generates it
      tenantId: ctx.tenant.id,
      branchId: branch.id,
      tableNumber: tableNumber,
      capacity: capacity,
      floorId: floorId,
      isActive: true,
    );

    final previousState = state;
    state = const AsyncValue.loading();
    try {
      await repo.createTable(dto);
      final list = await repo.getTables(ctx.tenant.id, branch.id);
      state = AsyncValue.data(list);
    } catch (e) {
      state = previousState;
      rethrow;
    }
  }

  Future<void> deleteTable(String tableId) async {
    final ctx = ref.read(appContextProvider);
    if (ctx == null) return;

    final branch = ref.read(currentBranchProvider).value;
    if (branch == null) return;

    final repo = ref.read(tableInfrastructureRepositoryProvider);

    final previousState = state;
    state = const AsyncValue.loading();
    try {
      await repo.deleteTable(tableId);
      final list = await repo.getTables(ctx.tenant.id, branch.id);
      state = AsyncValue.data(list);
    } catch (e) {
      state = previousState;
      rethrow;
    }
  }
}

final floorsFutureProvider =
    AsyncNotifierProvider<FloorsNotifier, List<FloorDto>>(() {
      return FloorsNotifier();
    });

class FloorsNotifier extends AsyncNotifier<List<FloorDto>> {
  @override
  Future<List<FloorDto>> build() async {
    final ctx = ref.watch(appContextProvider);
    debugPrint('[FloorsNotifier.build] WATCH appContextProvider: $ctx');
    if (ctx == null) {
      debugPrint('[FloorsNotifier.build] RETURN [] because ctx is null');
      return [];
    }

    final branchAsync = ref.watch(currentBranchProvider);
    debugPrint(
      '[FloorsNotifier.build] WATCH currentBranchProvider state: $branchAsync',
    );
    final branch = branchAsync.value;
    if (branch == null) {
      debugPrint(
        '[FloorsNotifier.build] RETURN [] because branch is null (branchAsync.value is null)',
      );
      return [];
    }

    final repo = ref.watch(tableInfrastructureRepositoryProvider);
    debugPrint(
      '[FloorsNotifier.build] CALL getFloors with tenant: ${ctx.tenant.id}, branch: ${branch.id}',
    );
    try {
      final list = await repo.getFloors(ctx.tenant.id, branch.id);
      debugPrint('[FloorsNotifier.build] SUCCESS: returned ${list.length} floors');
      return list;
    } catch (e, stack) {
      debugPrint('[FloorsNotifier.build] ERROR: $e\n$stack');
      rethrow;
    }
  }

  Future<void> addFloor(String name) async {
    final ctx = ref.read(appContextProvider);
    debugPrint('[FloorsNotifier.addFloor] READ appContextProvider: $ctx');
    if (ctx == null) {
      debugPrint('[FloorsNotifier.addFloor] RETURN because ctx is null');
      return;
    }

    final branch = ref.read(currentBranchProvider).value;
    debugPrint(
      '[FloorsNotifier.addFloor] READ currentBranchProvider value: $branch',
    );
    if (branch == null) {
      debugPrint('[FloorsNotifier.addFloor] RETURN because branch is null');
      return;
    }

    final repo = ref.read(tableInfrastructureRepositoryProvider);
    debugPrint(
      '[FloorsNotifier.addFloor] CALL createFloor with branch: ${branch.id}, name: $name',
    );

    final previousState = state;
    state = const AsyncValue.loading();
    try {
      final newFloor = await repo.createFloor(branch.id, name);
      debugPrint('[FloorsNotifier.addFloor] createFloor SUCCESS: $newFloor');
      final list = await repo.getFloors(ctx.tenant.id, branch.id);
      debugPrint(
        '[FloorsNotifier.addFloor] getFloors SUCCESS: returned ${list.length} floors',
      );
      state = AsyncValue.data(list);
    } catch (e, stack) {
      debugPrint('[FloorsNotifier.addFloor] ERROR: $e\n$stack');
      state = previousState;
      rethrow;
    }
  }

  Future<void> deleteFloor(String floorId) async {
    final ctx = ref.read(appContextProvider);
    debugPrint('[FloorsNotifier.deleteFloor] READ appContextProvider: $ctx');
    if (ctx == null) {
      debugPrint('[FloorsNotifier.deleteFloor] RETURN because ctx is null');
      return;
    }

    final branch = ref.read(currentBranchProvider).value;
    debugPrint(
      '[FloorsNotifier.deleteFloor] READ currentBranchProvider value: $branch',
    );
    if (branch == null) {
      debugPrint('[FloorsNotifier.deleteFloor] RETURN because branch is null');
      return;
    }

    final repo = ref.read(tableInfrastructureRepositoryProvider);
    debugPrint('[FloorsNotifier.deleteFloor] CALL deleteFloor: $floorId');

    final previousState = state;
    state = const AsyncValue.loading();
    try {
      await repo.deleteFloor(floorId);
      debugPrint('[FloorsNotifier.deleteFloor] deleteFloor SUCCESS');
      final list = await repo.getFloors(ctx.tenant.id, branch.id);
      debugPrint(
        '[FloorsNotifier.deleteFloor] getFloors SUCCESS: returned ${list.length} floors',
      );
      state = AsyncValue.data(list);
    } catch (e, stack) {
      debugPrint('[FloorsNotifier.deleteFloor] ERROR: $e\n$stack');
      state = previousState;
      rethrow;
    }
  }
}

final activeFloorIdProvider = StateProvider<String?>((ref) => null);
