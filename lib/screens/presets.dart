import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api.dart';
import '../auth.dart';
import '../format.dart';

class PresetsScreen extends StatefulWidget {
  const PresetsScreen({super.key});
  @override
  State<PresetsScreen> createState() => _PresetsScreenState();
}

class _PresetsScreenState extends State<PresetsScreen> {
  ApiClient get _api => context.read<AuthState>().api;
  late Future<List<dynamic>> _f;

  final _label = TextEditingController();
  final _amount = TextEditingController();
  String _category = '';
  List<dynamic> _cats = [];
  String _type = 'expense';
  String _method = 'cash';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _f = _api.presets();
    _loadCats();
  }

  void _reload() => setState(() => _f = _api.presets());
  Future<void> _loadCats() async {
    try {
      final c = await _api.categories();
      if (mounted) setState(() => _cats = c);
    } catch (_) {}
  }

  List<String> get _catNames => _cats.map((c) => asStr(c['name'])).toList();

  Future<void> _add() async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _api.addPreset({
        'label': _label.text.trim(),
        'type': _type,
        'amount': _amount.text,
        'category': _category,
        'method': _method,
      });
      _label.clear();
      _amount.clear();
      _category = '';
      _reload();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _del(int id) async {
    try {
      await _api.delPreset(id);
      _reload();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  void dispose() {
    _label.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('프리셋 추가', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextField(controller: _label, decoration: const InputDecoration(labelText: '이름', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              Row(children: [
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
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: TextField(controller: _amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '기본금액', border: OutlineInputBorder(), prefixText: '₩ '))),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
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
              ]),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                key: ValueKey('pc$_category'),
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
              const SizedBox(height: 12),
              FilledButton(onPressed: _busy ? null : _add, child: const Text('추가')),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<dynamic>>(
          future: _f,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
            }
            if (snap.hasError) return Text('불러오기 실패: ${snap.error}', style: const TextStyle(color: expenseColor));
            final list = snap.data!;
            if (list.isEmpty) return const Text('저장된 프리셋이 없습니다.', style: TextStyle(color: Colors.black54));
            return Column(children: [
              for (final p in list)
                Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    title: Text(asStr(p['label'])),
                    subtitle: Text('${typeLabel(asStr(p['type']))} · ${methodLabel(asStr(p['method']))} · ${asStr(p['category'])}'),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(krw(asInt(p['amount']))),
                      IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _del(asInt(p['id']))),
                    ]),
                  ),
                ),
            ]);
          },
        ),
      ],
    );
  }
}
