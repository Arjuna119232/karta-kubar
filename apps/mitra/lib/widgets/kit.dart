import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Kartu kaca untuk layer atas peta. Blur dipakai, TAPI teks selalu ikut
/// diletakkan di atas panel solid (bukan di dalam area blur) supaya tidak
/// pernah buram di HP Android.
class Kaca extends StatelessWidget {
  const Kaca({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = AppRadius.card,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = Palet.of(context);
    final isi = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: (p.gelap ? const Color(0xFF101014) : Colors.white)
                .withValues(alpha: p.gelap ? 0.66 : 0.86),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
            boxShadow: const [
              BoxShadow(color: Color(0x22000000), blurRadius: 18, offset: Offset(0, 6)),
            ],
          ),
          child: child,
        ),
      ),
    );
    if (onTap == null) return isi;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: isi,
    );
  }
}

/// Tombol gradien besar (AKTIFKAN / NONAKTIFKAN).
class TombolGradien extends StatefulWidget {
  const TombolGradien({
    super.key,
    required this.judul,
    required this.gradien,
    required this.onTekan,
    this.denyut = false,
    this.subjudul,
    this.ikon,
    this.menyala = true,
  });

  final String judul;
  final String? subjudul;
  final Gradient gradien;
  final VoidCallback onTekan;

  /// true = denyut pelan saat status aktif (menarik mata tanpa mengganggu).
  final bool denyut;
  final IconData? ikon;

  /// false = tombol sedang bekerja (teks diganti indikator).
  final bool menyala;

  @override
  State<TombolGradien> createState() => _TombolGradienState();
}

