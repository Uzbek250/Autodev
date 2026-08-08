import 'package:uuid/uuid.dart';
import '../entities/project_entity.dart';
import '../entities/file_entity.dart';
import '../repositories/ai_repository.dart';
import '../repositories/project_repository.dart';
import '../repositories/settings_repository.dart';
import '../../core/constants/app_constants.dart';
import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../../core/utils/code_validator.dart';

/// Callback fired after each file is written/fixed so the BLoC can
/// stream live progress to the UI.
typedef EngineerProgressCallback = void Function(int current, int total, String filePath);

class RunEngineerUseCase {
  final AiRepository aiRepository;
  final ProjectRepository projectRepository;
  final SettingsRepository settingsRepository;
  final Uuid _uuid = const Uuid();

  RunEngineerUseCase({
    required this.aiRepository,
    required this.projectRepository,
    required this.settingsRepository,
  });

  Future<Result<List<FileEntity>>> call({
    required ProjectEntity project,
    required ProductSpecEntity spec,
    EngineerProgressCallback? onProgress,
  }) async {
    final apiKey = await settingsRepository.resolveEngineerKey(
      projectCustomKey: project.customApiKey,
    );
    if (apiKey == null || apiKey.isEmpty) {
      return Result.error(const ApiKeyMissingFailure(
        'DeepSeek (Engineer) API kalit topilmadi. Sozlamalarda "Engineer kalit" ni kiriting.',
      ));
    }

    final totalFiles = spec.files.length;
    final completedFiles = <FileEntity>[];
    final previousFilesMap = <String, String>{};

    // Update project status to coding
    await projectRepository.saveProject(project.copyWith(
      status: AppConstants.statusCoding,
      totalFiles: totalFiles,
      completedFiles: 0,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    ));

    for (var i = 0; i < spec.files.length; i++) {
      final specFile = spec.files[i];
      final fileId = _uuid.v4();

      // Mark file as "writing" in DB
      final pendingFile = FileEntity(
        id: fileId,
        projectId: project.id,
        path: specFile.path,
        code: '',
        language: specFile.language,
        status: AppConstants.fileStatusWriting,
      );
      await projectRepository.saveFile(pendingFile);

      // First generation attempt
      var genResult = await aiRepository.generateFile(
        spec: spec,
        file: specFile,
        previousFiles: Map.unmodifiable(previousFilesMap),
        apiKey: apiKey,
      );

      String? finalCode;
      String? lastError;
      int attempts = 0;

      if (genResult.isSuccess) {
        final validation = CodeValidator.validate(genResult.value!, specFile.language);
        if (validation.isValid) {
          finalCode = genResult.value!;
        } else {
          lastError = validation.error;
        }
      } else {
        lastError = genResult.failure?.message;
      }

      // Auto-fix loop (up to ApiConstants.maxAutoFixAttempts)
      const maxFix = 5;
      while (finalCode == null && attempts < maxFix) {
        attempts++;
        await projectRepository.saveProject(project.copyWith(
          status: AppConstants.statusFixing,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        ));

        final fixResult = await aiRepository.fixFile(
          filePath: specFile.path,
          currentCode: genResult.value ?? '',
          errorMessage: lastError ?? 'Unknown error',
          apiKey: apiKey,
        );

        if (fixResult.isSuccess) {
          final fixValidation =
              CodeValidator.validate(fixResult.value!, specFile.language);
          if (fixValidation.isValid) {
            finalCode = fixResult.value!;
          } else {
            lastError = fixValidation.error;
            genResult = fixResult;
          }
        } else {
          lastError = fixResult.failure?.message;
        }
      }

      if (finalCode != null) {
        final readyFile = FileEntity(
          id: fileId,
          projectId: project.id,
          path: specFile.path,
          code: finalCode,
          version: attempts + 1,
          language: specFile.language,
          status: AppConstants.fileStatusReady,
        );
        await projectRepository.saveFile(readyFile);
        completedFiles.add(readyFile);
        previousFilesMap[specFile.path] = finalCode;

        await projectRepository.addChatMessage(ChatMessageEntity(
          id: _uuid.v4(),
          projectId: project.id,
          agent: AppConstants.agentEngineer,
          role: AppConstants.roleAssistant,
          message: '✅ ${specFile.path} yazildi${attempts > 0 ? " ($attempts ta tuzatishdan keyin)" : ""}',
          action: 'code_generated',
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ));
      } else {
        // Max retries exhausted — mark as error but continue other files
        final errorFile = FileEntity(
          id: fileId,
          projectId: project.id,
          path: specFile.path,
          code: genResult.value ?? '// Generation failed after $maxFix attempts',
          version: maxFix + 1,
          language: specFile.language,
          status: AppConstants.fileStatusError,
          errorLog: lastError,
        );
        await projectRepository.saveFile(errorFile);
        completedFiles.add(errorFile);

        await projectRepository.addChatMessage(ChatMessageEntity(
          id: _uuid.v4(),
          projectId: project.id,
          agent: AppConstants.agentEngineer,
          role: AppConstants.roleAssistant,
          message: '⚠️ ${specFile.path} - $maxFix urinishdan keyin ham xato: $lastError',
          action: 'error_fixed',
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ));
      }

      // Persist progress
      final newCompleted = completedFiles.length;
      await projectRepository.saveProject(project.copyWith(
        status: AppConstants.statusCoding,
        completedFiles: newCompleted,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ));
      onProgress?.call(newCompleted, totalFiles, specFile.path);
    }

    // Final status update
    final allReady = completedFiles.every((f) => f.status == AppConstants.fileStatusReady);
    await projectRepository.saveProject(project.copyWith(
      status: allReady ? AppConstants.statusReady : AppConstants.statusFixing,
      completedFiles: completedFiles.length,
      currentStep: AppConstants.stepDeploy,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    ));

    return Result<List<FileEntity>>.success(completedFiles);
  }
}
