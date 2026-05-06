import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design_tokens.dart';
import '../../core/supabase.dart';
import '../../core/theme.dart';
import '../../services/pin_service.dart';
import '../../services/realtime_service.dart';
import '../../widgets/back_pill.dart';
import '../../widgets/big_button.dart';

class GuardianPinScreen extends ConsumerStatefulWidget {
  const GuardianPinScreen({super.key});

  @override
  ConsumerState<GuardianPinScreen> createState() => _GuardianPinScreenState();
}

class _GuardianPinScreenState extends ConsumerState<GuardianPinScreen> {
  final _ctrl = TextEditingController();
  bool _busy = false;

  Future<void> _check() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final settings = ref.read(seniorSettingsProvider).value;
      final hash = settings?.guardianPinHash;
      if (hash == null || hash.isEmpty) {
        final newHash = PinService.hash(_ctrl.text);
        final sb = ref.read(supabaseProvider);
        await sb
            .from('senior_settings')
            .update({'guardian_pin_hash': newHash})
            .eq('user_id', sb.auth.currentUser!.id);
        if (mounted) context.go('/guardian/edit');
        return;
      }
      if (PinService.verify(_ctrl.text, hash)) {
        if (mounted) context.go('/guardian/edit');
      } else {
        _ctrl.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('PIN이 다릅니다')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SeniorBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [BackPill(onTap: () => context.pop())]),
                const SizedBox(height: 24),
                const Text(
                  '보호자 모드',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: JD.ink,
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'PIN을 입력하세요',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: JD.inkSoft,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(JD.rCard),
                    boxShadow: JD.shadowCard,
                  ),
                  child: TextField(
                    controller: _ctrl,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 12,
                      color: JD.ink,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '••••',
                      hintStyle: TextStyle(
                        color: JD.inkMute,
                        letterSpacing: 12,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                BigButton(
                  label: '확인',
                  background: JD.cCoralDeep,
                  shadowBottomColor: const Color(0xFFD9794D),
                  foreground: Colors.white,
                  onTap: _busy ? null : _check,
                  height: 80,
                  fontSize: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
