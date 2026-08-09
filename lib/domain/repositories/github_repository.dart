import '../../core/utils/result.dart';
import '../entities/github_entity.dart';

abstract class GitHubRepository {
  /// Recursively lists every file path in the repo at [target.branch],
  /// skipping common noise (build output, node_modules, .git, etc — see
  /// GitHubRemoteDatasource for the exact filter).
  Future<Result<List<String>>> listFiles({
    required GitHubTarget target,
    required String token,
  });

  /// Fetches the content + blob SHA of a single file.
  Future<Result<GitHubFile>> getFile({
    required GitHubTarget target,
    required String path,
    required String token,
  });

  /// Fetches several files in one call (sequential requests under the hood —
  /// the Contents API has no batch endpoint). Skips files it fails to read
  /// rather than failing the whole batch, since a single missing/binary file
  /// shouldn't block giving the agent everything else.
  Future<Result<List<GitHubFile>>> getFiles({
    required GitHubTarget target,
    required List<String> paths,
    required String token,
  });

  /// Commits [change] directly to [target.branch] via the Contents API
  /// (one commit per file — GitHub's Contents API doesn't support atomic
  /// multi-file commits). Returns the new commit SHA.
  Future<Result<String>> commitFile({
    required GitHubTarget target,
    required GitHubChange change,
    required String token,
    required String commitMessage,
  });
}
