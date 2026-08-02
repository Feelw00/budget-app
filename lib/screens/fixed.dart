import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api.dart';
import '../auth.dart';
import '../format.dart';

class FixedScreen extends StatefulWidget {
  const FixedScreen({super.key});
  @override
  State<FixedScreen> createState() => _FixedScreenState();
}

class _FixedScreenState extends State<FixedScreen> {
  ApiClient get _api => context.read<AuthState>().api;
  late Future<Map<String, dynamic>> _f;

  final _label = TextEditingController();
  final _amount = TextEditingController();
  final _day = TextEditingController(text: '1');
  final _category = TextEditingController();
  String _type = 'expense';
  String _method = 'transfer';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _f = _api.fixed();
  }

  void _reload() => setState(() => _f = _api.fixed());

  Future<void> _add() async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _api.addFixed({
        'label': _label.text.trim(),
        'type': _type,
        'amount': _amount.text,
        'day': _day.text,
        'method': _method,
        'category': _category.text.trim(),
      });
      _label.clear();
      _amount.clear();
      _category.clear();
      _reload();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _del(int id) async {
    try {
      await _api.delFixed(id);
      _reload();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _toggle(int id) async {
    try {
      await _api.toggleFixed(id);
      _reload();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  void dispose() {
    _label.dispose();
    _amount.dispose();
    _day.dispose();
    _category.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FutureBuilder<Map<String, dynamic>>(
          future: _f,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
            }
            if (snap.hasError) return Text('불러오기 실패: ${snap.error}', style: const TextStyle(color: expenseColor));
            final d = snap.data!;
            final totals = d['totals'] as Map<String, dynamic>;
            final items = d['items'] as List<dynamic>;
            final net = asInt(totals['income']) - asInt(totals['expense']);
            final incomes = items.where((i) => asStr(i['type']) == 'income').toList();
            final expenses = items.where((i) => asStr(i['type']) == 'expense').toList();
            return Column(children: [
              Row(children: [
                _stat('고정수입', krw(asInt(totals['income'])), incomeColor),
                const SizedBox(width: 10),
                _stat('고정지출', krw(asInt(totals['expense'])), expenseColor),
                const SizedBox(width: 10),
                _stat('순액', krw(net), amountColor(net)),
              ]),
              const SizedBox(height: 8),
              _section('급여 · 고정수입', incomes),
              _section('고정지출', expenses),
            ]);
          },
        ),
        const SizedBox(height: 12),
        _addCard(),
      ],
    );
  }

  Widget _stat(String label, String value, Color color) => Expanded(
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            ]),
          ),
        ),
      );

  Widget _section(String title, List<dynamic> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          if (items.isEmpty)
            const Padding(padding: EdgeInsets.all(8), child: Text('항목이 없습니다.', style: TextStyle(color: Colors.black54)))
          else
            for (final i in items)
              () {
                final active = asInt(i['active']) == 1;
                final type = asStr(i['type']);
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Opacity(opacity: active ? 1 : 0.45, child: Text('${asStr(i['label'])}  (${asInt(i['day'])}일)')),
                  subtitle: Opacity(opacity: active ? 1 : 0.45, child: Text('${methodLabel(asStr(i['method']))} · ${asStr(i['category'])}')),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(signed(type, asInt(i['amount'])),
                        style: TextStyle(color: type == 'income' ? incomeColor : expenseColor, fontWeight: FontWeight.bold)),
                    IconButton(
                      tooltip: active ? '비활성화' : '활성화',
                      icon: Icon(active ? Icons.toggle_on : Icons.toggle_off_outlined, color: active ? incomeColor : Colors.black38),
                      onPressed: () => _toggle(asInt(i['id'])),
                    ),
                    IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _del(asInt(i['id']))),
                  ]),
                );
              }(),
        ]),
      ),
    );
  }

  Widget _addCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('항목 추가', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(controller: _label, decoration: const InputDecoration(labelText: '이름 (예: 월급 / 월세)', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'expense', label: Text('고정지출')),
              ButtonSegment(value: 'income', label: Text('급여·수입')),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: TextField(controller: _amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '금액', border: OutlineInputBorder(), prefixText: '₩ '))),
            const SizedBox(width: 8),
            SizedBox(width: 90, child: TextField(controller: _day, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '결제일', border: OutlineInputBorder()))),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _method,
                decoration: const InputDecoration(labelText: '수단', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'transfer', child: Text('이체')),
                  DropdownMenuItem(value: 'card', child: Text('카드')),
                  DropdownMenuItem(value: 'cash', child: Text('현금')),
                ],
                onChanged: (v) => setState(() => _method = v ?? 'transfer'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: _category, decoration: const InputDecoration(labelText: '카테고리', border: OutlineInputBorder()))),
          ]),
          const SizedBox(height: 12),
          FilledButton(onPressed: _busy ? null : _add, child: const Text('추가')),
        ]),
      ),
    );
  }
}
