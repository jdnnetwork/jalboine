import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/supabase.dart';
import 'question_screen.dart';

class OnboardingQuestion {
  final String key;
  final String audio;
  final String text;
  final String subtitle;
  const OnboardingQuestion(this.key, this.audio, this.text, this.subtitle);
}

const _questions = <OnboardingQuestion>[
  OnboardingQuestion('phone', 'assets/audio/phone.wav',
      '전화를 자주 하시나요?', '바로 거는 버튼을 만들어드릴게요'),
  OnboardingQuestion('kakao', 'assets/audio/kakao.wav',
      '카카오톡을 사용하시나요?', '큰 화면으로 보여드릴게요'),
  OnboardingQuestion('youtube', 'assets/audio/youtube.wav',
      '동영상을 자주 보시나요?', '한 번에 켜드릴게요'),
  OnboardingQuestion('camera', 'assets/audio/camera.wav',
      '사진을 자주 찍으시나요?', '바로 찍기 버튼을 넣어드릴게요'),
  OnboardingQuestion('album', 'assets/audio/album.wav',
      '사진 앨범을 자주 보시나요?', '쉽게 열어드릴게요'),
  OnboardingQuestion('medicine', JConst.audioMedicineQ,
      '약을 드시나요?', '복용 시간을 알려드릴게요'),
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
        context.go('/family');
      }
    }
  }

  Future<void> _persist() async {
    try {
      final sb = ref.read(supabaseProvider);
      final uid = sb.auth.currentUser!.id;
      await sb.from('senior_settings').upsert({
        'user_id': uid,
        'enabled_apps': _enabled,
        'takes_medication': _takesMedication,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_i];
    return QuestionScreen(
      question: q.text,
      subtitle: q.subtitle,
      audioAsset: q.audio,
      step: _i,
      total: _questions.length,
      onAnswer: _answer,
    );
  }
}
