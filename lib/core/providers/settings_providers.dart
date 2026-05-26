import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dtos/settings_dto.dart';
import 'repository_providers.dart';
import '../auth/mock_auth_provider.dart';

/// Provides the current settings for the active tenant.
final tenantSettingsProvider = FutureProvider<TenantSettingsDto?>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  final tenantId = profile?['tenant_id'] as String?;
  if (tenantId == null || tenantId.isEmpty) {
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
