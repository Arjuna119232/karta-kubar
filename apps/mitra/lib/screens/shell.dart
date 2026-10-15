import 'package:flutter/material.dart';

import 'account_screen.dart';
import 'earnings_screen.dart';
import 'history_screen.dart';
import 'home_screen.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _i = 0;
  static const _pages = [HomeScreen(), HistoryScreen(), EarningsScreen(), AccountScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _i, children: _pages),
      bottomNavigationBar: NavigationBar(
        height: 76,
        selectedIndex: _i,
        onDestinationSelected: (v) => setState(() => _i = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded, size: 30), label: 'Beranda'),
          NavigationDestination(icon: Icon(Icons.history_rounded, size: 30), label: 'Riwayat'),
          NavigationDestination(icon: Icon(Icons.payments_rounded, size: 30), label: 'Penghasilan'),
          NavigationDestination(icon: Icon(Icons.person_rounded, size: 30), label: 'Akun'),
        ],
      ),
    );
  }
}
