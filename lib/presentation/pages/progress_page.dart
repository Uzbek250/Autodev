import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/project/project_bloc.dart';
import '../bloc/project/project_state.dart';
import '../../domain/entities/project_entity.dart';
import '../../domain/entities/file_entity.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../widgets/common_widgets.dart';
import 'deploy_page.dart';

class ProgressPage extends StatelessWidget {
  final ProjectEntity project;

  const ProgressPage({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProjectBloc, ProjectState>(
      listener: (context, state) {
        if (state is ProjectEngineerComplete) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => DeployPage(project: state.project),
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Kod yaratilmoqda'),
            automaticallyImplyLeading: false,
          ),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, state),
                const SizedBox(height: 24),
                _buildProgressBar(state),
                const SizedBox(height: 24),
                Expanded(child: _buildFileList(context, state)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, ProjectState state) {
    String title = 'AI kod yozmoqda...';
    String subtitle = 'Iltimos kuting';

    if (state is ProjectThinkingLoading) {
      title = '🧠 Arxitektura tahlil qilinmoqda';
      subtitle = 'Texnik spetsifikatsiya tayyorlanmoqda...';
    } else if (state is ProjectEngineerLoading) {
      title =
          '⚙️ ${state.current}/${state.total} fayl yaratildi';
      subtitle = '📝 ${state.currentFilePath}';
    } else if (state is ProjectError) {
      title = '❌ Xato yuz berdi';
      subtitle = state.message;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(subtitle,
            style:
                const TextStyle(fontSize: 13, color: Colors.white54),
            maxLines: 2,
            overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Widget _buildProgressBar(ProjectState state) {
    double progress = 0;
    if (state is ProjectEngineerLoading) {
      progress = state.total > 0 ? state.current / state.total : 0;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Progress',
                style: const TextStyle(
                    fontSize: 12, color: Colors.white54)),
            Text('${(progress * 100).toInt()}%',
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: state is ProjectThinkingLoading ? null : progress,
            minHeight: 8,
            backgroundColor: Colors.white10,
          ),
        ),
      ],
    );
  }

  Widget _buildFileList(BuildContext context, ProjectState state) {
    List<FileEntity>? files;
    String? currentPath;

    if (state is ProjectEngineerLoading) {
      currentPath = state.currentFilePath;
    }

    if (files == null && state is! ProjectThinkingLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(height: 16),
            Text('Fayl ro\'yxati tayyorlanmoqda...',
                style: TextStyle(color: Colors.white38, fontSize: 13)),
          ],
        ),
      );
    }

    if (state is ProjectThinkingLoading) {
      return _AgentStepsWidget();
    }

    return const SizedBox.shrink();
  }
}

class _AgentStepsWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final steps = [
      ('1', '💬 Analyst', 'Foydalanuvchi g\'oyasi tahlil qilindi', true),
      ('2', '🧠 Thinking', 'Texnik arxitektura ishlanmoqda...', false),
      ('3', '⚙️ Engineer', 'Kod yoziladi', false),
      ('4', '🚀 Deploy', 'Loyiha joylashtiriladi', false),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pipeline bosqichlari',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white54)),
        const SizedBox(height: 12),
        ...steps.asMap().entries.map((e) {
          final step = e.value;
          final isDone = step.$4;
          final isCurrent = e.key == 1; // thinking = current
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCurrent
                  ? AppColors.primary.withOpacity(0.1)
                  : AppColors.darkSurfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: isCurrent
                  ? Border.all(
                      color: AppColors.primary.withOpacity(0.4))
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isDone
                        ? AppColors.success.withOpacity(0.2)
                        : isCurrent
                            ? AppColors.primary.withOpacity(0.2)
                            : Colors.white10,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check,
                            size: 14, color: AppColors.success)
                        : isCurrent
                            ? const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              )
                            : Text(step.$1,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white38)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(step.$2,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isCurrent
                                  ? AppColors.primary
                                  : isDone
                                      ? Colors.white
                                      : Colors.white38)),
                      Text(step.$3,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.white38)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
