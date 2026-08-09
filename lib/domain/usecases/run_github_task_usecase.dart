import '../entities/github_entity.dart';
import '../repositories/ai_repository.dart';
import '../repositories/github_repository.dart';
import '../repositories/settings_repository.dart';
import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../../core/utils/code_validator.dart';

/// How many other repo files (besides the target file itself) get pulled in
/// as read-only context for the agent. Kept small on purpose: each context
/// file adds to the prompt token count, and on a mobile connection large
/// repos would otherwise make every task slow and expensive for little gain
/// — most fixes only need a couple of neighboring files for import/style
/// context, not the whole tree.
const _maxContextFiles = 6;

class RunGitHubTaskUseCase {
  final AiRepository aiRepository;
  final GitHubRepository githubRepository;
  final SettingsRepository settingsRepository;

  RunGitHubTaskUseCase({
    required this.aiRepository,
    required this.githubRepository,
    required this.settingsRepository,
  });

  /// Runs one task against one file in [target]:
  /// 1. Fetch the target file (need its content + SHA).
  /// 2. Fetch a small set of nearby files as read-only context.
  /// 3. Ask the agent to produce the new file content.
  /// 4. Validate it (brace balance / non-empty / no leftover placeholders).
  /// 5. Commit it back to the branch.
  ///
  /// Returns the new commit SHA on success.
  Future<Result<String>> call({
    required GitHubTarget target,
    required String taskDescription,
    required String targetFilePath,
    List<String> contextFilePaths = const [],
  }) async {
    final githubToken = await settingsRepository.getGithubToken();
    if (githubToken == null || githubToken.isEmpty) {
      return Result.error(const ApiKeyMissingFailure(
        'GitHub token topilmadi. Sozlamalarda "GitHub token" ni kiriting.',
      ));
    }

    final apiKey = await settingsRepository.resolveEngineerKey();
    if (apiKey == null || apiKey.isEmpty) {
      return Result.error(const ApiKeyMissingFailure(
        'DeepSeek (Engineer) API kalit topilmadi. Sozlamalarda kiriting.',
      ));
    }

    // 1. Fetch the target file.
    final targetFileResult = await githubRepository.getFile(
      target: target,
      path: targetFilePath,
      token: githubToken,
    );
    if (targetFileResult.isError) {
      return Result.error(targetFileResult.failure!);
    }
    final targetFile = targetFileResult.value!;

    // 2. Fetch context files (best-effort — missing ones are just skipped).
    final contextPaths = contextFilePaths.take(_maxContextFiles).toList();
    final repoContext = <String, String>{};
    if (contextPaths.isNotEmpty) {
      final contextResult = await githubRepository.getFiles(
        target: target,
        paths: contextPaths,
        token: githubToken,
      );
      if (contextResult.isSuccess) {
        for (final f in contextResult.value!) {
          repoContext[f.path] = f.content;
        }
      }
    }

    // 3. Run the agent, with one retry-with-error-context if validation fails.
    String? finalCode;
    String? lastError;
    var attempts = 0;
    const maxAttempts = 3;

    while (finalCode == null && attempts < maxAttempts) {
      attempts++;
      final genResult = await aiRepository.applyGitHubTask(
        taskDescription: lastError == null
            ? taskDescription
            : '$taskDescription\n\n(Previous attempt failed validation: $lastError. Please fix that too.)',
        filePath: targetFilePath,
        currentCode: targetFile.content,
        repoContext: repoContext,
        apiKey: apiKey,
      );

      if (genResult.isError) {
        lastError = genResult.failure?.message;
        continue;
      }

      final validation =
          CodeValidator.validate(genResult.value!, _languageFor(targetFilePath));
      if (validation.isValid) {
        finalCode = genResult.value!;
      } else {
        lastError = validation.error;
      }
    }

    if (finalCode == null) {
      return Result.error(ServerFailure(
        '$maxAttempts urinishdan keyin ham yaroqli kod olinmadi: $lastError',
      ));
    }

    // 4. Commit.
    final commitResult = await githubRepository.commitFile(
      target: target,
      change: GitHubChange(
        path: targetFilePath,
        newContent: finalCode,
        previousContent: targetFile.content,
      ),
      token: githubToken,
      commitMessage: 'AutoDev: $taskDescription',
    );

    return commitResult;
  }

  String _languageFor(String path) {
    final ext = path.split('.').last.toLowerCase();
    const map = {
      'dart': 'dart',
      'js': 'javascript',
      'jsx': 'javascript',
      'ts': 'typescript',
      'tsx': 'typescript',
      'py': 'python',
      'java': 'java',
      'kt': 'kotlin',
      'go': 'go',
      'rb': 'ruby',
      'php': 'php',
      'json': 'json',
      'yaml': 'yaml',
      'yml': 'yaml',
    };
    return map[ext] ?? 'text';
  }
}
