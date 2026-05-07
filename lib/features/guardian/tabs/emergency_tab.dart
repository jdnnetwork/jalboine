import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design_tokens.dart';
import '../../../core/supabase.dart';
import '../../../models/senior_settings.dart';

class EmergencyTab extends ConsumerStatefulWidget {
  final String seniorId;
  final SeniorSettings s;
  const EmergencyTab({super.key, required this.seniorId, required this.s});

  @override
  ConsumerState<EmergencyTab> createState() => _EmergencyTabState();
}

class _EmergencyTabState extends ConsumerState<EmergencyTab> {
  late final TextEditingController _name =
      TextEditingController(text: widget.s.guardianName ?? '');
  late final TextEditingController _phone =
      TextEditingController(text: widget.s.guardianPhone ?? '');
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final sb = ref.read(supabaseProvider);
      await sb.from('senior_settings').update({
        'guardian_name': _name.text.trim(),
        'guardian_phone': _phone.text.trim(),
      }).eq('user_id', widget.seniorId);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('저장되었습니다')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      children: [
        const Text(
          '기본 연락처',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: JD.gInkMute,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 8),
        const _DefaultRow(
            number: '119', label: '구급차', icon: Icons.local_hospital_rounded),
        const SizedBox(height: 8),
        const _DefaultRow(
            number: '112', label: '경찰', icon: Icons.shield_rounded),
        const SizedBox(height: 24),
        const Text(
          '보호자 연락처',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: JD.gInkMute,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: JD.gLine, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Field(controller: _name, label: '이름'),
              const SizedBox(height: 10),
              _Field(
                controller: _phone,
                label: '전화번호',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: JD.gBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800),
                ),
                child: const Text('저장'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DefaultRow extends StatelessWidget {
  final String number;
  final String label;
  final IconData icon;
  const _DefaultRow({
    required this.number,
    required this.label,
    required this.icon,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: JD.gBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: JD.gLine, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: JD.gInkMute, size: 22),
          ),
          const SizedBox(width: 12),
          Text(
            number,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: JD.gInkSoft,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: JD.gInkMute,
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  const _Field({
    required this.controller,
    required this.label,
    this.keyboardType,
  });
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.w700, color: JD.gInk),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: JD.gInkMute),
        filled: true,
        fillColor: JD.gBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: JD.gBlue, width: 1.5),
        ),
      ),
    );
  }
}
