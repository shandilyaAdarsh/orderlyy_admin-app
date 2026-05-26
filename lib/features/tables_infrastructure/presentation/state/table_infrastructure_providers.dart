import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orderlli_admin/core/auth/app_context_provider.dart';
import 'package:orderlli_admin/features/tables_infrastructure/data/dtos/table_dto.dart';
import 'package:orderlli_admin/features/tables_infrastructure/data/repositories/table_infrastructure_repository.dart';

final tablesFutureProvider = FutureProvider<List<TableDto>>((ref) async {
  final ctx = ref.watch(appContextProvider);
  if (ctx == null) return [];

  final repo = ref.watch(tableInfrastructureRepositoryProvider);
  const branchId = 'branch_1';
  return repo.getTables(ctx.tenant.id, branchId);
});
