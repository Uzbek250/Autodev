import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'core/theme/app_theme.dart';
import 'data/datasources/local/database_helper.dart';
import 'data/datasources/remote/kimi_remote_datasource.dart';
import 'data/repositories/repository_impls.dart';
import 'domain/repositories/project_repository.dart';
import 'domain/repositories/ai_repository.dart';
import 'domain/repositories/deploy_repository.dart';
import 'domain/repositories/settings_repository.dart';
import 'domain/usecases/create_project_usecase.dart';
import 'domain/usecases/run_analyst_usecase.dart';
import 'domain/usecases/run_thinking_usecase.dart';
import 'domain/usecases/run_engineer_usecase.dart';
import 'domain/usecases/deploy_project_usecase.dart';
import 'presentation/bloc/project/project_bloc.dart';
import 'presentation/bloc/settings/settings_bloc.dart';
import 'presentation/pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait + landscape (DeX support)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // ─── Dependency Injection (manual, no get_it/injectable to stay on-spec) ───

  final dbHelper = DatabaseHelper.instance;
  const secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  final kimiDatasource = KimiRemoteDatasource();

  // Repositories
  final ProjectRepository projectRepo = ProjectRepositoryImpl(dbHelper);
  final AiRepository aiRepo = AiRepositoryImpl(kimiDatasource);
  final DeployRepository deployRepo = DeployRepositoryImpl();
  final SettingsRepository settingsRepo =
      SettingsRepositoryImpl(dbHelper, secure);

  // Use cases
  final createProject = CreateProjectUseCase(projectRepo);
  final runAnalyst = RunAnalystUseCase(
    aiRepository: aiRepo,
    projectRepository: projectRepo,
    settingsRepository: settingsRepo,
  );
  final runThinking = RunThinkingUseCase(
    aiRepository: aiRepo,
    projectRepository: projectRepo,
    settingsRepository: settingsRepo,
  );
  final runEngineer = RunEngineerUseCase(
    aiRepository: aiRepo,
    projectRepository: projectRepo,
    settingsRepository: settingsRepo,
  );
  final deployProjectUseCase = DeployProjectUseCase(
    deployRepository: deployRepo,
    projectRepository: projectRepo,
    settingsRepository: settingsRepo,
  );

  runApp(AutoDevApp(
    projectRepo: projectRepo,
    settingsRepo: settingsRepo,
    projectBloc: ProjectBloc(
      createProject: createProject,
      runAnalyst: runAnalyst,
      runThinking: runThinking,
      runEngineer: runEngineer,
      deployProject: deployProjectUseCase,
      projectRepository: projectRepo,
    ),
    settingsBloc: SettingsBloc(settingsRepo),
    deployUseCase: deployProjectUseCase,
  ));
}

class AutoDevApp extends StatelessWidget {
  final ProjectRepository projectRepo;
  final SettingsRepository settingsRepo;
  final ProjectBloc projectBloc;
  final SettingsBloc settingsBloc;
  final DeployProjectUseCase deployUseCase;

  const AutoDevApp({
    super.key,
    required this.projectRepo,
    required this.settingsRepo,
    required this.projectBloc,
    required this.settingsBloc,
    required this.deployUseCase,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ProjectRepository>.value(value: projectRepo),
        RepositoryProvider<SettingsRepository>.value(value: settingsRepo),
        RepositoryProvider<DeployProjectUseCase>.value(value: deployUseCase),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ProjectBloc>.value(value: projectBloc),
          BlocProvider<SettingsBloc>.value(value: settingsBloc),
        ],
        child: MaterialApp(
          title: 'AutoDev',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: const HomePage(),
        ),
      ),
    );
  }
}
