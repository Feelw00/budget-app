import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api.dart';
import '../auth.dart';
import '../format.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});
  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  ApiClient get _api => context.read<AuthState>().api;

  String _date = todayStr();
  String _type = 'expense';
  String _method = 'cash';
  final _amount = TextEditingController();
  String _category = '';
  final _memo = TextEditingController();
  bool _busy = false;

  List<dynamic> _presets = [];
  List<dynamic> _recent = [];
  List<dynamic> _cats = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final p = await _api.presets();
      final r = await _api.transactions(limit: 20);
      final c = await _api.categories();
      if (!mounted) return;
      setState(() {
        _presets = p;
        _recent = r;
        _cats = c;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  void _applyPreset(Map<String, dynamic> p) {
    setState(() {
      _type = asStr(p['type']);
      _amount.text = asInt(p['amount']) > 0 ? '${asInt(p['amount'])}' : '';
      _category = asStr(p['category']);
      _method = asStr(p['method']);
    });
  }

  Future<void> _pickDate() async {
    final parts = _date.split('-').map(int.parse).toList();
    final init = DateTime(parts[0], parts[1], parts[2]);
    final picked = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(2000),
      lastDate: DateTime(3000),
    );
    if (picked != null) {
      setState(() => _date =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
    }
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _api.addTx({
        'dt': _date,
        'type': _type,
        'amount': _amount.text,
        'category': _category,
        'method': _method,
        'memo': _memo.text.trim(),
      });
      _amount.clear();
      _memo.clear();
      await _load();
      messenger.showSnackBar(const SnackBar(content: Text('추가되었습니다')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(int id) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        content: const Text('삭제할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('삭제')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _api.delTx(id);
      await _load();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _memo.dispose();
    super.dispose();
  }

  List<String> get _catNames => _cats.map((c) => asStr(c['name'])).toList();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(_date),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'expense', label: Text('지출')),
                        ButtonSegment(value: 'income', label: Text('수입')),
                      ],
                      selected: {_type},
                      onSelectionChanged: (s) => setState(() => _type = s.first),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                TextField(
                  controller: _amount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '금액', border: OutlineInputBorder(), prefixText: '₩ '),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      key: ValueKey('m$_method'),
                      initialValue: _method,
                      decoration: const InputDecoration(labelText: '수단', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'cash', child: Text('현금')),
                        DropdownMenuItem(value: 'card', child: Text('카드')),
                        DropdownMenuItem(value: 'transfer', child: Text('이체')),
                      ],
                      onChanged: (v) => setState(() => _method = v ?? 'cash'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      key: ValueKey('c$_category'),
                      initialValue: _category.isEmpty ? null : _category,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: '카테고리', border: OutlineInputBorder()),
                      items: [
                        const DropdownMenuItem<String>(value: null, child: Text('(선택)')),
                        if (_category.isNotEmpty && !_catNames.contains(_category))
                          DropdownMenuItem<String>(value: _category, child: Text(_category)),
                        for (final n in _catNames) DropdownMenuItem<String>(value: n, child: Text(n)),
                      ],
                      onChanged: (v) => setState(() => _category = v ?? ''),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                TextField(
                  controller: _memo,
                  decoration: const InputDecoration(labelText: '메모', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('추가'),
                ),
              ]),
            ),
          ),
          if (_presets.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('프리셋', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in _presets)
                  ActionChip(
                    label: Text('${asStr(p['label'])}  ${signed(asStr(p['type']), asInt(p['amount']))}'),
                    onPressed: () => _applyPreset(p as Map<String, dynamic>),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          const Text('최근 입력', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          if (_loading)
            const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            Text('불러오기 실패: $_error', style: const TextStyle(color: expenseColor))
          else if (_recent.isEmpty)
            const Text('아직 입력이 없습니다.', style: TextStyle(color: Colors.black54))
          else
            for (final t in _recent) _txTile(t as Map<String, dynamic>),
        ],
      ),
    );
  }

  Widget _txTile(Map<String, dynamic> t) {
    final type = asStr(t['type']);
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        title: Text('${asStr(t['category']).isEmpty ? '(미분류)' : asStr(t['category'])} · ${methodLabel(asStr(t['method']))}'),
        subtitle: Text('${asStr(t['dt'])}${asStr(t['memo']).isEmpty ? '' : ' · ${asStr(t['memo'])}'}'),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(signed(type, asInt(t['amount'])),
              style: TextStyle(color: type == 'income' ? incomeColor : expenseColor, fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: () => _delete(asInt(t['id'])),
          ),
        ]),
      ),
    );
  }
}
