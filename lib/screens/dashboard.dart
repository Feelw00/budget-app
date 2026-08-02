import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../api.dart';
import '../auth.dart';
import '../format.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<Map<String, dynamic>> _f;
  ApiClient get _api => context.read<AuthState>().api;

  @override
  void initState() {
    super.initState();
    _f = _api.dashboard();
  }

  Future<void> _refresh() async {
    final f = _api.dashboard();
    setState(() => _f = f);
    await f;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _f,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const _Loading();
          }
          if (snap.hasError) {
            return _ErrorView(message: '${snap.error}', onRetry: _refresh);
          }
          final d = snap.data!;
          final chart = d['chart'] as Map<String, dynamic>;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _remainCard(d),
              const SizedBox(height: 12),
              _periodGrid(d),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('올해 월별 수입·지출', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Row(children: const [
                      _Legend(color: incomeColor, label: '수입'),
                      SizedBox(width: 12),
                      _Legend(color: expenseColor, label: '지출'),
                    ]),
                    const SizedBox(height: 12),
                    SizedBox(height: 200, child: _yearChart(chart)),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _remainCard(Map<String, dynamic> d) {
    final remaining = asInt(d['remaining']);
    final over = remaining < 0;
    final month = d['month'] as Map<String, dynamic>;
    final fixed = d['fixed'] as Map<String, dynamic>;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Text('이번 달 남은 비용 (${asStr(d['ym'])})', style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 6),
          Text(krw(remaining),
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: over ? expenseColor : incomeColor)),
          const SizedBox(height: 8),
          Text('총수입 ${krw(asInt(d['totalIncome']))} − 총지출 ${krw(asInt(d['totalExpense']))}',
              style: const TextStyle(color: Colors.black54), textAlign: TextAlign.center),
          Text('이번 달 카드 사용 ${krw(asInt(d['cardMonth']))}',
              style: const TextStyle(color: expenseColor, fontSize: 13), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text('(고정수입 ${krw(asInt(fixed['income']))} + 변동수입 ${krw(asInt(month['income']))}) − (고정지출 ${krw(asInt(fixed['expense']))} + 변동지출 ${krw(asInt(month['expense']))})',
              style: const TextStyle(color: Colors.black38, fontSize: 11), textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  Widget _periodGrid(Map<String, dynamic> d) {
    final items = <(String, Map<String, dynamic>)>[
      ('오늘', d['day'] as Map<String, dynamic>),
      ('이번 주', d['week'] as Map<String, dynamic>),
      ('이번 달', d['month'] as Map<String, dynamic>),
      ('올해', d['year_summary'] as Map<String, dynamic>),
    ];
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth >= 600 ? 4 : 2;
      return GridView.count(
        crossAxisCount: cols,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.6,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        children: [
          for (final it in items)
            () {
              final net = asInt(it.$2['income']) - asInt(it.$2['expense']);
              return Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(it.$1, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(krw(net), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: amountColor(net))),
                    const SizedBox(height: 2),
                    Text('수입 ${krw(asInt(it.$2['income']))}', style: const TextStyle(color: incomeColor, fontSize: 11)),
                    Text('지출 ${krw(asInt(it.$2['expense']))}', style: const TextStyle(color: expenseColor, fontSize: 11)),
                  ]),
                ),
              );
            }(),
        ],
      );
    });
  }

  Widget _yearChart(Map<String, dynamic> chart) {
    final inc = (chart['monthIncome'] as List).map((e) => (e as num).toDouble()).toList();
    final exp = (chart['monthExpense'] as List).map((e) => (e as num).toDouble()).toList();
    return BarChart(
      BarChartData(
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 20,
              getTitlesWidget: (v, meta) => Text('${v.toInt() + 1}', style: const TextStyle(fontSize: 10, color: Colors.black54)),
            ),
          ),
        ),
        barGroups: [
          for (int i = 0; i < 12; i++)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(toY: i < inc.length ? inc[i] : 0, color: incomeColor, width: 4),
              BarChartRodData(toY: i < exp.length ? exp[i] : 0, color: expenseColor, width: 4),
            ]),
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) => ListView(
        children: const [Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))],
      );
}

class _ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _ErrorView({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              Text('불러오기 실패: $message', style: const TextStyle(color: expenseColor)),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
            ]),
          ),
        ],
      );
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 10, height: 10, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ]);
}
