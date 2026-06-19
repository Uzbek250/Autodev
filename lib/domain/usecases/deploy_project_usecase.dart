import 'package:uuid/uuid.dart';
import '../entities/project_entity.dart';
import '../entities/file_entity.dart';
import '../repositories/deploy_repository.dart';
import '../repositories/project_repository.dart';
import '../repositories/settings_repository.dart';
import '../../core/constants/app_constants.dart';
import '../../core/error/failures.dart';
import '../../core/utils/result.dart';

class DeployProjectUseCase {
  final DeployRepository deployRepository;
  final ProjectRepository projectRepository;
  final SettingsRepository settingsRepository;
  final Uuid _uuid = const Uuid();

  DeployProjectUseCase({
    required this.deployRepository,
    required this.projectRepository,
    required this.settingsRepository,
  });

  Future<Result<String>> callZip(ProjectEntity project) async {
    final files = await projectRepository.getFilesForProject(project.id);
    if (files.isEmpty) {
      return Result.error(
          const DeployFailure('Hech qanday fayl topilmadi. Avval kod yarating.'));
    }

    final result = await deployRepository.generateZip(
      projectName: project.name,
      files: files,
    );

    if (result.isError) return Result.error(result.failure!);

    final zipPath = result.value!;
    await projectRepository.saveProject(project.copyWith(
      deployType: AppConstants.deployTypeZip,
      zipPath: zipPath,
      status: AppConstants.statusDeployed,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    ));
    await projectRepository.addChatMessage(ChatMessageEntity(
      id: _uuid.v4(),
      projectId: project.id,
      agent: AppConstants.agentDeployer,
      role: AppConstants.roleAssistant,
      message: '📦 ZIP arxivi tayyor: $zipPath',
      action: 'deployed',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));
    return Result<String>.success(zipPath);
  }

  Future<Result<String>> callVercel(ProjectEntity project) async {
    final vercelToken = await settingsRepository.getVercelToken();
    if (vercelToken == null || vercelToken.isEmpty) {
      return Result.error(const DeployFailure(
        'Vercel token topilmadi. Sozlamalarda tokenni kiriting.',
      ));
    }

    final files = await projectRepository.getFilesForProject(project.id);
    if (files.isEmpty) {
      return Result.error(
          const DeployFailure('Hech qanday fayl topilmadi. Avval kod yarating.'));
    }

    final result = await deployRepository.deployToVercel(
      projectName: project.name,
      files: files,
      vercelToken: vercelToken,
    );

    if (result.isError) return Result.error(result.failure!);

    final deployUrl = result.value!;
    await projectRepository.saveProject(project.copyWith(
      deployType: AppConstants.deployTypeVercel,
      deployUrl: deployUrl,
      status: AppConstants.statusDeployed,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    ));
    await projectRepository.addChatMessage(ChatMessageEntity(
      id: _uuid.v4(),
      projectId: project.id,
      agent: AppConstants.agentDeployer,
      role: AppConstants.roleAssistant,
      message: '🚀 Vercelga yuklandi: $deployUrl',
      action: 'deployed',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));
    return Result<String>.success(deployUrl);
  }

  Future<void> shareZip(String zipPath) async {
    await deployRepository.shareFile(zipPath);
  }
}
