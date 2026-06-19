import 'package:equatable/equatable.dart';

class ProjectEntity extends Equatable {
  final String id;
  final String name;
  final String type;
  final String status;

  final String? userIdea;
  final List<AnalystQuestion>? analystQuestions;
  final String? analystMockup;
  final ProductSpecEntity? productSpec;

  final bool planApproved;

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

  const ProjectEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    this.userIdea,
    this.analystQuestions,
    this.analystMockup,
    this.productSpec,
    this.planApproved = false,
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

  double get progress => totalFiles == 0 ? 0 : completedFiles / totalFiles;

  ProjectEntity copyWith({
    String? id,
    String? name,
    String? type,
    String? status,
    String? userIdea,
    List<AnalystQuestion>? analystQuestions,
    String? analystMockup,
    ProductSpecEntity? productSpec,
    bool? planApproved,
    int? currentStep,
    int? totalFiles,
    int? completedFiles,
    String? deployType,
    String? deployUrl,
    String? zipPath,
    String? apiKeySource,
    String? customApiKey,
    int? createdAt,
    int? updatedAt,
  }) {
    return ProjectEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      status: status ?? this.status,
      userIdea: userIdea ?? this.userIdea,
      analystQuestions: analystQuestions ?? this.analystQuestions,
      analystMockup: analystMockup ?? this.analystMockup,
      productSpec: productSpec ?? this.productSpec,
      planApproved: planApproved ?? this.planApproved,
      currentStep: currentStep ?? this.currentStep,
      totalFiles: totalFiles ?? this.totalFiles,
      completedFiles: completedFiles ?? this.completedFiles,
      deployType: deployType ?? this.deployType,
      deployUrl: deployUrl ?? this.deployUrl,
      zipPath: zipPath ?? this.zipPath,
      apiKeySource: apiKeySource ?? this.apiKeySource,
      customApiKey: customApiKey ?? this.customApiKey,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        status,
        userIdea,
        analystQuestions,
        analystMockup,
        productSpec,
        planApproved,
        currentStep,
        totalFiles,
        completedFiles,
        deployType,
        deployUrl,
        zipPath,
        apiKeySource,
        customApiKey,
        createdAt,
        updatedAt,
      ];
}

class AnalystQuestion extends Equatable {
  final String question;
  final List<String> options;

  const AnalystQuestion({required this.question, required this.options});

