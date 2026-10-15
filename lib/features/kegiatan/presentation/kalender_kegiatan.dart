import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_id.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_icon.dart';
import '../../../shared/widgets/app_dialogs.dart';
import '../../../core/utils/haptics.dart';
import '../domain/kegiatan.dart';

/// Kalender kegiatan: grid bulan penuh + daftar kegiatan pada tanggal yang
/// dipilih.
///
/// Data diteruskan dari luar (bukan diambil sendiri) supaya layar yang memakai
/// widget ini tetap punya satu sumber data saja - yaitu `kegiatanProvider`.
///
/// Tanggal tanpa kegiatan yang dihitung dari daftar ini, BUKAN kalender
/// jaringan, jadi tetap jalan tanpa internet.
class KalenderKegiatan extends StatefulWidget {
  const KalenderKegiatan({
    super.key,
    required this.kegiatan,
    required this.accent,
  });

  final List<Kegiatan> kegiatan;
  final Color accent;

  @override
  State<KalenderKegiatan> createState() => _KalenderKegiatanState();
}

class _KalenderKegiatanState extends State<KalenderKegiatan> {
  DateTime _bulan = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _dipilih;

  /// Tanggal (tanpa jam) -> daftar kegiatan pada tanggal itu.
  Map<DateTime, List<Kegiatan>> get _perHari {
    final Map<DateTime, List<Kegiatan>> out = <DateTime, List<Kegiatan>>{};
    for (final Kegiatan k in widget.kegiatan) {
      final DateTime? t = k.tanggal;
      if (t == null) continue;
      out.putIfAbsent(DateTime(t.year, t.month, t.day), () => <Kegiatan>[]).add(k);
    }
    return out;
  }

  void _geser(int jumlahBulan) {
    Haptics.light();
    setState(() {
      _bulan = DateTime(_bulan.year, _bulan.month + jumlahBulan);
      _dipilih = null;
    });
  }

  void _keBulanIni() {
    Haptics.light();
    final DateTime n = DateTime.now();
    setState(() {
      _bulan = DateTime(n.year, n.month);
      _dipilih = DateTime(n.year, n.month, n.day);
    });
  }

  @override
  Widget build(BuildContext context) {
    final Map<DateTime, List<Kegiatan>> perHari = _perHari;
    final DateTime? terpilih = _dipilih;
    final List<Kegiatan> hariTerpilih = terpilih == null
        ? const <Kegiatan>[]
        : perHari[terpilih] ?? const <Kegiatan>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            _TombolBulan(
              ikon: Ik.arrowBack,
              tooltip: 'Bulan sebelumnya',
              onTap: () => _geser(-1),
            ),
            Expanded(
              child: Center(
                child: Text(
                  '${DateId.bulanSingkat(_bulan)} ${_bulan.year}',
                  style: context.text.titleMedium,
                ),
              ),
            ),
            _TombolBulan(
              ikon: Ik.arrowForward,
              tooltip: 'Bulan berikutnya',
              onTap: () => _geser(1),
            ),
          ],
        ),
        Center(
          child: TextButton(
            onPressed: _keBulanIni,
            style: TextButton.styleFrom(
              minimumSize: const Size(44, 36),
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('Bulan ini'),
          ),
        ),
        const SizedBox(height: 4),
        _GridBulan(
          bulan: _bulan,
          perHari: perHari,
          accent: widget.accent,
          dipilih: _dipilih,
          onPilih: (DateTime d) {
            Haptics.light();
            setState(() => _dipilih = d);
          },
        ),
        const SizedBox(height: 16),
        if (terpilih == null)
          Text(
            'Pilih tanggal untuk melihat kegiatan pada hari itu.',
            style: context.text.bodySmall
                ?.copyWith(color: context.semantic.textSecondary),
          )
        else ...<Widget>[
          Text(DateId.hariTanggal(terpilih), style: context.text.titleSmall),
          const SizedBox(height: 8),
          if (hariTerpilih.isEmpty)
            Text(
              'Tidak ada kegiatan pada tanggal ini.',
              style: context.text.bodySmall
                  ?.copyWith(color: context.semantic.textSecondary),
            )
          else
            for (final Kegiatan k in hariTerpilih)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.gap),
                child: _BarisKegiatan(kegiatan: k, accent: widget.accent),
              ),
        ],
      ],
    );
  }
}

class _TombolBulan extends StatelessWidget {
  const _TombolBulan({
    required this.ikon,
    required this.tooltip,
    required this.onTap,
  });

