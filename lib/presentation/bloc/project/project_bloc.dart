import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/project_entity.dart';
import '../../../domain/usecases/create_project_usecase.dart';
import '../../../domain/usecases/run_analyst_usecase.dart';
import '../../../domain/usecases/run_thinking_usecase.dart';
import '../../../domain/usecases/run_engineer_usecase.dart';
import '../../../domain/usecases/deploy_project_usecase.dart';
import '../../../domain/repositories/project_repository.dart';
import 'project_event.dart';
import 'project_state.dart';

class ProjectBloc extends Bloc<ProjectEvent, ProjectState> {
  final CreateProjectUseCase createProject;
  final RunAnalystUseCase runAnalyst;
  final RunThinkingUseCase runThinking;
  final RunEngineerUseCase runEngineer;
  final DeployProjectUseCase deployProject;
  final ProjectRepository projectRepository;

  ProjectBloc({
    required this.createProject,
    required this.runAnalyst,
    required this.runThinking,
    required this.runEngineer,
    required this.deployProject,
    required this.projectRepository,
  }) : super(const ProjectInitial()) {
    on<ProjectsLoadAllEvent>(_onLoadAll);
    on<ProjectLoadEvent>(_onLoadOne);
    on<ProjectCreateEvent>(_onCreate);
    on<ProjectPlanApprovedEvent>(_onPlanApproved);
    on<ProjectPlanRejectedEvent>(_onPlanRejected);
    on<ProjectThinkingCompleteEvent>(_onThinkingComplete);
    on<ProjectEngineerProgressEvent>(_onEngineerProgress);
    on<ProjectEngineerCompleteEvent>(_onEngineerComplete);
    on<ProjectDeployZipEvent>(_onDeployZip);
    on<ProjectDeployVercelEvent>(_onDeployVercel);
    on<ProjectDeleteEvent>(_onDelete);
    on<ProjectErrorAcknowledgeEvent>(_onErrorAcknowledge);
  }

  Future<void> _onLoadAll(
      ProjectsLoadAllEvent event, Emitter<ProjectState> emit) async {
    emit(const ProjectsLoading());
    try {
      final projects = await projectRepository.getAllProjects();
      emit(ProjectsLoaded(projects));
    } catch (e) {
      emit(ProjectError('Loyihalar yuklanmadi: ${e.toString()}'));
    }
  }

  Future<void> _onLoadOne(
      ProjectLoadEvent event, Emitter<ProjectState> emit) async {
    try {
      final project = await projectRepository.getProjectById(event.projectId);
      if (project == null) {
        emit(const ProjectError('Loyiha topilmadi'));
        return;
      }
      final files = await projectRepository.getFilesForProject(project.id);
      if (project.status == 'ready' || project.status == 'deployed') {
        emit(ProjectEngineerComplete(files: files, project: project));
      } else {
        emit(ProjectsLoaded([project]));
      }
    } catch (e) {
      emit(ProjectError('Loyiha yuklanmadi: ${e.toString()}'));
    }
  }

  Future<void> _onCreate(
      ProjectCreateEvent event, Emitter<ProjectState> emit) async {
    emit(const ProjectCreating());
    try {
      final project = await createProject(
        event.userIdea,
        clientApiKey: event.clientApiKey,
      );
      emit(ProjectAnalystLoading(project));

      final result = await runAnalyst(project);
      if (result.isError) {
        emit(ProjectError(result.failure!.message, project: project));
        return;
      }
      emit(ProjectAnalystComplete(
          output: result.value!, project: project));
    } catch (e) {
      emit(ProjectError('Loyiha yaratishda xato: ${e.toString()}'));
    }
  }