  factory AnalystQuestion.fromJson(Map<String, dynamic> json) {
    return AnalystQuestion(
      question: json['question']?.toString() ?? '',
      options: (json['options'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {'question': question, 'options': options};

  @override
  List<Object?> get props => [question, options];
}

class AnalystOutputEntity extends Equatable {
  final List<AnalystQuestion> questions;
  final String mockup;
  final List<String> mvpFeatures;
  final List<String> v2Features;
  final String riskAnalysis;
  final String suggestedStack;

  const AnalystOutputEntity({
    required this.questions,
    required this.mockup,
    required this.mvpFeatures,
    required this.v2Features,
    required this.riskAnalysis,
    required this.suggestedStack,
  });

  factory AnalystOutputEntity.fromJson(Map<String, dynamic> json) {
    return AnalystOutputEntity(
      questions: (json['questions'] as List? ?? [])
          .map((e) => AnalystQuestion.fromJson(e as Map<String, dynamic>))
          .toList(),
      mockup: json['mockup']?.toString() ?? '',
      mvpFeatures:
          (json['mvp_features'] as List? ?? []).map((e) => e.toString()).toList(),
      v2Features:
          (json['v2_features'] as List? ?? []).map((e) => e.toString()).toList(),
      riskAnalysis: json['risk_analysis']?.toString() ?? '',
      suggestedStack: json['suggested_stack']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'questions': questions.map((e) => e.toJson()).toList(),
        'mockup': mockup,
        'mvp_features': mvpFeatures,
        'v2_features': v2Features,
        'risk_analysis': riskAnalysis,
        'suggested_stack': suggestedStack,
      };

  @override
  List<Object?> get props =>
      [questions, mockup, mvpFeatures, v2Features, riskAnalysis, suggestedStack];
}

class SpecFile extends Equatable {
  final String path;
  final String description;
  final String language;

  const SpecFile({
    required this.path,
    required this.description,
    required this.language,
  });

  factory SpecFile.fromJson(Map<String, dynamic> json) => SpecFile(
        path: json['path']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        language: json['language']?.toString() ?? 'text',
      );

  Map<String, dynamic> toJson() =>
      {'path': path, 'description': description, 'language': language};

  @override
  List<Object?> get props => [path, description, language];
}

class DbField extends Equatable {
  final String name;
  final String type;

  const DbField({required this.name, required this.type});

  factory DbField.fromJson(Map<String, dynamic> json) =>
      DbField(name: json['name']?.toString() ?? '', type: json['type']?.toString() ?? '');

  Map<String, dynamic> toJson() => {'name': name, 'type': type};

  @override
  List<Object?> get props => [name, type];
}

class DbTable extends Equatable {
  final String table;
  final List<DbField> fields;

  const DbTable({required this.table, required this.fields});

  factory DbTable.fromJson(Map<String, dynamic> json) => DbTable(
        table: json['table']?.toString() ?? '',
        fields: (json['fields'] as List? ?? [])
            .map((e) => DbField.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() =>
      {'table': table, 'fields': fields.map((e) => e.toJson()).toList()};

  @override
  List<Object?> get props => [table, fields];
}

class ApiEndpoint extends Equatable {
  final String path;
  final String method;
  final String description;

  const ApiEndpoint({
    required this.path,
    required this.method,
    required this.description,
  });

  factory ApiEndpoint.fromJson(Map<String, dynamic> json) => ApiEndpoint(
        path: json['path']?.toString() ?? '',
        method: json['method']?.toString() ?? 'GET',
        description: json['description']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() =>
      {'path': path, 'method': method, 'description': description};

  @override
  List<Object?> get props => [path, method, description];
}

class ProductSpecEntity extends Equatable {
  final String projectName;
  final String type;
  final Map<String, String> techStack;
  final List<SpecFile> files;
  final List<DbTable> databaseSchema;
  final List<ApiEndpoint> apiEndpoints;
  final List<String> mvpFeatures;
  final List<String> v2Features;
  final String complexity;
  final int estimatedFiles;
  final int estimatedApiRoutes;

  const ProductSpecEntity({
    required this.projectName,
    required this.type,
    required this.techStack,
    required this.files,
    required this.databaseSchema,
    required this.apiEndpoints,
    required this.mvpFeatures,
    required this.v2Features,
    required this.complexity,
    required this.estimatedFiles,
    required this.estimatedApiRoutes,
  });

  factory ProductSpecEntity.fromJson(Map<String, dynamic> json) {
    final techStackRaw = json['tech_stack'] as Map<String, dynamic>? ?? {};
    return ProductSpecEntity(
      projectName: json['project_name']?.toString() ?? 'Untitled Project',
      type: json['type']?.toString() ?? 'web',
      techStack: techStackRaw.map((k, v) => MapEntry(k, v?.toString() ?? '')),
      files: (json['files'] as List? ?? [])
          .map((e) => SpecFile.fromJson(e as Map<String, dynamic>))
          .toList(),
      databaseSchema: (json['database_schema'] as List? ?? [])
          .map((e) => DbTable.fromJson(e as Map<String, dynamic>))
          .toList(),
      apiEndpoints: (json['api_endpoints'] as List? ?? [])
          .map((e) => ApiEndpoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      mvpFeatures:
          (json['mvp_features'] as List? ?? []).map((e) => e.toString()).toList(),
      v2Features:
          (json['v2_features'] as List? ?? []).map((e) => e.toString()).toList(),
      complexity: json['complexity']?.toString() ?? 'medium',
      estimatedFiles: (json['estimated_files'] as num?)?.toInt() ??
          (json['files'] as List? ?? []).length,
      estimatedApiRoutes: (json['estimated_api_routes'] as num?)?.toInt() ??
          (json['api_endpoints'] as List? ?? []).length,
    );
  }

  Map<String, dynamic> toJson() => {
        'project_name': projectName,
        'type': type,
        'tech_stack': techStack,
        'files': files.map((e) => e.toJson()).toList(),
        'database_schema': databaseSchema.map((e) => e.toJson()).toList(),
        'api_endpoints': apiEndpoints.map((e) => e.toJson()).toList(),
        'mvp_features': mvpFeatures,
        'v2_features': v2Features,
        'complexity': complexity,
        'estimated_files': estimatedFiles,
        'estimated_api_routes': estimatedApiRoutes,
      };

  @override
  List<Object?> get props => [
        projectName,
        type,
        techStack,
        files,
        databaseSchema,
        apiEndpoints,
        mvpFeatures,
        v2Features,
        complexity,
        estimatedFiles,
        estimatedApiRoutes,
      ];
}
