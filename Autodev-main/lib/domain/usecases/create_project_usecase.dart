import 'package:uuid/uuid.dart';
import '../entities/project_entity.dart';
import '../entities/file_entity.dart';
import '../repositories/project_repository.dart';
import '../../core/constants/app_constants.dart';

class CreateProjectUseCase {
  final ProjectRepository repository;
  final Uuid _uuid = const Uuid();

  CreateProjectUseCase(this.repository);

  Future<ProjectEntity> call(String userIdea, {String? clientApiKey}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final project = ProjectEntity(
      id: _uuid.v4(),
      name: _deriveName(userIdea),
      type: AppConstants.typeWeb,
      status: AppConstants.statusPlanning,
      userIdea: userIdea,
      currentStep: AppConstants.stepAnalyst,
      apiKeySource: (clientApiKey != null && clientApiKey.isNotEmpty)
          ? AppConstants.apiKeySourceCustom
          : AppConstants.apiKeySourceDefault,
      customApiKey: (clientApiKey != null && clientApiKey.isNotEmpty)
          ? clientApiKey
          : null,
      createdAt: now,
      updatedAt: now,
    );
    await repository.saveProject(project);
    await repository.addChatMessage(ChatMessageEntity(
      id: _uuid.v4(),
      projectId: project.id,
      agent: AppConstants.agentSystem,
      role: AppConstants.roleUser,
      message: userIdea,
      createdAt: now,
    ));
    return project;
  }

  String _deriveName(String idea) {
    final trimmed = idea.trim();
    if (trimmed.isEmpty) return 'New Project';
    final words = trimmed.split(RegExp(r'\s+'));
    final name = words.take(6).join(' ');
    return name.length > 60 ? '${name.substring(0, 60)}...' : name;
  }
}
