import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api.dart';
import '../auth.dart';
import '../format.dart';

class HoldingsScreen extends StatefulWidget {
  const HoldingsScreen({super.key});
  @override
  State<HoldingsScreen> createState() => _HoldingsScreenState();
}

class _HoldingsScreenState extends State<HoldingsScreen> {
  ApiClient get _api => context.read<AuthState>().api;
  late Future<Map<String, dynamic>> _f;
  String _type = 'account';
  final _label = TextEditingController();
  final _amount = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _f = _api.holdings();
  }

  void _reload() => setState(() => _f = _api.holdings());

  Future<void> _add() async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _api.addHolding({'type': _type, 'label': _label.text.trim(), 'amount': _amount.text});
      _label.clear();
      _amount.clear();
      _reload();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _del(int id) async {
    try {
      await _api.delHolding(id);
      _reload();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _edit(Map<String, dynamic> h) async {
    final ctrl = TextEditingController(text: '${asInt(h['amount'])}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('${holdingLabel(asStr(h['type']))} · ${asStr(h['label'])}'),
        content: TextField(controller: ctrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '금액', prefixText: '₩ ')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('저장')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _api.updateHolding(asInt(h['id']), ctrl.text);
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
        FutureBuilder<Map<String, dynamic>>(
          future: _f,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
            }
            if (snap.hasError) return Text('불러오기 실패: ${snap.error}', style: const TextStyle(color: expenseColor));
            final d = snap.data!;
            final items = d['items'] as List<dynamic>;
            final byType = (d['byType'] as Map).cast<String, dynamic>();
            return Column(children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('총 소지금', style: TextStyle(color: Colors.black54)),
                    Text(krw(asInt(d['total'])), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Wrap(spacing: 8, runSpacing: 4, children: [
                      for (final t in holdingTypes)
                        if (byType[t] != null)
                          Text('${holdingLabel(t)} ${krw(asInt(byType[t]))}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    ]),
                  ]),
                ),
              ),
              if (items.isEmpty)
                const Padding(padding: EdgeInsets.all(16), child: Text('등록된 소지금이 없습니다.', style: TextStyle(color: Colors.black54)))
              else
                for (final h in items)
                  Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      title: Text('${holdingLabel(asStr(h['type']))} · ${asStr(h['label'])}'),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        TextButton(onPressed: () => _edit(h as Map<String, dynamic>), child: Text(krw(asInt(h['amount'])))),
                        IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _del(asInt(h['id']))),
                      ]),
                    ),
                  ),
            ]);
          },
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('소지금 추가', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _type,
                    decoration: const InputDecoration(labelText: '유형', border: OutlineInputBorder()),
                    items: [for (final t in holdingTypes) DropdownMenuItem(value: t, child: Text(holdingLabel(t)))],
                    onChanged: (v) => setState(() => _type = v ?? 'account'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _label, decoration: const InputDecoration(labelText: '이름', border: OutlineInputBorder()))),
              ]),
              const SizedBox(height: 10),
              TextField(controller: _amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '금액', border: OutlineInputBorder(), prefixText: '₩ ')),
              const SizedBox(height: 12),
              FilledButton(onPressed: _busy ? null : _add, child: const Text('추가')),
            ]),
          ),
        ),
      ],
    );
  }
}
