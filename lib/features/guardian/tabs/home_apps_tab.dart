import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants.dart';
import '../../../core/design_tokens.dart';
import '../../../core/supabase.dart';
import '../../../models/senior_settings.dart';

class HomeAppsTab extends ConsumerStatefulWidget {
  final String seniorId;
  final SeniorSettings s;
  const HomeAppsTab({super.key, required this.seniorId, required this.s});

  @override
  ConsumerState<HomeAppsTab> createState() => _HomeAppsTabState();
}

class _HomeAppsTabState extends ConsumerState<HomeAppsTab> {
  static const _maxOn = 8;
  static const _allKeys = ['phone', 'message', 'kakaotalk', 'youtube', 'camera', 'gallery'];

  /// senior_settings에서 받은 enabled_apps + 빠진 앱들을 뒤에 OFF로 붙인 정렬 리스트
  late List<_Item> _items;

  @override
  void initState() {
    super.initState();
    _items = _buildItems(widget.s.enabledApps);
  }

  @override
  void didUpdateWidget(covariant HomeAppsTab old) {
    super.didUpdateWidget(old);
    if (!_listsEqual(old.s.enabledApps, widget.s.enabledApps)) {
      _items = _buildItems(widget.s.enabledApps);
    }
  }

  bool _listsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  List<_Item> _buildItems(List<String> enabled) {
    final out = <_Item>[];
    for (final k in enabled) {
      if (_allKeys.contains(k)) out.add(_Item(k, true));
    }
    for (final k in _allKeys) {
      if (!enabled.contains(k)) out.add(_Item(k, false));
    }
    return out;
  }

  int get _onCount => _items.where((it) => it.on).length;

  Future<void> _persist() async {
    final enabled = _items.where((it) => it.on).map((it) => it.key).toList();
    final sb = ref.read(supabaseProvider);
    try {
      await sb
          .from('senior_settings')
          .update({'enabled_apps': enabled}).eq('user_id', widget.seniorId);
      await sb
          .from('profiles')
          .update({'selected_apps': enabled}).eq('user_id', widget.seniorId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  void _toggle(int i) {
    final it = _items[i];
    if (!it.on && _onCount >= _maxOn) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('최대 8개까지 가능해요')));
      return;
    }
    setState(() => _items[i] = _Item(it.key, !it.on));
    _persist();
  }

  void _reorder(int oldIdx, int newIdx) {
    setState(() {
      if (newIdx > oldIdx) newIdx -= 1;
      final it = _items.removeAt(oldIdx);
      _items.insert(newIdx, it);
    });
    _persist();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '부모님 홈 화면에 표시할 앱을 선택하세요',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: JD.gInk,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '현재 표시 중: $_onCount개 (최대 $_maxOn개)',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: JD.gInkMute,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ReorderableListView.builder(
              buildDefaultDragHandles: false,
              proxyDecorator: (child, index, animation) => Material(
                color: Colors.transparent,
                child: child,
              ),
              itemCount: _items.length,
              onReorder: _reorder,
              itemBuilder: (_, i) {
                final it = _items[i];
                final meta = JConst.apps[it.key]!;
                return _AppRow(
                  key: ValueKey(it.key),
                  index: i,
                  label: meta.label,
                  icon: meta.icon,
                  color: meta.gradStart,
                  on: it.on,
                  onToggle: () => _toggle(i),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Item {
  final String key;
  final bool on;
  const _Item(this.key, this.on);
}

class _AppRow extends StatelessWidget {
  final int index;
  final String label;
  final IconData icon;
  final Color color;
  final bool on;
  final VoidCallback onToggle;
  const _AppRow({
    super.key,
    required this.index,
    required this.label,
    required this.icon,
    required this.color,
    required this.on,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: JD.gLine, width: 1),
        ),
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child:
                    Icon(Icons.drag_indicator_rounded, color: JD.gInkMute),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: JD.gInk,
                ),
              ),
            ),
            Switch(
              value: on,
              activeThumbColor: JD.gBlue,
              onChanged: (_) => onToggle(),
            ),
          ],
        ),
      ),
    );
  }
}
