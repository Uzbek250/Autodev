import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/error/failures.dart';
import '../../../domain/entities/github_entity.dart';

/// Paths never worth pulling into the agent's context: build artifacts,
/// dependency caches, lockfiles, and VCS internals. Kept as substring
/// matches on the path for simplicity rather than full gitignore parsing.
const _ignoredPathSegments = [
  '/.git/',
  '/node_modules/',
  '/build/',
  '/.dart_tool/',
  '/.gradle/',
  'ios/Pods/',
  '/.idea/',
  '/.vscode/',
];

const _ignoredExtensions = [
  '.lock',
  '.png',
  '.jpg',
  '.jpeg',
  '.gif',
  '.ico',
  '.webp',
  '.ttf',
  '.otf',
  '.jar',
  '.keystore',
  '.jks',
];

/// Raw HTTP datasource for the GitHub REST API (v3, api.github.com).
/// Throws [ServerException] / [NetworkException].
class GitHubRemoteDatasource {
  final Dio _dio;

  GitHubRemoteDatasource({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: 'https://api.github.com',
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
            ));

  Options _authHeaders(String token) => Options(headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
      });

  Future<T> _wrap<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          (e.type == DioExceptionType.unknown &&
              e.error?.toString().contains('SocketException') == true)) {
        throw NetworkException(
            'Internet aloqasi yo\'q yoki GitHub javob bermadi.');
      }
      final status = e.response?.statusCode;
      if (status == 401) {
        throw ServerException(
            'GitHub token noto\'g\'ri yoki muddati o\'tgan.');
      }
      if (status == 403) {
        throw ServerException(
            'GitHub ruxsat bermadi (403). Token\'da "repo" huquqi borligini tekshiring, yoki rate-limit\'ga tegib qolgan bo\'lishingiz mumkin.');
      }
      if (status == 404) {
        throw ServerException(
            'Repo yoki fayl topilmadi. Owner/repo nomi va branch to\'g\'riligini tekshiring.');
      }
      if (status == 409) {
        throw ServerException(
            'Fayl boshqa joyda o\'zgargan (SHA mos kelmadi). Qayta urinib ko\'ring.');
      }
      throw ServerException('GitHub xatosi: $status - ${e.message}');
    }
  }

  bool _shouldSkip(String path) {
    final lower = path.toLowerCase();
    if (_ignoredPathSegments.any((seg) => '/$lower'.contains(seg))) {
      return true;
    }
    return _ignoredExtensions.any((ext) => lower.endsWith(ext));
  }

  /// Uses the Git Trees API (recursive=1) to list every blob path in one
  /// call, instead of walking the Contents API directory-by-directory.
  Future<List<String>> listFiles({
    required String owner,
    required String repo,
    required String branch,
    required String token,
  }) async {
    return _wrap(() async {
      final response = await _dio.get(
        '/repos/$owner/$repo/git/trees/$branch',
        queryParameters: {'recursive': '1'},
        options: _authHeaders(token),
      );
      final data = response.data as Map<String, dynamic>;
      final tree = data['tree'] as List? ?? [];
      final paths = tree
          .cast<Map<String, dynamic>>()
          .where((entry) => entry['type'] == 'blob')
          .map((entry) => entry['path'] as String)
          .where((path) => !_shouldSkip(path))
          .toList();

      if (data['truncated'] == true) {
        // Extremely large repos: GitHub capped the tree response. We still
        // return what we got rather than failing outright — the agent can
        // work with a partial file list, and a full walk is out of scope
        // for a mobile client.
      }
      return paths;
    });
  }

  /// Fetches one file's content (base64-decoded) and blob SHA.
  Future<GitHubFile> getFile({
    required String owner,
    required String repo,
    required String path,
    required String branch,
    required String token,
  }) async {
    return _wrap(() async {
      final response = await _dio.get(
        '/repos/$owner/$repo/contents/$path',
        queryParameters: {'ref': branch},
        options: _authHeaders(token),
      );
      final data = response.data as Map<String, dynamic>;
      final encoding = data['encoding'] as String?;
      final rawContent = (data['content'] as String? ?? '').replaceAll('\n', '');
      final content = encoding == 'base64'
          ? utf8.decode(base64.decode(rawContent), allowMalformed: true)
          : rawContent;
      return GitHubFile(
        path: path,
        content: content,
        sha: data['sha'] as String?,
      );
    });
  }

  /// Creates or updates a single file via the Contents API. This produces
  /// one commit per file (the Contents API has no multi-file/atomic commit
  /// support) — acceptable for AutoDev's use case of a handful of targeted
  /// changes, not a full-repo rewrite.
  Future<String> commitFile({
    required String owner,
    required String repo,
    required String path,
    required String branch,
    required String content,
    required String commitMessage,
    required String token,
    String? sha,
  }) async {
    return _wrap(() async {
      final response = await _dio.put(
        '/repos/$owner/$repo/contents/$path',
        options: _authHeaders(token),
        data: jsonEncode({
          'message': commitMessage,
          'content': base64.encode(utf8.encode(content)),
          'branch': branch,
          if (sha != null) 'sha': sha,
        }),
      );
      final data = response.data as Map<String, dynamic>;
      final commit = data['commit'] as Map<String, dynamic>?;
      return commit?['sha'] as String? ?? '';
    });
  }
}
