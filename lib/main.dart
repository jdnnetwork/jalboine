import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/router.dart';
import 'core/supabase.dart';
import 'core/theme.dart';
import 'services/deep_link_service.dart';
import 'services/fcm_service.dart';
import 'services/foreground_sync_service.dart';
import 'services/notification_service.dart';
import 'services/sound_mode_service.dart';
import 'services/status_sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
  ]);
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // google-services.json 미배치 등 — 푸시 비활성으로 진행
  }
  await initSupabase();
  await NotificationService.instance.init();
  await DeepLinkService.instance.init();
  ForegroundSyncService.instance.initOptions();
  // Firebase 초기화 성공 시에만 FCM 셋업
  try {
    await FcmService.instance.init();
  } catch (_) {}
  runApp(const ProviderScope(child: JalboineApp()));
}

class JalboineApp extends ConsumerStatefulWidget {
  const JalboineApp({super.key});

  @override
  ConsumerState<JalboineApp> createState() => _JalboineAppState();
}

class _JalboineAppState extends ConsumerState<JalboineApp> {
  @override
  void initState() {
    super.initState();
    // 피보호자(익명) 세션이 살아있으면 3분 주기 + 백그라운드 동기화 시작
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && user.isAnonymous) {
      StatusSyncService.instance.startPeriodic();
      ForegroundSyncService.instance.startIfNeeded();
    }
    Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      final u = event.session?.user;
      if (u == null) {
        StatusSyncService.instance.stop();
        ForegroundSyncService.instance.stop();
        return;
      }
      if (u.isAnonymous) {
        StatusSyncService.instance.startPeriodic();
        ForegroundSyncService.instance.startIfNeeded();
      } else {
        StatusSyncService.instance.stop();
        ForegroundSyncService.instance.stop();
      }
    });
  }

  bool _tapHandlerRegistered = false;

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    // soundMode를 senior_settings에서 받아 즉시 반영
    ref.listen(seniorSettingsForBootstrap, (_, _) {});
    if (!_tapHandlerRegistered) {
      _tapHandlerRegistered = true;
      // 라우터 준비 후 FCM 탭 핸들러 등록.
      // route 키가 있으면 그 경로로, 없으면 기본 라우팅(보호자=대시보드/어르신=메시지).
      FcmService.instance.registerTapHandler((data) {
        final route = data['route'] as String?;
        final user = Supabase.instance.client.auth.currentUser;
        final dest = route ??
            (user != null && user.isAnonymous
                ? '/messages'
                : '/guardian/dashboard');
        router.go(dest);
      });
    }
    return MaterialApp.router(
      title: '잘보이네',
      theme: JTheme.light(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

/// 부팅 시 senior_settings의 sound_mode를 한 번 읽어와 provider에 반영.
final seniorSettingsForBootstrap = Provider<void>((ref) {
  final sb = ref.watch(supabaseProvider);
  final uid = sb.auth.currentUser?.id;
  if (uid == null) return;
  sb
      .from('senior_settings')
      .select('sound_mode')
      .eq('user_id', uid)
      .maybeSingle()
      .then((row) {
    if (row == null) return;
    final m = parseSoundMode(row['sound_mode'] as String?);
    ref.read(soundModeProvider.notifier).state = m;
  }).catchError((_) {});
});
