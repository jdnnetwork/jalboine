import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'supabase.dart';
import '../features/start/start_screen.dart';
import '../features/font_size/font_size_screen.dart';
import '../features/age/age_screen.dart';
import '../features/auth/guardian_login_screen.dart';
import '../features/setup_intro/setup_intro_screen.dart';
import '../features/setup_intro/setup_done_screen.dart';
import '../features/onboarding/onboarding_flow.dart';
import '../features/medication_setup/med_has_screen.dart';
import '../features/medication_setup/med_count_screen.dart';
import '../features/medication_setup/med_hour_screen.dart';
import '../features/medication_setup/med_confirm_screen.dart';
import '../features/pairing/family_branch_screen.dart';
import '../features/home/home_screen.dart';
import '../features/emergency/emergency_screen.dart';
import '../features/medication_alarm/med_alarm_screen.dart';
import '../features/guardian_mode/guardian_pin_screen.dart';
import '../features/guardian/parent_connect_screen.dart';
import '../features/guardian/guardian_dashboard_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final sb = ref.watch(supabaseProvider);
  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(sb.auth.onAuthStateChange),
    routes: [
      GoRoute(path: '/', builder: (_, _) => const StartScreen()),
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
      GoRoute(path: '/alarm', builder: (_, _) => const MedAlarmScreen()),
      GoRoute(
          path: '/guardian/pin',
          builder: (_, _) => const GuardianPinScreen()),
      GoRoute(
          path: '/guardian/login',
          builder: (_, _) => const GuardianLoginScreen()),
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
