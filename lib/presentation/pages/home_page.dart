import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/project/project_bloc.dart';
import '../bloc/project/project_event.dart';
import '../bloc/project/project_state.dart';
import '../widgets/common_widgets.dart';
import '../../domain/entities/project_entity.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import 'chat_page.dart';
import 'settings_page.dart';
import 'progress_page.dart';
import 'deploy_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    context.read<ProjectBloc>().add(const ProjectsLoadAllEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AutoDev'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Sozlamalar',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ).then((_) =>
                context.read<ProjectBloc>().add(const ProjectsLoadAllEvent())),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewProjectSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Yangi loyiha'),
      ),
      body: BlocConsumer<ProjectBloc, ProjectState>(
        listener: (context, state) {
          if (state is ProjectError) {
            _showErrorSnackBar(context, state.message);
          }
          if (state is ProjectAnalystComplete) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatPage(
                  project: state.project,
                  analystOutput: state.output,
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ProjectsLoading || state is ProjectCreating) {
            return const LoadingOverlay(message: 'Yuklanmoqda...');
          }
          if (state is ProjectAnalystLoading) {
            return LoadingOverlay(
              message:
                  '🧠 Analyst ishlamoqda...\n"${state.project.name}"\nBiroz kuting',
            );
          }
          if (state is ProjectsLoaded) {
            if (state.projects.isEmpty) {
              return EmptyStateWidget(
                icon: Icons.rocket_launch_outlined,
                title: 'Hali loyiha yo\'q',
                subtitle:
                    'G\'oyangizni yozing va AI avtomatik ravishda loyiha yaratadi',
                action: ElevatedButton.icon(
                  onPressed: () => _showNewProjectSheet(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Boshlash'),
                ),
              );
            }
            return _ProjectList(projects: state.projects);
          }
          return const LoadingOverlay(message: 'Yuklanmoqda...');
        },
      ),
    );
  }

  void _showNewProjectSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _NewProjectSheet(
        onSubmit: (idea, clientKey) {
          Navigator.pop(ctx);
          context.read<ProjectBloc>().add(
                ProjectCreateEvent(idea,
                    clientApiKey: clientKey.isEmpty ? null : clientKey),
              );
        },
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }
}

// ─── New Project Sheet ────────────────────────────────────────────────────────

class _NewProjectSheet extends StatefulWidget {
  final void Function(String idea, String clientKey) onSubmit;

  const _NewProjectSheet({required this.onSubmit});

  @override
  State<_NewProjectSheet> createState() => _NewProjectSheetState();
}

class _NewProjectSheetState extends State<_NewProjectSheet> {
  final _ideaController = TextEditingController();
  final _clientKeyController = TextEditingController();
  bool _isClientProject = false;
  bool _clientKeyObscure = true;

  @override
  void dispose() {
    _ideaController.dispose();
    _clientKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(
          left: 20, right: 20, top: 20, bottom: bottomPadding + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Title
          const Text('Yangi loyiha',
              style:
                  TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('G\'oyangizni tasvirlab bering',
              style: TextStyle(fontSize: 13, color: Colors.white54)),
          const SizedBox(height: 18),

          // Idea field
          TextField(
            controller: _ideaController,
            autofocus: true,
            maxLines: 4,
            minLines: 3,
            decoration: const InputDecoration(
              hintText:
                  'Masalan: "Oshxona menyu va buyurtma boshqaruv tizimi"\n'
                  'yoki "Telegram bot — mijozlar savollariga javob beradi"',
              hintMaxLines: 3,
            ),
          ),
          const SizedBox(height: 16),

          // Client project toggle
          InkWell(
            onTap: () =>
                setState(() => _isClientProject = !_isClientProject),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _isClientProject
                    ? AppColors.primary.withOpacity(0.1)
                    : AppColors.darkSurfaceVariant,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _isClientProject
                      ? AppColors.primary.withOpacity(0.4)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isClientProject
                        ? Icons.business_center
                        : Icons.business_center_outlined,
                    size: 18,
                    color: _isClientProject
                        ? AppColors.primary
                        : Colors.white54,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mijoz loyihasi',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _isClientProject
                                ? AppColors.primary
                                : Colors.white70,
                          ),
                        ),
                        Text(
                          'Mijoz o\'z Kimi API kalitini to\'laydi',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.white38),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isClientProject,
                    onChanged: (v) =>
                        setState(() => _isClientProject = v),
                    activeColor: AppColors.primary,
                    materialTapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
            ),
          ),

