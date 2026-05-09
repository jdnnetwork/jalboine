import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/message.dart';
import '../../services/messages_service.dart';
import '../../services/subscription_service.dart';
import '../subscription/paywall_dialog.dart';

/// 피보호자/보호자 양쪽에서 재사용하는 채팅 본문 + 입력창.
/// senior=true 면 글씨를 더 크고 따뜻한 톤으로 그린다.
class ChatView extends ConsumerStatefulWidget {
  final String me;
  final String partner;
  final bool senior;
  final Color bubbleMine;
  final Color bubbleTheir;
  final Color textMine;
  final Color textTheir;
  final Color sendButton;
  final Color background;

  const ChatView({
    super.key,
    required this.me,
    required this.partner,
    required this.senior,
    required this.bubbleMine,
    required this.bubbleTheir,
    required this.textMine,
    required this.textTheir,
    required this.sendButton,
    required this.background,
  });

  @override
  ConsumerState<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<ChatView> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _picker = ImagePicker();
  bool _sending = false;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sending) return;
    final text = _input.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await MessagesService.instance
          .sendText(receiverId: widget.partner, text: text);
      _input.clear();
      ref.invalidate(monthlyMessageCountsProvider);
    } on LimitExceeded {
      _toast('이번 달 무료 메시지를 다 사용했어요');
    } catch (e) {
      _toast('$e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendPhoto() async {
    if (_sending) return;
    XFile? picked;
    try {
      picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 80,
      );
    } catch (e) {
      _toast('$e');
      return;
    }
    if (picked == null) return;
    setState(() => _sending = true);
    try {
      await MessagesService.instance
          .sendImage(receiverId: widget.partner, file: File(picked.path));
      ref.invalidate(monthlyMessageCountsProvider);
    } on LimitExceeded {
      _toast('이번 달 무료 사진을 다 사용했어요');
    } catch (e) {
      _toast('$e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  void _scrollToEnd() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncMessages = ref.watch(
      conversationProvider(ConversationKey(widget.me, widget.partner)),
    );
    ref.listen(
      conversationProvider(ConversationKey(widget.me, widget.partner)),
      (_, _) => WidgetsBinding.instance.addPostFrameCallback(
        (_) => _scrollToEnd(),
      ),
    );
    final fontSize = widget.senior ? 20.0 : 15.0;
    final isPremium = ref.watch(subscriptionStatusProvider).maybeWhen(
          data: (v) => v.isPremium,
          orElse: () => false,
        );
    final counts = ref.watch(monthlyMessageCountsProvider).maybeWhen(
          data: (v) => v,
          orElse: () => const MonthlyCounts(text: 0, image: 0),
        );
    final textLimit = MessagesService.monthlyTextLimit;
    final imageLimit = MessagesService.monthlyImageLimit;
    final textOver = !isPremium && counts.text >= textLimit;
    final imageOver = !isPremium && counts.image >= imageLimit;
    return Container(
      color: widget.background,
      child: Column(
        children: [
          _UsageStrip(
            isPremium: isPremium,
            text: counts.text,
            image: counts.image,
            textLimit: textLimit,
            imageLimit: imageLimit,
          ),
          Expanded(
            child: asyncMessages.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (msgs) {
                if (msgs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        widget.senior
                            ? '아직 주고받은\n메시지가 없어요'
                            : '아직 메시지가 없습니다',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: widget.senior ? 22 : 14,
                          fontWeight: FontWeight.w700,
                          color: widget.textTheir.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) => _Bubble(
                    msg: msgs[i],
                    isMine: msgs[i].senderId == widget.me,
                    bgMine: widget.bubbleMine,
                    bgTheir: widget.bubbleTheir,
                    fgMine: widget.textMine,
                    fgTheir: widget.textTheir,
                    fontSize: fontSize,
                  ),
                );
              },
            ),
          ),
          if (textOver || imageOver)
            _LimitBanner(
              textOver: textOver,
              imageOver: imageOver,
              onSubscribe: () => showPaywallDialog(context),
            ),
          _InputBar(
            controller: _input,
            sending: _sending,
            sendColor: widget.sendButton,
            senior: widget.senior,
            textBlocked: textOver,
            imageBlocked: imageOver,
            onSend: _send,
            onPhoto: _sendPhoto,
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final Message msg;
  final bool isMine;
  final Color bgMine;
  final Color bgTheir;
  final Color fgMine;
  final Color fgTheir;
  final double fontSize;
  const _Bubble({
    required this.msg,
    required this.isMine,
    required this.bgMine,
    required this.bgTheir,
    required this.fgMine,
    required this.fgTheir,
    required this.fontSize,
  });

  String _time(DateTime dt) {
    final ampm = dt.hour < 12 ? '오전' : '오후';
    final h = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    return '$ampm $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isMine ? 18 : 4),
      bottomRight: Radius.circular(isMine ? 4 : 18),
    );
    final bg = isMine ? bgMine : bgTheir;
    final fg = isMine ? fgMine : fgTheir;
    final timeStr = _time(msg.createdAt);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isMine)
            Padding(
              padding: const EdgeInsets.only(right: 6, bottom: 2),
              child: Text(
                timeStr,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF9099AC),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              decoration: BoxDecoration(color: bg, borderRadius: radius),
              padding: msg.isImage
                  ? const EdgeInsets.all(4)
                  : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: msg.isImage
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        msg.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox(
                          width: 160,
                          height: 120,
                          child: Center(child: Icon(Icons.broken_image)),
                        ),
                        loadingBuilder: (_, child, p) => p == null
                            ? child
                            : SizedBox(
                                width: 160,
                                height: 120,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: p.expectedTotalBytes == null
                                        ? null
                                        : p.cumulativeBytesLoaded /
                                            p.expectedTotalBytes!,
                                  ),
                                ),
                              ),
                      ),
                    )
                  : Text(
                      msg.content ?? '',
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                        color: fg,
                        height: 1.35,
                      ),
                    ),
            ),
          ),
          if (!isMine)
            Padding(
              padding: const EdgeInsets.only(left: 6, bottom: 2),
              child: Text(
                timeStr,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF9099AC),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final Color sendColor;
  final bool senior;
  final bool textBlocked;
  final bool imageBlocked;
  final VoidCallback onSend;
  final VoidCallback onPhoto;
  const _InputBar({
    required this.controller,
    required this.sending,
    required this.sendColor,
    required this.senior,
    required this.onSend,
    required this.onPhoto,
    this.textBlocked = false,
    this.imageBlocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE6E1D6), width: 1)),
      ),
      padding: EdgeInsets.fromLTRB(
        10,
        10,
        10,
        10 + MediaQuery.of(context).viewInsets.bottom * 0,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: (sending || imageBlocked) ? null : onPhoto,
                child: Container(
                  width: senior ? 56 : 44,
                  height: senior ? 56 : 44,
                  decoration: BoxDecoration(
                    color: imageBlocked
                        ? const Color(0xFFE6E1D6)
                        : const Color(0xFFF2EFE8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.image_rounded,
                    size: senior ? 28 : 22,
                    color: imageBlocked
                        ? const Color(0xFFB0A99B)
                        : const Color(0xFF5C5347),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !sending,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                style: TextStyle(
                  fontSize: senior ? 20 : 15,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: senior ? '메시지를 적어주세요' : '메시지 입력',
                  hintStyle: TextStyle(
                    fontSize: senior ? 18 : 14,
                    color: const Color(0xFF8A8073),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF7F4ED),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: senior ? 16 : 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: (sending || textBlocked)
                  ? const Color(0xFFCBC2B0)
                  : sendColor,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: (sending || textBlocked) ? null : onSend,
                child: Container(
                  width: senior ? 72 : 56,
                  height: senior ? 56 : 44,
                  alignment: Alignment.center,
                  child: Text(
                    '전송',
                    style: TextStyle(
                      fontSize: senior ? 18 : 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UsageStrip extends StatelessWidget {
  final bool isPremium;
  final int text;
  final int image;
  final int textLimit;
  final int imageLimit;
  const _UsageStrip({
    required this.isPremium,
    required this.text,
    required this.image,
    required this.textLimit,
    required this.imageLimit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: const Color(0xFFF7F4ED),
      child: Text(
        isPremium
            ? '안심 프리미엄 — 무제한'
            : '텍스트 $text/$textLimit | 사진 $image/$imageLimit',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: isPremium
              ? const Color(0xFF2F6BFF)
              : const Color(0xFF5C5347),
        ),
      ),
    );
  }
}

class _LimitBanner extends StatelessWidget {
  final bool textOver;
  final bool imageOver;
  final VoidCallback onSubscribe;
  const _LimitBanner({
    required this.textOver,
    required this.imageOver,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    final headline = textOver
        ? '이번 달 무료 메시지를 다 사용했어요'
        : '이번 달 무료 사진을 다 사용했어요';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      color: const Color(0xFFFFF3CC),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            headline,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Color(0xFF7A5C00),
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            '안심 프리미엄 구독하면 무제한으로 보낼 수 있어요',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF7A5C00),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: onSubscribe,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2F6BFF),
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w900),
              ),
              child: const Text('구독하기'),
            ),
          ),
        ],
      ),
    );
  }
}
