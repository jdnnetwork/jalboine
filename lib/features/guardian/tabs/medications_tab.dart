import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design_tokens.dart';
import '../../../core/supabase.dart';

class MedicationsTab extends ConsumerStatefulWidget {
  final String seniorId;
  const MedicationsTab({super.key, required this.seniorId});

  @override
  ConsumerState<MedicationsTab> createState() => _MedicationsTabState();
}

class _MedicationsTabState extends ConsumerState<MedicationsTab> {
  Map<String, dynamic>? _med;
  List<Map<String, dynamic>> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final sb = ref.read(supabaseProvider);
      final med = await sb
          .from('medications')
          .select()
          .eq('user_id', widget.seniorId)
          .order('id')
          .limit(1)
          .maybeSingle();
      final since = DateTime.now().subtract(const Duration(days: 7));
      final logs = await sb
          .from('med_logs')
          .select()
          .eq('user_id', widget.seniorId)
          .gte('scheduled_at', since.toIso8601String())
          .order('scheduled_at', ascending: false);
      if (!mounted) return;
      setState(() {
        _med = med;
        _logs = List<Map<String, dynamic>>.from(logs);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('약 정보 삭제'),
        content: const Text('정말 삭제하시겠습니까?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('삭제')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final sb = ref.read(supabaseProvider);
      await sb.from('medications').delete().eq('user_id', widget.seniorId);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _editOrCreate() async {
    final saved = await showDialog<_MedDraft>(
      context: context,
      builder: (_) => _EditDialog(initial: _MedDraft.fromRow(_med)),
    );
    if (saved == null) return;
    try {
      final sb = ref.read(supabaseProvider);
      await sb.from('medications').upsert({
        'user_id': widget.seniorId,
        'frequency': saved.frequency,
        'times_per_day': saved.frequency,
        'times': saved.times.map((t) => '$t:00').toList(),
        'alarm_enabled': saved.alarmEnabled,
      });
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      children: [
        if (_med == null)
          _NewMedCard(onTap: _editOrCreate)
        else
          _MedCard(
            row: _med!,
            onEdit: _editOrCreate,
            onDelete: _delete,
          ),
        const SizedBox(height: 20),
        const Text(
          '최근 7일 복용 기록',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: JD.gInk,
          ),
        ),
        const SizedBox(height: 10),
        if (_logs.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              '기록이 없어요',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: JD.gInkMute),
            ),
          )
        else
          for (final l in _logs) _LogRow(row: l),
      ],
    );
  }
}

class _MedCard extends StatelessWidget {
  final Map<String, dynamic> row;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _MedCard({
    required this.row,
    required this.onEdit,
    required this.onDelete,
  });

  String _fmtTime(String t) {
    final parts = t.split(':');
    final h = int.tryParse(parts.first) ?? 0;
    final m = parts.length > 1 ? parts[1] : '00';
    final ampm = h < 12 ? '오전' : '오후';
    final hh = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$ampm $hh:$m';
  }

  @override
  Widget build(BuildContext context) {
    final freq = (row['frequency'] ?? row['times_per_day'] ?? 0) as int;
    final times = ((row['times'] as List?) ?? [])
        .map((e) => e.toString())
        .toList();
    final alarm = (row['alarm_enabled'] as bool?) ?? true;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: JD.gLine, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: JD.gBlueSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.medication_rounded,
                    color: JD.gBlue, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '하루 $freq번',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: JD.gInk,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      times.map(_fmtTime).join(', '),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: JD.gInkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: alarm ? JD.gBlueSoft : JD.gBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  alarm ? '알림 ON' : '알림 OFF',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: alarm ? JD.gBlue : JD.gInkMute,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onEdit,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: JD.gBlue,
                    side: const BorderSide(color: JD.gBlue),
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('수정하기'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: onDelete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: JD.gPink,
                    side: const BorderSide(color: JD.gPink),
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('삭제하기'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NewMedCard extends StatelessWidget {
  final VoidCallback onTap;
  const _NewMedCard({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: JD.gBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: JD.gLine, width: 1),
      ),
      child: Column(
        children: [
          const Icon(Icons.medication_outlined, size: 36, color: JD.gInkMute),
          const SizedBox(height: 8),
          const Text(
            '등록된 약이 없어요',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: JD.gInkMute),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: JD.gBlue,
              foregroundColor: Colors.white,
              minimumSize: const Size(180, 44),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('새로 설정하기'),
          ),
        ],
      ),
    );
  }
}

class _LogRow extends StatelessWidget {
  final Map<String, dynamic> row;
  const _LogRow({required this.row});
  @override
  Widget build(BuildContext context) {
    final dt = DateTime.tryParse(row['scheduled_at'] as String? ?? '')
        ?.toLocal();
    final status = row['status'] as String?;
    final (color, label) = switch (status) {
      'taken' => (JD.gGreen, '복용'),
      'delayed' => (JD.gOrange, '나중에'),
      'missed' => (JD.gPink, '미복용'),
      _ => (JD.gInkMute, '대기'),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: JD.gLine, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              dt == null
                  ? '${row['scheduled_at']}'
                  : '${dt.month}월 ${dt.day}일 '
                      '${dt.hour.toString().padLeft(2, '0')}:'
                      '${dt.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: JD.gInk),
            ),
          ),
          Text(
            label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color),
          ),
        ],
      ),
    );
  }
}

