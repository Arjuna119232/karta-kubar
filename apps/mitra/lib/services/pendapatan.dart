import '../models/models.dart';
import '../state/app_state.dart';

/// Periode rekap pendapatan.
enum Periode { hari, minggu, bulan }

extension PeriodeX on Periode {
  String get label => switch (this) {
        Periode.hari => 'Hari Ini',
        Periode.minggu => 'Minggu Ini',
        Periode.bulan => 'Bulan Ini',
      };

  String get pendek => switch (this) {
        Periode.hari => 'Hari',
        Periode.minggu => 'Minggu',
        Periode.bulan => 'Bulan',
      };
}

/// Filter baris riwayat.
enum FilterTransaksi { semua, jastip, ojek, tarik }

extension FilterTransaksiX on FilterTransaksi {
  String get label => switch (this) {
        FilterTransaksi.semua => 'Semua',
        FilterTransaksi.jastip => 'Jastip',
        FilterTransaksi.ojek => 'Ojek',
        FilterTransaksi.tarik => 'Tarik',
      };
}

class BarisTransaksi {
  const BarisTransaksi({
    required this.judul,
    required this.keterangan,
    required this.nominal,
    required this.waktu,
    required this.ikon,
    required this.warna,
    this.order,
    this.sWithdraw,
  });

  final String judul;
  final String keterangan;
  final int nominal;
  final DateTime waktu;
  final int ikon;
  final int warna;

  /// Terisi kalau baris ini berasal dari order (bukan penarikan saldo).
  final Order? order;

  /// Terisi kalau baris ini penarikan saldo.
  final Withdraw? sWithdraw;

  bool get masuk => nominal >= 0;
}

/// Satu titik di grafik batang.
class TitikGrafik {
  const TitikGrafik(this.label, this.nilai, this.jumlahOrder);
  final String label;
  final int nilai;
  final int jumlahOrder;
}

/// Semua angka berasal dari order yang benar-benar selesai.
class RekapPendapatan {
  RekapPendapatan({
    required this.periode,
    required this.total,
    required this.jumlahOrder,
    required this.jastip,
    required this.jastipOrder,
    required this.ojek,
    required this.ojekOrder,
    required this.grafik,
    required this.riwayat,
  });

  final Periode periode;
  final int total;
  final int jumlahOrder;
  final int jastip;
  final int jastipOrder;
  final int ojek;
  final int ojekOrder;
  final List<TitikGrafik> grafik;
  final List<BarisTransaksi> riwayat;

  int get rataRata => jumlahOrder == 0 ? 0 : total ~/ jumlahOrder;

  double get porsiJastip => total == 0 ? 0 : jastip / total;
  double get porsiOjek => total == 0 ? 0 : ojek / total;

  factory RekapPendapatan.hitung(AppState s, Periode p, FilterTransaksi f) {
    final now = DateTime.now();
    final mulai = switch (p) {
      Periode.hari => DateTime(now.year, now.month, now.day),
      Periode.minggu => s.weekStart,
      Periode.bulan => s.monthStart,
    };
    final selesai = s.doneSince(mulai);

    var total = 0, jastip = 0, ojek = 0, jOrder = 0, oOrder = 0;
    final riwayat = <BarisTransaksi>[];
    for (final o in selesai) {
      total += o.fee;
      if (o.type == 'jastip') {
        jastip += o.fee;
        jOrder++;
      } else {
        ojek += o.fee;
        oOrder++;
      }
      if (f == FilterTransaksi.jastip && o.type != 'jastip') continue;
      if (f == FilterTransaksi.ojek && o.type != 'ojek') continue;
      riwayat.add(BarisTransaksi(
        judul: o.customerName.isEmpty ? 'Order ${o.typeLabel}' : o.customerName,
        keterangan: '${o.typeLabel} - ${o.statusLabel}',
        nominal: o.fee,
        waktu: o.doneAt.toLocal(),
        ikon: o.type == 'jastip' ? 0xe59c : 0xe0d4,
        warna: o.type == 'jastip' ? 0xFF1B5E20 : 0xFF1565C0,
        order: o,
      ));
    }

    // Permintaan tarik saldo pada periode ini ikut masuk riwayat.
    for (final w in s.withdrawals) {
      if (w.createdAt.isBefore(mulai)) continue;
      if (f != FilterTransaksi.semua && f != FilterTransaksi.tarik) continue;
      riwayat.add(BarisTransaksi(
        judul: 'Tarik saldo',
        keterangan: '${w.metode} - ${w.tujuan}',
        nominal: -w.jumlah,
        waktu: w.createdAt,
        ikon: 0xe0b9,
        warna: 0xFF6A1B9A,
        sWithdraw: w,
      ));
    }

    riwayat.sort((a, b) => b.waktu.compareTo(a.waktu));

    return RekapPendapatan(
      periode: p,
      total: total,
      jumlahOrder: selesai.length,
      jastip: jastip,
      jastipOrder: jOrder,
      ojek: ojek,
      ojekOrder: oOrder,
      grafik: _grafik(s, mulai, p),
      riwayat: riwayat,
    );
  }

  /// Grafik batang 7 hari terakhir (untuk hari) atau per-bagian minggu/bulan.
  static List<TitikGrafik> _grafik(AppState s, DateTime mulai, Periode p) {
    final now = DateTime.now();
    int perHari(DateTime d, Order o) {
      final t = o.doneAt.toLocal();
      return d.year == t.year && d.month == t.month && d.day == t.day ? o.fee : 0;
    }

    switch (p) {
      case Periode.hari:
      case Periode.minggu:
        return [
          for (var i = 6; i >= 0; i--)
            () {
              final d = now.subtract(Duration(days: i));
              final nilai = s.history
                  .where((o) => o.isDone)
                  .where((o) => perHari(d, o) > 0)
                  .fold<int>(0, (a, o) => a + perHari(d, o));
              final jml = s.history
                  .where((o) => o.isDone)
                  .where((o) => perHari(d, o) > 0)
                  .length;
              return TitikGrafik(_namaHariPendek(d.weekday), nilai, jml);
            }(),
        ];
      case Periode.bulan:
        // 4 minggu terakhir dalam bulan berjalan.
        return [
          for (var i = 3; i >= 0; i--)
            () {
              final akhir = DateTime(now.year, now.month + 1, 1)
                  .subtract(Duration(days: 7 * i));
              final awal = akhir.subtract(const Duration(days: 7));
              final dalam = s.history
                  .where((o) => o.isDone && o.doneAt.toLocal().isAfter(awal) &&
                      o.doneAt.toLocal().isBefore(akhir))
                  .toList();
              return TitikGrafik('M${akhir.month}', dalam.fold(0, (a, o) => a + o.fee),
                  dalam.length);
            }(),
        ];
    }
  }

  static String _namaHariPendek(int w) =>
      const ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'][w - 1];
}