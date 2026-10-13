import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../galeri/presentation/galeri_screen.dart';
import '../../home/presentation/home_screen.dart';
import '../../keuangan/presentation/keuangan_screen.dart';
import '../../kegiatan/presentation/kegiatan_screen.dart';
import '../../profile/presentation/profile_screen.dart';

/// Kerangka utama: 5 tab dengan IndexedStack (state tiap tab terjaga).
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  static const List<Widget> _tabs = <Widget>[
    HomeScreen(),
    KegiatanScreen(),
    KeuanganScreen(),
    GaleriScreen(),
    ProfileScreen(),
  ];

  static const List<NavigationDestination> _destinations =
      <NavigationDestination>[
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: 'Beranda',
    ),
    NavigationDestination(
      icon: Icon(Icons.event_outlined),
      selectedIcon: Icon(Icons.event_rounded),
      label: 'Kegiatan',
    ),
    NavigationDestination(
      icon: Icon(Icons.account_balance_wallet_outlined),
      selectedIcon: Icon(Icons.account_balance_wallet_rounded),
      label: 'Keuangan',
    ),
    NavigationDestination(
      icon: Icon(Icons.photo_library_outlined),
      selectedIcon: Icon(Icons.photo_library_rounded),
      label: 'Galeri',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline_rounded),
      selectedIcon: Icon(Icons.person_rounded),
      label: 'Profil',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int index = ref.watch(navigationIndexProvider);

    return Scaffold(
      body: IndexedStack(index: index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        destinations: _destinations,
        onDestinationSelected: (int i) =>
            ref.read(navigationIndexProvider.notifier).state = i,
      ),
    );
  }
}
