import 'package:equatable/equatable.dart';

/// A single file pulled from (or about to be pushed to) a GitHub repo.
class GitHubFile extends Equatable {
  final String path;
  final String content;

  /// The blob SHA GitHub gave us when we fetched this file. Required when
  /// updating an existing file via the Contents API — GitHub uses it to
  /// detect conflicting edits. Null for a brand new file.
  final String? sha;

  const GitHubFile({required this.path, required this.content, this.sha});

  @override
  List<Object?> get props => [path, content, sha];
}

/// Identifies a repo + branch the user wants AutoDev to work against.
class GitHubTarget extends Equatable {
  final String owner;
  final String repo;
  final String branch;

  const GitHubTarget({
    required this.owner,
    required this.repo,
    this.branch = 'main',
  });

  String get fullName => '$owner/$repo';

  @override
  List<Object?> get props => [owner, repo, branch];
}

/// One file the Engineer/Fixer agent changed as part of a GitHub task,
/// kept in memory so the UI can show a diff-style summary before pushing.
class GitHubChange extends Equatable {
  final String path;
  final String newContent;
  final String? previousContent; // null if this is a new file
  final String status; // pending, applied, error
  final String? errorLog;

  const GitHubChange({
    required this.path,
    required this.newContent,
    this.previousContent,
    this.status = 'pending',
    this.errorLog,
  });

  bool get isNewFile => previousContent == null;

  GitHubChange copyWith({String? status, String? errorLog}) => GitHubChange(
        path: path,
        newContent: newContent,
        previousContent: previousContent,
        status: status ?? this.status,
        errorLog: errorLog ?? this.errorLog,
      );

  @override
  List<Object?> get props =>
      [path, newContent, previousContent, status, errorLog];
}
