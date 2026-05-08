import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import '../../core/design_tokens.dart';

/// 마크다운 약관 뷰어. asset 경로와 표시할 제목을 extra 로 전달.
class TermsViewerScreen extends StatefulWidget {
  final String assetPath;
  final String title;
  const TermsViewerScreen({
    super.key,
    required this.assetPath,
    required this.title,
  });

  @override
  State<TermsViewerScreen> createState() => _TermsViewerScreenState();
}

class _TermsViewerScreenState extends State<TermsViewerScreen> {
  String? _content;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final s = await rootBundle.loadString(widget.assetPath);
      if (!mounted) return;
      setState(() => _content = s);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    icon: const Icon(Icons.close_rounded),
                  ),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: JD.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFEEE9DC)),
            Expanded(
              child: _content == null && _error == null
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text('약관을 불러오지 못했습니다\n$_error'))
                      : Markdown(
                          data: _content!,
                          padding: const EdgeInsets.all(20),
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(
                              fontSize: 16,
                              height: 1.55,
                              color: JD.ink,
                            ),
                            h1: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: JD.ink,
                              height: 1.3,
                            ),
                            h2: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: JD.ink,
                            ),
                            listBullet: const TextStyle(
                              fontSize: 16,
                              color: JD.ink,
                            ),
                          ),
                        ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: ElevatedButton(
                  onPressed: () => context.pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: JD.ink,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    textStyle: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w900),
                  ),
                  child: const Text('닫기'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
