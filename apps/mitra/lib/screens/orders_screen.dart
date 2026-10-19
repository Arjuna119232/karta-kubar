import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../models/models.dart' show Order; // 'Lencana' juga ada di kit.dart
import '../state/app_state.dart';
import '../widgets/kit.dart';
import 'order_detail_screen.dart';
import 'widgets.dart';

/// Daftar order: yang masuk (masih bisa diambil), yang sedang berjalan,
/// dan riwayat. Bisa disaring supaya tidak perlu scroll panjang.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  /// 0 = semua, 1 = masuk, 2 = berjalan, 3 = riwayat.
  int _saring = 0;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = Palet.of(context);
    final masuk = s.incoming;
    final aktif = s.active;

    if (masuk.isEmpty && aktif == null && s.history.isEmpty) {
      return Scaffold(
        backgroundColor: p.latar,
        appBar: _bilah(p),
        body: const Kosong(
          ikon: Icons.inbox_rounded,
          judul: 'Belum ada order',
          pesan: 'Tekan AKTIFKAN di Beranda supaya kamu mulai menerima '
              'order di sekitar.',
        ),
      );
    }

    final tampilMasuk = _saring == 0 || _saring == 1;
    final tampilAktif = _saring == 0 || _saring == 2;
    final tampilRiwayat = _saring == 0 || _saring == 3;

    final adaMasuk = tampilMasuk && masuk.isNotEmpty;
    final adaAktif = tampilAktif && aktif != null;
    final adaRiwayat = tampilRiwayat && s.history.isNotEmpty;

    return Scaffold(
      backgroundColor: p.latar,
      appBar: _bilah(p),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
        children: [
          _Ringkas(s: s),
          const SizedBox(height: 16),
          _Saringan(
            nilai: _saring,
            jumlahMasuk: masuk.length,
            adaAktif: aktif != null,
            jumlahRiwayat: s.history.length,
            onPilih: (v) => setState(() => _saring = v),
          ),
          const SizedBox(height: 18),
          if (!adaMasuk && !adaAktif && !adaRiwayat)
            const Kosong(
              ikon: Icons.filter_alt_off_rounded,
              judul: 'Tidak ada di bagian ini',
              pesan: 'Coba pilih "Semua".',
              ringkas: true,
            ),
          if (adaMasuk) ...[
            Bagian(
              judul: 'MASUK (${masuk.length})',
              ikon: Icons.notifications_active_rounded,
              warnaIkon: AppColors.error,
            ),
            for (final o in masuk)
              OrderCard(
                o,
                actions: _aksiMasuk(context, s, o),
              ),
          ],
          if (adaAktif) ...[
            Bagian(
              judul: 'SEDANG BERJALAN',
              ikon: Icons.delivery_dining_rounded,
              warnaIkon: p.brand,
            ),
            OrderCard(
              aktif,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderDetailScreen(order: aktif),
                ),
              ),
            ),
          ],
          if (adaRiwayat) ...[
            Bagian(
              judul: 'RIWAYAT (${s.history.length})',
              ikon: Icons.history_rounded,
              warnaIkon: AppColors.muted,
            ),
            for (final o in s.history.take(30))
              OrderCard(
                o,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderDetailScreen(order: o, readOnly: true),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _aksiMasuk(BuildContext context, AppState s, Order o) {
    final p = Palet.of(context);
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => s.reject(o),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: BorderSide(color: AppColors.error.withValues(alpha: 0.45)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('TOLAK'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: FilledButton(
            onPressed: () async {
              final err = await s.accept(o);
              if (context.mounted && err != null) toast(context, err);
            },
            style: FilledButton.styleFrom(
              backgroundColor: p.brand,
              foregroundColor: AppColors.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('TERIMA'),
          ),
        ),
      ],
    );
  }

  PreferredSizeWidget _bilah(Palet p) => AppBar(
        title: const Text('Order Saya'),
        backgroundColor: p.latar,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      );
}

/// Ringkasan hari ini: penghasilan + jumlah order selesai.
class _Ringkas extends StatelessWidget {
  const _Ringkas({required this.s});
  final AppState s;

  @override
  Widget build(BuildContext context) {
    final p = Palet.of(context);
    return Kaca(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PENGHASILAN HARI INI',
                    style: Teks.label.copyWith(color: p.teks2)),
                const SizedBox(height: 6),
                Text(rp(s.todayEarnings),
                    style: Teks.angka.copyWith(color: p.brand)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Lencana(
            teks: '${s.todayCount} selesai',
            warna: AppColors.success,
            ikon: Icons.check_circle_rounded,
          ),
        ],
      ),
    );
  }
}

/// Baris chip penyaring.
class _Saringan extends StatelessWidget {
  const _Saringan({
    required this.nilai,
    required this.jumlahMasuk,
    required this.adaAktif,
    required this.jumlahRiwayat,
    required this.onPilih,
  });

  final int nilai;
  final int jumlahMasuk;
  final bool adaAktif;
  final int jumlahRiwayat;
  final ValueChanged<int> onPilih;

  @override
  Widget build(BuildContext context) {
    final p = Palet.of(context);
    final chips = <Widget>[
      ChipSaring(
        label: 'Semua',
        aktif: nilai == 0,
        lencana: jumlahMasuk + (adaAktif ? 1 : 0) + jumlahRiwayat,
        onTap: () => onPilih(0),
      ),
      ChipSaring(
        label: 'Masuk',
        ikon: Icons.notifications_active_rounded,
        warna: AppColors.error,
        aktif: nilai == 1,
        lencana: jumlahMasuk,
        onTap: () => onPilih(1),
      ),
      ChipSaring(
        label: 'Berjalan',
        ikon: Icons.delivery_dining_rounded,
        warna: p.brand,
        aktif: nilai == 2,
        lencana: adaAktif ? 1 : 0,
        onTap: () => onPilih(2),
      ),
      ChipSaring(
        label: 'Riwayat',
        ikon: Icons.history_rounded,
        aktif: nilai == 3,
        lencana: jumlahRiwayat,
        onTap: () => onPilih(3),
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < chips.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            chips[i],
          ],
        ],
      ),
    );
  }
}
