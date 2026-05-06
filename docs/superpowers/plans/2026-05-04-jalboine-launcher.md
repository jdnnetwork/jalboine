# 잘보이네 런처 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 고령층 Flutter 런처 앱을 구현. 보호자가 Supabase Realtime을 통해 원격으로 UI/약/긴급연락처를 제어한다.

**Architecture:** Riverpod + go_router + supabase_flutter. 피보호자/보호자 두 역할을 한 앱에서 처리하고 인증 후 분기. `senior_settings` 행이 single source of truth — 보호자 편집 → Realtime 푸시 → 피보호자 UI 즉시 갱신.

**Tech Stack:** Flutter 3.10.8, Riverpod 2.5, go_router 14, supabase_flutter 2.5, audioplayers 6, flutter_local_notifications 17, url_launcher 6, android_intent_plus 5

---

## File Structure (Create / Modify)

```
pubspec.yaml                                  # Modify: 의존성 추가, assets 등록
android/app/src/main/AndroidManifest.xml      # Modify: 권한, queries
lib/main.dart                                 # Replace: Supabase init, 라우터, 테마
lib/core/
  theme.dart                                  # Create: ColorScheme, TextTheme, 버튼
  supabase.dart                               # Create: 클라이언트 + auth provider
  router.dart                                 # Create: go_router 설정
  constants.dart                              # Create: 앱 ID, 음성 파일 매핑
lib/models/
  user_profile.dart                           # Create
  senior_settings.dart                        # Create
  medication.dart                             # Create
  pair_link.dart                              # Create
  med_log.dart                                # Create
lib/services/
  audio_service.dart                          # Create
  launcher_service.dart                       # Create
  notification_service.dart                   # Create
  realtime_service.dart                       # Create
  pin_service.dart                            # Create
lib/features/auth/
  auth_screen.dart                            # Create: 전화/소셜 진입
  otp_screen.dart                             # Create
  role_select_screen.dart                     # Create
lib/features/pairing/
  pair_invite_screen.dart                     # Create: 피보호자 초대코드 표시
  pair_enter_screen.dart                      # Create: 보호자 초대코드 입력
lib/features/onboarding/
  onboarding_controller.dart                  # Create: 진행 상태
  question_screen.dart                        # Create: 재사용 위젯
  onboarding_flow.dart                        # Create: 7질문 PageView
lib/features/medication_setup/
  med_count_screen.dart                       # Create
  med_hour_screen.dart                        # Create
lib/features/home/
  home_screen.dart                            # Create: 그리드 + SOS 바
  app_tile.dart                               # Create
lib/features/medication_alarm/
  med_alarm_screen.dart                       # Create
lib/features/emergency/
  emergency_screen.dart                       # Create
lib/features/guardian_mode/
  guardian_pin_screen.dart                    # Create
  guardian_editor_screen.dart                 # Create
test/
  models/serialization_test.dart              # Create
  services/pin_service_test.dart              # Create
  widgets/onboarding_test.dart                # Create
```

Supabase 마이그레이션: `supabase/migrations/20260504000000_init.sql`

---

## Phase 0: Foundation

### Task 0.1: pubspec.yaml 의존성 + 자산

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: pubspec.yaml 전체 교체**

```yaml
name: jalboine
description: "고령층 스마트폰 런처"
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ^3.10.8

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  flutter_riverpod: ^2.5.1
  go_router: ^14.0.0
  supabase_flutter: ^2.5.0
  audioplayers: ^6.0.0
  flutter_local_notifications: ^17.0.0
  permission_handler: ^11.0.0
  timezone: ^0.9.0
  url_launcher: ^6.2.0
  android_intent_plus: ^5.0.0
  shared_preferences: ^2.2.0
  crypto: ^3.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/audio/
```

- [ ] **Step 2: pub get**

Run: `flutter pub get`
Expected: 모든 패키지 resolve 성공

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add core dependencies (riverpod, supabase, audio, notifications)"
```

---

### Task 0.2: Android 권한 / Manifest

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml`

- [ ] **Step 1: 권한 + queries 추가**

`<manifest>` 루트 자식으로 추가 (기존 `<application>` 위):

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.CALL_PHONE"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>

<queries>
  <intent>
    <action android:name="android.intent.action.DIAL"/>
  </intent>
  <intent>
    <action android:name="android.intent.action.VIEW"/>
    <data android:scheme="https"/>
  </intent>
  <package android:name="com.kakao.talk"/>
  <package android:name="com.google.android.youtube"/>
  <package android:name="com.android.camera"/>
  <package android:name="com.google.android.apps.photos"/>
</queries>
```

`<application>` 안에 알림 receiver 추가 (flutter_local_notifications 요구):

```xml
<receiver android:exported="false"
  android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"/>
<receiver android:exported="false"
  android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
  <intent-filter>
    <action android:name="android.intent.action.BOOT_COMPLETED"/>
    <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
    <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
  </intent-filter>
</receiver>
```

- [ ] **Step 2: Commit**

```bash
git add android/app/src/main/AndroidManifest.xml
git commit -m "chore(android): add permissions and intents for launcher/notifications"
```

---

### Task 0.3: 테마 (디자인 팔레트)

**Files:**
- Create: `lib/core/theme.dart`

- [ ] **Step 1: theme.dart 작성**

```dart
import 'package:flutter/material.dart';

