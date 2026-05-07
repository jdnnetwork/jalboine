import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design_tokens.dart';
import '../../../core/supabase.dart';

class InfoTab extends ConsumerStatefulWidget {
  final String seniorId;
  final VoidCallback onLogout;
  const InfoTab({super.key, required this.seniorId, required this.onLogout});

  @override
  ConsumerState<InfoTab> createState() => _InfoTabState();
}

class _InfoTabState extends ConsumerState<InfoTab> {
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final sb = ref.read(supabaseProvider);
      final row = await sb
          .from('profiles')
          .select(
              'name, age_group, font_size_level, audio_guide_mode, user_id')
          .eq('user_id', widget.seniorId)
          .maybeSingle();
      if (!mounted) return;
      setState(() {
        _profile = row;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  String _fontSizeLabel(int? lv) => switch (lv) {
        1 => '보통',
        2 => '크게',
        3 => '아주 크게',
        _ => '-',
      };

  String _shortId(String id) {
    if (id.length <= 8) return id;
    return id.substring(0, 8).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final p = _profile ?? const <String, dynamic>{};
    final uid = (p['user_id'] as String?) ?? widget.seniorId;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      children: [
        const _SectionTitle('부모님 정보'),
        const SizedBox(height: 8),
        _Card(
          rows: [
            _Row(label: '이름', value: (p['name'] as String?) ?? '-'),
            _Row(label: '연령대', value: (p['age_group'] as String?) ?? '-'),
            _Row(
                label: '글자 크기',
                value: _fontSizeLabel(p['font_size_level'] as int?)),
            _Row(
                label: '음성 안내 모드',
                value:
                    (p['audio_guide_mode'] as bool?) == true ? '켜짐' : '꺼짐'),
            _Row(
              label: '고객식별번호',
              value: _shortId(uid),
              copyable: true,
            ),
          ],
        ),
        const SizedBox(height: 18),
        const _SectionTitle('연결 상태'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: JD.gLine, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    color: JD.gGreen, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              const Text(
                '연결됨',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: JD.gInk,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: widget.onLogout,
          style: OutlinedButton.styleFrom(
            foregroundColor: JD.gPink,
            side: const BorderSide(color: JD.gPink),
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            textStyle:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          child: const Text('로그아웃'),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: JD.gInkMute,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final List<_Row> rows;
  const _Card({required this.rows});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: JD.gLine, width: 1),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: JD.gLine),
            rows[i],
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool copyable;
  const _Row({
    required this.label,
    required this.value,
    this.copyable = false,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: JD.gInkMute,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: JD.gInk,
              ),
            ),
          ),
          if (copyable)
            IconButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('복사되었습니다')));
              },
              icon: const Icon(Icons.copy_rounded,
                  size: 18, color: JD.gInkMute),
            ),
        ],
      ),
    );
  }
}
