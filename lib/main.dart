import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/router.dart';
import 'core/supabase.dart';
import 'core/theme.dart';
import 'services/deep_link_service.dart';
import 'services/notification_service.dart';
import 'services/sound_mode_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSupabase();
  await NotificationService.instance.init();
  await DeepLinkService.instance.init();
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
    // 보호자 OAuth 콜백 또는 첫 로그인 직후 라우팅
    Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      final user = event.session?.user;
      if (user == null) return;
      final ctx = ref.read(routerProvider).routerDelegate.navigatorKey.currentContext;
      if (ctx == null) return;
      // OAuth로 로그인했고 anonymous가 아니면 보호자 흐름으로
      final isAnon = user.isAnonymous;
      if (!isAnon) {
        ref.read(routerProvider).go('/parent/connect');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    // soundMode를 senior_settings에서 받아 즉시 반영
    ref.listen(seniorSettingsForBootstrap, (_, _) {});
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
