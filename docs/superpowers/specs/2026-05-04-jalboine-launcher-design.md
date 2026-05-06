# 잘보이네 — 고령층 스마트폰 런처 (Flutter + Supabase) 설계

작성일: 2026-05-04
플랫폼: Android (iOS 미지원)
스택: Flutter 3.10.8 / Riverpod / go_router / Supabase

---

## 1. 목적

고령 사용자가 평소 쓰는 앱만 큼직하게 노출하는 런처. 보호자가 원격으로 화면 구성·약 알림·긴급 연락처를 설정한다. 음성 안내, 약 복용 리마인더, 119/112/보호자 단축 다이얼이 핵심.

## 2. 사용자 역할

- **피보호자(senior)**: 런처 모드로 사용. UI는 단순/대형, 모든 설정은 보호자가 관리.
- **보호자(guardian)**: 피보호자의 `senior_settings` 행을 읽고 수정한다. 자기 폰에서 원격 변경하면 피보호자 화면에 실시간 반영.

## 3. 디자인 시스템

`design/잘보이네.html.html`의 SVG 썸네일에서 추출한 팔레트.

| 토큰 | 값 | 용도 |
|---|---|---|
| `surface` | `#F5E6D3` | 화면 배경 (베이지) |
| `surfaceContainer` | `#FAF7F0` | 폰 화면/카드 |
| `onSurface` | `#1A1A1A` | 본문 텍스트 |
| `tilePhone` | `#1B8A3A` | 전화 타일 |
| `tileKakao` | `#FAE100` | 카카오톡 타일 (검정 텍스트) |
| `tileMessage` | `#2BB3F0` | 문자 타일 |
| `tileYoutube` | `#E63946` | 유튜브 타일 |
| `tileCamera` | `#1A1A1A` | 카메라 타일 (흰 텍스트) |
| `tileAlbum` | `#C8102E` | 앨범 타일 |
| `sos` | `#C8102E` | 긴급 전화 바 |

타이포: 한글 sans-serif (Pretendard 또는 시스템 default). 본문 22sp, 버튼 28sp, 제목 32sp, 모든 텍스트 weight 900.
버튼: 최소 높이 88dp, `borderRadius: 24`, 평면 (그림자 없음), 명확한 단색 배경.

## 4. 디렉토리 구조

```
lib/
  main.dart                    # Supabase/알림 초기화, 라우터, 테마
  core/
    theme.dart                 # ColorScheme, TextTheme, 버튼 테마
    router.dart                # go_router (인증 게이트, 역할 분기)
    supabase.dart              # 클라이언트 + authStateProvider
    constants.dart             # 앱 ID 매핑, 음성 파일 경로
  models/
    user_profile.dart
    senior_settings.dart
    medication.dart
    pair_link.dart
    med_log.dart
  services/
    audio_service.dart         # 온보딩 음성 자동 재생
    launcher_service.dart      # 시스템 앱 인텐트 실행
    notification_service.dart  # flutter_local_notifications 래퍼
    realtime_service.dart      # senior_settings 구독
    pin_service.dart           # 보호자 PIN 해시/검증
  features/
    auth/                      # 전화 OTP, Google/Kakao 소셜
    pairing/                   # 초대 코드 생성/입력
    onboarding/                # 7개 질문 + 약 분기
    medication_setup/          # 횟수/시간 선택
    home/                      # 앱 그리드 + SOS 바
    medication_alarm/          # 알림 다이얼로그
    emergency/                 # 119/112/보호자
    guardian_mode/             # PIN → 편집기
```

## 5. Supabase 스키마

