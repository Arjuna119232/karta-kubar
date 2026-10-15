import 'package:any_map/any_map.dart';
import 'package:any_map_maplibre/any_map_maplibre.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../shared/models/order.dart';
import '../../../shared/models/order_ringkas.dart';
import '../../../shared/services/tarif_service.dart';
import '../../../shared/services/tracking_service.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_icon.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/section_header.dart';

/// Style OpenFreeMap yang dipakai seluruh aplikasi.
///
/// CATATAN: `https://openfreemap.org/style.json` (yang sering muncul di
/// tutorial) mengembalikan 404. Yang benar ada di host `tiles`:
/// `https://tiles.openfreemap.org/styles/liberty`.
const String gayaPetaGratis = 'https://tiles.openfreemap.org/styles/liberty';

/// Peta gratis KUNBAR: MapLibre + OpenFreeMap, tanpa API key.
///
/// Satu widget untuk semua kebutuhan peta order (form jastip, form ojek,
/// tracking) supaya tidak ada tiga versi peta yang tampil beda.
///
/// Peta sengaja punya tampilan "kosong" yang jujur: kalau koordinat belum ada,
/// layar memberi tahu, bukan menampilkan peta kosong yang membingungkan.
class PetaOrder extends StatelessWidget {
  const PetaOrder({
    super.key,
    required this.titik,
    this.garis = const <TitikPeta>[],
    this.tinggi = 220,
    this.penanda,
    this.lokasiSaya = false,
  });

  /// Titik yang digambar: jemput, tujuan, lokasi beli, alamat antar.
  final List<TitikPeta> titik;

  /// Garis rute; boleh kosong kalau rute belum dihitung.
  final List<TitikPeta> garis;

  final double tinggi;

  /// Warna penanda pertama. Penanda berikutnya memakai warna aksen.
  final Color? penanda;

  /// Tampilkan tombol "lokasi saya" di peta.
  final bool lokasiSaya;

  @override
  Widget build(BuildContext context) {
    final List<TitikPeta> sah = titik.where((TitikPeta t) => t.valid).toList();
    final List<TitikPeta> garisSah =
        garis.where((TitikPeta t) => t.valid).toList(growable: false);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: SizedBox(
        height: tinggi,
        width: double.infinity,
        child: sah.isEmpty
            ? PetaKosong(tinggi: tinggi)
            : AnyMapWidget(
                adapter: MapLibreAdapter(styleUrl: gayaPetaGratis),
                initialCamera: AnyCameraPosition(
                  target: _pusat(sah),
                  zoom: _zoom(sah),
                ),
                markers: <AnyMarker>[
                  for (int i = 0; i < sah.length; i++)
                    AnyMarker(
                      id: 't$i',
                      position: AnyLatLng(sah[i].lat, sah[i].lng),
                      anchor: AnyMarkerAnchor.center,
                      icon: _Pin(warna: penanda ?? _warna(i), label: '${i + 1}'),
                    ),
                ],
                polylines: <AnyPolyline>[
                  if (garisSah.length > 1)
                    AnyPolyline(
                      id: 'rute',
                      points: garisSah
                          .map((TitikPeta t) => AnyLatLng(t.lat, t.lng))
                          .toList(growable: false),
                      color: context.colors.primary,
                      width: 5,
                    ),
                ],
                myLocationEnabled: lokasiSaya,
                myLocationButtonEnabled: lokasiSaya,
                compassEnabled: true,
              ),
      ),
    );
  }

  static Color _warna(int i) =>
      i.isEven ? AppColors.primary : AppColors.accent;

  /// Titik tengah semua titik supaya seluruh rute terlihat.
  static AnyLatLng _pusat(List<TitikPeta> titik) {
    double lat = 0;
    double lng = 0;
    for (final TitikPeta t in titik) {
      lat += t.lat;
      lng += t.lng;
    }
    final double n = titik.length;
    if (titik.length == 1) {
      return AnyLatLng(titik.first.lat, titik.first.lng);
    }
    return AnyLatLng(lat / n, lng / n);
  }

  /// Zoom ikut jarak antar titik: makin dekat, makin dekat.
  static double _zoom(List<TitikPeta> titik) {
    if (titik.length < 2) return 15.5;
    double jauh = 0;
    for (final TitikPeta a in titik) {
      for (final TitikPeta b in titik) {
        final double d = jarakKm(a, b);
        if (d > jauh) jauh = d;
      }
    }
    if (jauh <= 0) return 15.5;
    if (jauh < 0.4) return 16.5;
    if (jauh < 1) return 16;
    if (jauh < 3) return 15;
    if (jauh < 8) return 14;
    return 13;
  }
}

