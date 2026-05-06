import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/design_tokens.dart';
import '../../core/supabase.dart';
import '../../core/theme.dart';
import '../../models/senior_settings.dart';
import '../../services/realtime_service.dart';
import '../../widgets/back_pill.dart';
import '../../widgets/elder_card.dart';

/// 어르신 폰의 보호자 PIN 진입 후 편집 — 앱 표시 / 긴급 연락처.
/// (보호자 본인 폰의 대시보드는 /guardian/dashboard.)
class GuardianEditorScreen extends ConsumerWidget {
  const GuardianEditorScreen({super.key});

  Future<void> _toggleApp(
      WidgetRef ref, SeniorSettings s, String key) async {
    final next = List<String>.from(s.enabledApps);
    if (next.contains(key)) {
      next.remove(key);
    } else if (next.length < 8) {
      next.add(key);
    }
    final sb = ref.read(supabaseProvider);
    await sb
        .from('senior_settings')
        .update({'enabled_apps': next})
        .eq('user_id', sb.auth.currentUser!.id);
  }

  Future<void> _setContact(
      WidgetRef ref, SeniorSettings s, String name, String phone) async {
    final next = [
      {'name': name, 'phone': phone},
      ...s.emergencyContacts.skip(1).map((e) => e.toJson()),
    ];
    final sb = ref.read(supabaseProvider);
    await sb
        .from('senior_settings')
        .update({'emergency_contacts': next})
        .eq('user_id', sb.auth.currentUser!.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(seniorSettingsProvider);
    return Scaffold(
      body: SeniorBackground(
        child: SafeArea(
          child: settings.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (s) => ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                Row(
                  children: [
                    BackPill(onTap: () => context.go('/home')),
                    const SizedBox(width: 14),
                    const Text(
                      '보호자 설정',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: JD.ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElderCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '표시할 앱',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: JD.ink),
                      ),
                      const SizedBox(height: 12),
                      ...JConst.apps.entries.map((e) {
                        final selected = s.enabledApps.contains(e.key);
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: e.value.gradient,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(e.value.icon,
                                color: Colors.white, size: 22),
                          ),
                          title: Text(
                            e.value.label,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                          trailing: Switch(
                            value: selected,
                            activeThumbColor: JD.cCoralDeep,
                            onChanged: (_) => _toggleApp(ref, s, e.key),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElderCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '보호자 연락처',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: JD.ink),
                      ),
                      const SizedBox(height: 12),
                      _ContactEditor(
                        initial: s.emergencyContacts.isEmpty
                            ? null
                            : s.emergencyContacts.first,
                        onSave: (name, phone) =>
                            _setContact(ref, s, name, phone),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactEditor extends StatefulWidget {
  final EmergencyContact? initial;
  final Future<void> Function(String name, String phone) onSave;
  const _ContactEditor({this.initial, required this.onSave});

  @override
  State<_ContactEditor> createState() => _ContactEditorState();
}

class _ContactEditorState extends State<_ContactEditor> {
  late final TextEditingController _name =
      TextEditingController(text: widget.initial?.name ?? '');
  late final TextEditingController _phone =
      TextEditingController(text: widget.initial?.phone ?? '');
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            labelText: '이름',
            filled: true,
            fillColor: JD.bgCream,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            labelText: '전화번호',
            filled: true,
            fillColor: JD.bgCream,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: JD.cCoralDeep,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: _saving
                ? null
                : () async {
                    final messenger = ScaffoldMessenger.of(context);
                    setState(() => _saving = true);
                    await widget.onSave(_name.text.trim(), _phone.text.trim());
                    if (!mounted) return;
                    setState(() => _saving = false);
                    messenger.showSnackBar(
                        const SnackBar(content: Text('저장되었습니다')));
                  },
            child: const Text('저장'),
          ),
        ),
      ],
    );
  }
}
