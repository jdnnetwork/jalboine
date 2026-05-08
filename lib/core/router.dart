import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'supabase.dart';
import '../features/start/start_screen.dart';
import '../features/audio_guide/audio_guide_ask_screen.dart';
import '../features/font_size/font_size_screen.dart';
import '../features/age/age_screen.dart';
import '../features/auth/guardian_login_screen.dart';
import '../features/setup_intro/setup_intro_screen.dart';
import '../features/setup_intro/setup_done_screen.dart';
import '../features/onboarding/onboarding_flow.dart';
import '../features/onboarding/setup/launcher_guide_screen.dart';
import '../features/onboarding/setup/launcher_done_screen.dart';
import '../features/onboarding/setup/battery_guide_screen.dart';
import '../features/onboarding/setup/notification_guide_screen.dart';
import '../features/medication_setup/med_has_screen.dart';
import '../features/medication_setup/med_count_screen.dart';
import '../features/medication_setup/med_hour_screen.dart';
import '../features/medication_setup/med_confirm_screen.dart';
import '../features/pairing/family_branch_screen.dart';
import '../features/home/home_screen.dart';
import '../features/emergency/emergency_screen.dart';
import '../features/messages/senior_messages_screen.dart';
import '../features/medication_alarm/med_alarm_screen.dart';
import '../features/guardian_mode/guardian_pin_screen.dart';
import '../features/guardian/parent_connect_screen.dart';
import '../features/guardian/connect_method_screen.dart';
import '../features/guardian/guardian_dashboard_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final sb = ref.watch(supabaseProvider);
  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(sb.auth.onAuthStateChange),
    routes: [
      GoRoute(path: '/', builder: (_, _) => const StartScreen()),
      GoRoute(
          path: '/audio-guide-ask',
          builder: (_, _) => const AudioGuideAskScreen()),
      GoRoute(
        path: '/font-size',
        builder: (_, s) => FontSizeScreen(
          level: int.tryParse(s.uri.queryParameters['level'] ?? '1') ?? 1,
        ),
      ),
      GoRoute(path: '/age', builder: (_, _) => const AgeScreen()),
      GoRoute(
          path: '/setup-intro',
          builder: (_, _) => const SetupIntroScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingFlow()),
      GoRoute(
          path: '/onboarding/launcher-guide',
          builder: (_, _) => const LauncherGuideScreen()),
      GoRoute(
          path: '/onboarding/launcher-done',
          builder: (_, _) => const LauncherDoneScreen()),
      GoRoute(
          path: '/onboarding/battery-guide',
          builder: (_, _) => const BatteryGuideScreen()),
      GoRoute(
          path: '/onboarding/notification-guide',
          builder: (_, _) => const NotificationGuideScreen()),
      GoRoute(path: '/med/has', builder: (_, _) => const MedHasScreen()),
      GoRoute(path: '/med/count', builder: (_, _) => const MedCountScreen()),
      GoRoute(
        path: '/med/hour',
        builder: (_, s) => MedHourScreen(
          count: int.tryParse(s.uri.queryParameters['count'] ?? '1') ?? 1,
        ),
      ),
      GoRoute(
        path: '/med/confirm',
        builder: (_, s) => MedConfirmScreen(
          count: int.tryParse(s.uri.queryParameters['count'] ?? '1') ?? 1,
          times: (s.uri.queryParameters['times'] ?? '')
              .split(',')
              .where((t) => t.isNotEmpty)
              .toList(),
        ),
      ),
      GoRoute(path: '/setup-done', builder: (_, _) => const SetupDoneScreen()),
      GoRoute(path: '/family', builder: (_, _) => const FamilyBranchScreen()),
      GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
      GoRoute(path: '/emergency', builder: (_, _) => const EmergencyScreen()),
      GoRoute(
          path: '/messages',
          builder: (_, _) => const SeniorMessagesScreen()),
      GoRoute(path: '/alarm', builder: (_, _) => const MedAlarmScreen()),
      GoRoute(
          path: '/guardian/pin',
          builder: (_, _) => const GuardianPinScreen()),
      GoRoute(
          path: '/guardian/login',
          builder: (_, _) => const GuardianLoginScreen()),
      GoRoute(
          path: '/guardian/connect-method',
          builder: (_, _) => const ConnectMethodScreen()),
      GoRoute(
          path: '/guardian/connect-code',
          builder: (_, _) => const ParentConnectScreen()),
      GoRoute(
          path: '/guardian/dashboard',
          builder: (_, _) => const GuardianDashboardScreen()),
      GoRoute(
          path: '/parent/connect',
          builder: (_, _) => const ParentConnectScreen()),
    ],
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