/// Penanda peta: lingkaran bernomor dengan warna status.
class _Pin extends StatelessWidget {
  const _Pin({required this.warna, required this.label});

  final Color warna;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: warna,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.white, width: 3),
        boxShadow: AppShadows.medium,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: context.text.labelSmall?.copyWith(color: AppColors.white),
      ),
    );
  }
}

/// Tampilan saat koordinat belum ada: memberi tahu, bukan peta kosong.
class PetaKosong extends StatelessWidget {
  const PetaKosong({super.key, this.tinggi = 220});

  final double tinggi;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: tinggi,
      color: context.semantic.line,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppIcon(Ik.place, size: 30, color: context.semantic.textSecondary),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Peta muncul setelah lokasi diketahui',
            style: context.text.bodySmall
                ?.copyWith(color: context.semantic.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Kartu ringkasan tarif, dipakai form jastip dan form ojek.
class KartuTarif extends StatelessWidget {
  const KartuTarif({
    super.key,
    required this.ringkasan,
    required this.judul,
    this.catatanTambahan,
  });

  final RingkasanTarif ringkasan;
  final String judul;
  final String? catatanTambahan;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              AppIcon(Ik.wallet, size: 20, color: context.colors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(judul, style: context.text.titleSmall)),
              Text(
                ringkasan.adaJarak ? rupiah(ringkasan.tarif) : '-',
                style: context.text.titleMedium
                    ?.copyWith(color: context.colors.primary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              ChipInfo(ikon: Ik.route, label: ringkasan.jarakTeks),
              const SizedBox(width: AppSpacing.sm),
              ChipInfo(
                ikon: Ik.clock,
                label: ringkasan.durasiMenit > 0
                    ? '${ringkasan.durasiMenit} menit'
                    : 'durasi belum dihitung',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            catatanTambahan ?? ringkasan.sumberTeks,
            style: context.text.bodySmall
                ?.copyWith(color: context.semantic.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Chip kecil untuk informasi sekilas (jarak, durasi, status).
class ChipInfo extends StatelessWidget {
  const ChipInfo({super.key, required this.ikon, required this.label});

  final Ik ikon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.semantic.line,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppIcon(ikon, size: 14, color: context.semantic.textSecondary),
          const SizedBox(width: 6),
          Text(label, style: context.text.labelSmall),
        ],
      ),
    );
  }
}

/// Kartu order untuk daftar (riwayat, semua order, order aktif).
///
/// Satu widget untuk jastip dan ojek supaya tampilan selalu sama; yang
/// membedakan hanya ikon dan warna jenis.
class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    required this.onTap,
    this.onBatal,
  });

  final OrderRingkas order;
  final VoidCallback onTap;
  final VoidCallback? onBatal;

  static Ik ikonUntuk(JenisOrder jenis) =>
      jenis == JenisOrder.jastip ? Ik.package : Ik.motorcycle;

  @override
  Widget build(BuildContext context) {
    final bool bisaBatal = onBatal != null && order.status.bisaDibatalWarga;
    return AppCard(
      onTap: () {
        Haptics.light();
        onTap();
      },
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              _Lencana(order.jenis),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  order.kode.isEmpty ? order.jenis.label : order.kode,
                  style: context.text.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              StatusBadge(status: order.status),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            order.ringkas,
            style: context.text.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Text(
                order.tarif > 0 ? rupiah(order.tarif) : 'Tarif menyusul',
                style: context.text.labelLarge,
              ),
              const Spacer(),
              Text(
                waktuRelatif(order.dibuat),
                style: context.text.bodySmall
                    ?.copyWith(color: context.semantic.textSecondary),
              ),
            ],
          ),
          if (bisaBatal) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: 'Batalkan order',
                tone: PrimaryButtonTone.outlined,
                onPressed: () {
                  Haptics.medium();
                  onBatal!();
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "baru saja" / "5 menit lalu" - dipakai kartu dan timeline.
String waktuRelatif(DateTime w) {
  final Duration d = DateTime.now().difference(w);
  if (d.inMinutes < 1) return 'baru saja';
  if (d.inHours < 1) return '${d.inMinutes} menit lalu';
  if (d.inDays < 1) return '${d.inHours} jam lalu';
  if (d.inDays < 30) return '${d.inDays} hari lalu';
  return '${w.day}/${w.month}/${w.year}';
}

/// Lencana jenis order (ikon + warna).
class _Lencana extends StatelessWidget {
  const _Lencana(this.jenis);

  final JenisOrder jenis;

  @override
  Widget build(BuildContext context) {
    final Color w = jenis == JenisOrder.jastip
        ? context.colors.primary
        : context.colors.accent;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: w.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: AppIcon(OrderCard.ikonUntuk(jenis), size: 20, color: w),
    );
  }
}

/// Badge status dengan warna sesuai kondisi.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final StatusOrder status;

