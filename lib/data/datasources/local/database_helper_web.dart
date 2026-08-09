import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Browser implementation of the database contract.
///
/// Flutter Web cannot use sqflite, so collections are persisted as JSON in
/// browser localStorage through shared_preferences. The public methods mirror
/// the mobile SQLite helper so repositories remain platform-independent.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _projectsKey = 'autodev.web.projects';
  static const _filesKey = 'autodev.web.files';
  static const _chatKey = 'autodev.web.chat_history';
  static const _settingsKey = 'autodev.web.settings';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<List<Map<String, dynamic>>> _readList(String key) async {
    final prefs = await _prefs;
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  Future<void> _writeList(String key, List<Map<String, dynamic>> values) async {
    final prefs = await _prefs;
    await prefs.setString(key, jsonEncode(values));
  }

  Future<void> _upsertInList(String key, Map<String, dynamic> map) async {
    final values = await _readList(key);
    final id = map['id']?.toString();
    final index = values.indexWhere((item) => item['id']?.toString() == id);
    if (index >= 0) {
      values[index] = Map<String, dynamic>.from(map);
    } else {
      values.add(Map<String, dynamic>.from(map));
    }
    await _writeList(key, values);
  }

  Future<List<Map<String, dynamic>>> getAllProjects() async {
    final values = await _readList(_projectsKey);
    values.sort((a, b) =>
        ((b['updated_at'] as num?)?.toInt() ?? 0).compareTo((a['updated_at'] as num?)?.toInt() ?? 0));
    return values;
  }

  Future<Map<String, dynamic>?> getProjectById(String id) async {
    final values = await _readList(_projectsKey);
    for (final item in values) {
      if (item['id']?.toString() == id) return item;
    }
    return null;
  }

  Future<void> upsertProject(Map<String, dynamic> map) =>
      _upsertInList(_projectsKey, map);

  Future<void> deleteProject(String id) async {
    final projects = await _readList(_projectsKey);
    projects.removeWhere((item) => item['id']?.toString() == id);
    await _writeList(_projectsKey, projects);

    final files = await _readList(_filesKey);
    files.removeWhere((item) => item['project_id']?.toString() == id);
    await _writeList(_filesKey, files);

    final chat = await _readList(_chatKey);
    chat.removeWhere((item) => item['project_id']?.toString() == id);
    await _writeList(_chatKey, chat);
  }

  Future<List<Map<String, dynamic>>> getFilesForProject(String projectId) async {
    final values = await _readList(_filesKey);
    values.removeWhere((item) => item['project_id']?.toString() != projectId);
    values.sort((a, b) =>
        (a['path']?.toString() ?? '').compareTo(b['path']?.toString() ?? ''));
    return values;
  }

  Future<void> upsertFile(Map<String, dynamic> map) =>
      _upsertInList(_filesKey, map);

  Future<void> upsertFiles(List<Map<String, dynamic>> maps) async {
    for (final map in maps) {
      await _upsertInList(_filesKey, map);
    }
  }

  Future<List<Map<String, dynamic>>> getChatHistory(String projectId) async {
    final values = await _readList(_chatKey);
    values.removeWhere((item) => item['project_id']?.toString() != projectId);
    values.sort((a, b) =>
        ((a['created_at'] as num?)?.toInt() ?? 0).compareTo((b['created_at'] as num?)?.toInt() ?? 0));
    return values;
  }

  Future<void> insertChatMessage(Map<String, dynamic> map) =>
      _upsertInList(_chatKey, map);

  Future<Map<String, dynamic>?> getSettings() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_settingsKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  Future<void> upsertSettings(Map<String, dynamic> map) async {
    final current = await getSettings() ?? <String, dynamic>{};
    current.addAll(map);
    current['id'] = 1;
    final prefs = await _prefs;
    await prefs.setString(_settingsKey, jsonEncode(current));
  }
}
