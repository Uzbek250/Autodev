import 'dart:convert';
import '../../domain/entities/project_entity.dart';
import '../../domain/entities/file_entity.dart';

class ProjectModel {
  final String id;
  final String name;
  final String type;
  final String status;
  final String? userIdea;
  final String? analystQuestionsJson;
  final String? analystMockup;
  final String? productSpecJson;
  final int planApproved;
  final int currentStep;
  final int totalFiles;
  final int completedFiles;
  final String? deployType;
  final String? deployUrl;
  final String? zipPath;
  final String apiKeySource;
  final String? customApiKey;
  final int createdAt;
  final int updatedAt;

  const ProjectModel({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    this.userIdea,
    this.analystQuestionsJson,
    this.analystMockup,
    this.productSpecJson,
    this.planApproved = 0,
    this.currentStep = 1,
    this.totalFiles = 0,
    this.completedFiles = 0,
    this.deployType,
    this.deployUrl,
    this.zipPath,
    this.apiKeySource = 'default',
    this.customApiKey,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProjectModel.fromMap(Map<String, dynamic> map) {
    return ProjectModel(
      id: map['id'] as String,
      name: map['name'] as String,
      type: map['type'] as String,
      status: map['status'] as String,
      userIdea: map['user_idea'] as String?,
      analystQuestionsJson: map['analyst_questions'] as String?,
      analystMockup: map['analyst_mockup'] as String?,
      productSpecJson: map['product_spec'] as String?,
      planApproved: (map['plan_approved'] as int?) ?? 0,
      currentStep: (map['current_step'] as int?) ?? 1,
      totalFiles: (map['total_files'] as int?) ?? 0,
      completedFiles: (map['completed_files'] as int?) ?? 0,
      deployType: map['deploy_type'] as String?,
      deployUrl: map['deploy_url'] as String?,
      zipPath: map['zip_path'] as String?,
      apiKeySource: (map['api_key_source'] as String?) ?? 'default',
      customApiKey: map['custom_api_key'] as String?,
      createdAt: (map['created_at'] as int?) ?? 0,
      updatedAt: (map['updated_at'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type,
        'status': status,
        'user_idea': userIdea,
        'analyst_questions': analystQuestionsJson,
        'analyst_mockup': analystMockup,
        'product_spec': productSpecJson,
        'plan_approved': planApproved,
        'current_step': currentStep,
        'total_files': totalFiles,
        'completed_files': completedFiles,
        'deploy_type': deployType,
        'deploy_url': deployUrl,
        'zip_path': zipPath,
        'api_key_source': apiKeySource,
        'custom_api_key': customApiKey,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  ProjectEntity toEntity() {
    List<AnalystQuestion>? questions;
    if (analystQuestionsJson != null && analystQuestionsJson!.isNotEmpty) {
      try {
        final raw = jsonDecode(analystQuestionsJson!) as List?;
        questions = raw
            ?.map((e) => AnalystQuestion.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        questions = null;
      }
    }

    ProductSpecEntity? spec;
    if (productSpecJson != null && productSpecJson!.isNotEmpty) {
      try {
        final raw = jsonDecode(productSpecJson!) as Map<String, dynamic>;
        spec = ProductSpecEntity.fromJson(raw);
      } catch (_) {
        spec = null;
      }
    }

    return ProjectEntity(
      id: id,
      name: name,
      type: type,
      status: status,
      userIdea: userIdea,
      analystQuestions: questions,
      analystMockup: analystMockup,
      productSpec: spec,
      planApproved: planApproved == 1,
      currentStep: currentStep,
      totalFiles: totalFiles,
      completedFiles: completedFiles,
      deployType: deployType,
      deployUrl: deployUrl,
      zipPath: zipPath,
      apiKeySource: apiKeySource,
      customApiKey: customApiKey,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory ProjectModel.fromEntity(ProjectEntity entity) {
    String? questionsJson;
    if (entity.analystQuestions != null) {
      questionsJson =
          jsonEncode(entity.analystQuestions!.map((e) => e.toJson()).toList());
    }

    String? specJson;
    if (entity.productSpec != null) {
      specJson = jsonEncode(entity.productSpec!.toJson());
    }

    return ProjectModel(
      id: entity.id,
      name: entity.name,
      type: entity.type,
      status: entity.status,
      userIdea: entity.userIdea,
      analystQuestionsJson: questionsJson,
      analystMockup: entity.analystMockup,
      productSpecJson: specJson,
      planApproved: entity.planApproved ? 1 : 0,
      currentStep: entity.currentStep,
      totalFiles: entity.totalFiles,
      completedFiles: entity.completedFiles,
      deployType: entity.deployType,
      deployUrl: entity.deployUrl,
      zipPath: entity.zipPath,
      apiKeySource: entity.apiKeySource,
      customApiKey: entity.customApiKey,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}

class FileModel {
  final String id;
  final String projectId;
  final String path;
  final String code;
  final int version;
  final String language;
  final String status;
  final String? errorLog;

  const FileModel({
    required this.id,
    required this.projectId,
    required this.path,
    required this.code,
    this.version = 1,
    required this.language,
    this.status = 'pending',
    this.errorLog,
  });

  factory FileModel.fromMap(Map<String, dynamic> map) => FileModel(
        id: map['id'] as String,
        projectId: map['project_id'] as String,
        path: map['path'] as String,
        code: map['code'] as String,
        version: (map['version'] as int?) ?? 1,
        language: (map['language'] as String?) ?? 'text',
        status: (map['status'] as String?) ?? 'pending',
        errorLog: map['error_log'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'project_id': projectId,
        'path': path,
        'code': code,
        'version': version,
        'language': language,
        'status': status,
        'error_log': errorLog,
      };

  FileEntity toEntity() => FileEntity(
        id: id,
        projectId: projectId,
        path: path,
        code: code,
        version: version,
        language: language,
        status: status,
        errorLog: errorLog,
      );

  factory FileModel.fromEntity(FileEntity entity) => FileModel(
        id: entity.id,
        projectId: entity.projectId,
        path: entity.path,
        code: entity.code,
        version: entity.version,
        language: entity.language,
        status: entity.status,
        errorLog: entity.errorLog,
      );
}

class ChatMessageModel {
  final String id;
  final String projectId;
  final String agent;
  final String role;
  final String message;
  final String? action;
  final int createdAt;

  const ChatMessageModel({
    required this.id,
    required this.projectId,
    required this.agent,
    required this.role,
    required this.message,
    this.action,
    required this.createdAt,
  });

  factory ChatMessageModel.fromMap(Map<String, dynamic> map) =>
      ChatMessageModel(
        id: map['id'] as String,
        projectId: map['project_id'] as String,
        agent: map['agent'] as String,
        role: map['role'] as String,
        message: map['message'] as String,
        action: map['action'] as String?,
        createdAt: (map['created_at'] as int?) ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'project_id': projectId,
        'agent': agent,
        'role': role,
        'message': message,
        'action': action,
        'created_at': createdAt,
      };

  ChatMessageEntity toEntity() => ChatMessageEntity(
        id: id,
        projectId: projectId,
        agent: agent,
        role: role,
        message: message,
        action: action,
        createdAt: createdAt,
      );

  factory ChatMessageModel.fromEntity(ChatMessageEntity entity) =>
      ChatMessageModel(
        id: entity.id,
        projectId: entity.projectId,
        agent: entity.agent,
        role: entity.role,
        message: entity.message,
        action: entity.action,
        createdAt: entity.createdAt,
      );
}