class JTheme {
  static const surface = Color(0xFFF5E6D3);
  static const surfaceContainer = Color(0xFFFAF7F0);
  static const onSurface = Color(0xFF1A1A1A);
  static const tilePhone = Color(0xFF1B8A3A);
  static const tileMessage = Color(0xFF2BB3F0);
  static const tileKakao = Color(0xFFFAE100);
  static const tileYoutube = Color(0xFFE63946);
  static const tileCamera = Color(0xFF1A1A1A);
  static const tileAlbum = Color(0xFFC8102E);
  static const sos = Color(0xFFC8102E);

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: surface,
      colorScheme: base.colorScheme.copyWith(
        surface: surface,
        onSurface: onSurface,
        primary: tilePhone,
        error: sos,
      ),
      textTheme: base.textTheme.apply(fontFamilyFallback: const ['sans-serif']).copyWith(
        displayLarge: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: onSurface),
        headlineLarge: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: onSurface),
        headlineMedium: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: onSurface),
        titleLarge: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: onSurface),
        bodyLarge: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: onSurface),
        labelLarge: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(88),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          textStyle: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          elevation: 0,
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/core/theme.dart
git commit -m "feat(core): add design system theme with palette and large-text typography"
```

---

### Task 0.4: Supabase 클라이언트 + main.dart

**Files:**
- Create: `lib/core/supabase.dart`
- Create: `lib/core/constants.dart`
- Replace: `lib/main.dart`

- [ ] **Step 1: constants.dart**

```dart
class JConst {
  static const supabaseUrl = 'https://jubgobjvcrbagfuyohwv.supabase.co';
  static const supabaseAnonKey = 'sb_publishable_xtCmqqKIvSuSxdJPjRDh-w_m_TLIotZ';

  // 앱 ID → 음성 파일 + 한글 라벨
  static const apps = <String, AppMeta>{
    'phone':   AppMeta('전화',     'assets/audio/phone.wav',    Color(0xFF1B8A3A), Colors.white),
    'message': AppMeta('문자',     'assets/audio/message.wav',  Color(0xFF2BB3F0), Colors.white),
    'kakao':   AppMeta('카카오톡', 'assets/audio/kakao.wav',    Color(0xFFFAE100), Colors.black),
    'youtube': AppMeta('동영상',   'assets/audio/youtube.wav',  Color(0xFFE63946), Colors.white),
    'camera':  AppMeta('사진',     'assets/audio/camera.wav',   Color(0xFF1A1A1A), Colors.white),
    'album':   AppMeta('앨범',     'assets/audio/album.wav',    Color(0xFFC8102E), Colors.white),
  };

  static const audioMedicineQ      = 'assets/audio/medicine.wav';
  static const audioMedicineCount  = 'assets/audio/how many.wav';
  static const audioMedicineHour   = 'assets/audio/what hour.wav';
  static const audioMedicineAlarm  = 'assets/audio/medicine_alarm.wav';
}

class AppMeta {
  final String label;
  final String audio;
  final Color bg;
  final Color fg;
  const AppMeta(this.label, this.audio, this.bg, this.fg);
}
```

`flutter/material.dart` import 추가 (Color/Colors 때문).

- [ ] **Step 2: supabase.dart**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'constants.dart';

final supabaseProvider = Provider<SupabaseClient>((_) => Supabase.instance.client);

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseProvider).auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(supabaseProvider).auth.currentUser;
});

Future<void> initSupabase() async {
  await Supabase.initialize(url: JConst.supabaseUrl, anonKey: JConst.supabaseAnonKey);
}
```

- [ ] **Step 3: main.dart 교체**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/supabase.dart';
import 'core/theme.dart';
import 'core/router.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSupabase();
  await NotificationService.instance.init();
  runApp(const ProviderScope(child: JalboineApp()));
}

