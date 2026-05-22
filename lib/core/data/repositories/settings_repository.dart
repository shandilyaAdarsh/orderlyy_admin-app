import '../dtos/settings_dto.dart';

abstract class SettingsRepository {
  /// Fetches the tenant settings for the given [tenantId].
  Future<TenantSettingsDto?> getSettings(String tenantId);

  /// Updates the tenant settings.
  Future<TenantSettingsDto> updateSettings(TenantSettingsDto settings);
}
