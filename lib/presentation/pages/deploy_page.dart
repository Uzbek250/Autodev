import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/project/project_bloc.dart';
import '../bloc/project/project_event.dart';
import '../bloc/project/project_state.dart';
import '../../domain/entities/project_entity.dart';
import '../../domain/entities/file_entity.dart';
import '../../domain/repositories/project_repository.dart';
import '../../domain/usecases/deploy_project_usecase.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../widgets/common_widgets.dart';
import 'code_viewer_page.dart';

class DeployPage extends StatefulWidget {
  final ProjectEntity project;

  const DeployPage({super.key, required this.project});

  @override
  State<DeployPage> createState() => _DeployPageState();
}

class _DeployPageState extends State<DeployPage> {
  List<FileEntity> _files = [];
  bool _loadingFiles = true;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    final repo = context.read<ProjectRepository>();
    final files = await repo.getFilesForProject(widget.project.id);
    if (mounted) {
      setState(() {
        _files = files;
        _loadingFiles = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProjectBloc, ProjectState>(
      listener: (context, state) {
        if (state is ProjectError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ));
        }
        if (state is ProjectDeployComplete) {
          _showDeploySuccess(context, state.result, state.isUrl);
        }
      },
      builder: (context, state) {
        final isDeploying = state is ProjectDeployLoading;
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.project.name),
            actions: [
              StatusChip(status: widget.project.status),
              const SizedBox(width: 12),
            ],
          ),
          body: isDeploying
              ? const LoadingOverlay(
                  message: 'Loyiha joylashtirilmoqda...\nBiroz kuting')
              : _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, ProjectState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Success banner
          if (widget.project.status == AppConstants.statusDeployed)
            _DeploySuccessBanner(project: widget.project),
          // Stats
          _StatsRow(
            fileCount: _files.length,
            readyCount: _files
                .where((f) => f.status == AppConstants.fileStatusReady)
                .length,
            errorCount: _files
                .where((f) => f.status == AppConstants.fileStatusError)
                .length,
          ),
          const SizedBox(height: 24),

          // Deploy actions
          const SectionHeader(
            title: '🚀 Joylashtirish',
            subtitle: 'Loyihangizni qanday ulashmoqchisiz?',
          ),
          const SizedBox(height: 14),
          _DeployCard(
            icon: Icons.folder_zip_outlined,
            title: 'ZIP Arxiv',
            subtitle:
                'Barcha fayllarni ZIP sifatida yuklab oling va ulashing',
            color: Colors.orange,
            onTap: () => context
                .read<ProjectBloc>()
                .add(ProjectDeployZipEvent(widget.project)),
          ),
          const SizedBox(height: 10),
          _DeployCard(
            icon: Icons.cloud_upload_outlined,
            title: 'Vercel Deploy',
            subtitle:
                'Loyihani Vercelga yuklang va jonli URL oling',
            color: Colors.white,
            onTap: () => context
                .read<ProjectBloc>()
                .add(ProjectDeployVercelEvent(widget.project)),
          ),
          const SizedBox(height: 28),

          // Files list
          const SectionHeader(
            title: '📂 Yaratilgan fayllar',
          ),
          const SizedBox(height: 12),
          if (_loadingFiles)
            const Center(child: CircularProgressIndicator())
          else
            _FilesList(files: _files),
        ],
      ),
    );
  }

  void _showDeploySuccess(
      BuildContext context, String result, bool isUrl) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isUrl ? '🚀 Vercel Deploy!' : '📦 ZIP Tayyor!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isUrl
                ? 'Loyihangiz muvaffaqiyatli joylashtirildi:'
                : 'ZIP arxivi yaratildi:'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.darkSurfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(result,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.primary),
                        overflow: TextOverflow.ellipsis),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 16),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: result));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Nusxa olindi'),
                            behavior: SnackBarBehavior.floating),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
          if (!isUrl)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                context.read<DeployProjectUseCase>().shareZip(result);
              },
              icon: const Icon(Icons.share, size: 16),
              label: const Text('Ulashish'),
            ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int fileCount;
  final int readyCount;
  final int errorCount;

  const _StatsRow({
    required this.fileCount,
    required this.readyCount,
    required this.errorCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(value: '$fileCount', label: 'Jami fayl', color: AppColors.primary),
        const SizedBox(width: 10),
        _StatCard(
            value: '$readyCount', label: 'Tayyor', color: AppColors.success),
        const SizedBox(width: 10),
        _StatCard(
            value: '$errorCount', label: 'Xatoli', color: AppColors.error),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatCard(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}

class _DeployCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _DeployCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.darkSurface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white54)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 14, color: color.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeploySuccessBanner extends StatelessWidget {
  final ProjectEntity project;
  const _DeploySuccessBanner({required this.project});

  @override
  Widget build(BuildContext context) {
    final hasUrl = project.deployUrl != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.success.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle,
              color: AppColors.success, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Loyiha joylashtirildi!',
                    style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700)),
                if (hasUrl)
                  Text(project.deployUrl!,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 11),
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (hasUrl)
            IconButton(
              icon: const Icon(Icons.copy, size: 16, color: AppColors.success),
              onPressed: () {
                Clipboard.setData(
                    ClipboardData(text: project.deployUrl!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('URL nusxa olindi'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _FilesList extends StatelessWidget {
  final List<FileEntity> files;
  const _FilesList({required this.files});

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) {
      return const Text('Fayllar topilmadi',
          style: TextStyle(color: Colors.white38));
    }
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: files.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (ctx, i) => _FileRow(file: files[i]),
    );
  }
}

class _FileRow extends StatelessWidget {
  final FileEntity file;
  const _FileRow({required this.file});

  @override
  Widget build(BuildContext context) {
    final isError = file.status == AppConstants.fileStatusError;
    final isReady = file.status == AppConstants.fileStatusReady;
    final statusColor = isReady
        ? AppColors.success
        : isError
            ? AppColors.error
            : Colors.orange;

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CodeViewerPage(file: file)),
      ),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Icon(
              isReady
                  ? Icons.check_circle
                  : isError
                      ? Icons.error
                      : Icons.pending,
              size: 16,
              color: statusColor,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                file.path,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              file.language.toUpperCase(),
              style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.35),
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right,
                size: 16, color: Colors.white.withOpacity(0.2)),
          ],
        ),
      ),
    );
  }
}