  Future<void> _onPlanApproved(
      ProjectPlanApprovedEvent event, Emitter<ProjectState> emit) async {
    final project = event.project;
    emit(ProjectThinkingLoading(project));

    // Persist approval
    await projectRepository.saveProject(project.copyWith(
      planApproved: true,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    ));

    final thinkResult = await runThinking(
      project: project,
      analystOutput: event.analystOutput,
    );

    if (thinkResult.isError) {
      emit(ProjectError(thinkResult.failure!.message, project: project));
      return;
    }

    final spec = thinkResult.value!;
    final updatedProject =
        await projectRepository.getProjectById(project.id) ?? project;
    emit(ProjectThinkingComplete(spec: spec, project: updatedProject));

    // Immediately kick off engineer
    emit(ProjectEngineerLoading(
      current: 0,
      total: spec.files.length,
      currentFilePath: spec.files.isNotEmpty ? spec.files.first.path : '',
      project: updatedProject,
    ));

    final engineerResult = await runEngineer(
      project: updatedProject,
      spec: spec,
      onProgress: (current, total, filePath) {
        add(ProjectEngineerProgressEvent(current, total, filePath));
      },
    );

    if (engineerResult.isError) {
      emit(ProjectError(engineerResult.failure!.message, project: updatedProject));
      return;
    }

    add(ProjectEngineerCompleteEvent(engineerResult.value!));
  }

  Future<void> _onPlanRejected(
      ProjectPlanRejectedEvent event, Emitter<ProjectState> emit) async {
    // Reset to analyst state so user can re-enter idea
    await projectRepository.saveProject(event.project.copyWith(
      status: 'planning',
      planApproved: false,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    ));
    final projects = await projectRepository.getAllProjects();
    emit(ProjectsLoaded(projects));
  }

  void _onEngineerProgress(
      ProjectEngineerProgressEvent event, Emitter<ProjectState> emit) {
    if (state is ProjectEngineerLoading) {
      final current = state as ProjectEngineerLoading;
      emit(ProjectEngineerLoading(
        current: event.current,
        total: event.total,
        currentFilePath: event.filePath,
        project: current.project,
      ));
    }
  }

  Future<void> _onEngineerComplete(
      ProjectEngineerCompleteEvent event, Emitter<ProjectState> emit) async {
    ProjectEntity? project;
    if (state is ProjectEngineerLoading) {
      project = (state as ProjectEngineerLoading).project;
    }
    if (project != null) {
      final refreshed = await projectRepository.getProjectById(project.id);
      emit(ProjectEngineerComplete(
        files: event.files,
        project: refreshed ?? project,
      ));
    } else {
      emit(ProjectEngineerComplete(
        files: event.files,
        project: ProjectEntity(
          id: '',
          name: 'Project',
          type: 'web',
          status: 'ready',
          createdAt: 0,
          updatedAt: 0,
        ),
      ));
    }
  }

  Future<void> _onDeployZip(
      ProjectDeployZipEvent event, Emitter<ProjectState> emit) async {
    emit(ProjectDeployLoading(event.project));
    final result = await deployProject.callZip(event.project);
    if (result.isError) {
      emit(ProjectError(result.failure!.message, project: event.project));
      return;
    }
    final refreshed =
        await projectRepository.getProjectById(event.project.id) ??
            event.project;
    emit(ProjectDeployComplete(
        result: result.value!, isUrl: false, project: refreshed));
  }

  Future<void> _onDeployVercel(
      ProjectDeployVercelEvent event, Emitter<ProjectState> emit) async {
    emit(ProjectDeployLoading(event.project));
    final result = await deployProject.callVercel(event.project);
    if (result.isError) {
      emit(ProjectError(result.failure!.message, project: event.project));
      return;
    }
    final refreshed =
        await projectRepository.getProjectById(event.project.id) ??
            event.project;
    emit(ProjectDeployComplete(
        result: result.value!, isUrl: true, project: refreshed));
  }

  Future<void> _onDelete(
      ProjectDeleteEvent event, Emitter<ProjectState> emit) async {
    try {
      await projectRepository.deleteProject(event.projectId);
      final projects = await projectRepository.getAllProjects();
      emit(ProjectsLoaded(projects));
    } catch (e) {
      emit(ProjectError("O'chirishda xato: ${e.toString()}"));
    }
  }

  void _onErrorAcknowledge(
      ProjectErrorAcknowledgeEvent event, Emitter<ProjectState> emit) {
    emit(const ProjectInitial());
  }
}
