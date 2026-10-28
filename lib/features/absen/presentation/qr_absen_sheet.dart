import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/data/data_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_id.dart';
import '../../../core/utils/haptics.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_icon.dart';
import '../../../shared/widgets/loading_dots.dart';
import '../../kegiatan/domain/kegiatan.dart';
import '../data/absen_state.dart';

/// Lembar pemindai QR absensi (kamera asli, bukan simulasi).
///
/// Mengembalikan [Kegiatan] lewat `Navigator.pop` kalau anggota menekan
/// "Ya, saya hadir". `null` = ditutup tanpa mencatat apa pun.
class QrAbsenSheet extends ConsumerStatefulWidget {
  const QrAbsenSheet({super.key});

  /// Buka lembar pemindai; hasilnya kegiatan yang mau dicatat, atau null.
  static Future<Kegiatan?> tampilkan(BuildContext context) {
    return showModalBottomSheet<Kegiatan>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      builder: (BuildContext _) => const QrAbsenSheet(),
    );
  }

  @override
  ConsumerState<QrAbsenSheet> createState() => _QrAbsenSheetState();
}

class _QrAbsenSheetState extends ConsumerState<QrAbsenSheet> {
  /// Batas jeda supaya QR yang sama tidak memicu getaran berulang.
  static const Duration _jedaTolak = Duration(seconds: 2);

  late final MobileScannerController _kamera;
  AbsenKode? _kode;
  Kegiatan? _sasaran;
  String? _tolak;
  bool _terkunci = false;
  DateTime? _tolakPada;

