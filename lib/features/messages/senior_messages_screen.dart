import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/design_tokens.dart';
import '../../core/supabase.dart';
import '../../services/messages_service.dart';
import 'chat_view.dart';

class SeniorMessagesScreen extends ConsumerStatefulWidget {
  const SeniorMessagesScreen({super.key});

  @override
  ConsumerState<SeniorMessagesScreen> createState() =>
      _SeniorMessagesScreenState();
}

class _SeniorMessagesScreenState extends ConsumerState<SeniorMessagesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _markAsRead());
  }

  Future<void> _markAsRead() async {
    final partnerId = await ref.read(partnerIdProvider.future);
    if (partnerId == null) return;
    await MessagesService.instance.markConversationAsRead(partnerId);
  }

  @override
  Widget build(BuildContext context) {
    final partner = ref.watch(partnerIdProvider);
    final me = ref.watch(currentUserProvider)?.id;
    final nicknameAsync = ref.watch(partnerNicknameProvider);
    final nickname = nicknameAsync.maybeWhen(
      data: (v) => v ?? '가족',
      orElse: () => '가족',
    );
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      nickname,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.notoSansKr(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF1A1A2E),
                        letterSpacing: -0.8,
                        height: 1.0,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/home'),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 80,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '✕ 닫기',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF3E2723),
                          height: 1.0,
                          letterSpacing: -0.6,
                        ),
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
                    bubbleMine: const Color(0xFFFF6B8A),
                    bubbleTheir: const Color(0xFFFFF0F0),
                    textMine: Colors.white,
                    textTheir: const Color(0xFF1A1A2E),
                    sendButton: const Color(0xFFFF2D6F),
                    background: const Color(0x00000000),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
