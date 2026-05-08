import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase.dart';

enum SoundMode { sound, vibrate }

extension SoundModeX on SoundMode {
  String get id => switch (this) {
        SoundMode.sound => 'sound',
        SoundMode.vibrate => 'vibrate',
      };
  String get label => switch (this) {
        SoundMode.sound => '소리',
        SoundMode.vibrate => '진동',
      };
  String get audioAsset => switch (this) {
        SoundMode.sound => 'assets/audio/sound_on.wav',
        SoundMode.vibrate => 'assets/audio/vibrate.wav',
      };
  String get toastLabel => switch (this) {
        SoundMode.sound => '소리 켜짐',
        SoundMode.vibrate => '진동만',
      };
  SoundMode get next => switch (this) {
        SoundMode.sound => SoundMode.vibrate,
        SoundMode.vibrate => SoundMode.sound,
      };
}

SoundMode parseSoundMode(String? s) => switch (s) {
      'vibrate' => SoundMode.vibrate,
      _ => SoundMode.sound,
    };

class SoundModeService {
  SoundModeService._();
  static final instance = SoundModeService._();

  static const _channel = MethodChannel('com.jalboine/sound_mode');

  Future<void> apply(SoundMode m) async {
    await HapticFeedback.lightImpact();
    if (m == SoundMode.sound) {
      await SystemSound.play(SystemSoundType.click);
    }
    try {
      await _channel.invokeMethod('setRingerMode', {'mode': m.id});
    } on PlatformException {
      // 권한 없거나 미지원 플랫폼 - 무시
    } on MissingPluginException {
      // iOS/데스크탑 - 무시
    }
  }
}

final soundModeProvider = StateProvider<SoundMode>((ref) => SoundMode.sound);

Future<void> persistSoundMode(WidgetRef ref, SoundMode m) async {
  ref.read(soundModeProvider.notifier).state = m;
  final sb = ref.read(supabaseProvider);
  final uid = sb.auth.currentUser?.id;
  if (uid == null) return;
  await sb
      .from('senior_settings')
      .update({'sound_mode': m.id})
      .eq('user_id', uid);
}
