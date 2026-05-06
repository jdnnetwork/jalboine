import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design_tokens.dart';
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

  Future<void> _exitConfirm(BuildContext context) async {
    final ok1 = await _ask(context, '기본 홈 화면으로 돌아가시겠어요?');
    if (!ok1 || !context.mounted) return;
    final ok2 = await _ask(
        context, '정말로 돌아가시겠어요?\n잘보이네 앱은 유지됩니다');
    if (!ok2 || !context.mounted) return;
    SystemNavigator.pop();
  }

  Future<bool> _ask(BuildContext context, String text) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.white,
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: JD.ink,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              '아니요',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: JD.inkSoft,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              '네',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: JD.cCoralDeep,
              ),
            ),
          ),
        ],
      ),
    );
    return r == true;
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 11) return '좋은 아침이에요';
    if (h < 17) return '좋은 오후에요';
    return '편안한 저녁이에요';
  }

  String get _dateStr {
    final n = DateTime.now();
    const wd = ['월', '화', '수', '목', '금', '토', '일'];
    return '${n.month}월 ${n.day}일 ${wd[n.weekday - 1]}요일';
  }

  String get _timeStr {
    final n = DateTime.now();
    final ampm = n.hour < 12 ? '오전' : '오후';
    final h = n.hour == 0 ? 12 : (n.hour > 12 ? n.hour - 12 : n.hour);
    final m = n.minute.toString().padLeft(2, '0');
    return '$ampm $h:$m';
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
                      // Greeting + sound toggle
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _dateStr,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: JD.inkMute,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _greeting,
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      color: JD.ink,
                                      letterSpacing: -0.8,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _SoundModeButton(
                              mode: mode,
                              onTap: () async {
                                final next = mode.next;
                                await persistSoundMode(ref, next);
                                await SoundModeService.instance.apply(next);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Weather/time card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _WeatherCard(timeStr: _timeStr),
                      ),
                      const SizedBox(height: 14),
                      // Apps grid (long press to enter guardian PIN)
                      Expanded(
                        child: GestureDetector(
                          onLongPress: () => context.push('/guardian/pin'),
                          child: apps.isEmpty
                              ? const Center(
                                  child: Text(
                                    '앱이 없어요',
                                    style: TextStyle(
                                        fontSize: 22, color: JD.inkSoft),
                                  ),
                                )
                              : Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      16, 4, 16, 8),
                                  child: GridView.builder(
                                    physics: const BouncingScrollPhysics(),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      mainAxisSpacing: 12,
                                      crossAxisSpacing: 12,
                                      childAspectRatio: 1,
                                    ),
                                    itemCount: apps.length,
                                    itemBuilder: (_, i) => AppTile(
                                      appKey: apps[i],
                                      onTap: () =>
                                          LauncherService.launchApp(apps[i]),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      // SOS bar
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: _SosButton(onTap: () => context.push('/emergency')),
                      ),
                    ],
                  ),
                  Positioned(
                    bottom: 96,
                    right: 16,
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

class _WeatherCard extends StatelessWidget {
  final String timeStr;
  const _WeatherCard({required this.timeStr});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-1, -1),
          end: Alignment(1, 1),
          colors: [Color(0xFFFFE9C2), Color(0xFFFFD49A)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFE89923).withValues(alpha: 0.18),
              offset: const Offset(0, 6),
              blurRadius: 16),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.wb_sunny_rounded, color: Color(0xFFE89923), size: 36),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timeStr,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: JD.ink,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '오늘은 맑아요',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: JD.inkSoft,
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

class _SosButton extends StatefulWidget {
  final VoidCallback onTap;
  const _SosButton({required this.onTap});

  @override
  State<_SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<_SosButton> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        final t = Curves.easeInOut.transform(_ctrl.value);
        final pulse = 0.0 + 8.0 * t;
        return Container(
          height: 84,
          decoration: BoxDecoration(
            color: JD.cRed,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              const BoxShadow(
                color: Color(0x40B41E1E),
                offset: Offset(0, 8),
                blurRadius: 0,
              ),
              BoxShadow(
                color: JD.cRedLight.withValues(alpha: 0.30 + 0.15 * t),
                offset: const Offset(0, 14),
                blurRadius: 30,
                spreadRadius: pulse,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: () {
                HapticFeedback.heavyImpact();
                widget.onTap();
              },
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.white, size: 30),
                    SizedBox(width: 12),
                    Text(
                      '긴급 전화 SOS',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Ink(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: JD.shadowCard,
          ),
          child: Icon(_icon, color: JD.ink, size: 32),
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
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: JD.inkSoft,
            ),
          ),
        ),
      ),
    );
  }
}
