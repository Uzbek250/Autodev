import 'package:equatable/equatable.dart';
import '../../../domain/entities/project_entity.dart';
import '../../../domain/entities/file_entity.dart';

abstract class ProjectState extends Equatable {
  const ProjectState();
  @override
  List<Object?> get props => [];
}

/// Nothing loaded yet.
class ProjectInitial extends ProjectState {
  const ProjectInitial();
}

/// Loading the list of all projects.
class ProjectsLoading extends ProjectState {
  const ProjectsLoading();
}

/// Home screen: list of all projects available.
class ProjectsLoaded extends ProjectState {
  final List<ProjectEntity> projects;
  const ProjectsLoaded(this.projects);
  @override
  List<Object?> get props => [projects];
}

/// A single project is being created / idea submitted.
class ProjectCreating extends ProjectState {
  const ProjectCreating();
}

/// Analyst agent is running.
class ProjectAnalystLoading extends ProjectState {
  final ProjectEntity project;
  const ProjectAnalystLoading(this.project);
  @override
  List<Object?> get props => [project];
}

/// Analyst is done — waiting for user to approve or reject the plan.
class ProjectAnalystComplete extends ProjectState {
  final AnalystOutputEntity output;
  final ProjectEntity project;
  const ProjectAnalystComplete({required this.output, required this.project});
  @override
  List<Object?> get props => [output, project];
}

/// Thinking agent is running.
class ProjectThinkingLoading extends ProjectState {
  final ProjectEntity project;
  const ProjectThinkingLoading(this.project);
  @override
  List<Object?> get props => [project];
}

/// Thinking done — spec is ready, engineer is about to start.
class ProjectThinkingComplete extends ProjectState {
  final ProductSpecEntity spec;
  final ProjectEntity project;
  const ProjectThinkingComplete({required this.spec, required this.project});
  @override
  List<Object?> get props => [spec, project];
}

/// Engineer loop running — live progress.
class ProjectEngineerLoading extends ProjectState {
  final int current;
  final int total;
  final String currentFilePath;
  final ProjectEntity project;
  const ProjectEngineerLoading({
    required this.current,
    required this.total,
    required this.currentFilePath,
    required this.project,
  });
  @override
  List<Object?> get props => [current, total, currentFilePath, project];
}

/// All files generated.
class ProjectEngineerComplete extends ProjectState {
  final List<FileEntity> files;
  final ProjectEntity project;
  const ProjectEngineerComplete({required this.files, required this.project});
  @override
  List<Object?> get props => [files, project];
}

/// Deploy in progress.
class ProjectDeployLoading extends ProjectState {
  final ProjectEntity project;
  const ProjectDeployLoading(this.project);
  @override
  List<Object?> get props => [project];
}

/// Deploy succeeded.
class ProjectDeployComplete extends ProjectState {
  final String result; // zip path OR live URL
  final bool isUrl;
  final ProjectEntity project;
  const ProjectDeployComplete({
    required this.result,
    required this.isUrl,
    required this.project,
  });
  @override
  List<Object?> get props => [result, isUrl, project];
}

/// Any error anywhere in the pipeline.
class ProjectError extends ProjectState {
  final String message;
  final ProjectEntity? project;
  const ProjectError(this.message, {this.project});
  @override
  List<Object?> get props => [message, project];
}
