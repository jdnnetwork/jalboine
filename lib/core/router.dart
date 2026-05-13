import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'supabase.dart';
import '../services/onboarding_status.dart';
import '../features/start/start_screen.dart';
import '../features/audio_guide/audio_guide_ask_screen.dart';
import '../features/font_size/font_size_screen.dart';
import '../features/age/age_screen.dart';
import '../features/auth/guardian_login_screen.dart';
import '../features/setup_intro/setup_done_screen.dart';
import '../features/onboarding/onboarding_flow.dart';
import '../features/terms/senior_terms_agreement_screen.dart';
import '../features/terms/terms_viewer_screen.dart';
import '../features/onboarding/setup/launcher_guide_screen.dart';
import '../features/onboarding/setup/launcher_done_screen.dart';
import '../features/onboarding/setup/battery_guide_screen.dart';
import '../features/onboarding/setup/notification_guide_screen.dart';
import '../features/medication_setup/med_has_screen.dart';
import '../features/medication_setup/med_count_screen.dart';
import '../features/medication_setup/med_slot_screen.dart';
import '../features/medication_setup/med_hour_screen.dart';
import '../features/medication_setup/med_confirm_screen.dart';
import '../features/medication_setup/notification_permission_screen.dart';
import '../features/pairing/family_branch_screen.dart';
import '../features/pairing/family_consent_screen.dart';
import '../features/home/home_screen.dart';
import '../features/home/more_screen.dart';
import '../features/emergency/emergency_screen.dart';
import '../features/messages/senior_messages_screen.dart';
import '../features/safety/call_permission_screen.dart';
import '../features/safety/unknown_call_alert_screen.dart';
import '../features/safety/location_permission_screen.dart';
import '../features/safety/emergency_sound_screen.dart';
import '../features/guardian/guardian_location_screen.dart';
import '../features/guardian/voice_record_screen.dart';
import '../features/subscription/subscription_screen.dart';
import '../features/medication_alarm/med_alarm_screen.dart';
import '../features/guardian_mode/guardian_pin_screen.dart';
import '../features/guardian/parent_connect_screen.dart';
import '../features/guardian/connect_method_screen.dart';
import '../features/guardian/guardian_dashboard_screen.dart';
import '../features/guardian/guardian_messages_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final sb = ref.watch(supabaseProvider);
  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(sb.auth.onAuthStateChange),
    redirect: (context, state) {
      // 온보딩을 마친 익명(피보호자) 세션은 시작/온보딩 경로에 진입 시 곧장 /home 으로.
      // 앱이 기본 런처로 떠도 매번 StartScreen 으로 돌아가는 무한 루프 방지.
      final path = state.uri.path;
      final isOnboardingPath = path == '/' ||
          path == '/audio-guide-ask' ||
          path == '/font-size' ||
          path == '/age' ||
          path.startsWith('/onboarding');
      if (!isOnboardingPath) return null;

      final user = sb.auth.currentUser;
      final shouldGoHome = user != null &&
          user.isAnonymous &&
          OnboardingStatus.isComplete;
      // ignore: avoid_print
      print(
        'jalboine route: path=$path '
        'anon=${user?.isAnonymous ?? false} '
        'done=${OnboardingStatus.isComplete} '
        '→ ${shouldGoHome ? "/home" : "stay"}',
      );
      if (shouldGoHome) return '/home';
      return null;
    },
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
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingFlow()),
      GoRoute(
          path: '/onboarding/terms',
          builder: (_, _) => const SeniorTermsAgreementScreen()),
      GoRoute(
        path: '/terms/view',
        builder: (_, s) {
          final extra = (s.extra as Map?) ?? const {};
          return TermsViewerScreen(
            assetPath: (extra['asset'] as String?) ?? '',
            title: (extra['title'] as String?) ?? '',
          );
        },
      ),
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
        path: '/med/slot',
        builder: (_, s) => MedSlotScreen(
          count: int.tryParse(s.uri.queryParameters['count'] ?? '1') ?? 1,
        ),
      ),
      GoRoute(
        path: '/med/hour',
        builder: (_, s) {
          final count =
              int.tryParse(s.uri.queryParameters['count'] ?? '1') ?? 1;
          final slotsStr = s.uri.queryParameters['slots'] ?? '';
          final slots = slotsStr
              .split(',')
              .where((x) => x.isNotEmpty)
              .toList();
          return MedHourScreen(count: count, slots: slots);
        },
      ),
      GoRoute(
        path: '/med/confirm',
        builder: (_, s) => MedConfirmScreen(
          count: int.tryParse(s.uri.queryParameters['count'] ?? '1') ?? 1,
          times: (s.uri.queryParameters['times'] ?? '')
              .split(',')
              .where((t) => t.isNotEmpty)
              .toList(),
          slots: (s.uri.queryParameters['slots'] ?? '')
              .split(',')
              .where((t) => t.isNotEmpty)
              .toList(),
        ),
      ),
      GoRoute(
        path: '/permission/notification',
        builder: (_, s) {
          final v = s.uri.queryParameters['med_alarm'] ?? 'false';
          return NotificationPermissionScreen(medicineAlarm: v == 'true');
        },
      ),
      GoRoute(path: '/setup-done', builder: (_, _) => const SetupDoneScreen()),
      GoRoute(path: '/family', builder: (_, _) => const FamilyBranchScreen()),
      GoRoute(
        path: '/family/consent',
        builder: (_, s) => FamilyConsentScreen(
          pairId: s.uri.queryParameters['pair'] ?? '',
        ),
      ),
      GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
      GoRoute(path: '/more', builder: (_, _) => const MoreScreen()),
      GoRoute(path: '/emergency', builder: (_, _) => const EmergencyScreen()),
      GoRoute(
          path: '/messages',
          builder: (_, _) => const SeniorMessagesScreen()),
      GoRoute(
          path: '/safety/call-permission',
          builder: (_, _) => const CallPermissionScreen()),
      GoRoute(
        path: '/safety/unknown-call',
        builder: (_, s) {
          final extra = (s.extra as Map?) ?? const {};
          return UnknownCallAlertScreen(
            phoneNumber: (extra['phone'] as String?) ?? '알 수 없음',
            durationSec: extra['duration'] as int?,
          );
        },
      ),
      GoRoute(
          path: '/safety/location-permission',
          builder: (_, _) => const LocationPermissionScreen()),
      GoRoute(
          path: '/safety/emergency-sound',
          builder: (_, _) => const EmergencySoundScreen()),
      GoRoute(
        path: '/guardian/location',
        builder: (_, s) {
          final extra = (s.extra as Map?) ?? const {};
          return GuardianLocationScreen(
            seniorId: (extra['seniorId'] as String?) ?? '',
          );
        },
      ),
      GoRoute(
        path: '/guardian/voice-record',
        builder: (_, s) {
          final extra = (s.extra as Map?) ?? const {};
          return VoiceRecordScreen(
            seniorId: (extra['seniorId'] as String?) ?? '',
          );
        },
      ),
      GoRoute(
          path: '/guardian/subscription',
          builder: (_, _) => const SubscriptionScreen()),
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
        path: '/guardian/messages',
        builder: (_, s) {
          final extra = (s.extra as Map?) ?? const {};
          return GuardianMessagesScreen(
            seniorId: (extra['seniorId'] as String?) ?? '',
          );
        },
      ),
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
