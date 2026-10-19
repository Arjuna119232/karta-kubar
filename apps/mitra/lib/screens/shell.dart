import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../state/app_state.dart';
import 'account_screen.dart';
import 'chat_list_screen.dart';
import 'home_screen.dart';
import 'pendapatan_screen.dart';

/// Kerangka tab aplikasi. Tab Beranda berisi peta, tab lain halaman biasa.
///
/// Bilah bawah dibuat sendiri (bukan NavigationBar bawaan) supaya bentuknya
/// pil melayang dengan latar kaca — pola yang sama dipakai hampir semua
/// aplikasi driver.
class Shell extends StatefulWidget {
  const Shell({super.key, this.awal = 0});
  final int awal;

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  late int _i = widget.awal;

  void _pindah(int v) {
    if (v == _i) return;
    HapticFeedback.selectionClick();
    setState(() => _i = v);
  }

  @override
  Widget build(BuildContext context) {
    final belum = context.watch<AppState>().unreadTotal();

    return PopScope(
      // Tab selain Beranda: tombol kembali balik ke Beranda dulu.
      canPop: _i == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _i != 0) _pindah(0);
      },
      child: Scaffold(
        body: IndexedStack(
          index: _i,
          children: const [
            HomeScreen(),
            PendapatanScreen(),
            ChatListScreen(),
            AccountScreen(),
          ],
        ),
        bottomNavigationBar: _BilahBawah(
          indeks: _i,
          belumDibaca: belum,
          onPilih: _pindah,
        ),
      ),
    );
  }
}

class _BilahBawah extends StatelessWidget {
  const _BilahBawah({
    required this.indeks,
    required this.belumDibaca,
    required this.onPilih,
  });

  final int indeks;
  final int belumDibaca;
  final ValueChanged<int> onPilih;

  static const _item = <_ItemNav>[
    _ItemNav('Beranda', Icons.map_outlined, Icons.map_rounded),
    _ItemNav('Pendapatan', Icons.account_balance_wallet_outlined,
        Icons.account_balance_wallet_rounded),
    _ItemNav('Chat', Icons.forum_outlined, Icons.forum_rounded),
    _ItemNav('Akun', Icons.person_outline_rounded, Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final p = Palet.of(context);
    return Container(
      decoration: BoxDecoration(
        color: p.kartu,
        border: Border(top: BorderSide(color: p.garis)),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              for (var i = 0; i < _item.length; i++)
                Expanded(
                  child: _TombolNav(
                    item: _item[i],
                    aktif: i == indeks,
                    lencana: i == 2 ? belumDibaca : 0,
                    onTap: () => onPilih(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemNav {
  const _ItemNav(this.label, this.ikon, this.ikonAktif);
  final String label;
  final IconData ikon;
  final IconData ikonAktif;
}

class _TombolNav extends StatelessWidget {
  const _TombolNav({
    required this.item,
    required this.aktif,
    required this.lencana,
    required this.onTap,
  });

  final _ItemNav item;
  final bool aktif;
  final int lencana;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Palet.of(context);
    final warna = aktif ? p.brand : p.teks2;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: aktif ? p.brandSoft : Colors.transparent,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Icon(aktif ? item.ikonAktif : item.ikon, size: 22, color: warna),
              ),
              if (lencana > 0)
                Positioned(
                  right: 6,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    constraints: const BoxConstraints(minWidth: 16),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: p.kartu, width: 1.5),
                    ),
                    child: Text(
                      lencana > 9 ? '9+' : '$lencana',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: aktif ? FontWeight.w800 : FontWeight.w600,
              color: warna,
            ),
          ),
        ],
      ),
    );
  }
}
