import '../entities/project_entity.dart';
import '../entities/file_entity.dart';

abstract class ProjectRepository {
  Future<List<ProjectEntity>> getAllProjects();
  Future<ProjectEntity?> getProjectById(String id);
  Future<void> saveProject(ProjectEntity project);
  Future<void> deleteProject(String id);

  Future<List<FileEntity>> getFilesForProject(String projectId);
  Future<void> saveFile(FileEntity file);
  Future<void> saveFiles(List<FileEntity> files);

  Future<List<ChatMessageEntity>> getChatHistory(String projectId);
  Future<void> addChatMessage(ChatMessageEntity message);
}
