import '../../core/utils/result.dart';
import '../entities/file_entity.dart';

abstract class DeployRepository {
  /// Builds a ZIP archive from [files] plus a generated README, saves it to
  /// app temp storage, and returns the absolute file path.
  Future<Result<String>> generateZip({
    required String projectName,
    required List<FileEntity> files,
  });

  /// Deploys [files] to Vercel and returns the live deployment URL.
  Future<Result<String>> deployToVercel({
    required String projectName,
    required List<FileEntity> files,
    required String vercelToken,
  });

  /// Shares a file at [path] using the platform share sheet.
  Future<void> shareFile(String path);
}
