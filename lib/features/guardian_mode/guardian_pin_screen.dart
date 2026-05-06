import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/supabase.dart';
import '../../services/pin_service.dart';
import '../../services/realtime_service.dart';

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
      appBar: AppBar(title: const Text('보호자 모드')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('PIN을 입력하세요',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 24),
            TextField(
              controller: _ctrl,
              keyboardType: TextInputType.number,
              obscureText: true,
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                letterSpacing: 12,
              ),
              textAlign: TextAlign.center,
              decoration:
                  const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _busy ? null : _check,
              child: const Text('확인'),
            ),
          ],
        ),
      ),
    );
  }
}
