import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../core/constants/app_constants.dart';
import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/project_entity.dart';
import '../../domain/entities/file_entity.dart';
import '../../domain/repositories/project_repository.dart';
import '../../domain/repositories/ai_repository.dart';
import '../../domain/repositories/deploy_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/local/database_helper.dart';
import '../datasources/remote/kimi_remote_datasource.dart';
import '../models/data_models.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  final DatabaseHelper _db;
  ProjectRepositoryImpl(this._db);

  @override
  Future<List<ProjectEntity>> getAllProjects() async {
    final rows = await _db.getAllProjects();
    return rows.map((r) => ProjectModel.fromMap(r).toEntity()).toList();
  }

  @override
  Future<ProjectEntity?> getProjectById(String id) async {
    final row = await _db.getProjectById(id);
    return row == null ? null : ProjectModel.fromMap(row).toEntity();
  }

  @override
  Future<void> saveProject(ProjectEntity project) async {
    await _db.upsertProject(ProjectModel.fromEntity(project).toMap());
  }

  @override
  Future<void> deleteProject(String id) async {
    await _db.deleteProject(id);
  }

  @override
  Future<List<FileEntity>> getFilesForProject(String projectId) async {
    final rows = await _db.getFilesForProject(projectId);
    return rows.map((r) => FileModel.fromMap(r).toEntity()).toList();
  }

  @override
  Future<void> saveFile(FileEntity file) async {
    await _db.upsertFile(FileModel.fromEntity(file).toMap());
  }

  @override
  Future<void> saveFiles(List<FileEntity> files) async {
    await _db.upsertFiles(
        files.map((f) => FileModel.fromEntity(f).toMap()).toList());
  }

  @override
  Future<List<ChatMessageEntity>> getChatHistory(String projectId) async {
    final rows = await _db.getChatHistory(projectId);
    return rows.map((r) => ChatMessageModel.fromMap(r).toEntity()).toList();
  }

  @override
  Future<void> addChatMessage(ChatMessageEntity message) async {
    await _db.insertChatMessage(ChatMessageModel.fromEntity(message).toMap());
  }
}

class AiRepositoryImpl implements AiRepository {
  final KimiRemoteDatasource _remote;
  AiRepositoryImpl(this._remote);

