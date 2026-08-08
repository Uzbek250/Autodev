import 'package:equatable/equatable.dart';
import '../../../domain/entities/project_entity.dart';
import '../../../domain/entities/file_entity.dart';

abstract class ProjectEvent extends Equatable {
  const ProjectEvent();
  @override
  List<Object?> get props => [];
}

/// Start the full pipeline from a user's raw idea text.
class ProjectCreateEvent extends ProjectEvent {
  final String userIdea;
  final String? clientApiKey; // Mijoz o'z kalitini bersa
  const ProjectCreateEvent(this.userIdea, {this.clientApiKey});
  @override
  List<Object?> get props => [userIdea, clientApiKey];
}

/// Analyst finished → approval pending.
class ProjectAnalystCompleteEvent extends ProjectEvent {
  final AnalystOutputEntity output;
  final ProjectEntity project;
  const ProjectAnalystCompleteEvent(this.output, this.project);
  @override
  List<Object?> get props => [output, project];
}

/// User approved the analyst plan.
class ProjectPlanApprovedEvent extends ProjectEvent {
  final ProjectEntity project;
  final AnalystOutputEntity analystOutput;
  const ProjectPlanApprovedEvent(this.project, this.analystOutput);
  @override
  List<Object?> get props => [project, analystOutput];
}

/// User rejected the plan → go back to chat.
class ProjectPlanRejectedEvent extends ProjectEvent {
  final ProjectEntity project;
  const ProjectPlanRejectedEvent(this.project);
  @override
  List<Object?> get props => [project];
}

/// Thinking agent finished → now start engineering.
class ProjectThinkingCompleteEvent extends ProjectEvent {
  final ProductSpecEntity spec;
  final ProjectEntity project;
  const ProjectThinkingCompleteEvent(this.spec, this.project);
  @override
  List<Object?> get props => [spec, project];
}

/// Progress tick from the engineer loop.
class ProjectEngineerProgressEvent extends ProjectEvent {
  final int current;
  final int total;
  final String filePath;
  const ProjectEngineerProgressEvent(this.current, this.total, this.filePath);
  @override
  List<Object?> get props => [current, total, filePath];
}

/// All files have been generated (with or without errors).
class ProjectEngineerCompleteEvent extends ProjectEvent {
  final List<FileEntity> files;
  final ProjectEntity project;
  const ProjectEngineerCompleteEvent(this.files, this.project);
  @override
  List<Object?> get props => [files, project];
}

/// User triggered a deploy action.
class ProjectDeployZipEvent extends ProjectEvent {
  final ProjectEntity project;
  const ProjectDeployZipEvent(this.project);
  @override
  List<Object?> get props => [project];
}

class ProjectDeployVercelEvent extends ProjectEvent {
  final ProjectEntity project;
  const ProjectDeployVercelEvent(this.project);
  @override
  List<Object?> get props => [project];
}

/// Load all projects for the home screen.
class ProjectsLoadAllEvent extends ProjectEvent {
  const ProjectsLoadAllEvent();
}

/// Load a single project by ID.
class ProjectLoadEvent extends ProjectEvent {
  final String projectId;
  const ProjectLoadEvent(this.projectId);
  @override
  List<Object?> get props => [projectId];
}

/// Delete a project.
class ProjectDeleteEvent extends ProjectEvent {
  final String projectId;
  const ProjectDeleteEvent(this.projectId);
  @override
  List<Object?> get props => [projectId];
}

/// Generic error acknowledgement.
class ProjectErrorAcknowledgeEvent extends ProjectEvent {
  const ProjectErrorAcknowledgeEvent();
}
