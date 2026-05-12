import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/design_tokens.dart';
import '../../services/audio_service.dart';
import '../../services/foreground_sync_service.dart';
import '../../services/launcher_service.dart';
import '../../services/location_service.dart';
import '../../services/messages_service.dart';
import '../../services/onboarding_settings_service.dart';
import '../../services/realtime_service.dart';
import '../../services/sound_mode_service.dart';
import '../../services/status_sync_service.dart';
import '../../services/unknown_call_detector.dart';

const _bg = Color(0xFFFBF6EE);
const _ink = Color(0xFF1A1A2E);
const _inkSoft = Color(0xFF5C5347);
const _accentPink = Color(0xFFFF6B8A);
const _emphasisRed = Color(0xFFD32F2F);
const _btnGray = Color(0xFFF5F5F5);
const _btnGrayBorder = Color(0xFFCCCCCC);
const _btnGrayInk = Color(0xFF3E2723);
const _btnPinkBg = Color(0xFFFFF0F0);

const _kCachedAppsKey = 'cached_enabled_apps';

class _AppDef {
  final String label;
  final IconData icon;
  final Color startColor;
  final Color endColor;
  final String audioAsset;
  const _AppDef({
    required this.label,
    required this.icon,
    required this.startColor,
    required this.endColor,
    required this.audioAsset,
  });
}

