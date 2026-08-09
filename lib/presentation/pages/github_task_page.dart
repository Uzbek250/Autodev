import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/github_entity.dart';
import '../../domain/usecases/run_github_task_usecase.dart';
import '../widgets/common_widgets.dart';

/// Single-screen tool: point at a file in a GitHub repo, describe a task in
/// natural language, run it, and commit the result. Intentionally minimal —
/// this is a personal utility, not a multi-user product, so there's no repo
/// browser, no diff viewer, no BLoC. Just the inputs the use case needs.
class GitHubTaskPage extends StatefulWidget {
  final RunGitHubTaskUseCase runGitHubTask;

  const GitHubTaskPage({super.key, required this.runGitHubTask});

  @override
  State<GitHubTaskPage> createState() => _GitHubTaskPageState();
}

class _GitHubTaskPageState extends State<GitHubTaskPage> {
  final _ownerController = TextEditingController();
  final _repoController = TextEditingController();
  final _branchController = TextEditingController(text: 'main');
  final _filePathController = TextEditingController();
  final _contextPathsController = TextEditingController();
  final _taskController = TextEditingController();

  bool _isRunning = false;
  String? _resultMessage;
  bool _resultIsError = false;

  @override
  void dispose() {
    _ownerController.dispose();
    _repoController.dispose();
    _branchController.dispose();
    _filePathController.dispose();
    _contextPathsController.dispose();
    _taskController.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final owner = _ownerController.text.trim();
    final repo = _repoController.text.trim();
    final branch = _branchController.text.trim().isEmpty
        ? 'main'
        : _branchController.text.trim();
    final filePath = _filePathController.text.trim();
    final task = _taskController.text.trim();

    if (owner.isEmpty || repo.isEmpty || filePath.isEmpty || task.isEmpty) {
      setState(() {
        _resultIsError = true;
        _resultMessage =
            'Owner, repo, fayl yo\'li va vazifa tavsifi to\'ldirilishi shart.';
      });
      return;
    }

    final contextPaths = _contextPathsController.text
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    setState(() {
      _isRunning = true;
      _resultMessage = null;
    });

    final result = await widget.runGitHubTask(
      target: GitHubTarget(owner: owner, repo: repo, branch: branch),
      taskDescription: task,
      targetFilePath: filePath,
      contextFilePaths: contextPaths,
    );

    if (!mounted) return;
    setState(() {
      _isRunning = false;
      _resultIsError = result.isError;
      _resultMessage = result.fold(
        (failure) => failure.message,
        (commitSha) => '✅ Commit qilindi: ${commitSha.substring(0, commitSha.length.clamp(0, 7))}',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GitHub vazifa')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: '📦 Repo',
              subtitle: 'Qaysi repo va branch\'da ishlaymiz',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _TextField(
                    controller: _ownerController,
                    label: 'Owner',
                    hint: 'Uzbek250',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TextField(
                    controller: _repoController,
                    label: 'Repo',
                    hint: 'virtual-hamroh',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _TextField(
              controller: _branchController,
              label: 'Branch',
              hint: 'main',
            ),
            const SizedBox(height: 24),

            const SectionHeader(
              title: '📄 Fayl',
              subtitle: 'O\'zgartirilishi kerak bo\'lgan fayl',
            ),
            const SizedBox(height: 12),
            _TextField(
              controller: _filePathController,
              label: 'Fayl yo\'li',
              hint: 'lib/main.dart',
            ),
            const SizedBox(height: 10),
            _TextField(
              controller: _contextPathsController,
              label: 'Kontekst fayllar (ixtiyoriy, vergul bilan)',
              hint: 'lib/models/user.dart, lib/api/client.dart',
            ),
            const SizedBox(height: 24),

            const SectionHeader(
              title: '✏️ Vazifa',
              subtitle: 'Nima qilish kerakligini tabiiy tilda yoz',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _taskController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText:
                    'Masalan: "loginda email validatsiyasi yo\'q, qo\'sh" yoki "bu funksiyada null xato bor, tuzat"',
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isRunning ? null : _run,
                child: _isRunning
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Bajarish va commit qilish'),
              ),
            ),

            if (_resultMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: (_resultIsError
                          ? AppColors.error
                          : AppColors.success)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (_resultIsError
                            ? AppColors.error
                            : AppColors.success)
                        .withOpacity(0.3),
                  ),
                ),
                child: Text(
                  _resultMessage!,
                  style: TextStyle(
                    color: _resultIsError
                        ? AppColors.error
                        : AppColors.success,
                    fontSize: 13,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '⚠️ Bu to\'g\'ridan-to\'g\'ri belgilangan branch\'ga commit qiladi '
                '(pull request emas). GitHub token\'ni Sozlamalarda kiritganingizga ishonch hosil qiling.',
                style: TextStyle(fontSize: 11, color: Colors.white54, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;

  const _TextField({
    required this.controller,
    required this.label,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}