          // Client API key field (visible when toggled)
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            child: _isClientProject
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🔑 Mijoz Kimi API kaliti',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _clientKeyController,
                          obscureText: _clientKeyObscure,
                          style: const TextStyle(
                              fontFamily: 'monospace', fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'sk-...',
                            helperText:
                                'Bu kalit faqat ushbu loyiha uchun ishlatiladi',
                            helperStyle: const TextStyle(
                                fontSize: 11, color: Colors.white38),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _clientKeyObscure
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                size: 18,
                              ),
                              onPressed: () => setState(() =>
                                  _clientKeyObscure = !_clientKeyObscure),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          const SizedBox(height: 20),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                final idea = _ideaController.text.trim();
                if (idea.isEmpty) return;
                final clientKey = _isClientProject
                    ? _clientKeyController.text.trim()
                    : '';
                widget.onSubmit(idea, clientKey);
              },
              icon: const Icon(Icons.rocket_launch, size: 18),
              label: const Text('Boshlash'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Project List ─────────────────────────────────────────────────────────────

class _ProjectList extends StatelessWidget {
  final List<ProjectEntity> projects;
  const _ProjectList({required this.projects});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: projects.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) => _ProjectCard(project: projects[i]),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final ProjectEntity project;
  const _ProjectCard({required this.project});

  @override
  Widget build(BuildContext context) {
    final updatedAt =
        DateTime.fromMillisecondsSinceEpoch(project.updatedAt);
    final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(updatedAt);
    final isClientProject =
        project.apiKeySource == AppConstants.apiKeySourceCustom;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToProject(context),
        onLongPress: () => _showDeleteDialog(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Client badge
                  if (isClientProject) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: Colors.purple.withOpacity(0.4)),
                      ),
                      child: const Text('MIJOZ',
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.purple,
                              letterSpacing: 0.5)),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      project.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusChip(status: project.status),
                ],
              ),
              if (project.userIdea != null &&
                  project.userIdea!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  project.userIdea!,
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.45)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time,
                      size: 12,
                      color: Colors.white.withOpacity(0.3)),
                  const SizedBox(width: 4),
                  Text(dateStr,
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.3))),
                  const Spacer(),
                  if (project.totalFiles > 0) ...[
                    Icon(Icons.insert_drive_file_outlined,
                        size: 12,
                        color: Colors.white.withOpacity(0.3)),
                    const SizedBox(width: 4),
                    Text(
                      '${project.completedFiles}/${project.totalFiles} fayl',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.3)),
                    ),
                  ],
                ],
              ),
              if (project.totalFiles > 0 &&
                  (project.status == AppConstants.statusCoding ||
                      project.status == AppConstants.statusFixing)) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: project.progress,
                  backgroundColor: Colors.white10,
                  borderRadius: BorderRadius.circular(4),
                  minHeight: 4,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToProject(BuildContext context) {
    final status = project.status;
    if (status == AppConstants.statusReady ||
        status == AppConstants.statusDeployed) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => DeployPage(project: project)));
    } else if (status == AppConstants.statusCoding ||
        status == AppConstants.statusFixing) {
      Navigator.push(context,
          MaterialPageRoute(
              builder: (_) => ProgressPage(project: project)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Yangi loyiha yaratib, bu g\'oyani qayta kiriting'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Loyihani o\'chirish'),
        content: Text(
            '«${project.name}» loyihasini o\'chirishni istaysizmi?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Bekor qilish')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context
                  .read<ProjectBloc>()
                  .add(ProjectDeleteEvent(project.id));
            },
            style:
                TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('O\'chirish'),
          ),
        ],
      ),
    );
  }
}
