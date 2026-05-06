import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../services/launcher_service.dart';
import '../../services/realtime_service.dart';
import '../../services/sound_mode_service.dart';
import '../../services/status_sync_service.dart';
import 'app_tile.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      StatusSyncService.instance.pushOnce();
    });
  }

  int _crossAxisCount(int n) {
    if (n <= 1) return 1;
    if (n <= 4) return 2;
    return 2;
  }

  Future<void> _exitConfirm(BuildContext context) async {
    final ok1 = await _ask(context, '원래 화면으로 가시겠어요?');
    if (!ok1 || !context.mounted) return;
    final ok2 = await _ask(context, '정말로 가시겠어요?');
    if (!ok2 || !context.mounted) return;
    SystemNavigator.pop();
  }

  Future<bool> _ask(BuildContext context, String text) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Text(text,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('아니요',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('네',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    return r == true;
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(seniorSettingsProvider);
    final mode = ref.watch(soundModeProvider);
    return Scaffold(
      body: SeniorBackground(
        child: SafeArea(
          child: settings.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (s) {
              final apps = s.enabledApps.take(8).toList();
              return Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onLongPress: () => context.push('/guardian/pin'),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 64, 16, 12),
                            child: apps.isEmpty
                                ? const Center(
                                    child: Text(
                                      '앱이 없어요',
                                      style: TextStyle(fontSize: 24),
                                    ),
                                  )
                                : GridView.count(
                                    crossAxisCount: _crossAxisCount(apps.length),
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    children: [
                                      for (final k in apps)
                                        AppTile(
                                          appKey: k,
                                          onTap: () =>
                                              LauncherService.launchApp(k),
                                        ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      _SosButton(onTap: () => context.push('/emergency')),
                    ],
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _SoundModeButton(
                      mode: mode,
                      onTap: () async {
                        final next = mode.next;
                        await persistSoundMode(ref, next);
                        await SoundModeService.instance.apply(next);
                      },
                    ),
                  ),
                  Positioned(
                    bottom: 110,
                    right: 12,
                    child: _ExitButton(onTap: () => _exitConfirm(context)),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SosButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SosButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 96,
      child: Material(
        color: JTheme.sos,
        child: InkWell(
          onTap: () {
            HapticFeedback.heavyImpact();
            SystemSound.play(SystemSoundType.click);
            onTap();
          },
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.white, size: 32),
                SizedBox(width: 12),
                Text(
                  '긴급 전화',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
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

class _SoundModeButton extends StatelessWidget {
  final SoundMode mode;
  final VoidCallback onTap;
  const _SoundModeButton({required this.mode, required this.onTap});

  IconData get _icon => switch (mode) {
        SoundMode.sound => Icons.volume_up_rounded,
        SoundMode.vibrate => Icons.vibration_rounded,
        SoundMode.silent => Icons.notifications_off_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black12),
          ),
          child: Icon(_icon, color: JTheme.seniorAccent, size: 30),
        ),
      ),
    );
  }
}

class _ExitButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ExitButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            '원래 화면',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.black54),
          ),
        ),
      ),
    );
  }
}
