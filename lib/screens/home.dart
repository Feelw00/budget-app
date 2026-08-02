import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth.dart';
import 'dashboard.dart';
import 'input.dart';
import 'detail.dart';
import 'presets.dart';
import 'fixed.dart';
import 'holdings.dart';
import 'categories.dart';
import 'account.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _i = 0;

  static const _dests = <(IconData, String)>[
    (Icons.dashboard_outlined, '대시보드'),
    (Icons.add_circle_outline, '입력'),
    (Icons.list_alt, '상세'),
    (Icons.bolt_outlined, '프리셋'),
    (Icons.repeat, '고정·급여'),
    (Icons.account_balance_wallet_outlined, '소지금'),
    (Icons.label_outline, '카테고리'),
    (Icons.settings_outlined, '설정'),
  ];

  Widget _page(int i) {
    switch (i) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const InputScreen();
      case 2:
        return const DetailScreen();
      case 3:
        return const PresetsScreen();
      case 4:
        return const FixedScreen();
      case 5:
        return const HoldingsScreen();
      case 6:
        return const CategoriesScreen();
      default:
        return const AccountScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 800;
    return Scaffold(
      appBar: AppBar(
        title: Text(_dests[_i].$2),
        actions: [
          IconButton(
            tooltip: '로그아웃',
            onPressed: () => context.read<AuthState>().logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      drawer: wide
          ? null
          : Drawer(
              child: SafeArea(
                child: ListView(
                  children: [
                    for (int k = 0; k < _dests.length; k++)
                      ListTile(
                        leading: Icon(_dests[k].$1),
                        title: Text(_dests[k].$2),
                        selected: _i == k,
                        onTap: () {
                          setState(() => _i = k);
                          Navigator.pop(context);
                        },
                      ),
                  ],
                ),
              ),
            ),
      body: Row(
        children: [
          if (wide) ...[
            NavigationRail(
              selectedIndex: _i,
              onDestinationSelected: (v) => setState(() => _i = v),
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final d in _dests)
                  NavigationRailDestination(icon: Icon(d.$1), label: Text(d.$2)),
              ],
            ),
            const VerticalDivider(width: 1),
          ],
          Expanded(child: _page(_i)),
        ],
      ),
    );
  }
}
