import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dtos/settings_dto.dart';
import 'repository_providers.dart';
import '../auth/mock_auth_provider.dart';

/// Provides the current settings for the active tenant.
final tenantSettingsProvider = FutureProvider<TenantSettingsDto?>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  final tenantId = profile?['tenant_id'];

  if (tenantId == null) {
    // Return default settings for mock tenant if no auth context exists
    if (kUseMockRepositories) {
      return ref
          .watch(settingsRepositoryProvider)
          .getSettings('mock-tenant-001');
    }
    return null;
  }

  final repo = ref.watch(settingsRepositoryProvider);
  return repo.getSettings(tenantId);
});

/// Provides a function to update the tenant settings and invalidate the cache.
final updateSettingsProvider =
    Provider<Future<TenantSettingsDto> Function(TenantSettingsDto)>((ref) {
      final repo = ref.read(settingsRepositoryProvider);

      return (settings) async {
        final updated = await repo.updateSettings(settings);
        ref.invalidate(tenantSettingsProvider);
        return updated;
      };
    });
