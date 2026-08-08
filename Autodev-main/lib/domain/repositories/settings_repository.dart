import '../entities/file_entity.dart';

abstract class SettingsRepository {
  Future<AppSettingsEntity> getSettings();
  Future<void> saveSettings(AppSettingsEntity settings);

  /// Kimi K2.6 kaliti — Analyst va Thinking agentlar uchun.
  /// Mijoz kaliti bo'lsa u ishlatiladi, aks holda default k2.6 kalit.
  Future<String?> resolveAnalystKey({String? projectCustomKey});

  /// Kimi K2.7-Code kaliti — Engineer va Fixer agentlar uchun.
  /// Mijoz kaliti bo'lsa u ishlatiladi, aks holda default k2.7-code kalit.
  Future<String?> resolveEngineerKey({String? projectCustomKey});

  Future<String?> getVercelToken();
}
