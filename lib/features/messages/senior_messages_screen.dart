import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design_tokens.dart';
import '../../core/supabase.dart';
import '../../core/theme.dart';
import '../../services/messages_service.dart';
import '../../widgets/back_pill.dart';
import 'chat_view.dart';

class SeniorMessagesScreen extends ConsumerWidget {
  const SeniorMessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partner = ref.watch(partnerIdProvider);
    final me = ref.watch(currentUserProvider)?.id;
    return Scaffold(
      body: SeniorBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    BackPill(onTap: () => context.go('/home')),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        '가족에게 보내기',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: JD.ink,
                          letterSpacing: -0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: partner.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('$e')),
                  data: (pid) {
                    if (pid == null || me == null) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            '가족 연결이 필요해요',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: JD.inkSoft,
                            ),
                          ),
                        ),
                      );
                    }
                    return ChatView(
                      me: me,
                      partner: pid,
                      senior: true,
                      bubbleMine: JD.cPinkBg,
                      bubbleTheir: Colors.white,
                      textMine: JD.ink,
                      textTheir: JD.ink,
                      sendButton: JD.cPink,
                      background: const Color(0x00000000),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