const _appDefs = <String, _AppDef>{
  'phone': _AppDef(
    label: '전화',
    icon: Icons.phone,
    startColor: Color(0xFF66BB6A),
    endColor: Color(0xFF2E7D32),
    audioAsset: 'assets/audio/phone.wav',
  ),
  'message': _AppDef(
    label: '메시지',
    icon: Icons.chat_bubble_rounded,
    startColor: Color(0xFF42A5F5),
    endColor: Color(0xFF1565C0),
    audioAsset: 'assets/audio/message.wav',
  ),
  'kakao': _AppDef(
    label: '카카오톡',
    icon: Icons.chat_rounded,
    startColor: Color(0xFFFFCA28),
    endColor: Color(0xFFF57F17),
    audioAsset: 'assets/audio/kakao.wav',
  ),
  'youtube': _AppDef(
    label: '유튜브',
    icon: Icons.play_arrow_rounded,
    startColor: Color(0xFFEF5350),
    endColor: Color(0xFFC62828),
    audioAsset: 'assets/audio/youtube.wav',
  ),
  'camera': _AppDef(
    label: '카메라',
    icon: Icons.camera_alt_rounded,
    startColor: Color(0xFFAB47BC),
    endColor: Color(0xFF6A1B9A),
    audioAsset: 'assets/audio/camera.wav',
  ),
  'gallery': _AppDef(
    label: '갤러리',
    icon: Icons.photo_library_rounded,
    startColor: Color(0xFFEC407A),
    endColor: Color(0xFFAD1457),
    audioAsset: 'assets/audio/gallery.wav',
  ),
};

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  String? _primedKey;
  Timer? _callCheckTimer;
  Timer? _clockTimer;
  bool _checkingCall = false;
  bool _alertOpen = false;
  List<String>? _cachedApps;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCachedApps();
    _clockTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      StatusSyncService.instance.pushOnce();
      StatusSyncService.instance.startPeriodic();
      await OnboardingSettingsService.loadFromProfiles(ref);
      await ForegroundSyncService.instance.startIfNeeded();
    });
  }

  Future<void> _loadCachedApps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_kCachedAppsKey);
      if (list != null && mounted) {
        setState(() => _cachedApps = list);
      }
    } catch (_) {}
  }

  Future<void> _saveCachedApps(List<String> apps) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_kCachedAppsKey, apps);
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _callCheckTimer?.cancel();
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      StatusSyncService.instance.pushOnce();
      StatusSyncService.instance.startPeriodic();
      _maybeStartCallChecker();
    } else if (state == AppLifecycleState.paused) {
      StatusSyncService.instance.stop();
      _callCheckTimer?.cancel();
      _callCheckTimer = null;
    }
  }

  void _maybeStartCallChecker() {
    final s = ref.read(seniorSettingsProvider).value;
    if (s == null || !s.unknownCallDetection) {
      _callCheckTimer?.cancel();
      _callCheckTimer = null;
      return;
    }
    if (_callCheckTimer != null) return;
    _callCheckTimer =
        Timer.periodic(const Duration(minutes: 3), (_) => _checkUnknownCall());
    _checkUnknownCall();
  }

  Future<void> _checkUnknownCall() async {
    if (_checkingCall || _alertOpen) return;
    _checkingCall = true;
    try {
      final hit = await UnknownCallDetector.instance.checkOnce();
      if (hit == null || !mounted) return;
      _alertOpen = true;
      await context.push(
        '/safety/unknown-call',
        extra: {
          'phone': hit.number,
          'duration': hit.durationSec,
        },
      );
      _alertOpen = false;
    } finally {
      _checkingCall = false;
    }
  }

  Future<void> _maybePromptCallPermission() async {
    final has = await UnknownCallDetector.instance.hasPermissions();
    if (has || !mounted) {
      _maybeStartCallChecker();
      return;
    }
    if (_alertOpen) return;
    _alertOpen = true;
    await context.push('/safety/call-permission');
    _alertOpen = false;
    _maybeStartCallChecker();
  }

  Future<void> _maybePromptLocationPermission() async {
    final fine = await LocationService.instance.hasFinePermission();
    final bg = await LocationService.instance.hasBackgroundPermission();
    if (fine && bg) {
      LocationService.instance.pushOnce();
      return;
    }
    if (_alertOpen || !mounted) return;
    _alertOpen = true;
    await context.push('/safety/location-permission');
    _alertOpen = false;
  }

  Future<void> _onEmergencySound() async {
    if (_alertOpen || !mounted) return;
    _alertOpen = true;
    await context.push('/safety/emergency-sound');
    _alertOpen = false;
  }

  void _onCardTap(String key) {
    final voiceMode = ref.read(voiceGuideModeProvider);
    final def = _appDefs[key];
    if (!voiceMode) {
      LauncherService.launchApp(key);
      return;
    }
    if (_primedKey == key) {
      setState(() => _primedKey = null);
      LauncherService.launchApp(key);
    } else {
      setState(() => _primedKey = key);
      if (def != null) AudioService.instance.play(def.audioAsset);
    }
  }

  void _showSoundToast(BuildContext context, String label) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        duration: const Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _ink,
        content: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.notoSansKr(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ));
  }

  String get _dateStr {
    final n = DateTime.now();
    const wd = ['월', '화', '수', '목', '금', '토', '일'];
    return '${n.year}년 ${n.month}월 ${n.day}일 ${wd[n.weekday - 1]}요일';
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
    final partner = ref.watch(partnerIdProvider);
    final partnerConnected = partner.maybeWhen(
      data: (v) => v != null,
      orElse: () => false,
    );

    ref.listen(seniorSettingsProvider, (prev, next) {
      final prevOn = prev?.value?.unknownCallDetection ?? false;
      final nextOn = next.value?.unknownCallDetection ?? false;
      if (!prevOn && nextOn) {
        _maybePromptCallPermission();
      } else if (prevOn && !nextOn) {
        _callCheckTimer?.cancel();
        _callCheckTimer = null;
      } else if (nextOn) {
        _maybeStartCallChecker();
      }
    });
    ref.listen(seniorSettingsProvider, (prev, next) {
      final prevOn = prev?.value?.locationTracking ?? false;
      final nextOn = next.value?.locationTracking ?? false;
      if (!prevOn && nextOn) _maybePromptLocationPermission();
    });
    ref.listen(seniorSettingsProvider, (prev, next) {
      final prevOn = prev?.value?.emergencySound ?? false;
      final nextOn = next.value?.emergencySound ?? false;
      if (!prevOn && nextOn) _onEmergencySound();
    });
    ref.listen(seniorSettingsProvider, (_, next) {
      final apps = next.value?.enabledApps;
      if (apps != null) _saveCachedApps(apps);
    });

    // 캐시된 앱이 있으면 즉시 표시, 없으면 supabase 로딩 대기.
    final apps = settings.value?.enabledApps ?? _cachedApps ?? const <String>[];
    final effectiveApps = apps.take(6).toList();

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: settings.when(
          loading: () => _cachedApps == null
              ? const Center(child: CircularProgressIndicator())
              : _buildHome(effectiveApps, mode, partnerConnected),
          error: (e, _) => Center(
            child: Text(
              '$e',
              style: GoogleFonts.notoSansKr(color: _inkSoft, fontSize: 16),
            ),
          ),
          data: (_) => _buildHome(effectiveApps, mode, partnerConnected),
        ),
      ),
    );
  }

  Widget _buildHome(
    List<String> apps,
    SoundMode mode,
    bool partnerConnected,
  ) {
    return GestureDetector(
      onLongPress: () => context.push('/guardian/pin'),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          children: [
            _Header(
              dateStr: _dateStr,
              timeStr: _timeStr,
              mode: mode,
              onSoundTap: () async {
                final next = mode.next;
                _showSoundToast(context, next.toastLabel);
                AudioService.instance.play(next.audioAsset);
                await persistSoundMode(ref, next);
                await SoundModeService.instance.apply(next);
              },
            ),
            const SizedBox(height: 14),
            Expanded(
              child: _CardArea(
                apps: apps,
                primedKey: _primedKey,
                onAppTap: _onCardTap,
                onMoreTap: () => context.push('/more'),
              ),
            ),
            const SizedBox(height: 10),
            _BottomArea(
              count: apps.length,
              partnerConnected: partnerConnected,
              onMore: () => context.push('/more'),
              onFamily: () => context.push('/family'),
              onSos: () => context.push('/emergency'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String dateStr;
  final String timeStr;
  final SoundMode mode;
  final VoidCallback onSoundTap;
  const _Header({
    required this.dateStr,
    required this.timeStr,
    required this.mode,
    required this.onSoundTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                    letterSpacing: -0.4,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  timeStr,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: _ink,
                    letterSpacing: -1.0,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          _SoundModeButton(mode: mode, onTap: onSoundTap),
        ],
      ),
    );
  }
}

class _CardArea extends StatelessWidget {
  final List<String> apps;
  final String? primedKey;
  final void Function(String) onAppTap;
  final VoidCallback onMoreTap;
  const _CardArea({
    required this.apps,
    required this.primedKey,
    required this.onAppTap,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final n = apps.length;
    if (n == 0) {
      return _MoreCard(onTap: onMoreTap);
    }
    if (n == 1) {
      return Column(
        children: [
          Expanded(child: _appCard(apps[0], banner: true)),
          const SizedBox(height: 12),
          Expanded(child: _MoreCard(banner: true, onTap: onMoreTap)),
        ],
      );
    }
    if (n == 2 || n == 3) {
      return Column(
        children: [
          for (var i = 0; i < n; i++) ...[
            Expanded(child: _appCard(apps[i], banner: true)),
            if (i < n - 1) const SizedBox(height: 12),
          ],
        ],
      );
    }
    if (n == 4) {
      return Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _appCard(apps[0])),
                const SizedBox(width: 12),
                Expanded(child: _appCard(apps[1])),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _appCard(apps[2])),
                const SizedBox(width: 12),
                Expanded(child: _appCard(apps[3])),
              ],
            ),
          ),
        ],
      );
    }
    if (n == 5) {
      return Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _appCard(apps[0])),
                const SizedBox(width: 12),
                Expanded(child: _appCard(apps[1])),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _appCard(apps[2])),
                const SizedBox(width: 12),
                Expanded(child: _appCard(apps[3])),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _appCard(apps[4])),
                const SizedBox(width: 12),
                Expanded(child: _MoreCard(onTap: onMoreTap)),
              ],
            ),
          ),
        ],
      );
    }
    // 6
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: _appCard(apps[0])),
              const SizedBox(width: 12),
              Expanded(child: _appCard(apps[1])),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _appCard(apps[2])),
              const SizedBox(width: 12),
              Expanded(child: _appCard(apps[3])),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _appCard(apps[4])),
              const SizedBox(width: 12),
              Expanded(child: _appCard(apps[5])),
            ],
          ),
        ),
      ],
    );
  }

  Widget _appCard(String key, {bool banner = false}) {
    final def = _appDefs[key];
    if (def == null) return const SizedBox.shrink();
    return _AppCard(
      def: def,
      primed: primedKey == key,
      banner: banner,
      onTap: () => onAppTap(key),
    );
  }
}

