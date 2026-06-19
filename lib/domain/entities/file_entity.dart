import 'package:equatable/equatable.dart';

class FileEntity extends Equatable {
  final String id;
  final String projectId;
  final String path;
  final String code;
  final int version;
  final String language;
  final String status; // pending, writing, ready, error
  final String? errorLog;

  const FileEntity({
    required this.id,
    required this.projectId,
    required this.path,
    required this.code,
    this.version = 1,
    required this.language,
    this.status = 'pending',
    this.errorLog,
  });

  FileEntity copyWith({
    String? code,
    int? version,
    String? status,
    String? errorLog,
  }) {
    return FileEntity(
      id: id,
      projectId: projectId,
      path: path,
      code: code ?? this.code,
      version: version ?? this.version,
      language: language,
      status: status ?? this.status,
      errorLog: errorLog ?? this.errorLog,
    );
  }

  @override
  List<Object?> get props =>
      [id, projectId, path, code, version, language, status, errorLog];
}

class ChatMessageEntity extends Equatable {
  final String id;
  final String projectId;
  final String agent; // analyst, thinking, engineer, system, deployer
  final String role; // user, assistant
  final String message;
  final String? action;
  final int createdAt;

  const ChatMessageEntity({
    required this.id,
    required this.projectId,
    required this.agent,
    required this.role,
    required this.message,
    this.action,
    required this.createdAt,
  });

  @override
  List<Object?> get props =>
      [id, projectId, agent, role, message, action, createdAt];
}

class AppSettingsEntity extends Equatable {
  final String? kimiK26Key;       // Analyst + Thinking agentlar uchun
  final String? kimiK27CodeKey;   // Engineer + Fixer agentlar uchun
  final String? defaultVercelToken;
  final String theme;
  final String language;

  const AppSettingsEntity({
    this.kimiK26Key,
    this.kimiK27CodeKey,
    this.defaultVercelToken,
    this.theme = 'dark',
    this.language = 'uz',
  });

  AppSettingsEntity copyWith({
    String? kimiK26Key,
    String? kimiK27CodeKey,
    String? defaultVercelToken,
    String? theme,
    String? language,
  }) {
    return AppSettingsEntity(
      kimiK26Key: kimiK26Key ?? this.kimiK26Key,
      kimiK27CodeKey: kimiK27CodeKey ?? this.kimiK27CodeKey,
      defaultVercelToken: defaultVercelToken ?? this.defaultVercelToken,
      theme: theme ?? this.theme,
      language: language ?? this.language,
    );
  }

  bool get hasAnalystKey => kimiK26Key != null && kimiK26Key!.isNotEmpty;
  bool get hasEngineerKey => kimiK27CodeKey != null && kimiK27CodeKey!.isNotEmpty;
  bool get isFullyConfigured => hasAnalystKey && hasEngineerKey;

  @override
  List<Object?> get props =>
      [kimiK26Key, kimiK27CodeKey, defaultVercelToken, theme, language];
}