  @override
  Widget build(BuildContext context) {
    final Color w = warnaStatus(context, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: w.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: context.text.labelSmall?.copyWith(color: w),
      ),
    );
  }
}

/// Warna status, dipakai bersama kartu, timeline, dan detail.
Color warnaStatus(BuildContext context, StatusOrder status) {
  switch (status) {
    case StatusOrder.menunggu:
      return context.semantic.textSecondary;
    case StatusOrder.diterima:
      return context.colors.info;
    case StatusOrder.diproses:
      return context.colors.warning;
    case StatusOrder.dalamPerjalanan:
      return context.colors.primary;
    case StatusOrder.selesai:
      return context.colors.success;
    case StatusOrder.batal:
    case StatusOrder.dibatalkan:
      return context.semantic.textSecondary;
  }
}

/// Timeline status: tahap yang sudah lewat berwarna, berikutnya redup.
class TimelineStatus extends StatelessWidget {
  const TimelineStatus({
    super.key,
    required this.status,
    required this.jenis,
    this.catatan,
  });

  final StatusOrder status;
  final JenisOrder jenis;
  final String? catatan;

  @override
  Widget build(BuildContext context) {
    final List<StatusOrder> tahapan = alurStatus(status);
    final bool gagal = !status.aktif;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (int i = 0; i < tahapan.length; i++)
          _BarisTahapan(
            tahap: tahapan[i],
            jenis: jenis,
            selesai: !gagal && tahapan[i].urutan <= status.urutan,
            terakhir: i == tahapan.length - 1,
          ),
        if (catatan != null && catatan!.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: context.semantic.line,
              borderRadius: BorderRadius.circular(AppRadius.field),
            ),
            child: Text(catatan!, style: context.text.bodySmall),
          ),
        ],
      ],
    );
  }
}

class _BarisTahapan extends StatelessWidget {
  const _BarisTahapan({
    required this.tahap,
    required this.jenis,
    required this.selesai,
    required this.terakhir,
  });

  final StatusOrder tahap;
  final JenisOrder jenis;
  final bool selesai;
  final bool terakhir;

  @override
  Widget build(BuildContext context) {
    final Color w =
        selesai ? warnaStatus(context, tahap) : context.semantic.textSecondary;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Column(
            children: <Widget>[
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: selesai ? w : context.semantic.line,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: selesai
                    ? const AppIcon(Ik.check, size: 13, color: AppColors.white)
                    : null,
              ),
              if (!terakhir)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: selesai
                        ? w.withValues(alpha: 0.4)
                        : context.semantic.line,
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: terakhir ? 0 : AppSpacing.lg),
              child: Text(
                labelTahap(tahap, jenis),
                style: context.text.bodyMedium?.copyWith(
                  color: selesai ? null : context.semantic.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bintang rating: bisa ditekan (form) atau hanya dibaca (display).
class BintangRating extends StatelessWidget {
  const BintangRating({
    super.key,
    required this.nilai,
    this.onUbah,
    this.ukuran = 24,
  });

  final int nilai;
  final ValueChanged<int>? onUbah;
  final double ukuran;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 1; i <= 5; i++)
          GestureDetector(
            onTap: onUbah == null
                ? null
                : () {
                    Haptics.selection();
                    onUbah!(i);
                  },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: AppIcon(
                Ik.star,
                size: ukuran,
                color: i <= nilai
                    ? AppColors.secondary
                    : context.semantic.textSecondary.withValues(alpha: 0.35),
              ),
            ),
          ),
      ],
    );
  }
}

