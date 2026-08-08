import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../entities/project_entity.dart';
import '../entities/file_entity.dart';
import '../repositories/ai_repository.dart';
import '../repositories/project_repository.dart';
import '../repositories/settings_repository.dart';
import '../../core/constants/app_constants.dart';
import '../../core/error/failures.dart';
import '../../core/utils/result.dart';

class RunThinkingUseCase {
  final AiRepository aiRepository;
  final ProjectRepository projectRepository;
  final SettingsRepository settingsRepository;
  final Uuid _uuid = const Uuid();

  RunThinkingUseCase({
    required this.aiRepository,
    required this.projectRepository,
    required this.settingsRepository,
  });

  Future<Result<ProductSpecEntity>> call({
    required ProjectEntity project,
    required AnalystOutputEntity analystOutput,
  }) async {
    final apiKey = await settingsRepository.resolveAnalystKey(
      projectCustomKey: project.customApiKey,
    );
    if (apiKey == null || apiKey.isEmpty) {
      return Result.error(const ApiKeyMissingFailure(
        'DeepSeek (Analyst) API kalit topilmadi. Sozlamalarda "Analyst kalit" ni kiriting.',
      ));
    }

    final result = await aiRepository.runThinking(
      userIdea: project.userIdea ?? '',
      analystOutput: analystOutput,
      apiKey: apiKey,
    );

    if (result.isError) {
      final failure = result.failure!;
      await projectRepository.addChatMessage(ChatMessageEntity(
        id: _uuid.v4(),
        projectId: project.id,
        agent: AppConstants.agentThinking,
        role: AppConstants.roleAssistant,
        message: 'Xatolik yuz berdi: ${failure.message}',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ));
      return Result<ProductSpecEntity>.error(failure);
    }

    final spec = result.value!;
    final updated = project.copyWith(
      name: spec.projectName,
      type: spec.type,
      productSpec: spec,
      totalFiles: spec.files.length,
      currentStep: AppConstants.stepEngineer,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await projectRepository.saveProject(updated);
    await projectRepository.addChatMessage(ChatMessageEntity(
      id: _uuid.v4(),
      projectId: project.id,
      agent: AppConstants.agentThinking,
      role: AppConstants.roleAssistant,
      message: jsonEncode(spec.toJson()),
      action: 'plan_created',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));
    return Result<ProductSpecEntity>.success(spec);
  }
}