class _AppCard extends StatelessWidget {
  final _AppDef def;
  final bool primed;
  final bool banner;
  final VoidCallback onTap;
  const _AppCard({
    required this.def,
    required this.primed,
    required this.banner,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [def.startColor, def.endColor],
          ),
          borderRadius: BorderRadius.circular(24),
          border: primed
              ? Border.all(color: Colors.white, width: 4)
              : null,
          boxShadow: [
            BoxShadow(
              color: def.endColor.withValues(alpha: 0.40),
              offset: const Offset(0, 6),
              blurRadius: 14,
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.15),
              offset: const Offset(0, -2),
              blurRadius: 0,
            ),
          ],
        ),
        child: banner ? _bannerContent() : _verticalContent(),
      ),
    );
  }

  Widget _bannerContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        children: [
          Icon(def.icon, color: Colors.white, size: 64),
          const SizedBox(width: 22),
          Expanded(
            child: Text(
              def.label,
              style: GoogleFonts.notoSansKr(
                fontSize: 42,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -1.2,
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _verticalContent() {
    return LayoutBuilder(
      builder: (context, c) {
        final compact = c.maxHeight < 120;
        final iconSize = compact ? 48.0 : 64.0;
        final fontSize = compact ? 26.0 : 32.0;
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(def.icon, color: Colors.white, size: iconSize),
            SizedBox(height: compact ? 6 : 10),
            Text(
              def.label,
              style: GoogleFonts.notoSansKr(
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -1.0,
                height: 1.0,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MoreCard extends StatelessWidget {
  final bool banner;
  final VoidCallback onTap;
  const _MoreCard({this.banner = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _btnGrayBorder, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              offset: const Offset(0, 4),
              blurRadius: 10,
            ),
          ],
        ),
        child: banner ? _bannerContent() : _verticalContent(),
      ),
    );
  }

  Widget _bannerContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        children: [
          const Icon(Icons.apps_rounded, color: _btnGrayInk, size: 56),
          const SizedBox(width: 22),
          Expanded(
            child: Text(
              '다른 화면 보기',
              style: GoogleFonts.notoSansKr(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: _btnGrayInk,
                letterSpacing: -1.0,
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _verticalContent() {
    return LayoutBuilder(
      builder: (context, c) {
        final compact = c.maxHeight < 120;
        final iconSize = compact ? 44.0 : 56.0;
        final fontSize = compact ? 24.0 : 28.0;
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.apps_rounded, color: _btnGrayInk, size: iconSize),
            SizedBox(height: compact ? 6 : 10),
            Text(
              '다른 화면 보기',
              style: GoogleFonts.notoSansKr(
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                color: _btnGrayInk,
                letterSpacing: -0.8,
                height: 1.0,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BottomArea extends StatelessWidget {
  final int count;
  final bool partnerConnected;
  final VoidCallback onMore;
  final VoidCallback onFamily;
  final VoidCallback onSos;
  const _BottomArea({
    required this.count,
    required this.partnerConnected,
    required this.onMore,
    required this.onFamily,
    required this.onSos,
  });

  bool get _moreInGrid => count == 0 || count == 5;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_moreInGrid)
          _FamilyButton(
            partnerConnected: partnerConnected,
            onTap: onFamily,
          )
        else
          Row(
            children: [
              Expanded(child: _MoreButton(onTap: onMore)),
              const SizedBox(width: 12),
              Expanded(
                child: _FamilyButton(
                  partnerConnected: partnerConnected,
                  onTap: onFamily,
                ),
              ),
            ],
          ),
        const SizedBox(height: 8),
        _SosButton(onTap: onSos),
      ],
    );
  }
}

class _MoreButton extends StatelessWidget {
  final VoidCallback onTap;
  const _MoreButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: _btnGray,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _btnGrayBorder, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(
          '다른 화면 보기',
          style: GoogleFonts.notoSansKr(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _btnGrayInk,
            letterSpacing: -0.6,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

class _FamilyButton extends StatelessWidget {
  final bool partnerConnected;
  final VoidCallback onTap;
  const _FamilyButton({
    required this.partnerConnected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: _btnPinkBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _accentPink, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.favorite, color: _emphasisRed, size: 22),
                const SizedBox(width: 8),
                Text(
                  '가족 연결',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _emphasisRed,
                    letterSpacing: -0.6,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!partnerConnected)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: _emphasisRed,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

class _SosButton extends StatefulWidget {
  final VoidCallback onTap;
  const _SosButton({required this.onTap});

  @override
  State<_SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<_SosButton>
    with SingleTickerProviderStateMixin {
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
        final pulse = 8.0 * t;
        return Container(
          height: 64,
          decoration: BoxDecoration(
            color: _emphasisRed,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _emphasisRed.withValues(alpha: 0.30 + 0.15 * t),
                offset: const Offset(0, 8),
                blurRadius: 20,
                spreadRadius: pulse,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                HapticFeedback.heavyImpact();
                widget.onTap();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.white, size: 30),
                  const SizedBox(width: 12),
                  Text(
                    '긴급 전화 SOS',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.8,
                      height: 1.0,
                    ),
                  ),
                ],
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
      };

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: JD.shadowCard,
          ),
          child: Icon(_icon, color: _ink, size: 24),
        ),
      ),
    );
  }
}
