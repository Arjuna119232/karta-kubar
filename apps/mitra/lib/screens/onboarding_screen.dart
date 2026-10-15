import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';

/// 3 slide cara pakai. Tampil sekali setelah akun dibuat / pertama kali masuk.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _i = 0;

  static const _slide = [
    (
      Icons.two_wheeler_rounded,
      '1. Nyalakan ONLINE',
      'Tekan tombol besar di beranda. Selama ONLINE, ada notifikasi yang tidak '
          'bisa dihapus - itu tandamu sedang menerima order.',
    ),
    (
      Icons.notifications_active_outlined,
      '2. Terima order dalam 30 detik',
      'Order masuk berbunyi sampai kamu Terima atau Tolak. Kalau tidak dibalas '
          'selama 30 detik, ordernya otomatis hilang.',
    ),
    (
      Icons.map_outlined,
      '3. Kerjakan sampai Selesai',
      'Buka order -> Lihat Peta -> Ikuti tahap: jemput, antar, selesai. '
          'Penghasilan langsung masuk.',
    ),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                itemCount: _slide.length,
                onPageChanged: (v) => setState(() => _i = v),
                itemBuilder: (_, i) {
                  final (ikon, judul, isi) = _slide[i];
                  return Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(ikon,
                            size: 96,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(height: 28),
                        Text(judul,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 26, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 12),
                        Text(isi,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 17)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var k = 0; k < _slide.length; k++)
                  Container(
                    width: k == _i ? 22 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: k == _i
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: FilledButton(
                onPressed: () async {
                  if (_i < _slide.length - 1) {
                    _ctrl.nextPage(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic);
                  } else {
                    await s.tandaiOnboardingDitinjau();
                  }
                },
                child: Text(_i < _slide.length - 1 ? 'LANJUT' : 'MULAI JALAN'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}