class JalboineApp extends ConsumerWidget {
  const JalboineApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: '잘보이네',
      theme: JTheme.light(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

- [ ] **Step 4: Commit**

```bash
git add lib/core/constants.dart lib/core/supabase.dart lib/main.dart
git commit -m "feat(core): wire Supabase init and app shell"
```

---

### Task 0.5: 모델 클래스

**Files:**
- Create: `lib/models/user_profile.dart`
- Create: `lib/models/senior_settings.dart`
- Create: `lib/models/medication.dart`
- Create: `lib/models/pair_link.dart`
- Create: `lib/models/med_log.dart`
- Create: `test/models/serialization_test.dart`

- [ ] **Step 1: 실패 테스트 작성**

```dart
// test/models/serialization_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:jalboine/models/senior_settings.dart';

void main() {
  test('SeniorSettings round-trips through JSON', () {
    final s = SeniorSettings(
      userId: 'u1',
      enabledApps: const ['phone', 'kakao'],
      takesMedication: true,
      emergencyContacts: const [EmergencyContact(name: '아들', phone: '01012345678')],
      guardianPinHash: 'abc',
    );
    final json = s.toJson();
    final back = SeniorSettings.fromJson(json);
    expect(back.userId, 'u1');
    expect(back.enabledApps, ['phone', 'kakao']);
    expect(back.takesMedication, isTrue);
    expect(back.emergencyContacts.first.phone, '01012345678');
    expect(back.guardianPinHash, 'abc');
  });
}
```

Run: `flutter test test/models/serialization_test.dart`
Expected: FAIL (파일 없음)

- [ ] **Step 2: user_profile.dart**

```dart
enum UserRole { senior, guardian }

class UserProfile {
  final String userId;
  final UserRole role;
  final String? name;
  final String? phone;

  const UserProfile({required this.userId, required this.role, this.name, this.phone});

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        userId: j['user_id'] as String,
        role: j['role'] == 'guardian' ? UserRole.guardian : UserRole.senior,
        name: j['name'] as String?,
        phone: j['phone'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'role': role.name,
        'name': name,
        'phone': phone,
      };
}
```

- [ ] **Step 3: senior_settings.dart**

```dart
class EmergencyContact {
  final String name;
  final String phone;
  const EmergencyContact({required this.name, required this.phone});

  factory EmergencyContact.fromJson(Map<String, dynamic> j) =>
      EmergencyContact(name: j['name'] as String, phone: j['phone'] as String);

  Map<String, dynamic> toJson() => {'name': name, 'phone': phone};
}

class SeniorSettings {
  final String userId;
  final List<String> enabledApps;
  final bool takesMedication;
  final List<EmergencyContact> emergencyContacts;
  final String? guardianPinHash;

  const SeniorSettings({
    required this.userId,
    required this.enabledApps,
    required this.takesMedication,
    required this.emergencyContacts,
    this.guardianPinHash,
  });

  factory SeniorSettings.fromJson(Map<String, dynamic> j) => SeniorSettings(
        userId: j['user_id'] as String,
        enabledApps: List<String>.from((j['enabled_apps'] as List?) ?? const []),
        takesMedication: (j['takes_medication'] as bool?) ?? false,
        emergencyContacts: ((j['emergency_contacts'] as List?) ?? const [])
            .map((e) => EmergencyContact.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        guardianPinHash: j['guardian_pin_hash'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'enabled_apps': enabledApps,
        'takes_medication': takesMedication,
        'emergency_contacts': emergencyContacts.map((e) => e.toJson()).toList(),
        'guardian_pin_hash': guardianPinHash,
      };

  SeniorSettings copyWith({
    List<String>? enabledApps,
    bool? takesMedication,
    List<EmergencyContact>? emergencyContacts,
    String? guardianPinHash,
  }) =>
      SeniorSettings(
        userId: userId,
        enabledApps: enabledApps ?? this.enabledApps,
        takesMedication: takesMedication ?? this.takesMedication,
        emergencyContacts: emergencyContacts ?? this.emergencyContacts,
        guardianPinHash: guardianPinHash ?? this.guardianPinHash,
      );

  static const empty = SeniorSettings(
    userId: '',
    enabledApps: [],
    takesMedication: false,
    emergencyContacts: [],
  );
}
```

- [ ] **Step 4: medication.dart**

```dart
class Medication {
  final String id;
  final String userId;
  final List<String> times; // 'HH:mm:ss' from Postgres time[]
  final int timesPerDay;

  const Medication({
    required this.id,
    required this.userId,
    required this.times,
    required this.timesPerDay,
  });

  factory Medication.fromJson(Map<String, dynamic> j) => Medication(
        id: j['id'] as String,
        userId: j['user_id'] as String,
        times: List<String>.from((j['times'] as List?) ?? const []),
        timesPerDay: (j['times_per_day'] as int?) ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'times': times,
        'times_per_day': timesPerDay,
      };
}
```

- [ ] **Step 5: pair_link.dart**

```dart
class PairLink {
  final String id;
  final String? seniorUserId;
  final String? guardianUserId;
  final String status; // 'pending'|'accepted'
  final String? inviteCode;

  const PairLink({
    required this.id,
    this.seniorUserId,
    this.guardianUserId,
    required this.status,
    this.inviteCode,
  });

  factory PairLink.fromJson(Map<String, dynamic> j) => PairLink(
        id: j['id'] as String,
        seniorUserId: j['senior_user_id'] as String?,
        guardianUserId: j['guardian_user_id'] as String?,
        status: j['status'] as String,
        inviteCode: j['invite_code'] as String?,
      );
}
```

- [ ] **Step 6: med_log.dart**

```dart
class MedLog {
  final String id;
  final String userId;
  final DateTime scheduledAt;
  final String status; // 'taken'|'delayed'|'missed'
  final DateTime? takenAt;

  const MedLog({
    required this.id,
    required this.userId,
    required this.scheduledAt,
    required this.status,
    this.takenAt,
  });

  Map<String, dynamic> toInsert() => {
        'user_id': userId,
        'scheduled_at': scheduledAt.toIso8601String(),
        'status': status,
        if (takenAt != null) 'taken_at': takenAt!.toIso8601String(),
      };
}
```

- [ ] **Step 7: 테스트 PASS 확인**

Run: `flutter test test/models/serialization_test.dart`
Expected: PASS

- [ ] **Step 8: Commit**

```bash
git add lib/models/ test/models/
git commit -m "feat(models): add UserProfile, SeniorSettings, Medication, PairLink, MedLog"
```

---

## Phase 1: Auth & Pairing

### Task 1.1: PIN 서비스

**Files:**
- Create: `lib/services/pin_service.dart`
- Create: `test/services/pin_service_test.dart`

- [ ] **Step 1: 실패 테스트**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:jalboine/services/pin_service.dart';

void main() {
  test('hash and verify match', () {
    final h = PinService.hash('1234');
    expect(PinService.verify('1234', h), isTrue);
    expect(PinService.verify('0000', h), isFalse);
  });
}
```

Run: `flutter test test/services/pin_service_test.dart` → FAIL

- [ ] **Step 2: pin_service.dart**

```dart
import 'dart:convert';
import 'package:crypto/crypto.dart';

class PinService {
  static const _salt = 'jalboine_v1_pin_salt';

  static String hash(String pin) {
    final bytes = utf8.encode('$_salt:$pin');
    return sha256.convert(bytes).toString();
  }

  static bool verify(String pin, String? hashed) {
    if (hashed == null || hashed.isEmpty) return false;
    return hash(pin) == hashed;
  }
}
```

- [ ] **Step 3: PASS 확인 + commit**

```bash
flutter test test/services/pin_service_test.dart
git add lib/services/pin_service.dart test/services/pin_service_test.dart
git commit -m "feat(services): add PinService with SHA-256 hashing"
```

---

### Task 1.2: 라우터 + 인증 화면

**Files:**
- Create: `lib/core/router.dart`
- Create: `lib/features/auth/auth_screen.dart`
- Create: `lib/features/auth/otp_screen.dart`
- Create: `lib/features/auth/role_select_screen.dart`

- [ ] **Step 1: router.dart**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'supabase.dart';
import '../features/auth/auth_screen.dart';
import '../features/auth/otp_screen.dart';
import '../features/auth/role_select_screen.dart';
import '../features/pairing/pair_invite_screen.dart';
import '../features/pairing/pair_enter_screen.dart';
import '../features/onboarding/onboarding_flow.dart';
import '../features/medication_setup/med_count_screen.dart';
import '../features/medication_setup/med_hour_screen.dart';
import '../features/home/home_screen.dart';
import '../features/emergency/emergency_screen.dart';
import '../features/medication_alarm/med_alarm_screen.dart';
import '../features/guardian_mode/guardian_pin_screen.dart';
import '../features/guardian_mode/guardian_editor_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authStateProvider);
  return GoRouter(
    initialLocation: '/',
    redirect: (ctx, state) {
      final user = ref.read(supabaseProvider).auth.currentUser;
      final loggedIn = user != null;
      final atAuth = state.matchedLocation.startsWith('/auth');
      if (!loggedIn && !atAuth) return '/auth';
      if (loggedIn && atAuth) return '/role';
      return null;
    },
    refreshListenable: GoRouterRefreshStream(ref.read(supabaseProvider).auth.onAuthStateChange),
    routes: [
      GoRoute(path: '/', redirect: (_, __) => '/auth'),
      GoRoute(path: '/auth', builder: (_, __) => const AuthScreen()),
      GoRoute(path: '/auth/otp', builder: (_, s) => OtpScreen(phone: s.uri.queryParameters['phone']!)),
      GoRoute(path: '/role', builder: (_, __) => const RoleSelectScreen()),
      GoRoute(path: '/pair/invite', builder: (_, __) => const PairInviteScreen()),
      GoRoute(path: '/pair/enter', builder: (_, __) => const PairEnterScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingFlow()),
      GoRoute(path: '/med/count', builder: (_, __) => const MedCountScreen()),
      GoRoute(path: '/med/hour', builder: (_, s) => MedHourScreen(count: int.parse(s.uri.queryParameters['count']!))),
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/emergency', builder: (_, __) => const EmergencyScreen()),
      GoRoute(path: '/alarm', builder: (_, __) => const MedAlarmScreen()),
      GoRoute(path: '/guardian/pin', builder: (_, __) => const GuardianPinScreen()),
      GoRoute(path: '/guardian/edit', builder: (_, __) => const GuardianEditorScreen()),
    ],
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _sub;
  @override
  void dispose() { _sub.cancel(); super.dispose(); }
}
```

`import 'dart:async';` 추가, `import 'package:flutter/foundation.dart';` 추가.

- [ ] **Step 2: auth_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});
  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _phone = TextEditingController();
  bool _busy = false;

  Future<void> _sendOtp() async {
    setState(() => _busy = true);
    try {
      final phone = _phone.text.trim();
      final intl = phone.startsWith('0') ? '+82${phone.substring(1)}' : phone;
      await ref.read(supabaseProvider).auth.signInWithOtp(phone: intl);
      if (mounted) context.push('/auth/otp?phone=$intl');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signInWith(OAuthProvider p) async {
    await ref.read(supabaseProvider).auth.signInWithOAuth(p);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('잘보이네', style: Theme.of(context).textTheme.displayLarge),
              const SizedBox(height: 48),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                decoration: const InputDecoration(
                  labelText: '전화번호',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _busy ? null : _sendOtp,
                child: const Text('인증번호 받기'),
              ),
              const SizedBox(height: 16),
              const Text('— 또는 (보호자 전용) —', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 16),
              OutlinedButton(onPressed: () => _signInWith(OAuthProvider.google), child: const Text('Google 로그인')),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: () => _signInWith(OAuthProvider.kakao), child: const Text('카카오 로그인')),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: otp_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phone;
  const OtpScreen({super.key, required this.phone});
  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _code = TextEditingController();
  bool _busy = false;

  Future<void> _verify() async {
    setState(() => _busy = true);
    try {
      await ref.read(supabaseProvider).auth.verifyOTP(
            type: OtpType.sms,
            phone: widget.phone,
            token: _code.text.trim(),
          );
      if (mounted) context.go('/role');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('인증번호 입력', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 24),
              TextField(
                controller: _code,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: _busy ? null : _verify, child: const Text('확인')),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: role_select_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/supabase.dart';

class RoleSelectScreen extends ConsumerWidget {
  const RoleSelectScreen({super.key});

  Future<void> _setRole(WidgetRef ref, String role) async {
    final sb = ref.read(supabaseProvider);
    final user = sb.auth.currentUser!;
    await sb.from('profiles').upsert({
      'user_id': user.id,
      'role': role,
      'phone': user.phone,
    });
    if (role == 'senior') {
      await sb.from('senior_settings').upsert({'user_id': user.id});
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('어떤 분이신가요?', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async { await _setRole(ref, 'senior'); if (context.mounted) context.go('/pair/invite'); },
                child: const Text('어르신 (피보호자)'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async { await _setRole(ref, 'guardian'); if (context.mounted) context.go('/pair/enter'); },
                child: const Text('가족 (보호자)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Commit**

```bash
git add lib/core/router.dart lib/features/auth/
git commit -m "feat(auth): add phone OTP, OAuth, role selection with go_router"
```

---

### Task 1.3: 페어링 화면

**Files:**
- Create: `lib/features/pairing/pair_invite_screen.dart`
- Create: `lib/features/pairing/pair_enter_screen.dart`

- [ ] **Step 1: pair_invite_screen.dart (피보호자)**

```dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/supabase.dart';

class PairInviteScreen extends ConsumerStatefulWidget {
  const PairInviteScreen({super.key});
  @override
  ConsumerState<PairInviteScreen> createState() => _PairInviteScreenState();
}

class _PairInviteScreenState extends ConsumerState<PairInviteScreen> {
  String? _code;

  @override
  void initState() {
    super.initState();
    _ensureCode();
  }

  Future<void> _ensureCode() async {
    final sb = ref.read(supabaseProvider);
    final uid = sb.auth.currentUser!.id;
    final existing = await sb.from('pair_links')
        .select('invite_code, status')
        .eq('senior_user_id', uid)
        .maybeSingle();
    if (existing != null) {
      setState(() => _code = existing['invite_code'] as String?);
      if (existing['status'] == 'accepted' && mounted) context.go('/onboarding');
      return;
    }
    final code = _genCode();
    await sb.from('pair_links').insert({
      'senior_user_id': uid,
      'status': 'pending',
      'invite_code': code,
    });
    setState(() => _code = code);
  }

  String _genCode() {
    final r = Random.secure();
    return List.generate(6, (_) => r.nextInt(10).toString()).join();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('가족에게 보여주세요', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 24),
              Text(_code ?? '...', style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w900, letterSpacing: 12)),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.go('/onboarding'),
                child: const Text('나중에 연결하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: pair_enter_screen.dart (보호자)**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/supabase.dart';

class PairEnterScreen extends ConsumerStatefulWidget {
  const PairEnterScreen({super.key});
  @override
  ConsumerState<PairEnterScreen> createState() => _PairEnterScreenState();
}

class _PairEnterScreenState extends ConsumerState<PairEnterScreen> {
  final _code = TextEditingController();
  bool _busy = false;

  Future<void> _link() async {
    setState(() => _busy = true);
    try {
      final sb = ref.read(supabaseProvider);
      final uid = sb.auth.currentUser!.id;
      final res = await sb.from('pair_links')
          .update({'guardian_user_id': uid, 'status': 'accepted'})
          .eq('invite_code', _code.text.trim())
          .select();
      if (res.isEmpty) throw '잘못된 코드';
      if (mounted) context.go('/guardian/edit');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('초대 코드 입력', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 24),
              TextField(
                controller: _code,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: _busy ? null : _link, child: const Text('연결하기')),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/pairing/
git commit -m "feat(pairing): add invite code generation and entry screens"
```

---

## Phase 2: Onboarding & Audio

### Task 2.1: 오디오 서비스

**Files:**
- Create: `lib/services/audio_service.dart`

- [ ] **Step 1: audio_service.dart**

```dart
import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final instance = AudioService._();
  AudioService._();
  final _player = AudioPlayer();

  Future<void> play(String assetPath) async {
    final p = assetPath.startsWith('assets/') ? assetPath.substring('assets/'.length) : assetPath;
    await _player.stop();
    await _player.play(AssetSource(p));
  }

  Future<void> stop() => _player.stop();
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/services/audio_service.dart
git commit -m "feat(audio): add AudioService wrapping audioplayers"
```

---

### Task 2.2: 온보딩 흐름

**Files:**
- Create: `lib/features/onboarding/question_screen.dart`
- Create: `lib/features/onboarding/onboarding_flow.dart`

- [ ] **Step 1: question_screen.dart**

```dart
import 'package:flutter/material.dart';
import '../../services/audio_service.dart';

class QuestionScreen extends StatefulWidget {
  final String question;
  final String audioAsset;
  final int step;
  final int total;
  final void Function(bool yes) onAnswer;

  const QuestionScreen({
    super.key,
    required this.question,
    required this.audioAsset,
    required this.step,
    required this.total,
    required this.onAnswer,
  });

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AudioService.instance.play(widget.audioAsset);
    });
  }

  @override
  void didUpdateWidget(covariant QuestionScreen old) {
    super.didUpdateWidget(old);
    if (old.audioAsset != widget.audioAsset) {
      AudioService.instance.play(widget.audioAsset);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                widget.question,
                style: Theme.of(context).textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B8A3A), foregroundColor: Colors.white),
                    onPressed: () => widget.onAnswer(true),
                    child: const Text('네'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE63946), foregroundColor: Colors.white),
                    onPressed: () => widget.onAnswer(false),
                    child: const Text('아니요'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.total, (i) {
                final active = i <= widget.step;
                return Container(
                  width: 16, height: 16,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active ? const Color(0xFF1A1A1A) : Colors.black26,
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: onboarding_flow.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/supabase.dart';
import 'question_screen.dart';

class _Q { final String key, audio, text;
  const _Q(this.key, this.audio, this.text);
}

const _questions = <_Q>[
  _Q('phone',   'assets/audio/phone.wav',    '전화를 자주 하시나요?'),
  _Q('message', 'assets/audio/message.wav',  '문자를 자주 하시나요?'),
  _Q('kakao',   'assets/audio/kakao.wav',    '카카오톡을 하시나요?'),
  _Q('youtube', 'assets/audio/youtube.wav',  '동영상을 자주 보시나요?'),
  _Q('camera',  'assets/audio/camera.wav',   '사진을 자주 찍으시나요?'),
  _Q('album',   'assets/audio/album.wav',    '사진 앨범을 자주 보시나요?'),
  _Q('medicine',JConst.audioMedicineQ,       '약을 드시나요?'),
];

class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});
  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  int _i = 0;
  final List<String> _enabled = [];
  bool _takesMedication = false;

  Future<void> _answer(bool yes) async {
    final q = _questions[_i];
    if (q.key == 'medicine') {
      _takesMedication = yes;
    } else if (yes) {
      _enabled.add(q.key);
    }
    if (_i < _questions.length - 1) {
      setState(() => _i++);
    } else {
      await _persist();
      if (!mounted) return;
      if (_takesMedication) {
        context.go('/med/count');
      } else {
        context.go('/home');
      }
    }
  }

  Future<void> _persist() async {
    final sb = ref.read(supabaseProvider);
    final uid = sb.auth.currentUser!.id;
    await sb.from('senior_settings').upsert({
      'user_id': uid,
      'enabled_apps': _enabled,
      'takes_medication': _takesMedication,
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_i];
    return QuestionScreen(
      question: q.text,
      audioAsset: q.audio,
      step: _i,
      total: _questions.length,
      onAnswer: _answer,
    );
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/onboarding/
git commit -m "feat(onboarding): add 7-question flow with auto audio playback"
```

---

## Phase 3: Medication Setup

### Task 3.1: 횟수/시간 선택 화면

**Files:**
- Create: `lib/features/medication_setup/med_count_screen.dart`
- Create: `lib/features/medication_setup/med_hour_screen.dart`

- [ ] **Step 1: med_count_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../services/audio_service.dart';

class MedCountScreen extends StatefulWidget {
  const MedCountScreen({super.key});
  @override
  State<MedCountScreen> createState() => _MedCountScreenState();
}

class _MedCountScreenState extends State<MedCountScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AudioService.instance.play(JConst.audioMedicineCount);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 32),
              Text('하루에 몇 번\n약을 드시나요?',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge),
              const Spacer(),
              for (final n in [1, 2, 3, 4]) ...[
                ElevatedButton(
                  onPressed: () => context.go('/med/hour?count=$n'),
                  child: Text('$n 번'),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: med_hour_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/supabase.dart';
import '../../services/audio_service.dart';
import '../../services/notification_service.dart';

class MedHourScreen extends ConsumerStatefulWidget {
  final int count;
  const MedHourScreen({super.key, required this.count});
  @override
  ConsumerState<MedHourScreen> createState() => _MedHourScreenState();
}

class _MedHourScreenState extends ConsumerState<MedHourScreen> {
  final List<int> _hours = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AudioService.instance.play(JConst.audioMedicineHour);
    });
  }

  Future<void> _pick(int h) async {
    setState(() => _hours.add(h));
    if (_hours.length < widget.count) return;
    final sb = ref.read(supabaseProvider);
    final uid = sb.auth.currentUser!.id;
    final times = _hours.map((h) => '${h.toString().padLeft(2, '0')}:00:00').toList();
    await sb.from('medications').upsert({
      'user_id': uid,
      'times': times,
      'times_per_day': widget.count,
    });
    await NotificationService.instance.rescheduleMedications(times);
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Text('${_hours.length + 1}번째 시간',
                  style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 4,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: List.generate(24, (h) {
                    return ElevatedButton(
                      onPressed: () => _pick(h),
                      child: Text('$h시', style: const TextStyle(fontSize: 22)),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/medication_setup/
git commit -m "feat(medication): add count and hour selection screens"
```

---

## Phase 4: Notification Service

### Task 4.1: NotificationService

**Files:**
- Create: `lib/services/notification_service.dart`

- [ ] **Step 1: notification_service.dart**

```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final instance = NotificationService._();
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
    const init = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(init, onDidReceiveNotificationResponse: _onTap);
    await Permission.notification.request();
    _ready = true;
  }

  static void _onTap(NotificationResponse r) {
    // 진입은 main이 라우터로 처리. payload로 분기 가능.
  }

  Future<void> rescheduleMedications(List<String> times) async {
    await _plugin.cancelAll();
    final now = tz.TZDateTime.now(tz.local);
    int id = 100;
    for (final t in times) {
      final parts = t.split(':');
      final h = int.parse(parts[0]); final m = int.parse(parts[1]);
      var when = tz.TZDateTime(tz.local, now.year, now.month, now.day, h, m);
      if (when.isBefore(now)) when = when.add(const Duration(days: 1));
      await _plugin.zonedSchedule(
        id++,
        '약 드실 시간이에요!',
        '약을 드세요',
        when,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'med_alarm', '약 알림',
            channelDescription: '약 복용 시간 알림',
            importance: Importance.max,
            priority: Priority.high,
            fullScreenIntent: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'med_alarm',
      );
    }
  }

  Future<void> snooze10min() async {
    final when = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 10));
    await _plugin.zonedSchedule(
      999,
      '약 드실 시간이에요!',
      '아직 약을 드시지 않았어요',
      when,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'med_alarm', '약 알림', importance: Importance.max, priority: Priority.high, fullScreenIntent: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'med_alarm',
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/services/notification_service.dart
git commit -m "feat(notifications): schedule daily exact medication alarms"
```

---

## Phase 5: Home / Launcher / Emergency

### Task 5.1: 런처 서비스

**Files:**
- Create: `lib/services/launcher_service.dart`

- [ ] **Step 1: launcher_service.dart**

```dart
import 'package:android_intent_plus/android_intent.dart';
import 'package:url_launcher/url_launcher.dart';

class LauncherService {
  static Future<void> launchApp(String key) async {
    switch (key) {
      case 'phone':
        await launchUrl(Uri.parse('tel:'));
        break;
      case 'message':
        await launchUrl(Uri.parse('sms:'));
        break;
      case 'kakao':
        await const AndroidIntent(action: 'action_main', package: 'com.kakao.talk').launch();
        break;
      case 'youtube':
        await const AndroidIntent(action: 'action_main', package: 'com.google.android.youtube').launch();
        break;
      case 'camera':
        await const AndroidIntent(action: 'android.media.action.IMAGE_CAPTURE').launch();
        break;
      case 'album':
        await const AndroidIntent(action: 'android.intent.action.VIEW', type: 'image/*').launch();
        break;
    }
  }

  static Future<void> dial(String number) => launchUrl(Uri.parse('tel:$number'));
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/services/launcher_service.dart
git commit -m "feat(launcher): add system intents for phone, kakao, youtube, camera, album"
```

---

### Task 5.2: Realtime 서비스 + senior_settings provider

**Files:**
- Create: `lib/services/realtime_service.dart`

- [ ] **Step 1: realtime_service.dart**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase.dart';
import '../models/senior_settings.dart';

final seniorSettingsProvider = StreamProvider<SeniorSettings>((ref) async* {
  final sb = ref.watch(supabaseProvider);
  final uid = sb.auth.currentUser?.id;
  if (uid == null) return;
  final stream = sb.from('senior_settings').stream(primaryKey: ['user_id']).eq('user_id', uid);
  await for (final rows in stream) {
    if (rows.isEmpty) {
      yield SeniorSettings.empty;
    } else {
      yield SeniorSettings.fromJson(rows.first);
    }
  }
});

// 보호자가 다른 senior 설정을 보는 용도
final remoteSeniorSettingsProvider = StreamProvider.family<SeniorSettings, String>((ref, seniorId) async* {
  final sb = ref.watch(supabaseProvider);
  final stream = sb.from('senior_settings').stream(primaryKey: ['user_id']).eq('user_id', seniorId);
  await for (final rows in stream) {
    if (rows.isEmpty) { yield SeniorSettings.empty; continue; }
    yield SeniorSettings.fromJson(rows.first);
  }
});
```

- [ ] **Step 2: Commit**

```bash
git add lib/services/realtime_service.dart
git commit -m "feat(realtime): subscribe senior_settings via Supabase stream"
```

---

### Task 5.3: 홈 화면

**Files:**
- Create: `lib/features/home/app_tile.dart`
- Create: `lib/features/home/home_screen.dart`

- [ ] **Step 1: app_tile.dart**

```dart
import 'package:flutter/material.dart';
import '../../core/constants.dart';

class AppTile extends StatelessWidget {
  final String appKey;
  final VoidCallback onTap;
  const AppTile({super.key, required this.appKey, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final meta = JConst.apps[appKey]!;
    return Material(
      color: meta.bg,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Center(
          child: Text(
            meta.label,
            style: TextStyle(
              fontSize: 36, fontWeight: FontWeight.w900, color: meta.fg,
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: home_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../services/launcher_service.dart';
import '../../services/realtime_service.dart';
import 'app_tile.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  int _crossAxisCount(int n) {
    if (n <= 1) return 1;
    return 2;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(seniorSettingsProvider);
    return Scaffold(
      body: SafeArea(
        child: settings.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (s) {
            final apps = s.enabledApps;
            return Column(
              children: [
                Expanded(
                  child: GestureDetector(
                    onLongPress: () => context.push('/guardian/pin'),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: apps.isEmpty
                          ? const Center(child: Text('앱이 없어요', style: TextStyle(fontSize: 24)))
                          : GridView.count(
                              crossAxisCount: _crossAxisCount(apps.length),
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              children: [
                                for (final k in apps)
                                  AppTile(appKey: k, onTap: () => LauncherService.launchApp(k)),
                              ],
                            ),
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 96,
                  child: Material(
                    color: JTheme.sos,
                    child: InkWell(
                      onTap: () => context.push('/emergency'),
                      child: const Center(
                        child: Text('긴급 전화',
                            style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white)),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/home/
git commit -m "feat(home): add app grid with realtime settings and SOS bar"
```

---

### Task 5.4: 긴급 전화 화면

**Files:**
- Create: `lib/features/emergency/emergency_screen.dart`

- [ ] **Step 1: emergency_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/launcher_service.dart';
import '../../services/realtime_service.dart';

class EmergencyScreen extends ConsumerWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(seniorSettingsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('긴급 전화')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Expanded(child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC8102E), foregroundColor: Colors.white),
              onPressed: () => LauncherService.dial('119'),
              child: const Text('119 (구급)', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900)),
            )),
            const SizedBox(height: 16),
            Expanded(child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2BB3F0), foregroundColor: Colors.white),
              onPressed: () => LauncherService.dial('112'),
              child: const Text('112 (경찰)', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900)),
            )),
            const SizedBox(height: 16),
            Expanded(child: settings.when(
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
              data: (s) {
                if (s.emergencyContacts.isEmpty) return const SizedBox();
                final c = s.emergencyContacts.first;
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B8A3A), foregroundColor: Colors.white),
                  onPressed: () => LauncherService.dial(c.phone),
                  child: Text('${c.name}', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900)),
                );
              },
            )),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/emergency/
git commit -m "feat(emergency): add 119/112/guardian dial buttons"
```

---

## Phase 6: Medication Alarm Dialog

### Task 6.1: 알림 다이얼로그 화면

**Files:**
- Create: `lib/features/medication_alarm/med_alarm_screen.dart`

- [ ] **Step 1: med_alarm_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/supabase.dart';
import '../../services/audio_service.dart';
import '../../services/notification_service.dart';

class MedAlarmScreen extends ConsumerStatefulWidget {
  const MedAlarmScreen({super.key});
  @override
  ConsumerState<MedAlarmScreen> createState() => _MedAlarmScreenState();
}

class _MedAlarmScreenState extends ConsumerState<MedAlarmScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AudioService.instance.play(JConst.audioMedicineAlarm);
    });
  }

  Future<void> _logAndExit(String status) async {
    final sb = ref.read(supabaseProvider);
    await sb.from('med_logs').insert({
      'user_id': sb.auth.currentUser!.id,
      'scheduled_at': DateTime.now().toIso8601String(),
      'status': status,
      if (status == 'taken') 'taken_at': DateTime.now().toIso8601String(),
    });
    if (status == 'delayed') {
      await NotificationService.instance.snooze10min();
    }
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Text('약 드실 시간이에요!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayLarge),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B8A3A), foregroundColor: Colors.white),
                onPressed: () => _logAndExit('taken'),
                child: const Text('먹었어요'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFAE100), foregroundColor: Colors.black),
                onPressed: () => _logAndExit('delayed'),
                child: const Text('나중에'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/medication_alarm/
git commit -m "feat(med_alarm): big dialog with taken/delayed and 10-min snooze"
```

---

## Phase 7: Guardian Mode

### Task 7.1: PIN 게이트

**Files:**
- Create: `lib/features/guardian_mode/guardian_pin_screen.dart`

- [ ] **Step 1: guardian_pin_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/pin_service.dart';
import '../../services/realtime_service.dart';
import '../../core/supabase.dart';

class GuardianPinScreen extends ConsumerStatefulWidget {
  const GuardianPinScreen({super.key});
  @override
  ConsumerState<GuardianPinScreen> createState() => _GuardianPinScreenState();
}

class _GuardianPinScreenState extends ConsumerState<GuardianPinScreen> {
  final _ctrl = TextEditingController();

  Future<void> _check() async {
    final settings = ref.read(seniorSettingsProvider).value;
    final hash = settings?.guardianPinHash;
    if (hash == null || hash.isEmpty) {
      // 최초 진입: 입력 값을 PIN으로 저장
      final newHash = PinService.hash(_ctrl.text);
      final sb = ref.read(supabaseProvider);
      await sb.from('senior_settings').update({'guardian_pin_hash': newHash}).eq('user_id', sb.auth.currentUser!.id);
      if (mounted) context.go('/guardian/edit');
      return;
    }
    if (PinService.verify(_ctrl.text, hash)) {
      if (mounted) context.go('/guardian/edit');
    } else {
      _ctrl.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN이 다릅니다')));
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
            Text('PIN을 입력하세요', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 24),
            TextField(
              controller: _ctrl,
              keyboardType: TextInputType.number,
              obscureText: true,
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: 12),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _check, child: const Text('확인')),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/guardian_mode/guardian_pin_screen.dart
git commit -m "feat(guardian): PIN gate with first-time set behavior"
```

---

### Task 7.2: 편집기 화면

**Files:**
- Create: `lib/features/guardian_mode/guardian_editor_screen.dart`

- [ ] **Step 1: guardian_editor_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../core/supabase.dart';
import '../../models/senior_settings.dart';
import '../../services/realtime_service.dart';

class GuardianEditorScreen extends ConsumerWidget {
  const GuardianEditorScreen({super.key});

  Future<void> _toggleApp(WidgetRef ref, SeniorSettings s, String key) async {
    final next = List<String>.from(s.enabledApps);
    next.contains(key) ? next.remove(key) : next.add(key);
    final sb = ref.read(supabaseProvider);
    await sb.from('senior_settings')
        .update({'enabled_apps': next})
        .eq('user_id', sb.auth.currentUser!.id);
  }

  Future<void> _setContact(WidgetRef ref, SeniorSettings s, String name, String phone) async {
    final next = [{'name': name, 'phone': phone}, ...s.emergencyContacts.skip(1).map((e) => e.toJson())];
    final sb = ref.read(supabaseProvider);
    await sb.from('senior_settings')
        .update({'emergency_contacts': next})
        .eq('user_id', sb.auth.currentUser!.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(seniorSettingsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('보호자 설정')),
      body: settings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (s) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Padding(padding: EdgeInsets.all(8), child: Text('표시할 앱', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900))),
            for (final entry in JConst.apps.entries)
              CheckboxListTile(
                title: Text(entry.value.label, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                value: s.enabledApps.contains(entry.key),
                onChanged: (_) => _toggleApp(ref, s, entry.key),
              ),
            const Divider(),
            const Padding(padding: EdgeInsets.all(8), child: Text('보호자 연락처', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900))),
            _ContactEditor(
              initial: s.emergencyContacts.isEmpty ? null : s.emergencyContacts.first,
              onSave: (name, phone) => _setContact(ref, s, name, phone),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactEditor extends StatefulWidget {
  final EmergencyContact? initial;
  final Future<void> Function(String name, String phone) onSave;
  const _ContactEditor({this.initial, required this.onSave});
  @override
  State<_ContactEditor> createState() => _ContactEditorState();
}

class _ContactEditorState extends State<_ContactEditor> {
  late final _name = TextEditingController(text: widget.initial?.name ?? '');
  late final _phone = TextEditingController(text: widget.initial?.phone ?? '');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          TextField(controller: _name, decoration: const InputDecoration(labelText: '이름', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: '전화번호', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => widget.onSave(_name.text.trim(), _phone.text.trim()),
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/guardian_mode/guardian_editor_screen.dart
git commit -m "feat(guardian): edit enabled apps and emergency contact"
```

---

## Phase 8: Supabase 마이그레이션 (참고)

### Task 8.1: 마이그레이션 SQL 문서화

**Files:**
- Create: `supabase/migrations/20260504000000_init.sql`

- [ ] **Step 1: SQL 작성**

스펙 §5의 SQL을 그대로 파일에 저장. 사용자가 Supabase 대시보드에서 직접 실행하거나 supabase CLI로 적용.

- [ ] **Step 2: Commit**

```bash
git add supabase/migrations/
git commit -m "chore(supabase): add init migration with RLS and tables"
```

---

## Phase 9: 빌드 검증

### Task 9.1: flutter analyze + 빌드

- [ ] **Step 1: analyze**

Run: `flutter analyze`
Expected: 0 errors, warnings only

- [ ] **Step 2: APK 빌드**

Run: `flutter build apk --debug`
Expected: 빌드 성공

- [ ] **Step 3: 테스트 실행**

Run: `flutter test`
Expected: 모든 테스트 PASS

- [ ] **Step 4: Commit (빌드 산출물은 무시)**

빌드 산출물(.android/.gradle/build/)은 .gitignore에 있어야 함.

---

## Self-Review Notes

- 스펙 §6 모든 흐름이 Phase 0–7에 매핑됨.
- 약 알림 미응답 시 보호자 푸시는 후속 (Edge function)으로 명시적으로 제외.
- iOS는 빌드 대상 아님 (Android-only).
- 실제 .wav 파일명 (공백 포함) 사용.
- HARD GATE: 사용자가 "끝까지 진행" 지시했으므로 spec/plan review 게이트 생략하고 바로 실행.
