import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/supabase.dart';
import '../../services/push_service.dart';

const _ink = Color(0xFF1A1A2E);
const _accentPink = Color(0xFFFF6B8A);
const _yesStart = Color(0xFFFF2D6F);
const _yesEnd = Color(0xFFFF5A8A);
const _noBg = Color(0xFFF0F0F0);
const _noFg = Color(0xFF2D2D2D);
const _cardBg = Color(0xFFFFF0F0);
const _cardInk = Color(0xFF3E2723);
const _subText = Color(0xFF555555);

/// 어르신이 가족 연결 요청에 동의/거부하는 화면.
///
/// 진입 경로:
///  - FCM 푸시 탭 (route: '/family/consent?pair=...')
///  - 홈 화면 진입/resume 시 pending 요청 자동 감지
class FamilyConsentScreen extends ConsumerStatefulWidget {
  final String pairId;
  const FamilyConsentScreen({super.key, required this.pairId});

  @override
  ConsumerState<FamilyConsentScreen> createState() =>
      _FamilyConsentScreenState();
}

class _FamilyConsentScreenState extends ConsumerState<FamilyConsentScreen> {
  bool _busy = false;

  Future<void> _onYes() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final sb = ref.read(supabaseProvider);
      final user = sb.auth.currentUser;
      if (user == null) {
        throw StateError('세션이 만료됐어요. 다시 시작해주세요');
      }
      final row = await sb
          .from('pair_links')
          .update({'status': 'confirmed'})
          .eq('id', widget.pairId)
          .select('guardian_user_id')
          .single();
      final guardianId = row['guardian_user_id'] as String?;
      await sb.from('profiles').update({
        'consent_family': true,
        'consent_date': DateTime.now().toUtc().toIso8601String(),
      }).eq('user_id', user.id);
      if (guardianId != null) {
        await PushService.instance.sendTo(
          userId: guardianId,
          title: '연결이 완료되었어요!',
          body: '이제 어르신과 메시지를 주고받을 수 있어요',
          data: {'route': '/guardian/dashboard'},
        );
      }
      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      setState(() => _busy = false);
    }
  }

  Future<void> _onNo() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final sb = ref.read(supabaseProvider);
      final row = await sb
          .from('pair_links')
          .update({'status': 'rejected'})
          .eq('id', widget.pairId)
          .select('guardian_user_id')
          .single();
      final guardianId = row['guardian_user_id'] as String?;
      if (guardianId != null) {
        await PushService.instance.sendTo(
          userId: guardianId,
          title: '연결이 거부되었어요',
          body: '어르신이 연결 요청을 거부하셨어요',
          data: {'route': '/guardian/dashboard'},
        );
      }
      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 시스템 백버튼으로 동의/거부 결정을 건너뛸 수 없게 한다.
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                const _MascotWithBubble(),
                const SizedBox(height: 16),
                Text(
                  '연결하면 가족이\n이런 걸 도와줄 수 있어요',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: _subText,
                    height: 1.4,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 20),
                const _ConsentItem(text: '메시지 보내기'),
                const SizedBox(height: 12),
                const _ConsentItem(text: '홈 화면 관리'),
                const SizedBox(height: 12),
                const _ConsentItem(text: '긴급 연락처 설정'),
                const SizedBox(height: 12),
                const _ConsentItem(text: '폰 미사용 시 알려주기'),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      flex: 55,
                      child: _YesButton(onTap: _busy ? null : _onYes),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 40,
                      child: _NoButton(onTap: _busy ? null : _onNo),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConsentItem extends StatelessWidget {
  final String text;
  const _ConsentItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accentPink, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: _accentPink, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.notoSansKr(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: _cardInk,
                letterSpacing: -0.5,
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _YesButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _YesButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_yesStart, _yesEnd],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _yesStart.withValues(alpha: 0.35),
              offset: const Offset(0, 8),
              blurRadius: 18,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          '좋아요',
          style: GoogleFonts.notoSansKr(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -1.0,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

class _NoButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _NoButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: _noBg,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          '아니요',
          style: GoogleFonts.notoSansKr(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: _noFg,
            letterSpacing: -1.0,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

class _MascotWithBubble extends StatelessWidget {
  const _MascotWithBubble();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 84),
          child: _BubbleWithTail(
            child: Text(
              '가족이 연결을\n요청했어요',
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansKr(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: _ink,
                height: 1.25,
                letterSpacing: -1.2,
              ),
            ),
          ),
        ),
        Image.asset(
          'assets/images/mascot.png',
          width: 120,
          fit: BoxFit.contain,
        ),
      ],
    );
  }
}

class _BubbleWithTail extends StatelessWidget {
  final Widget child;
  const _BubbleWithTail({required this.child});

  static const double _tailH = 18;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _BubblePainter(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, _tailH + 24, 20, 24),
        child: child,
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  const _BubblePainter();

  @override
  void paint(Canvas canvas, Size size) {
    const r = 20.0;
    const tailW = 36.0;
    const tailH = _BubbleWithTail._tailH;
    final cx = size.width / 2;
    final w = size.width;
    final h = size.height;

    final path = Path()
      ..moveTo(r, tailH)
      ..lineTo(cx - tailW / 2, tailH)
      ..lineTo(cx, 0)
      ..lineTo(cx + tailW / 2, tailH)
      ..lineTo(w - r, tailH)
      ..arcToPoint(Offset(w, tailH + r), radius: const Radius.circular(r))
      ..lineTo(w, h - r)
      ..arcToPoint(Offset(w - r, h), radius: const Radius.circular(r))
      ..lineTo(r, h)
      ..arcToPoint(Offset(0, h - r), radius: const Radius.circular(r))
      ..lineTo(0, tailH + r)
      ..arcToPoint(Offset(r, tailH), radius: const Radius.circular(r))
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = _accentPink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _BubblePainter oldDelegate) => false;
}
