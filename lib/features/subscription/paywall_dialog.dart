import 'package:flutter/material.dart';
import '../../core/design_tokens.dart';

/// "안심 프리미엄 구독이 필요해요" 팝업.
/// 결제 미연동 — "구독하기" 는 "준비 중입니다" 토스트.
Future<void> showPaywallDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        '안심 프리미엄 구독이 필요해요',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: JD.gInk,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '모르는 번호 감지, 위치 추적, 긴급 소리 보내기 등 안심 기능을 이용할 수 있어요',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: JD.gInkSoft,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: JD.gBlueSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: JD.gBlue, size: 18),
                SizedBox(width: 8),
                Text(
                  '월 5,900원',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: JD.gBlue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: JD.gInkMute),
          child: const Text(
            '나중에',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context)
              ..clearSnackBars()
              ..showSnackBar(
                  const SnackBar(content: Text('준비 중입니다')));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: JD.gBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            textStyle:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
          ),
          child: const Text('구독하기'),
        ),
      ],
    ),
  );
}
