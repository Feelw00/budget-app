import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api.dart';
import '../auth.dart';
import '../format.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});
  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  ApiClient get _api => context.read<AuthState>().api;
  late Future<List<dynamic>> _f;
  final _name = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _f = _api.categories();
  }

  void _reload() => setState(() => _f = _api.categories());

  Future<void> _add() async {
    final name = _name.text.trim();
    if (name.isEmpty || _busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _api.addCategory(name);
      _name.clear();
      _reload();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _del(int id) async {
    try {
      await _api.delCategory(id);
      _reload();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  void dispose() {
    _name.dispose();
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
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: '새 카테고리', border: OutlineInputBorder()),
                  onSubmitted: (_) => _add(),
                ),
              ),
              const SizedBox(width: 8),
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
            if (list.isEmpty) return const Text('카테고리가 없습니다.', style: TextStyle(color: Colors.black54));
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in list)
                      Chip(
                        label: Text(asStr(c['name'])),
                        onDeleted: () => _del(asInt(c['id'])),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