```sql
-- 사용자 프로필 (Auth user 연결)
create table profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('senior','guardian')),
  name text,
  phone text,
  created_at timestamptz default now()
);

-- 피보호자 런처 설정 (Realtime 구독 대상)
create table senior_settings (
  user_id uuid primary key references profiles(user_id) on delete cascade,
  enabled_apps jsonb not null default '[]'::jsonb,  -- ["phone","kakao",...]
  takes_medication bool not null default false,
  emergency_contacts jsonb not null default '[]'::jsonb, -- [{name,phone}]
  guardian_pin_hash text,
  updated_at timestamptz default now()
);

-- 약 시간표
create table medications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(user_id) on delete cascade,
  times time[] not null,         -- ['08:00','13:00','19:00']
  times_per_day int not null
);

-- 보호자-피보호자 링크
create table pair_links (
  id uuid primary key default gen_random_uuid(),
  senior_user_id uuid references profiles(user_id),
  guardian_user_id uuid references profiles(user_id),
  status text not null check (status in ('pending','accepted')),
  invite_code text unique,
  created_at timestamptz default now()
);

-- 약 복용 기록
create table med_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(user_id),
  scheduled_at timestamptz not null,
  status text check (status in ('taken','delayed','missed')),
  taken_at timestamptz
);
```

**RLS 정책:**
- 모든 테이블 RLS 활성화.
- 본인 행은 모두 SELECT/UPDATE.
- `pair_links.status='accepted'`인 보호자는 해당 senior 행을 SELECT/UPDATE.

**Realtime:** `senior_settings` 테이블의 `UPDATE` 이벤트를 publication에 추가. 피보호자 앱이 본인 row를 stream subscribe.

## 6. 핵심 흐름

### 6.1 인증 / 페어링

1. 앱 시작 → `auth.currentSession` 확인
2. 미인증 → 로그인 화면
   - 전화번호 → OTP (피보호자 기본 경로)
   - 보호자: 전화 OTP 또는 Google/Kakao OAuth
3. 첫 로그인 → 역할 선택 (피보호자/보호자)
4. 보호자: 페어링 화면 → 초대 코드 입력 또는 피보호자 전화번호 검색
5. 피보호자: 본인 초대 코드 표시 + 페어링 대기. 페어링되면 온보딩으로 진행.

### 6.2 온보딩

질문 화면 (피보호자만):
1. phone.wav — "전화를 자주 하시나요?"
2. message.wav — "문자를 자주 하시나요?"
3. kakao.wav — "카카오톡을 하시나요?"
4. youtube.wav — "동영상 시청을 자주 하시나요?"
5. camera.wav — "사진을 자주 찍으시나요?"
6. album.wav — "사진 앨범을 자주 보시나요?"
7. medicine.wav — "약을 드시나요?"
   - 네 → 약 설정으로 분기
   - 아니요 → 홈으로

각 화면: 큰 "네"/"아니요" 두 버튼만, 화면 진입 시 음성 자동 재생, 하단 7-단계 진행 점.
응답은 `enabled_apps` 배열에 누적, 마지막에 `senior_settings`에 upsert.

### 6.3 약 설정

- "하루에 몇 번 약을 드시나요?" (how many.wav 재생) — 1, 2, 3, 4 큰 버튼
- "몇 시에 약을 드시나요?" (what hour.wav 재생) — 시간(0-23) 큰 숫자 그리드, 횟수만큼 반복
- 저장: `medications` 행 upsert
- `notification_service`로 매일 해당 시각에 로컬 알림 스케줄

### 6.4 메인 홈

- `senior_settings.enabled_apps` Realtime stream으로 빌드
- 앱 개수에 따라 그리드 동적 조정:
  - 1개 → 1×1 풀스크린
  - 2개 → 1×2
  - 3-4개 → 2×2
  - 5-6개 → 2×3
- 각 타일 탭 → `launcher_service`가 시스템 인텐트 실행:
  - phone → `tel:` 다이얼러
  - message → SMS 앱 (`sms:`)
  - kakao → `intent://com.kakao.talk`
  - youtube → `vnd.youtube://` 또는 패키지 인텐트
  - camera → `MediaStore.ACTION_IMAGE_CAPTURE`
  - album → 갤러리 인텐트
- 하단: 풀너비 빨간 SOS 바 ("긴급 전화") → 긴급 전화 화면 push

### 6.5 약 알림

