import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api.dart';
import '../auth.dart';
import '../format.dart';

String _pad2(int n) => n.toString().padLeft(2, '0');

class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key});
  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  ApiClient get _api => context.read<AuthState>().api;

  String _mode = 'month'; // week | month | year
  DateTime _anchor = DateTime.now();
  late Future<Map<String, dynamic>> _f;

  @override
  void initState() {
    super.initState();
    _f = _fetch();
  }

  String get _ym => '${_anchor.year.toString().padLeft(4, '0')}-${_pad2(_anchor.month)}';
  String get _date =>
      '${_anchor.year.toString().padLeft(4, '0')}-${_pad2(_anchor.month)}-${_pad2(_anchor.day)}';

  Future<Map<String, dynamic>> _fetch() {
    switch (_mode) {
      case 'week':
        return _api.week(_date);
      case 'year':
        return _api.year(_anchor.year);
      default:
        return _api.month(_ym);
    }
  }

  void _reload() => setState(() => _f = _fetch());

  void _setMode(String m) {
    setState(() {
      _mode = m;
      _anchor = DateTime.now();
      _f = _fetch();
    });
  }

  void _shift(int dir) {
    setState(() {
      if (_mode == 'week') {
        _anchor = _anchor.add(Duration(days: 7 * dir));
      } else if (_mode == 'year') {
        _anchor = DateTime(_anchor.year + dir, _anchor.month, 1);
      } else {
        _anchor = DateTime(_anchor.year, _anchor.month + dir, 1);
      }
      _f = _fetch();
    });
  }

  String get _periodLabel {
    switch (_mode) {
      case 'week':
        return _date;
      case 'year':
        return '${_anchor.year}년';
      default:
        return _ym;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'week', label: Text('주간')),
            ButtonSegment(value: 'month', label: Text('월간')),
            ButtonSegment(value: 'year', label: Text('연간')),
          ],
          selected: {_mode},
          onSelectionChanged: (s) => _setMode(s.first),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          IconButton(onPressed: () => _shift(-1), icon: const Icon(Icons.chevron_left)),
          Text(_periodLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          IconButton(onPressed: () => _shift(1), icon: const Icon(Icons.chevron_right)),
        ]),
      ),
      Expanded(
        child: RefreshIndicator(
          onRefresh: () async {
            final f = _fetch();
            setState(() => _f = f);
            await f;
          },
          child: FutureBuilder<Map<String, dynamic>>(
            future: _f,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return ListView(children: const [Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))]);
              }
              if (snap.hasError) {
                return ListView(children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(children: [
                      Text('불러오기 실패: ${snap.error}', style: const TextStyle(color: expenseColor)),
                      const SizedBox(height: 12),
                      OutlinedButton(onPressed: _reload, child: const Text('다시 시도')),
                    ]),
                  ),
                ]);
              }
              final d = snap.data!;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _summary(d),
                  const SizedBox(height: 12),
                  if (_mode == 'year') _yearBody(d) else if (_mode == 'month') _monthBody(d) else _weekBody(d),
                ],
              );
            },
          ),
        ),
      ),
    ]);
  }

  Widget _summary(Map<String, dynamic> d) {
    final income = asInt(d['income']);
    final expense = asInt(d['expense']);
    final net = income - expense;
    return Row(children: [
      _stat('수입', krw(income), incomeColor),
      const SizedBox(width: 10),
      _stat('지출', krw(expense), expenseColor),
      const SizedBox(width: 10),
      _stat('순액', krw(net), amountColor(net)),
    ]);
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

  Widget _categoryBars(List<dynamic> cats) {
    if (cats.isEmpty) return const Text('지출이 없습니다.', style: TextStyle(color: Colors.black54));
    final maxV = cats.map((c) => asInt(c['s'])).fold<int>(0, (a, b) => a > b ? a : b);
    return Column(children: [
      for (final c in cats)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(asStr(c['category'])),
              Text(krw(asInt(c['s'])), style: const TextStyle(color: expenseColor)),
            ]),
            const SizedBox(height: 3),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: maxV > 0 ? asInt(c['s']) / maxV : 0,
                minHeight: 8,
                backgroundColor: const Color(0xFFEDEFF2),
                valueColor: const AlwaysStoppedAnimation(expenseColor),
              ),
            ),
          ]),
        ),
    ]);
  }

  Widget _txList(List<dynamic> items) {
    if (items.isEmpty) return const Text('거래가 없습니다.', style: TextStyle(color: Colors.black54));
    return Column(children: [
      for (final t in items)
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text('${asStr(t['dt'])} · ${asStr(t['category']).isEmpty ? '(미분류)' : asStr(t['category'])}'),
          subtitle: Text('${methodLabel(asStr(t['method']))}${asStr(t['memo']).isEmpty ? '' : ' · ${asStr(t['memo'])}'}'),
          trailing: Text(signed(asStr(t['type']), asInt(t['amount'])),
              style: TextStyle(color: asStr(t['type']) == 'income' ? incomeColor : expenseColor, fontWeight: FontWeight.bold)),
        ),
    ]);
  }

  Widget _monthBody(Map<String, dynamic> d) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('카드 사용 ${krw(asInt(d['cardMonth']))}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
      const SizedBox(height: 12),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('카테고리별 지출', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _categoryBars(d['categories'] as List<dynamic>),
      ]))),
      const SizedBox(height: 12),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('거래 내역', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        _txList(d['items'] as List<dynamic>),
      ]))),
    ]);
  }

  Widget _weekBody(Map<String, dynamic> d) {
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('거래 내역', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 4),
      _txList(d['items'] as List<dynamic>),
    ])));
  }

  Widget _yearBody(Map<String, dynamic> d) {
    final months = d['months'] as List<dynamic>;
    return Column(children: [
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('월별', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        for (final m in months)
          () {
            final inc = asInt(m['income']);
            final exp = asInt(m['expense']);
            final net = inc - exp;
            final has = inc != 0 || exp != 0;
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text('${asInt(m['m'])}월'),
              trailing: Text(has ? krw(net) : '—', style: TextStyle(color: has ? amountColor(net) : Colors.black38, fontWeight: FontWeight.bold)),
              subtitle: has ? Text('수입 ${krw(inc)} · 지출 ${krw(exp)}', style: const TextStyle(fontSize: 11)) : null,
            );
          }(),
      ]))),
      const SizedBox(height: 12),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('카테고리별 지출 (연간)', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _categoryBars(d['categories'] as List<dynamic>),
      ]))),
    ]);
  }
}
