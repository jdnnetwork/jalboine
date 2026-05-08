import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design_tokens.dart';
import '../../../core/supabase.dart';
import '../../messages/chat_view.dart';

class MessagesTab extends ConsumerWidget {
  final String seniorId;
  const MessagesTab({super.key, required this.seniorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider)?.id;
    if (me == null) {
      return const Center(child: Text('로그인이 필요합니다'));
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ChatView(
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
    );
  }
}
