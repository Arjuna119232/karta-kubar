import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/session.dart';
import '../../../core/auth/user_role.dart';
import '../../../core/providers.dart';
import '../data/app_tabs.dart';

/// Kerangka utama. Bottom navigation ditentukan oleh role yang sedang aktif.
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Session session = ref.watch(sessionProvider);
    final UserRole role = session.efektif;
    final List<AppTab> tabs = tabsUntuk(role);
    final int index = ref.watch(navigationIndexProvider);

    // Role bisa berubah saat runtime (mis. setelah login). Jaga indeks tetap
    // supaya tidak keluar dari jangkauan tab yang sekarang tampil.
    final int aman = index.clamp(0, tabs.length - 1);

    return Scaffold(
      // IndexedStack menjaga scroll position tiap tab saat berpindah.
      body: IndexedStack(
        index: aman,
        children: <Widget>[for (final AppTab t in tabs) t.screen],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: aman,
        destinations: <Widget>[
          for (final AppTab t in tabs)
            NavigationDestination(
              icon: t.badge == null
                  ? Icon(t.icon)
                  : Badge.count(count: t.badge!, child: Icon(t.icon)),
              selectedIcon: Icon(t.selectedIcon),
              label: t.label,
              tooltip: t.label,
            ),
        ],
        onDestinationSelected: (int i) {
          if (i >= tabs.length) return;
          ref.read(navigationIndexProvider.notifier).state = i;
        },
      ),
    );
  }
}