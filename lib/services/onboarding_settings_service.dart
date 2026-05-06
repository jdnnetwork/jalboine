import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase.dart';

/// 온보딩 음성 재생 ON/OFF (각 화면 wav 자동 재생).
final audioGuideModeProvider = StateProvider<bool>((ref) => false);

/// 홈 화면 카드 더블탭 + 음성 ON/OFF.
final voiceGuideModeProvider = StateProvider<bool>((ref) => false);

class OnboardingSettingsService {
  static Future<void> setAudioGuide(WidgetRef ref, bool value) async {
    ref.read(audioGuideModeProvider.notifier).state = value;
    final sb = ref.read(supabaseProvider);
    final uid = sb.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await sb
          .from('profiles')
          .update({'audio_guide_mode': value}).eq('user_id', uid);
    } catch (_) {}
  }

  static Future<void> setVoiceGuide(WidgetRef ref, bool value) async {
    ref.read(voiceGuideModeProvider.notifier).state = value;
    final sb = ref.read(supabaseProvider);
    final uid = sb.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await sb
          .from('profiles')
          .update({'voice_guide_mode': value}).eq('user_id', uid);
    } catch (_) {}
  }

  /// 앱 시작/홈 화면 진입 시 profiles에서 두 모드 값을 읽어와 provider에 반영.
  static Future<void> loadFromProfiles(WidgetRef ref) async {
    final sb = ref.read(supabaseProvider);
    final uid = sb.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final row = await sb
          .from('profiles')
          .select('audio_guide_mode, voice_guide_mode')
          .eq('user_id', uid)
          .maybeSingle();
      if (row == null) return;
      final audio = row['audio_guide_mode'] as bool?;
      final voice = row['voice_guide_mode'] as bool?;
      if (audio != null) {
        ref.read(audioGuideModeProvider.notifier).state = audio;
      }
      if (voice != null) {
        ref.read(voiceGuideModeProvider.notifier).state = voice;
      }
    } catch (_) {}
  }
}