  final Ik ikon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: AppIcon(ikon, size: 20),
      tooltip: tooltip,
    );
  }
}

/// Grid 7 kolom: baris nama hari, lalu satu sel per tanggal.
class _GridBulan extends StatelessWidget {
  const _GridBulan({
    required this.bulan,
    required this.perHari,
    required this.accent,
    required this.dipilih,
    required this.onPilih,
  });

  final DateTime bulan;
  final Map<DateTime, List<Kegiatan>> perHari;
  final Color accent;
  final DateTime? dipilih;
  final ValueChanged<DateTime> onPilih;

  static const List<String> _namaHari = <String>[
    'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min',
  ];

  @override
  Widget build(BuildContext context) {
    // `DateTime.weekday` mulai dari 1 untuk Senin, jadi tidak perlu konversi
    // ke indeks gaya DateFormat yang dimulai dari Minggu.
    final int geser = DateTime(bulan.year, bulan.month).weekday - 1;
    final int jumlahHari = DateTime(bulan.year, bulan.month + 1, 0).day;
    final DateTime n = DateTime.now();
    final DateTime hariIni = DateTime(n.year, n.month, n.day);

    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            for (final String h in _namaHari)
              Expanded(
                child: Center(
                  child: Text(
                    h,
                    style: context.text.labelSmall
                        ?.copyWith(color: context.semantic.textSecondary),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
          children: <Widget>[
            for (int i = 0; i < geser; i++) const SizedBox.shrink(),
            for (int d = 1; d <= jumlahHari; d++)
              _SelHari(
                tanggal: DateTime(bulan.year, bulan.month, d),
                jumlah: perHari[DateTime(bulan.year, bulan.month, d)]?.length ?? 0,
                terpilih: dipilih,
                hariIni: hariIni,
                accent: accent,
                onTap: onPilih,
              ),
          ],
        ),
      ],
    );
  }
}

class _SelHari extends StatelessWidget {
  const _SelHari({
    required this.tanggal,
    required this.jumlah,
    required this.terpilih,
    required this.hariIni,
    required this.accent,
    required this.onTap,
  });

  final DateTime tanggal;
  final int jumlah;
  final DateTime? terpilih;
  final DateTime hariIni;
  final Color accent;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final bool iniHariIni = _samaHari(tanggal, hariIni);
    final bool iniTerpilih = terpilih != null && _samaHari(tanggal, terpilih!);

    return GestureDetector(
      onTap: () => onTap(tanggal),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: iniTerpilih ? accent : null,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: iniHariIni && !iniTerpilih
              ? Border.all(color: accent.withValues(alpha: 0.45))
              : null,
        ),
        child: Stack(
          children: <Widget>[
            Center(
              child: Text(
                '${tanggal.day}',
                style: context.text.bodySmall?.copyWith(
                  color: iniTerpilih
                      ? Colors.white
                      : jumlah > 0
                          ? null
                          : context.semantic.textSecondary,
                  fontWeight: jumlah > 0 ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (jumlah > 0)
              Positioned(
                bottom: 4,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: iniTerpilih ? Colors.white : accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static bool _samaHari(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _BarisKegiatan extends StatelessWidget {
  const _BarisKegiatan({required this.kegiatan, required this.accent});

  final Kegiatan kegiatan;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => _buka(context),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.field),
            ),
            child: AppIcon(Ik.calendar, size: 20, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  kegiatan.judul,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  '${kegiatan.kategori} - ${kegiatan.lokasi}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall
                      ?.copyWith(color: context.semantic.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AppIcon(Ik.chevronRight,
              size: 18, color: context.semantic.textSecondary),
        ],
      ),
    );
  }

  void _buka(BuildContext context) {
    Haptics.light();
    AppSheet.show<void>(
      context,
      builder: (BuildContext ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(kegiatan.judul, style: ctx.text.titleLarge),
          const SizedBox(height: 4),
          Text(
            DateId.hariTanggal(kegiatan.tanggal),
            style: ctx.text.bodySmall
                ?.copyWith(color: ctx.semantic.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Kategori: ${kegiatan.kategori}', style: ctx.text.bodyMedium),
          const SizedBox(height: 6),
          Text('Lokasi: ${kegiatan.lokasi}', style: ctx.text.bodyMedium),
          const SizedBox(height: 6),
          Text(
            kegiatan.mendatang ? 'Status: akan datang' : 'Status: sudah selesai',
            style: ctx.text.bodyMedium,
          ),
        ],
      ),
    );
  }
}