/// Baris info label-nilai, dipakai di layar detail.
class BarisInfo extends StatelessWidget {
  const BarisInfo({
    super.key,
    required this.label,
    required this.nilai,
    this.ikon,
  });

  final String label;
  final String nilai;
  final Ik? ikon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (ikon != null) ...<Widget>[
            AppIcon(ikon, size: 18, color: context.semantic.textSecondary),
            const SizedBox(width: AppSpacing.sm),
          ],
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: context.text.bodySmall
                  ?.copyWith(color: context.semantic.textSecondary),
            ),
          ),
          Expanded(child: Text(nilai, style: context.text.bodyMedium)),
        ],
      ),
    );
  }
}

/// Kartu pilihan metode bayar. CASH dulu; QRIS tampil tapi tidak bisa dipilih
/// supaya warga tidak memilih fitur yang belum ada.
class KartuBayar extends StatelessWidget {
  const KartuBayar({
    super.key,
    required this.dipilih,
    required this.onUbah,
  });

  final MetodeBayar dipilih;
  final ValueChanged<MetodeBayar> onUbah;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        OpsiBayar(
          metode: MetodeBayar.cash,
          dipilih: dipilih == MetodeBayar.cash,
          keterangan: 'Bayar langsung ke mitra saat barang diterima',
          aktif: true,
          onUbah: onUbah,
        ),
        const SizedBox(height: AppSpacing.sm),
        OpsiBayar(
          metode: MetodeBayar.qris,
          dipilih: dipilih == MetodeBayar.qris,
          keterangan: 'Belum tersedia. Segera hadir setelah QRIS aktif.',
          aktif: false,
          onUbah: onUbah,
        ),
      ],
    );
  }
}

/// Satu baris pilihan bayar.
class OpsiBayar extends StatelessWidget {
  const OpsiBayar({
    super.key,
    required this.metode,
    required this.dipilih,
    required this.keterangan,
    required this.aktif,
    required this.onUbah,
  });

  final MetodeBayar metode;
  final bool dipilih;
  final String keterangan;
  final bool aktif;
  final ValueChanged<MetodeBayar> onUbah;

  @override
  Widget build(BuildContext context) {
    final Color w = metode == MetodeBayar.cash
        ? context.colors.primary
        : context.colors.accent;
    return InkWell(
      onTap: aktif
          ? () {
              Haptics.selection();
              onUbah(metode);
            }
          : null,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: dipilih ? w.withValues(alpha: 0.08) : context.semantic.card,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: dipilih ? w : context.semantic.line,
            width: dipilih ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: <Widget>[
            AppIcon(
              metode == MetodeBayar.cash ? Ik.cash : Ik.qrCode,
              size: 24,
              color: aktif ? w : context.semantic.textSecondary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    metode.label,
                    style: context.text.titleSmall?.copyWith(
                      color: aktif ? null : context.semantic.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    keterangan,
                    style: context.text.bodySmall
                        ?.copyWith(color: context.semantic.textSecondary),
                  ),
                ],
              ),
            ),
            if (dipilih) AppIcon(Ik.checkCircle, size: 22, color: w),
          ],
        ),
      ),
    );
  }
}

/// Judul layar + tombol aksi, dipakai semua layar order.
class KepalaOrder extends StatelessWidget {
  const KepalaOrder({
    super.key,
    required this.judul,
    this.subjudul,
    this.aksi = const <Widget>[],
  });

  final String judul;
  final String? subjudul;
  final List<Widget> aksi;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(judul, style: context.text.headlineMedium),
              if (subjudul != null) ...<Widget>[
                const SizedBox(height: 2),
                Text(
                  subjudul!,
                  style: context.text.bodySmall
                      ?.copyWith(color: context.semantic.textSecondary),
                ),
              ],
            ],
          ),
        ),
        ...aksi,
      ],
    );
  }
}

/// Judul bagian di dalam layar order.
class SubOrder extends StatelessWidget {
  const SubOrder(this.judul, {super.key, this.ikon});

  final String judul;
  final Ik? ikon;

  @override
  Widget build(BuildContext context) {
    if (ikon == null) return SectionHeader(title: judul);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: <Widget>[
          AppIcon(ikon!, size: 18, color: context.colors.primary),
          const SizedBox(width: AppSpacing.sm),
          Text(judul, style: context.text.titleSmall),
        ],
      ),
    );
  }
}