import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design_tokens.dart';
import '../../core/supabase.dart';
import '../../core/theme.dart';
import '../messages/chat_view.dart';

class GuardianMessagesScreen extends ConsumerWidget {
  final String seniorId;
  const GuardianMessagesScreen({super.key, required this.seniorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider)?.id;
    return Theme(
      data: JTheme.guardian(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: JD.gInk),
                    ),
                    const Text(
                      '메시지',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: JD.gInk,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: me == null
                    ? const Center(child: Text('로그인이 필요합니다'))
                    : ChatView(
                        me: me,
                        partner: seniorId,
                        senior: false,
                        bubbleMine: JD.gBlue,
                        bubbleTheir: const Color(0xFFF2F4F8),
                        textMine: Colors.white,
                        textTheir: JD.gInk,
                        sendButton: JD.gBlue,
                        background: Colors.white,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