- 스케줄: 앱 시작 시 `notification_service.rescheduleAll()` 호출. `medications` 행을 읽어 매일 반복 알림 등록.
- 알림 발화 시: 풀스크린 인텐트로 앱 열기 → 알림 다이얼로그 화면
- 다이얼로그: 큰 글씨 "약 드실 시간이에요!" + medicine_alarm.wav 자동 재생 + "먹었어요" / "나중에" 두 버튼
  - 먹었어요 → `med_logs` insert (taken)
  - 나중에 → `med_logs` insert (delayed) + 10분 후 재알림 1회 등록
- 재알림에도 응답 없으면 30분 경과 후 `med_logs` insert (missed). 보호자 푸시는 후속 단계 (Edge function).

### 6.6 긴급 전화

3개 풀너비 큰 버튼:
- 119 (소방/구급) — `tel:119`
- 112 (경찰) — `tel:112`
- 보호자 (`emergency_contacts[0].phone`) — `tel:<번호>`

`emergency_contacts`가 비면 보호자 버튼 숨김.

### 6.7 보호자 모드

- 피보호자 폰에서 진입: 홈 화면의 SOS 바 위쪽 빈 영역을 3초간 long-press → PIN 입력 다이얼로그
- PIN 검증: `pin_service.verify(input, senior_settings.guardian_pin_hash)` (SHA-256 + salt)
- 진입 후: 앱 구성 / 약 설정 / 긴급 연락처 / PIN 변경 메뉴
- 모든 변경은 `senior_settings` upsert → Realtime로 피보호자 UI에 즉시 반영

### 6.8 보호자 원격 모드 (보호자 폰에서)

- 보호자가 자기 폰의 보호자 앱에서 페어된 senior 선택
- 동일한 편집기 UI로 `senior_settings` 수정 가능
- Realtime로 피보호자 화면에 즉시 반영

## 7. 의존성 (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
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
  cupertino_icons: ^1.0.8
```

## 8. 안드로이드 권한 (AndroidManifest.xml)

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.CALL_PHONE"/>
<queries>
  <intent><action android:name="android.intent.action.DIAL"/></intent>
  <package android:name="com.kakao.talk"/>
  <package android:name="com.google.android.youtube"/>
</queries>
```

## 9. 음성 자산

`assets/audio/` 폴더 (실제 파일은 `.wav`, 일부 공백 포함):
- phone.wav, message.wav, kakao.wav, youtube.wav, camera.wav, album.wav
- medicine.wav, "how many.wav", "what hour.wav", medicine_alarm.wav

`pubspec.yaml`에서 폴더 단위로 등록:
```yaml
flutter:
  assets:
    - assets/audio/
```

## 10. 범위 (YAGNI)

**1차 범위에 포함**:
- 9개 기능 모두 (인증/페어링/온보딩/홈/약 알림/긴급/보호자 모드/Realtime)
- 보호자 OAuth: Google + Kakao 둘만
- 약 알림 미응답 시 `med_logs` missed 기록까지

**1차 범위 제외 (후속)**:
- iOS 빌드
- 보호자 푸시 송신 (FCM/Edge function)
- 다국어 (한국어 단일)
- 약 외 일정 알림
- 위치 추적

## 11. 테스트 전략

- 모델 직렬화 단위 테스트 (`test/models/`)
- 서비스 모킹: `pin_service`, `audio_service` 단위 테스트
- 위젯 테스트: 온보딩 진행 점, 홈 그리드 동적 레이아웃, 알림 다이얼로그
- Supabase는 통합 테스트에서 실제 인스턴스 사용 (제공된 publishable key로 read-only 검증)

## 12. 알려진 트레이드오프

- **PIN을 클라이언트에서 해시 후 저장**: 진정한 보안엔 부족하나 고령층 보호자 모드 게이트 용도로 충분. 진짜 권한은 Supabase RLS가 막는다.
- **카카오톡/유튜브 등 외부 앱 인텐트**: 패키지 미설치 시 폴백으로 Play 스토어 이동.
- **약 알림 정확도**: Doze 모드 영향. `SCHEDULE_EXACT_ALARM` 권한 사용 + 사용자에게 배터리 최적화 예외 안내.
- **PROMPT 명세와 실제 자산 불일치**: PROMPT는 `.mp3`로 적었지만 실제 파일은 `.wav`. 코드는 실제 파일명에 맞춰 작성.
