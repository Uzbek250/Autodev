import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../domain/entities/file_entity.dart';
import '../../core/theme/app_theme.dart';

class CodeViewerPage extends StatelessWidget {
  final FileEntity file;

  const CodeViewerPage({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              file.path.split('/').last,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700),
            ),
            Text(
              file.path,
              style: const TextStyle(
                  fontSize: 11, color: Colors.white54),
            ),
          ],
        ),
        actions: [
          _StatusBadge(status: file.status),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.copy_outlined, size: 20),
            tooltip: 'Nusxa olish',
            onPressed: () => _copyToClipboard(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Meta info bar
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.darkSurfaceVariant,
            child: Row(
              children: [
                _MetaChip(
                    icon: Icons.code,
                    label: file.language.toUpperCase()),
                const SizedBox(width: 8),
                _MetaChip(
                    icon: Icons.update,
                    label: 'v${file.version}'),
                const SizedBox(width: 8),
                _MetaChip(
                    icon: Icons.text_snippet_outlined,
                    label:
                        '${file.code.split('\n').length} satr'),
              ],
            ),
          ),
          if (file.errorLog != null && file.errorLog!.isNotEmpty)
            _ErrorBanner(message: file.errorLog!),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: MarkdownBody(
                data: '```${file.language}\n${file.code}\n```',
                styleSheet: MarkdownStyleSheet(
                  codeblockDecoration: BoxDecoration(
                    color: AppColors.darkSurfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  code: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12.5,
                    height: 1.55,
                    color: Colors.white,
                  ),
                  codeblockPadding: const EdgeInsets.all(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: file.code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kod nusxa olindi'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      'ready' => (AppColors.success, Icons.check_circle_outline),
      'error' => (AppColors.error, Icons.error_outline),
      'writing' => (Colors.orange, Icons.edit_outlined),
      _ => (Colors.grey, Icons.hourglass_empty),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(status,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.white38),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: Colors.white38)),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: AppColors.error.withOpacity(0.12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber,
              size: 16, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.error,
                  height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