class _TombolGradienState extends State<TombolGradien>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  @override
  void initState() {
    super.initState();
    if (widget.denyut) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant TombolGradien old) {
    super.didUpdateWidget(old);
    if (widget.denyut && !_c.isAnimating) {
      _c.repeat(reverse: true);
    } else if (!widget.denyut && _c.isAnimating) {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: widget.gradien,
            borderRadius: BorderRadius.circular(AppRadius.button),
            boxShadow: [
              BoxShadow(
                color: widget.gradien.colors.first.withValues(alpha: 0.28 + 0.18 * t),
                blurRadius: 18 + 12 * t,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.menyala ? widget.onTekan : null,
              borderRadius: BorderRadius.circular(AppRadius.button),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 68),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!widget.menyala)
                      const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        ),
                      )
                    else if (widget.ikon != null) ...[
                      Icon(widget.ikon, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                    ],
                    Flexible(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.judul,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                          if (widget.subjudul != null)
                            Text(
                              widget.subjudul!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 12.5,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Kotak aksi cepat: ikon berwarna + label.
class KotakAksi extends StatelessWidget {
  const KotakAksi({
    super.key,
    required this.ikon,
    required this.warna,
    required this.judul,
    required this.onTekan,
    this.lencana,
    this.subjudul,
  });

  final IconData ikon;
  final Color warna;
  final String judul;
  final String? subjudul;
  final int? lencana;
  final VoidCallback onTekan;

  @override
  Widget build(BuildContext context) {
    final p = Palet.of(context);
    return Material(
      color: p.kartu,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onTekan,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: p.lembut(warna),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(ikon, color: warna, size: 24),
                  ),
                  if ((lencana ?? 0) > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('${lencana!}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(judul,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              if (subjudul != null)
                Text(subjudul!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kartu datar bergaris — bahan dasar hampir semua bagian layar.
class Kartu extends StatelessWidget {
  const Kartu({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.onTap,
    this.warna,
    this.garis,
    this.radius = AppRadius.card,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? warna;
  final Color? garis;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final p = Palet.of(context);
    return Container(
      decoration: BoxDecoration(
        color: warna ?? p.kartu,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: garis ?? p.garis),
        boxShadow: p.bayangan,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Judul bagian dengan aksi opsional di kanan ("Lihat semua").
class Bagian extends StatelessWidget {
  const Bagian({
    super.key,
    required this.judul,
    this.aksiLabel,
    this.onAksi,
    this.ikon,
    this.warnaIkon,
    this.padTop = AppSpacing.section,
  });

  final String judul;
  final String? aksiLabel;
  final VoidCallback? onAksi;
  final IconData? ikon;
  final Color? warnaIkon;
  final double padTop;

  @override
  Widget build(BuildContext context) {
    final p = Palet.of(context);
    return Padding(
      padding: EdgeInsets.only(top: padTop, bottom: AppSpacing.xs),
      child: Row(
        children: [
          if (ikon != null) ...[
            Icon(ikon, size: 18, color: warnaIkon ?? p.brand),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              judul,
              style: Teks.tebal.copyWith(
                color: p.teks,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (aksiLabel != null)
            InkWell(
              onTap: onAksi,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  children: [
                    Text(aksiLabel!,
                        style: Teks.tebal.copyWith(color: p.brand)),
                    const SizedBox(width: 2),
                    Icon(Icons.chevron_right, size: 16, color: p.brand),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Kotak statistik: ikon lembut + angka besar + label.
class StatKotak extends StatelessWidget {
  const StatKotak({
    super.key,
    required this.ikon,
    required this.warna,
    required this.nilai,
    required this.label,
    this.catatan,
    this.onTap,
  });

  final IconData ikon;
  final Color warna;
  final String nilai;
  final String label;
  final String? catatan;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = Palet.of(context);
    return Kartu(
      onTap: onTap,
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: p.lembut(warna),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(ikon, size: 18, color: warna),
          ),
          const SizedBox(height: 10),
          Text(
            nilai,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Teks.judul.copyWith(color: p.teks, fontSize: 20),
          ),
          const SizedBox(height: 2),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Teks.ket.copyWith(color: p.teks2, fontSize: 12.5)),
          if (catatan != null)
            Text(catatan!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Teks.ket.copyWith(color: p.brand, fontSize: 11.5)),
        ],
      ),
    );
  }
}

/// Baris menu: ikon berwarna, judul, keterangan, chevron.
class BarisMenu extends StatelessWidget {
  const BarisMenu({
    super.key,
    required this.ikon,
    required this.judul,
    required this.onTap,
    this.warna,
    this.keterangan,
    this.jejak,
    this.bahaya = false,
    this.garisAtas = true,
  });

  final IconData ikon;
  final String judul;
  final String? keterangan;
  final Widget? jejak;
  final Color? warna;
  final VoidCallback onTap;
  final bool bahaya;
  final bool garisAtas;

  @override
  Widget build(BuildContext context) {
    final p = Palet.of(context);
    final w = warna ?? p.brand;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            border: garisAtas
                ? Border(top: BorderSide(color: p.garis))
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: p.lembut(bahaya ? AppColors.error : w),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(ikon,
                    size: 20, color: bahaya ? AppColors.error : w),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(judul,
                        style: Teks.isi.copyWith(
                          color: bahaya ? AppColors.error : p.teks,
                          fontWeight: FontWeight.w600,
                        )),
                    if (keterangan != null)
                      Text(keterangan!,
                          style: Teks.ket.copyWith(color: p.teks2, fontSize: 12.5)),
                  ],
                ),
              ),
              if (jejak != null) ...[jejak!, const SizedBox(width: 6)],
              Icon(Icons.chevron_right,
                  size: 20, color: p.teks2.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chip pilihan (filter, kategori, periode).
class ChipSaring extends StatelessWidget {
  const ChipSaring({
    super.key,
    required this.label,
    required this.aktif,
    required this.onTap,
    this.ikon,
    this.warna,
    this.lencana,
  });

  final String label;
  final bool aktif;
  final VoidCallback onTap;
  final IconData? ikon;
  final Color? warna;
  final int? lencana;

  @override
  Widget build(BuildContext context) {
    final p = Palet.of(context);
    final w = warna ?? p.brand;
    final depan = aktif ? Colors.white : p.teks2;
    return Material(
      color: aktif ? w : p.kartuAlt,
      borderRadius: BorderRadius.circular(AppRadius.chip),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (ikon != null) ...[
                Icon(ikon, size: 15, color: depan),
                const SizedBox(width: 6),
              ],
              Text(label,
                  style: Teks.tebal.copyWith(
                    color: aktif ? Colors.white : p.teks,
                  )),
              if ((lencana ?? 0) > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: aktif
                        ? Colors.white.withValues(alpha: 0.26)
                        : p.lembut(w),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text('$lencana',
                      style: Teks.label.copyWith(
                        color: aktif ? Colors.white : w,
                        fontSize: 10.5,
                      )),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Lencana kecil (status, kategori, level).
class Lencana extends StatelessWidget {
  const Lencana({
    super.key,
    required this.teks,
    required this.warna,
    this.ikon,
    this.padat = false,
  });

  final String teks;
  final Color warna;
  final IconData? ikon;
  final bool padat;

  @override
  Widget build(BuildContext context) {
    final p = Palet.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: padat ? warna : p.lembut(warna, 0.14),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (ikon != null) ...[
            Icon(ikon, size: 12, color: padat ? Colors.white : warna),
            const SizedBox(width: 4),
          ],
          Text(
            teks,
            style: Teks.label.copyWith(
              color: padat ? Colors.white : warna,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// Deretan bintang penilaian.
class Bintang extends StatelessWidget {
  const Bintang({super.key, required this.nilai, this.ukuran = 14});

  final double nilai;
  final double ukuran;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final penuh = nilai >= i + 0.75;
        final separuh = !penuh && nilai >= i + 0.25;
        return Icon(
          penuh
              ? Icons.star_rounded
              : (separuh ? Icons.star_half_rounded : Icons.star_outline_rounded),
          size: ukuran,
          color: AppColors.gold,
        );
      }),
    );
  }
}

/// Keadaan kosong: ikon lembut + judul + penjelasan (+ tombol opsional).
class Kosong extends StatelessWidget {
  const Kosong({
    super.key,
    required this.ikon,
    required this.judul,
    this.pesan,
    this.aksiLabel,
    this.onAksi,
    this.warna,
    this.ringkas = false,
  });

  final IconData ikon;
  final String judul;
  final String? pesan;
  final String? aksiLabel;
  final VoidCallback? onAksi;
  final Color? warna;
  final bool ringkas;

  @override
  Widget build(BuildContext context) {
    final p = Palet.of(context);
    final w = warna ?? p.brand;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 32,
          vertical: ringkas ? 22 : 48,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: ringkas ? 60 : 76,
              height: ringkas ? 60 : 76,
              decoration: BoxDecoration(
                color: p.lembut(w),
                shape: BoxShape.circle,
              ),
              child: Icon(ikon, size: ringkas ? 28 : 34, color: w),
            ),
            const SizedBox(height: 14),
            Text(judul,
                textAlign: TextAlign.center,
                style: Teks.judul.copyWith(color: p.teks, fontSize: 17)),
            if (pesan != null) ...[
              const SizedBox(height: 6),
              Text(pesan!,
                  textAlign: TextAlign.center,
                  style: Teks.ket.copyWith(color: p.teks2)),
            ],
            if (aksiLabel != null) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onAksi,
                style: FilledButton.styleFrom(
                  backgroundColor: p.brand,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(160, 46),
                ),
                child: Text(aksiLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Judul halaman di layar non-tab: breadcrumb kecil + judul + aksi.
class KepalaHalaman extends StatelessWidget {
  const KepalaHalaman({
    super.key,
    required this.judul,
    this.keterangan,
    this.aksi,
    this.padTop = 8,
  });

  final String judul;
  final String? keterangan;
  final Widget? aksi;
  final double padTop;

  @override
  Widget build(BuildContext context) {
    final p = Palet.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.md, padTop, AppSpacing.md, AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(judul, style: Teks.halaman.copyWith(color: p.teks)),
                if (keterangan != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(keterangan!,
                        style: Teks.ket.copyWith(color: p.teks2)),
                  ),
              ],
            ),
          ),
          if (aksi != null) aksi!,
        ],
      ),
    );
  }
}
