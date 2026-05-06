import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase.dart';

enum SoundMode { sound, vibrate, silent }

extension SoundModeX on SoundMode {
  String get id => switch (this) {
        SoundMode.sound => 'sound',
        SoundMode.vibrate => 'vibrate',
        SoundMode.silent => 'silent',
      };
  String get label => switch (this) {
        SoundMode.sound => '소리',
        SoundMode.vibrate => '진동',
        SoundMode.silent => '무음',
      };
  String get audioAsset => switch (this) {
        SoundMode.sound => 'assets/audio/sound_on.wav',
        SoundMode.vibrate => 'assets/audio/vibrate.wav',
        SoundMode.silent => 'assets/audio/sound_off.wav',
      };
  String get toastLabel => switch (this) {
        SoundMode.sound => '소리 켜짐',
        SoundMode.vibrate => '진동만',
        SoundMode.silent => '소리 꺼짐',
      };
  SoundMode get next => switch (this) {
        SoundMode.sound => SoundMode.vibrate,
        SoundMode.vibrate => SoundMode.silent,
        SoundMode.silent => SoundMode.sound,
      };
}

SoundMode parseSoundMode(String? s) => switch (s) {
      'vibrate' => SoundMode.vibrate,
      'silent' => SoundMode.silent,
      _ => SoundMode.sound,
    };

class SoundModeService {
  SoundModeService._();
  static final instance = SoundModeService._();

  Future<void> apply(SoundMode m) async {
    switch (m) {
      case SoundMode.sound:
      case SoundMode.vibrate:
        await HapticFeedback.lightImpact();
        if (m == SoundMode.sound) {
          await SystemSound.play(SystemSoundType.click);
        }
        break;
      case SoundMode.silent:
        break;
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
