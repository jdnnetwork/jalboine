import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../core/supabase.dart';
import '../../models/senior_settings.dart';
import '../../services/realtime_service.dart';

class GuardianEditorScreen extends ConsumerWidget {
  const GuardianEditorScreen({super.key});

  Future<void> _toggleApp(
      WidgetRef ref, SeniorSettings s, String key) async {
    final next = List<String>.from(s.enabledApps);
    next.contains(key) ? next.remove(key) : next.add(key);
    final sb = ref.read(supabaseProvider);
    await sb
        .from('senior_settings')
        .update({'enabled_apps': next})
        .eq('user_id', sb.auth.currentUser!.id);
  }

  Future<void> _setContact(WidgetRef ref, SeniorSettings s, String name,
      String phone) async {
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
      appBar: AppBar(title: const Text('보호자 설정')),
      body: settings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (s) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                '표시할 앱',
                style:
                    TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
            ),
            for (final entry in JConst.apps.entries)
              CheckboxListTile(
                title: Text(
                  entry.value.label,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w700),
                ),
                value: s.enabledApps.contains(entry.key),
                onChanged: (_) => _toggleApp(ref, s, entry.key),
              ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                '보호자 연락처',
                style:
                    TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
            ),
            _ContactEditor(
              initial:
                  s.emergencyContacts.isEmpty ? null : s.emergencyContacts.first,
              onSave: (name, phone) => _setContact(ref, s, name, phone),
            ),
          ],
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
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: '이름',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: '전화번호',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _saving
                ? null
                : () async {
                    final messenger = ScaffoldMessenger.of(context);
                    setState(() => _saving = true);
                    await widget.onSave(
                        _name.text.trim(), _phone.text.trim());
                    if (!mounted) return;
                    setState(() => _saving = false);
                    messenger.showSnackBar(
                        const SnackBar(content: Text('저장되었습니다')));
                  },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }
}
