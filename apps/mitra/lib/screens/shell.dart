import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'account_screen.dart';
import 'chat_list_screen.dart';
import 'pendapatan_screen.dart';
import '../state/app_state.dart';
import 'home_screen.dart';
import 'orders_screen.dart';

/// Kerangka 5 tab. Tab Beranda berisi peta, tab lain halaman biasa.
class Shell extends StatefulWidget {
  const Shell({super.key, this.awal = 0});
  final int awal;

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  late int _i = widget.awal;

  @override
  Widget build(BuildContext context) {
    final belum = context.watch<AppState>().unreadTotal();
    return Scaffold(
      body: IndexedStack(
        index: _i,
        children: const [
          HomeScreen(),
          PendapatanScreen(),
          ChatListScreen(),
          OrdersScreen(),
          AccountScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _i,
        onDestinationSelected: (v) => setState(() => _i = v),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map_rounded),
            label: 'Beranda',
          ),
          const NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            selectedIcon: Icon(Icons.payments_rounded),
            label: 'Pendapatan',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: belum > 0,
              label: Text('$belum'),
              child: const Icon(Icons.chat_bubble_outline_rounded),
            ),
            selectedIcon: Badge(
              isLabelVisible: belum > 0,
              label: Text('$belum'),
              child: const Icon(Icons.chat_bubble_rounded),
            ),
            label: 'Chat',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Order',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