  @override
  Future<Result<AnalystOutputEntity>> runAnalyst({required String userIdea, required String apiKey}) async {
    try {
      final output = await _remote.runAnalyst(userIdea: userIdea, apiKey: apiKey.trim());
      return Result.success(output);
    } on NetworkException catch (e) {
      return Result.error(NetworkFailure(e.message));
    } on ParsingException catch (e) {
      return Result.error(ParsingFailure(e.message));
    } on ServerException catch (e) {
      return Result.error(ServerFailure(e.message));
    } catch (e) {
      return Result.error(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<ProductSpecEntity>> runThinking({required String userIdea, required AnalystOutputEntity analystOutput, required String apiKey}) async {
    try {
      final spec = await _remote.runThinking(userIdea: userIdea, analystOutput: analystOutput, apiKey: apiKey.trim());
      return Result.success(spec);
    } on NetworkException catch (e) {
      return Result.error(NetworkFailure(e.message));
    } on ParsingException catch (e) {
      return Result.error(ParsingFailure(e.message));
    } on ServerException catch (e) {
      return Result.error(ServerFailure(e.message));
    } catch (e) {
      return Result.error(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<String>> generateFile({required ProductSpecEntity spec, required SpecFile file, required Map<String, String> previousFiles, required String apiKey}) async {
    try {
      final code = await _remote.generateFile(spec: spec, file: file, previousFiles: previousFiles, apiKey: apiKey.trim());
      return Result.success(code);
    } on NetworkException catch (e) {
      return Result.error(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Result.error(ServerFailure(e.message));
    } catch (e) {
      return Result.error(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<String>> fixFile({required String filePath, required String currentCode, required String errorMessage, required String apiKey}) async {
    try {
      final code = await _remote.fixFile(filePath: filePath, currentCode: currentCode, errorMessage: errorMessage, apiKey: apiKey.trim());
      return Result.success(code);
    } on NetworkException catch (e) {
      return Result.error(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Result.error(ServerFailure(e.message));
    } catch (e) {
      return Result.error(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<String>> applyGitHubTask({required String taskDescription, required String filePath, required String currentCode, required Map<String, String> repoContext, required String apiKey}) async {
    try {
      final code = await _remote.applyGitHubTask(taskDescription: taskDescription, filePath: filePath, currentCode: currentCode, repoContext: repoContext, apiKey: apiKey.trim());
      return Result.success(code);
    } on NetworkException catch (e) {
      return Result.error(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Result.error(ServerFailure(e.message));
    } catch (e) {
      return Result.error(ServerFailure(e.toString()));
    }
  }
}

class DeployRepositoryImpl implements DeployRepository {
  final Dio _dio;
  DeployRepositoryImpl({Dio? dio}) : _dio = dio ?? Dio(BaseOptions(baseUrl: ApiConstants.vercelBaseUrl, connectTimeout: const Duration(seconds: 60), receiveTimeout: const Duration(seconds: 60)));

  @override
  Future<Result<String>> generateZip({required String projectName, required List<FileEntity> files}) async {
    try {
      final archive = Archive();
      for (final file in files) {
        final bytes = utf8.encode(file.code);
        archive.addFile(ArchiveFile(file.path, bytes.length, bytes));
      }
      final readme = _buildReadme(projectName, files);
      final readmeBytes = utf8.encode(readme);
      archive.addFile(ArchiveFile('README.md', readmeBytes.length, readmeBytes));
      final encodedZip = ZipEncoder().encode(archive);
      if (encodedZip == null) return Result.error(const DeployFailure('ZIP arxivi yaratishda xato'));
      final dir = await getTemporaryDirectory();
      final safeName = projectName.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_').toLowerCase();
      final zipPath = '${dir.path}/${safeName}_autodev.zip';
      await File(zipPath).writeAsBytes(encodedZip);
      return Result.success(zipPath);
    } catch (e) {
      return Result.error(DeployFailure('ZIP yaratishda xato: ${e.toString()}'));
    }
  }

  @override
  Future<Result<String>> deployToVercel({required String projectName, required List<FileEntity> files, required String vercelToken}) async {
    try {
      final vercelFiles = files.map((f) => {'file': f.path, 'data': base64Encode(utf8.encode(f.code)), 'encoding': 'base64'}).toList();
      final safeName = projectName.replaceAll(RegExp(r'[^a-zA-Z0-9\-]'), '-').toLowerCase();
      final response = await _dio.post(ApiConstants.vercelDeploymentsPath, options: Options(headers: {'Authorization': 'Bearer $vercelToken', 'Content-Type': 'application/json'}), data: jsonEncode({'name': safeName, 'files': vercelFiles, 'projectSettings': {'framework': null}}));
      final data = response.data as Map<String, dynamic>;
      final url = data['url'] as String? ?? data['alias']?.toString() ?? '';
      if (url.isEmpty) return Result.error(const DeployFailure('Vercel URL ni qaytarmadi'));
      return Result.success(url.startsWith('http') ? url : 'https://$url');
    } on DioException catch (e) {
      final body = e.response?.data?.toString() ?? e.message ?? '';
      return Result.error(DeployFailure('Vercel xatosi: ${e.response?.statusCode} - $body'));
    } catch (e) {
      return Result.error(DeployFailure('Vercel deploy xatosi: ${e.toString()}'));
    }
  }

  @override
  Future<void> shareFile(String path) async => Share.shareXFiles([XFile(path)]);

  String _buildReadme(String projectName, List<FileEntity> files) {
    final fileList = files.map((f) => '- `${f.path}`').join('\n');
    return '# $projectName\n\nBu loyiha **AutoDev** yordamida avtomatik tarzda yaratildi.\n\n## Fayl tarkibi\n\n$fileList\n';
  }
}

class SettingsRepositoryImpl implements SettingsRepository {
  final DatabaseHelper _db;
  final FlutterSecureStorage _secure;
  SettingsRepositoryImpl(this._db, this._secure);

  @override
  Future<AppSettingsEntity> getSettings() async {
    final row = await _db.getSettings();
    final k26 = (await _secure.read(key: AppConstants.secureKeyKimi26))?.trim();
    final k27 = (await _secure.read(key: AppConstants.secureKeyKimi27Code))?.trim();
    final vercel = (await _secure.read(key: AppConstants.secureKeyDefaultVercelToken))?.trim();
    final github = (await _secure.read(key: AppConstants.secureKeyGithubToken))?.trim();
    return AppSettingsEntity(kimiK26Key: k26, kimiK27CodeKey: k27, defaultVercelToken: vercel, githubToken: github, theme: (row?['theme'] as String?) ?? 'dark', language: (row?['language'] as String?) ?? 'uz');
  }

  @override
  Future<void> saveSettings(AppSettingsEntity settings) async {
    await _db.upsertSettings({'theme': settings.theme, 'language': settings.language});
    if (settings.kimiK26Key != null) await _secure.write(key: AppConstants.secureKeyKimi26, value: settings.kimiK26Key!.trim());
    if (settings.kimiK27CodeKey != null) await _secure.write(key: AppConstants.secureKeyKimi27Code, value: settings.kimiK27CodeKey!.trim());
    if (settings.defaultVercelToken != null) await _secure.write(key: AppConstants.secureKeyDefaultVercelToken, value: settings.defaultVercelToken!.trim());
    if (settings.githubToken != null) await _secure.write(key: AppConstants.secureKeyGithubToken, value: settings.githubToken!.trim());
  }

  @override
  Future<String?> resolveAnalystKey({String? projectCustomKey}) async {
    if (projectCustomKey != null && projectCustomKey.trim().isNotEmpty) return projectCustomKey.trim();
    return (await _secure.read(key: AppConstants.secureKeyKimi26))?.trim();
  }

  @override
  Future<String?> resolveEngineerKey({String? projectCustomKey}) async {
    if (projectCustomKey != null && projectCustomKey.trim().isNotEmpty) return projectCustomKey.trim();
    return (await _secure.read(key: AppConstants.secureKeyKimi27Code))?.trim();
  }

  @override
  Future<String?> getVercelToken() async => (await _secure.read(key: AppConstants.secureKeyDefaultVercelToken))?.trim();

  @override
  Future<String?> getGithubToken() async => (await _secure.read(key: AppConstants.secureKeyGithubToken))?.trim();
}
