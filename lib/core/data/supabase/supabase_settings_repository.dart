import 'package:supabase_flutter/supabase_flutter.dart';
import '../dtos/settings_dto.dart';
import '../repositories/settings_repository.dart';

class SupabaseSettingsRepository implements SettingsRepository {
  final SupabaseClient _client;

  const SupabaseSettingsRepository(this._client);

  @override
  Future<TenantSettingsDto?> getSettings(String tenantId) async {
    final response = await _client
        .from('tenant_settings')
        .select()
        .eq('tenant_id', tenantId)
        .maybeSingle();

    if (response == null) return null;
    return TenantSettingsDto.fromJson(response);
  }

  @override
  Future<TenantSettingsDto> updateSettings(TenantSettingsDto settings) async {
    final updatedSettings = settings.copyWith(updatedAt: DateTime.now());

    final response = await _client
        .from('tenant_settings')
        .upsert(updatedSettings.toJson())
        .select()
        .single();

    return TenantSettingsDto.fromJson(response);
  }
}
