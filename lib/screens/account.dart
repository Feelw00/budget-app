import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api.dart';
import '../auth.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  ApiClient get _api => context.read<AuthState>().api;
  final _cur = TextEditingController();
  final _n1 = TextEditingController();
  final _n2 = TextEditingController();
  bool _busy = false;

  Future<void> _submit() async {
    if (_busy) return;
    final messenger = ScaffoldMessenger.of(context);
    if (_n1.text.length < 8) {
      messenger.showSnackBar(const SnackBar(content: Text('새 비밀번호는 8자 이상이어야 합니다.')));
      return;
    }
    if (_n1.text != _n2.text) {
      messenger.showSnackBar(const SnackBar(content: Text('새 비밀번호가 일치하지 않습니다.')));
      return;
    }
    setState(() => _busy = true);
    try {
      await _api.changePassword(_cur.text, _n1.text);
      _cur.clear();
      _n1.clear();
      _n2.clear();
      messenger.showSnackBar(const SnackBar(content: Text('비밀번호가 변경되었습니다.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _cur.dispose();
    _n1.dispose();
    _n2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final username = context.watch<AuthState>().username ?? '';
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(username),
            subtitle: Text('API: $kApiBase', style: const TextStyle(fontSize: 11)),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('비밀번호 변경', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              TextField(controller: _cur, obscureText: true, decoration: const InputDecoration(labelText: '현재 비밀번호', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: _n1, obscureText: true, decoration: const InputDecoration(labelText: '새 비밀번호 (8자 이상)', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: _n2, obscureText: true, decoration: const InputDecoration(labelText: '새 비밀번호 확인', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              FilledButton(onPressed: _busy ? null : _submit, child: const Text('변경')),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => context.read<AuthState>().logout(),
          icon: const Icon(Icons.logout),
          label: const Text('로그아웃'),
        ),
      ],
    );
  }
}