  @override
  void initState() {
    super.initState();
    _kamera = MobileScannerController(
      formats: const <BarcodeFormat>[BarcodeFormat.qrCode],
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _kamera.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- logika

  void _tangkap(BarcodeCapture capture) {
    if (_terkunci) return;
    for (final Barcode kode in capture.barcodes) {
      final String isi = (kode.rawValue ?? kode.displayValue ?? '').trim();
      if (isi.isEmpty) continue;
      final AbsenKode? hasil = bacaAbsenKode(isi);
      if (hasil == null) {
        _tolakQr(isi);
        return;
      }
      _terima(hasil);
      return;
    }
  }

  void _terima(AbsenKode kode) {
    _terkunci = true;
    Haptics.medium();
    _kamera.stop();
    setState(() {
      _kode = kode;
      _sasaran = _cocokkan(kode);
      _tolak = null;
    });
  }

  void _tolakQr(String isi) {
    final DateTime sekarang = DateTime.now();
    final DateTime? lalu = _tolakPada;
    if (lalu != null && sekarang.difference(lalu) < _jedaTolak) return;
    _tolakPada = sekarang;
    Haptics.error();
    final String potong = isi.length > 48 ? '${isi.substring(0, 48)}…' : isi;
    setState(() => _tolak = potong);
  }

  /// Cari kegiatan yang judulnya sama dengan isi QR; kalau tidak ada (mis. QR
  /// dicetak dari daftar kegiatan versi lain) tetap dicatat memakai data QR.
  Kegiatan _cocokkan(AbsenKode kode) {
    final List<Kegiatan> semua =
        ref.read(kegiatanProvider).valueOrNull ?? const <Kegiatan>[];
    final String cari = kode.judul.trim().toLowerCase();
    for (final Kegiatan a in semua) {
      if (a.judul.trim().toLowerCase() == cari) return a;
    }
    return Kegiatan(
      judul: kode.judul,
      kategori: 'Kegiatan',
      tanggal: kode.tanggal,
      lokasi: 'Tidak tercatat di QR',
      mendatang: false,
    );
  }

  Future<void> _pindaiUlang() async {
    setState(() {
      _kode = null;
      _sasaran = null;
      _tolak = null;
      _terkunci = false;
    });
    await _mulaiUlangKamera();
  }

  /// `stop()` dan `start()` di-await berurutan: memanggil `start()` saat
  /// `stop()` masih berjalan bisa melempar `controllerAlreadyInitialized`.
  Future<void> _mulaiUlangKamera() async {
    try {
      await _kamera.stop();
      await _kamera.start();
    } catch (_) {
      // Kamera tetap tidak bisa dibuka: panel galat dari `errorBuilder`
      // yang memberi tahu anggota, jadi cukup diam di sini.
    }
  }

  Future<void> _lampu() async {
    try {
      await _kamera.toggleTorch();
    } catch (_) {
      // Sebagian kamera tidak punya lampu: cukup diam, tombol tetap ada.
    }
  }

  Future<void> _gantiKamera() async {
    try {
      await _kamera.switchCamera();
    } catch (_) {
      Haptics.error();
    }
  }

  // ------------------------------------------------------------------ UI

  @override
  Widget build(BuildContext context) {
    final AbsenKode? kode = _kode;
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _kepala(context),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: kode == null ? _pemindai(context) : _konfirmasi(context, kode),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kepala(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Pindai QR kegiatan', style: context.text.titleMedium),
                const SizedBox(height: 2),
                Text(
                  'Arahkan kamera ke kode yang ditampilkan pengurus.',
                  style: context.text.bodySmall
                      ?.copyWith(color: context.semantic.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const AppIcon(Ik.close, size: 20),
            tooltip: 'Tutup',
          ),
        ],
      ),
    );
  }

  Widget _pemindai(BuildContext context) {
    final double layar = MediaQuery.sizeOf(context).height;
    final double mentah = layar * 0.42;
    final double tinggi = mentah < 220 ? 220 : (mentah > 360 ? 360 : mentah);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: SizedBox(
            height: tinggi,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                MobileScanner(
                  controller: _kamera,
                  onDetect: _tangkap,
                  fit: BoxFit.cover,
                  errorBuilder: _galatKamera,
                  placeholderBuilder: _menungguKamera,
                ),
                const IgnorePointer(child: _Bingkai()),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Kode absen hanya berlaku untuk kegiatan yang dibuat pengurus.',
          textAlign: TextAlign.center,
          style: context.text.bodySmall
              ?.copyWith(color: context.semantic.textSecondary),
        ),
        if (_tolak != null) ...<Widget>[
          const SizedBox(height: 12),
          _Catatan(
            ikon: Ik.xCircle,
            warna: context.colors.error,
            judul: 'QR ini bukan absen KUNBAR',
            isi: 'Terbaca: "$_tolak". Minta pengurus menampilkan QR yang benar.',
          ),
        ],
        const SizedBox(height: 14),
        ValueListenableBuilder<MobileScannerState>(
          valueListenable: _kamera,
          builder: (BuildContext context, MobileScannerState state, Widget? _) {
            final bool menyala = state.torchState == TorchState.on;
            return Row(
              children: <Widget>[
                Expanded(
                  child: _TombolKecil(
                    ikon: Ik.bolt,
                    label: menyala ? 'Matikan lampu' : 'Nyalakan lampu',
                    aktif: menyala,
                    onTap: state.torchState == TorchState.unavailable
                        ? null
                        : _lampu,
                  ),
                ),
                const SizedBox(width: AppSpacing.gap),
                Expanded(
                  child: _TombolKecil(
                    ikon: Ik.flip,
                    label: 'Ganti kamera',
                    aktif: false,
                    onTap: _gantiKamera,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _konfirmasi(BuildContext context, AbsenKode kode) {
    final Kegiatan? sasaran = _sasaran;
    if (sasaran == null) {
      return const SizedBox.shrink();
    }
    final DateTime waktu =
        sasaran.tanggal ?? kode.tanggal ?? DateTime.now();
    final bool sudah =
        ref.read(absenProvider.notifier).sudahAbsen(sasaran.judul, waktu);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  AppIcon(Ik.checkCircle, size: 18, color: context.colors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'QR kegiatan terbaca',
                    style: context.text.labelMedium
                        ?.copyWith(color: context.semantic.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(sasaran.judul, style: context.text.titleMedium),
              const SizedBox(height: 8),
              _Baris(ikon: Ik.calendar, isi: DateId.hariTanggal(waktu)),
              const SizedBox(height: 6),
              _Baris(ikon: Ik.place, isi: sasaran.lokasi),
            ],
          ),
        ),
        if (sudah) ...<Widget>[
          const SizedBox(height: 14),
          _Catatan(
            ikon: Ik.lock,
            warna: context.semantic.textSecondary,
            judul: 'Sudah tercatat',
            isi: 'Kehadiran kamu untuk kegiatan ini sudah tersimpan.',
          ),
        ],
        const SizedBox(height: 18),
        if (sudah)
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          )
        else
          FilledButton(
            onPressed: () => Navigator.of(context).pop(sasaran),
            child: const Text('Ya, saya hadir'),
          ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: _pindaiUlang,
          child: const Text('Pindai ulang'),
        ),
      ],
    );
  }

  Widget _menungguKamera(BuildContext context, Widget? child) {
    return const ColoredBox(
      color: AppColors.ink,
      child: Center(child: LoadingDots()),
    );
  }

  Widget _galatKamera(
    BuildContext context,
    MobileScannerException e,
    Widget? child,
  ) {
    final bool izinDitolak = e.errorCode == MobileScannerErrorCode.permissionDenied;
    return ColoredBox(
      color: AppColors.ink,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const AppIcon(Ik.camera, size: 28, color: AppColors.white),
              const SizedBox(height: 12),
              Text(
                izinDitolak
                    ? 'Izin kamera ditolak'
                    : 'Kamera tidak bisa dibuka',
                textAlign: TextAlign.center,
                style: context.text.titleSmall?.copyWith(color: AppColors.white),
              ),
              const SizedBox(height: 6),
              Text(
                izinDitolak
                    ? 'Aktifkan izin Kamera di Pengaturan Android, lalu buka lagi lembar ini.'
                    : 'Tutup aplikasi lain yang memakai kamera, lalu coba lagi.',
                textAlign: TextAlign.center,
                style: context.text.bodySmall
                    ?.copyWith(color: AppColors.white.withValues(alpha: 0.72)),
              ),
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: _mulaiUlangKamera,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.white,
                  side: BorderSide(color: AppColors.white.withValues(alpha: 0.4)),
                ),
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Empat sudut putih di atas gambar kamera — penanda area pindai.
class _Bingkai extends StatelessWidget {
  const _Bingkai();

  static const double _sisi = 190;
  static const double _panjang = 34;
  static const double _tebal = 3;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: _sisi,
        height: _sisi,
        child: Stack(
          children: <Widget>[
            Positioned(left: 0, top: 0, child: _sudut(atas: true, kiri: true)),
            Positioned(right: 0, top: 0, child: _sudut(atas: true, kiri: false)),
            Positioned(left: 0, bottom: 0, child: _sudut(atas: false, kiri: true)),
            Positioned(right: 0, bottom: 0, child: _sudut(atas: false, kiri: false)),
          ],
        ),
      ),
    );
  }

  Widget _sudut({required bool atas, required bool kiri}) {
    const BorderRadius bulat = BorderRadius.all(Radius.circular(10));
    const BorderSide garis = BorderSide(color: AppColors.white, width: _tebal);
    const BorderSide kosong = BorderSide.none;
    return Container(
      width: _panjang,
      height: _panjang,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: atas && kiri ? bulat.topLeft : Radius.zero,
          topRight: atas && !kiri ? bulat.topRight : Radius.zero,
          bottomLeft: !atas && kiri ? bulat.bottomLeft : Radius.zero,
          bottomRight: !atas && !kiri ? bulat.bottomRight : Radius.zero,
        ),
        border: Border(
          top: atas ? garis : kosong,
          bottom: atas ? kosong : garis,
          left: kiri ? garis : kosong,
          right: kiri ? kosong : garis,
        ),
      ),
    );
  }
}

class _Baris extends StatelessWidget {
  const _Baris({required this.ikon, required this.isi});