class _MedDraft {
  int frequency;
  List<String> times; // 'HH:mm'
  bool alarmEnabled;
  _MedDraft({
    required this.frequency,
    required this.times,
    required this.alarmEnabled,
  });

  static _MedDraft fromRow(Map<String, dynamic>? row) {
    if (row == null) {
      return _MedDraft(
        frequency: 1,
        times: ['09:00'],
        alarmEnabled: true,
      );
    }
    final freq = (row['frequency'] ?? row['times_per_day'] ?? 1) as int;
    final raw = ((row['times'] as List?) ?? const [])
        .map((e) => e.toString())
        .toList();
    final times = raw.map((t) {
      final p = t.split(':');
      final h = p.isNotEmpty ? p[0].padLeft(2, '0') : '09';
      final m = p.length > 1 ? p[1].padLeft(2, '0') : '00';
      return '$h:$m';
    }).toList();
    while (times.length < freq) {
      times.add('09:00');
    }
    return _MedDraft(
      frequency: freq.clamp(1, 3),
      times: times.take(freq).toList(),
      alarmEnabled: (row['alarm_enabled'] as bool?) ?? true,
    );
  }
}

class _EditDialog extends StatefulWidget {
  final _MedDraft initial;
  const _EditDialog({required this.initial});
  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  late _MedDraft d;

  @override
  void initState() {
    super.initState();
    d = _MedDraft(
      frequency: widget.initial.frequency,
      times: List<String>.from(widget.initial.times),
      alarmEnabled: widget.initial.alarmEnabled,
    );
  }

  void _setFrequency(int f) {
    setState(() {
      d.frequency = f;
      while (d.times.length < f) {
        d.times.add('09:00');
      }
      d.times = d.times.take(f).toList();
    });
  }

  Future<void> _pickTime(int idx) async {
    final cur = d.times[idx].split(':');
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse(cur[0]) ?? 9,
        minute: int.tryParse(cur[1]) ?? 0,
      ),
    );
    if (t == null) return;
    final s =
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    setState(() => d.times[idx] = s);
  }

  String _slotLabel(int i) {
    if (d.frequency == 1) return '시간';
    if (d.frequency == 2) return i == 0 ? '아침' : '저녁';
    return ['아침', '점심', '저녁'][i];
  }

  String _fmt(String t) {
    final p = t.split(':');
    final h = int.tryParse(p[0]) ?? 0;
    final m = p[1];
    final ampm = h < 12 ? '오전' : '오후';
    final hh = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$ampm $hh:$m';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('약 정보'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('하루 복용 횟수',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: JD.gInkMute)),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final f in [1, 2, 3])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: OutlinedButton(
                        onPressed: () => _setFrequency(f),
                        style: OutlinedButton.styleFrom(
                          backgroundColor:
                              d.frequency == f ? JD.gBlueSoft : Colors.white,
                          side: BorderSide(
                              color: d.frequency == f ? JD.gBlue : JD.gLine),
                          foregroundColor:
                              d.frequency == f ? JD.gBlue : JD.gInkSoft,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text('$f번'),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            for (var i = 0; i < d.frequency; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 56,
                      child: Text(_slotLabel(i),
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: JD.gInkSoft)),
                    ),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pickTime(i),
                        style: OutlinedButton.styleFrom(
                          alignment: Alignment.centerLeft,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          minimumSize: const Size.fromHeight(44),
                          side: const BorderSide(color: JD.gLine),
                          foregroundColor: JD.gInk,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(_fmt(d.times[i])),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Text('알림',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: JD.gInkSoft)),
                const Spacer(),
                Switch(
                  value: d.alarmEnabled,
                  activeThumbColor: JD.gBlue,
                  onChanged: (v) => setState(() => d.alarmEnabled = v),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소')),
        TextButton(
            onPressed: () => Navigator.pop(context, d),
            child: const Text('저장')),
      ],
    );
  }
}
