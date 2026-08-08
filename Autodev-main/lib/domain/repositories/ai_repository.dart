import '../../core/utils/result.dart';
import '../entities/project_entity.dart';

abstract class AiRepository {
  /// Runs the Analyst agent on the user's raw idea text.
  /// [apiKey] is the resolved Kimi API key (custom or default).
  Future<Result<AnalystOutputEntity>> runAnalyst({
    required String userIdea,
    required String apiKey,
  });

  /// Runs the Thinking agent on the approved analyst output, producing a
  /// strict ProductSpec JSON.
  Future<Result<ProductSpecEntity>> runThinking({
    required String userIdea,
    required AnalystOutputEntity analystOutput,
    required String apiKey,
  });

  /// Runs the Engineer agent for a single file, given full project context
  /// and any previously generated files (for cross-file dependencies).
  Future<Result<String>> generateFile({
    required ProductSpecEntity spec,
    required SpecFile file,
    required Map<String, String> previousFiles,
    required String apiKey,
  });

  /// Runs the Fixer agent on a single file given its current code and error.
  Future<Result<String>> fixFile({
    required String filePath,
    required String currentCode,
    required String errorMessage,
    required String apiKey,
  });
}
