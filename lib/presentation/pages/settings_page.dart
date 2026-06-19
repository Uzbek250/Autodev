import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/settings/settings_bloc.dart';
import '../../domain/entities/file_entity.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // K2.6 — Analyst + Thinking
  final _k26Controller = TextEditingController();
  bool _k26Obscure = true;

  // K2.7-code — Engineer + Fixer
  final _k27Controller = TextEditingController();
  bool _k27Obscure = true;

  // Vercel
  final _vercelController = TextEditingController();
  bool _vercelObscure = true;

  String _selectedTheme = 'dark';
  String _selectedLanguage = 'uz';
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    context.read<SettingsBloc>().add(const SettingsLoadEvent());
  }

  @override
  void dispose() {
    _k26Controller.dispose();
    _k27Controller.dispose();
    _vercelController.dispose();
    super.dispose();
  }

  void _applySettings(AppSettingsEntity s) {
    _k26Controller.text = s.kimiK26Key ?? '';
    _k27Controller.text = s.kimiK27CodeKey ?? '';
    _vercelController.text = s.defaultVercelToken ?? '';
    _selectedTheme = s.theme;
    _selectedLanguage = s.language;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sozlamalar'),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _save,
              child: const Text('Saqlash',
                  style: TextStyle(color: AppColors.primary)),
            ),
        ],
      ),
      body: BlocConsumer<SettingsBloc, SettingsState>(
        listener: (context, state) {
          if (state is SettingsLoaded) {
            setState(() => _applySettings(state.settings));
          }
          if (state is SettingsSaved) {
            setState(() {
              _hasChanges = false;
              _applySettings(state.settings);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Sozlamalar saqlandi'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          if (state is SettingsError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ));
          }
        },
        builder: (context, state) {
          if (state is SettingsLoading) {
            return const LoadingOverlay(message: 'Yuklanmoqda...');
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Kimi API Keys ─────────────────────────────────────────
                const SectionHeader(
                  title: '🔑 Kimi (Moonshot AI) Kalitlar',
                  subtitle: 'Har bir model uchun alohida kalit kerak',
                ),
                const SizedBox(height: 12),

                // Status card
                _KeyStatusCard(
                  k26Set: _k26Controller.text.isNotEmpty,
                  k27Set: _k27Controller.text.isNotEmpty,
                ),
                const SizedBox(height: 16),

                // K2.6 — Analyst + Thinking
                _ApiKeyField(
                  label: '🧠 Kimi K2.6 — Analyst & Thinking',
                  hint: 'sk-K1sQR...',
                  controller: _k26Controller,
                  obscure: _k26Obscure,
                  onToggleObscure: () =>
                      setState(() => _k26Obscure = !_k26Obscure),
                  onChanged: (_) => setState(() => _hasChanges = true),
                  helperText:
                      'G\'oya tahlili va arxitektura rejasi uchun ishlatiladi',
                  accentColor: Colors.purple,
                ),
                const SizedBox(height: 14),

                // K2.7-code — Engineer + Fixer
                _ApiKeyField(
                  label: '⚙️ Kimi K2.7-Code — Engineer & Fixer',
                  hint: 'sk-A7ibb...',
                  controller: _k27Controller,
                  obscure: _k27Obscure,
                  onToggleObscure: () =>
                      setState(() => _k27Obscure = !_k27Obscure),
                  onChanged: (_) => setState(() => _hasChanges = true),
                  helperText: 'Kod yozish va xatolarni tuzatish uchun ishlatiladi',
                  accentColor: Colors.orange,
                ),
                const SizedBox(height: 28),

                // ── Vercel ────────────────────────────────────────────────
                const SectionHeader(
                  title: '🌐 Vercel (ixtiyoriy)',
                  subtitle: 'Faqat Vercelga deploy qilsangiz kerak',
                ),
                const SizedBox(height: 14),
                _ApiKeyField(
                  label: 'Vercel Token',
                  hint: 'vercel_...',
                  controller: _vercelController,
                  obscure: _vercelObscure,
                  onToggleObscure: () =>
                      setState(() => _vercelObscure = !_vercelObscure),
                  onChanged: (_) => setState(() => _hasChanges = true),
                  helperText: 'vercel.com → Account → Tokens',
                  accentColor: Colors.white54,
                ),
                const SizedBox(height: 28),

                // ── Mijoz haqida ──────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline,
                          color: AppColors.primary, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Mijoz loyihalari',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                    fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(
                              'Mijoz uchun loyiha yaratayotganda, '
                              '"+ Yangi loyiha" oynasida mijozning '
                              'API kalitini kiriting. U faqat O\'SHA '
                              'loyiha uchun ishlatiladi — sizning '
                              'kalitlaringiz hisobiga tegmaydi.',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.65),
                                  height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ── Ko'rinish ─────────────────────────────────────────────
                const SectionHeader(title: '🎨 Ko\'rinish'),
                const SizedBox(height: 14),
                _SettingsTile(
                  title: 'Mavzu',
                  subtitle: 'Ilovaning rangi va ko\'rinishi',
                  trailing: DropdownButton<String>(
                    value: _selectedTheme,
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(
                          value: 'dark', child: Text('Qorong\'u')),
                      DropdownMenuItem(
                          value: 'light', child: Text('Yorug\'')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          _selectedTheme = v;
                          _hasChanges = true;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 10),
                _SettingsTile(
                  title: 'Til',
                  subtitle: 'Interfeys tili',
                  trailing: DropdownButton<String>(
                    value: _selectedLanguage,
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(
                          value: 'uz', child: Text("O'zbek")),
                      DropdownMenuItem(
                          value: 'en', child: Text('English')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          _selectedLanguage = v;
                          _hasChanges = true;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 28),

                // ── Ilova haqida ──────────────────────────────────────────
                const SectionHeader(title: 'ℹ️ Ilova haqida'),
                const SizedBox(height: 14),
                _InfoRow(label: 'Ilova', value: 'AutoDev'),
                const SizedBox(height: 6),
                _InfoRow(label: 'Versiya', value: '1.0.0'),
                const SizedBox(height: 6),
                _InfoRow(label: 'AI Provider', value: 'Moonshot AI (Kimi)'),
                const SizedBox(height: 6),
                _InfoRow(label: 'Saqlash', value: 'Local SQLite + Secure Storage'),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _hasChanges ? _save : null,
                    child: const Text('Sozlamalarni saqlash'),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  void _save() {
    final settings = AppSettingsEntity(
      kimiK26Key: _k26Controller.text.trim(),
      kimiK27CodeKey: _k27Controller.text.trim(),
      defaultVercelToken: _vercelController.text.trim(),
      theme: _selectedTheme,
      language: _selectedLanguage,
    );
    context.read<SettingsBloc>().add(SettingsSaveEvent(settings));
  }
}

// ─── Key Status Card ──────────────────────────────────────────────────────────

class _KeyStatusCard extends StatelessWidget {
  final bool k26Set;
  final bool k27Set;
  const _KeyStatusCard({required this.k26Set, required this.k27Set});

  @override
  Widget build(BuildContext context) {
    final allSet = k26Set && k27Set;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: allSet
            ? AppColors.success.withOpacity(0.08)
            : Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: allSet
              ? AppColors.success.withOpacity(0.3)
              : Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            allSet ? Icons.check_circle : Icons.warning_amber,
            color: allSet ? AppColors.success : Colors.orange,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _KeyDot(label: 'K2.6', isSet: k26Set),
                    const SizedBox(width: 12),
                    _KeyDot(label: 'K2.7-Code', isSet: k27Set),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  allSet
                      ? 'Barcha kalitlar sozlangan — tayyor!'
                      : 'Ikkala kalitni kiriting, aks holda AI ishlamaydi',
                  style: TextStyle(
                    fontSize: 11,
                    color: allSet ? AppColors.success : Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyDot extends StatelessWidget {
  final String label;
  final bool isSet;
  const _KeyDot({required this.label, required this.isSet});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSet ? AppColors.success : Colors.grey,
          ),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSet ? Colors.white70 : Colors.white30)),
      ],
    );
  }
}

// ─── API Key Field ────────────────────────────────────────────────────────────

class _ApiKeyField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final ValueChanged<String> onChanged;
  final String? helperText;
  final Color accentColor;

  const _ApiKeyField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.obscure,
    required this.onToggleObscure,
    required this.onChanged,
    this.helperText,
    this.accentColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: accentColor)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (controller.text.isNotEmpty)
                  Icon(Icons.check_circle,
                      size: 16, color: AppColors.success),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(
                      obscure ? Icons.visibility_off : Icons.visibility,
                      size: 18),
                  onPressed: onToggleObscure,
                ),
              ],
            ),
          ),
          onChanged: onChanged,
        ),
        if (helperText != null) ...[
          const SizedBox(height: 5),
          Text(helperText!,
              style: const TextStyle(fontSize: 11, color: Colors.white38)),
        ],
      ],
    );
  }
}

// ─── Settings Tile ────────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget trailing;

  const _SettingsTile({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.white38)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

// ─── Info Row ─────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, color: Colors.white54)),
        Text(value,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
