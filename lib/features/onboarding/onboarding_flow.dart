import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/supabase.dart';
import '../../services/audio_service.dart';
import '../../services/onboarding_settings_service.dart';
import 'question_screen.dart';

class OnboardingQuestion {
  final String key;
  final String text;
  final String subtitle;
  final String audio;
  const OnboardingQuestion(this.key, this.text, this.subtitle, this.audio);
}

const _questions = <OnboardingQuestion>[
  OnboardingQuestion('phone', '전화를 쉽게 하고 싶으신가요?',
      '바로 거는 버튼을 만들어드릴게요', 'assets/audio/phone_q.wav'),
  OnboardingQuestion('message', '문자를 쉽게 보내고 싶으신가요?',
      '큰 글씨로 보여드릴게요', 'assets/audio/message_q.wav'),
  OnboardingQuestion('kakaotalk', '카카오톡을 쉽게 하고 싶으신가요?',
      '바로 켜드릴게요', 'assets/audio/kakao_q.wav'),
  OnboardingQuestion('youtube', '동영상 시청을 자주 하시나요?',
      '한 번에 켜드릴게요', 'assets/audio/youtube_q.wav'),
  OnboardingQuestion('camera', '사진을 쉽게 찍고 싶으신가요?',
      '바로 찍기 버튼을 넣어드릴게요', 'assets/audio/camera_q.wav'),
  OnboardingQuestion('gallery', '찍은 사진을 쉽게 보고 싶으신가요?',
      '쉽게 열어드릴게요', 'assets/audio/gallery_q.wav'),
];

class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  int _i = 0;
  final List<String> _enabled = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybePlay();
    });
  }

  void _maybePlay() {
    if (ref.read(audioGuideModeProvider)) {
      AudioService.instance.play(_questions[_i].audio);
    }
  }

  Future<void> _answer(bool yes) async {
    final q = _questions[_i];
    if (yes) {
      _enabled.add(q.key);
    }
    if (_i < _questions.length - 1) {
      setState(() => _i++);
      _maybePlay();
    } else {
      await _persist();
      if (!mounted) return;
      context.go('/med/has');
    }
  }

  Future<void> _persist() async {
    try {
      final sb = ref.read(supabaseProvider);
      final uid = sb.auth.currentUser!.id;
      await sb.from('senior_settings').upsert({
        'user_id': uid,
        'enabled_apps': _enabled,
      });
      await sb
          .from('profiles')
          .update({'selected_apps': _enabled}).eq('user_id', uid);
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
