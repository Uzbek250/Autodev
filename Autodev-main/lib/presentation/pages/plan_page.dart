import 'package:flutter/material.dart';
import '../../domain/entities/project_entity.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class PlanPage extends StatelessWidget {
  final ProjectEntity project;
  final AnalystOutputEntity analystOutput;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const PlanPage({
    super.key,
    required this.project,
    required this.analystOutput,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loyiha Rejasi'),
        actions: [
          TextButton.icon(
            onPressed: onApprove,
            icon: const Icon(Icons.check, color: AppColors.success),
            label: const Text('Tasdiqlash',
                style: TextStyle(color: AppColors.success)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ASCII Mockup
            if (analystOutput.mockup.isNotEmpty) ...[
              const SectionHeader(title: '🖼️ Interfeys eskizi'),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.darkSurfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.2)),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    analystOutput.mockup,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      height: 1.5,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // MVP Features
            const SectionHeader(
              title: '✅ MVP Xususiyatlar',
              subtitle: 'Birinchi versiyada bo\'ladigan funksiyalar',
            ),
            const SizedBox(height: 12),
            _FeatureList(
              items: analystOutput.mvpFeatures,
              color: AppColors.success,
            ),
            const SizedBox(height: 24),

            // V2 Features
            const SectionHeader(
              title: '🚀 V2 Xususiyatlar',
              subtitle: 'Keyingi versiyalarda qo\'shiladigan funksiyalar',
            ),
            const SizedBox(height: 12),
            _FeatureList(
              items: analystOutput.v2Features,
              color: AppColors.primary,
            ),
            const SizedBox(height: 24),

            // Risk analysis
            if (analystOutput.riskAnalysis.isNotEmpty) ...[
              const SectionHeader(title: '⚠️ Xatarlar tahlili'),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.orange.withOpacity(0.3)),
                ),
                child: Text(
                  analystOutput.riskAnalysis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    color: Colors.white70,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Suggested stack
            if (analystOutput.suggestedStack.isNotEmpty) ...[
              const SectionHeader(title: '🛠️ Tavsiya etilgan texnologiya'),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.darkSurfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  analystOutput.suggestedStack,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    color: Colors.white70,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Clarifying questions
            if (analystOutput.questions.isNotEmpty) ...[
              const SectionHeader(
                title: '❓ Aniqlashtirish savollari',
                subtitle:
                    'Loyiha haqidagi tushunarliroq qilish uchun savollar',
              ),
              const SizedBox(height: 12),
              ...analystOutput.questions.asMap().entries.map(
                    (e) => _QuestionCard(
                        question: e.value, number: e.key + 1),
                  ),
              const SizedBox(height: 24),
            ],

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close),
                    label: const Text('Rad etish'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(
                          color: AppColors.error.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.rocket_launch),
                    label: const Text('Tasdiqlash & Kodlash'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _FeatureList extends StatelessWidget {
  final List<String> items;
  final Color color;

  const _FeatureList({required this.items, required this.color});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text('Mavjud emas',
          style: TextStyle(color: Colors.white.withOpacity(0.3)));
    }
    return Column(
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 5),
                width: 7,
                height: 7,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item,
                  style: const TextStyle(
                      fontSize: 13, height: 1.5, color: Colors.white70),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final AnalystQuestion question;
  final int number;

  const _QuestionCard({required this.question, required this.number});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number. ${question.question}',
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.white),
          ),
          const SizedBox(height: 8),
          ...question.options.map(
            (opt) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('  $opt',
                  style:
                      const TextStyle(fontSize: 12, color: Colors.white60)),
            ),
          ),
        ],
      ),
    );
  }
}
