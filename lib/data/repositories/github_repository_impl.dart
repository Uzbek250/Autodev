import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/github_entity.dart';
import '../../domain/repositories/github_repository.dart';
import '../datasources/remote/github_remote_datasource.dart';

class GitHubRepositoryImpl implements GitHubRepository {
  final GitHubRemoteDatasource _remote;

  GitHubRepositoryImpl(this._remote);

  @override
  Future<Result<List<String>>> listFiles({
    required GitHubTarget target,
    required String token,
  }) async {
    try {
      final paths = await _remote.listFiles(
        owner: target.owner,
        repo: target.repo,
        branch: target.branch,
        token: token,
      );
      return Result.success(paths);
    } on NetworkException catch (e) {
      return Result.error(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Result.error(ServerFailure(e.message));
    } catch (e) {
      return Result.error(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<GitHubFile>> getFile({
    required GitHubTarget target,
    required String path,
    required String token,
  }) async {
    try {
      final file = await _remote.getFile(
        owner: target.owner,
        repo: target.repo,
        path: path,
        branch: target.branch,
        token: token,
      );
      return Result.success(file);
    } on NetworkException catch (e) {
      return Result.error(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Result.error(ServerFailure(e.message));
    } catch (e) {
      return Result.error(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<GitHubFile>>> getFiles({
    required GitHubTarget target,
    required List<String> paths,
    required String token,
  }) async {
    final files = <GitHubFile>[];
    for (final path in paths) {
      final result = await getFile(target: target, path: path, token: token);
      // A single unreadable file (binary, submodule, permissions quirk)
      // shouldn't abort the whole batch — skip it and keep going so the
      // agent still gets everything else in context.
      if (result.isSuccess) {
        files.add(result.value!);
      }
    }
    return Result.success(files);
  }

  @override
  Future<Result<String>> commitFile({
    required GitHubTarget target,
    required GitHubChange change,
    required String token,
    required String commitMessage,
  }) async {
    try {
      // Refetch the current SHA right before writing. The one we may have
      // cached from listFiles()/getFile() earlier in the session can go
      // stale if anything else touched the file meanwhile, and a stale SHA
      // makes GitHub reject the write with a 409 instead of just applying it.
      String? sha;
      final existing =
          await getFile(target: target, path: change.path, token: token);
      if (existing.isSuccess) {
        sha = existing.value!.sha;
      }

      final commitSha = await _remote.commitFile(
        owner: target.owner,
        repo: target.repo,
        path: change.path,
        branch: target.branch,
        content: change.newContent,
        commitMessage: commitMessage,
        token: token,
        sha: sha,
      );
      return Result.success(commitSha);
    } on NetworkException catch (e) {
      return Result.error(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Result.error(ServerFailure(e.message));
    } catch (e) {
      return Result.error(ServerFailure(e.toString()));
    }
  }
}