  final Ik ikon;
  final String isi;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AppIcon(ikon, size: 15, color: context.semantic.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            isi,
            style: context.text.bodySmall
                ?.copyWith(color: context.semantic.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _Catatan extends StatelessWidget {
  const _Catatan({
    required this.ikon,
    required this.warna,
    required this.judul,
    required this.isi,
  });

  final Ik ikon;
  final Color warna;
  final String judul;
  final String isi;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          warna.withValues(alpha: 0.10),
          context.colors.surface,
        ),
        borderRadius: BorderRadius.circular(AppRadius.field),
        border: Border.all(color: warna.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppIcon(ikon, size: 17, color: warna),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(judul, style: context.text.labelMedium),
                const SizedBox(height: 2),
                Text(
                  isi,
                  style: context.text.bodySmall
                      ?.copyWith(color: context.semantic.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TombolKecil extends StatelessWidget {
  const _TombolKecil({
    required this.ikon,
    required this.label,
    required this.aktif,
    required this.onTap,
  });

  final Ik ikon;
  final String label;
  final bool aktif;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color warna = aktif ? context.colors.primary : context.semantic.textSecondary;
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: AppIcon(ikon, size: 16, color: warna),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        foregroundColor: warna,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        side: BorderSide(color: context.semantic.line),
        textStyle: context.text.labelMedium,
      ),
    );
  }
}
