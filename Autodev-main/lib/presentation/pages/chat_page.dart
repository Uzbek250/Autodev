import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/project/project_bloc.dart';
import '../bloc/project/project_event.dart';
import '../bloc/project/project_state.dart';
import '../widgets/common_widgets.dart';
import '../../domain/entities/project_entity.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import 'plan_page.dart';
import 'progress_page.dart';

class ChatPage extends StatefulWidget {
  final ProjectEntity project;
  final AnalystOutputEntity analystOutput;

  const ChatPage({
    super.key,
    required this.project,
    required this.analystOutput,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProjectBloc, ProjectState>(
      listener: (context, state) {
        if (state is ProjectThinkingLoading ||
            state is ProjectEngineerLoading) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    ProgressPage(project: widget.project)),
          );
        }
        if (state is ProjectError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ));
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.project.name,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
              const AgentTag(agent: AppConstants.agentAnalyst),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                    vertical: 16, horizontal: 4),
                children: [
                  // User message
                  ChatBubble(
                    message: widget.project.userIdea ?? '',
                    isUser: true,
                    time: DateTime.fromMillisecondsSinceEpoch(
                        widget.project.createdAt),
                  ),
                  const SizedBox(height: 8),
                  // Analyst intro message
                  ChatBubble(
                    message:
                        'Salom! Men sizning g\'oyangizni tahlil qildim. Quyida natijalarni ko\'rishingiz mumkin. Iltimos, rejani ko\'zdan kechiring va tasdiqlang yoki o\'zgartirish kiriting.',
                    isUser: false,
                    agentName: '🧠 Analyst Agent',
                    time: DateTime.fromMillisecondsSinceEpoch(
                        widget.project.updatedAt),
                  ),
                  const SizedBox(height: 16),
                  // Plan preview card
                  _PlanPreviewCard(
                    analystOutput: widget.analystOutput,
                    onViewFull: () => _viewFullPlan(context),
                  ),
                  const SizedBox(height: 16),
                  // Questions bubble
                  if (widget.analystOutput.questions.isNotEmpty)
                    _QuestionsCard(
                        questions: widget.analystOutput.questions),
                  const SizedBox(height: 80),
                ],
              ),
            ),
            _BottomActions(
              onApprove: () => _approve(context),
              onReject: () => _reject(context),
              onViewPlan: () => _viewFullPlan(context),
            ),
          ],
        ),
      ),
    );
  }

  void _viewFullPlan(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlanPage(
          project: widget.project,
          analystOutput: widget.analystOutput,
          onApprove: () {
            Navigator.pop(context);
            _approve(context);
          },
          onReject: () {
            Navigator.pop(context);
            _reject(context);
          },
        ),
      ),
    );
  }

  void _approve(BuildContext context) {
    context.read<ProjectBloc>().add(
          ProjectPlanApprovedEvent(widget.project, widget.analystOutput),
        );
  }

  void _reject(BuildContext context) {
    context
        .read<ProjectBloc>()
        .add(ProjectPlanRejectedEvent(widget.project));
    Navigator.of(context).popUntil((r) => r.isFirst);
  }
}

class _PlanPreviewCard extends StatelessWidget {
  final AnalystOutputEntity analystOutput;
  final VoidCallback onViewFull;

  const _PlanPreviewCard(
      {required this.analystOutput, required this.onViewFull});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.darkSurfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text('Loyiha Rejasi',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      )),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _row('MVP xususiyatlar',
                      '${analystOutput.mvpFeatures.length} ta'),
                  const SizedBox(height: 6),
                  _row('V2 xususiyatlar',
                      '${analystOutput.v2Features.length} ta'),
                  const SizedBox(height: 6),
                  _row('Savollar',
                      '${analystOutput.questions.length} ta'),
                ],
              ),
            ),
            const Divider(height: 1),
            InkWell(
              onTap: onViewFull,
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('To\'liq rejani ko\'rish',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.primary)),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios,
                        size: 12, color: AppColors.primary),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: Colors.white54)),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ],
      );
}

class _QuestionsCard extends StatelessWidget {
  final List<AnalystQuestion> questions;
  const _QuestionsCard({required this.questions});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ChatBubble(
        message: questions
            .asMap()
            .entries
            .map((e) =>
                '${e.key + 1}. ${e.value.question}\n   ${e.value.options.join("\n   ")}')
            .join('\n\n'),
        isUser: false,
        agentName: '❓ Aniqlashtirish savollari',
        time: DateTime.now(),
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onViewPlan;

  const _BottomActions({
    required this.onApprove,
    required this.onReject,
    required this.onViewPlan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.07))),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onReject,
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Rad etish'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(
                    color: AppColors.error.withOpacity(0.5)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: onApprove,
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Tasdiqlash & Kodlash'),
            ),
          ),
        ],
      ),
    );
  }
}
