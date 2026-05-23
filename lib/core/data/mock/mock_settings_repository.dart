import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../dtos/settings_dto.dart';
import '../repositories/settings_repository.dart';

class MockSettingsRepository implements SettingsRepository {
  List<TenantSettingsDto>? _settingsList;

  Future<void> _ensureLoaded() async {
    if (_settingsList != null) return;
    try {
      final raw = await rootBundle.loadString(
        'lib/core/data/mock/fixtures/settings_fixtures.json',
      );
      final json = jsonDecode(raw) as Map<String, dynamic>;
      _settingsList = (json['settings'] as List)
          .map((e) => TenantSettingsDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Fallback if file doesn't exist or is malformed
      _settingsList = [];
    }
  }

  @override
  Future<TenantSettingsDto?> getSettings(String tenantId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    await _ensureLoaded();
    try {
      return _settingsList!.firstWhere((s) => s.tenantId == tenantId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<TenantSettingsDto> updateSettings(TenantSettingsDto settings) async {
    await Future.delayed(const Duration(milliseconds: 400));
    await _ensureLoaded();

    final idx = _settingsList!.indexWhere(
      (s) => s.tenantId == settings.tenantId,
    );
    final updated = settings.copyWith(updatedAt: DateTime.now());

    if (idx == -1) {
      _settingsList!.add(updated);
    } else {
      _settingsList![idx] = updated;
    }

    return updated;
  }
}
