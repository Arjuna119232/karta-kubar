
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/session.dart';
import '../../../core/data/hasil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../shared/models/mitra_jasa.dart';
import '../../../shared/models/order.dart';
import '../../../shared/models/order_ringkas.dart';
import '../../../shared/models/order_tracking.dart';
import '../../../shared/services/lokasi_service.dart';
import '../../../shared/services/ojek_service.dart';
import '../../../shared/services/tarif_service.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/alamat_autocomplete.dart';
import '../../../shared/widgets/app_icon.dart';
import '../../../shared/widgets/loading_dots.dart';
import '../../../shared/widgets/primary_button.dart';
import '../data/order_state.dart';
import 'widgets_order.dart';

/// Form order OJEK: jemput di lokasi warga, tujuan bebas.
///
/// Bedanya dengan form jastip: lokasi jemput diambil dari GPS otomatis, dan
/// warga boleh memilih mitra sendiri atau membiarkan sistem menugaskan.
class OjekFormScreen extends ConsumerStatefulWidget {
  const OjekFormScreen({super.key});

  @override
  ConsumerState<OjekFormScreen> createState() => _OjekFormScreenState();
}

class _OjekFormScreenState extends ConsumerState<OjekFormScreen> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _jemput = TextEditingController();
  final TextEditingController _tujuan = TextEditingController();
  final TextEditingController _catatan = TextEditingController();

  TitikPeta _titikJemput = const TitikPeta(lat: 0, lng: 0);
  TitikPeta _titikTujuan = const TitikPeta(lat: 0, lng: 0);
  MetodeBayar _bayar = MetodeBayar.cash;
  MitraJasa? _mitra;
  bool _sibukLokasi = false;
  bool _sibukKirim = false;
  bool _sibukTarif = false;
  RingkasanTarif _ringkasan = RingkasanTarif.kosong;

  /// Lokasi HP warga terakhir yang terbaca. Dipakai sebagai posisi mitra bila
  /// mitra belum punya koordinat.
  TitikPeta _titikHp = const TitikPeta(lat: 0, lng: 0);

  /// Rincian jarak: mitra -> jemput, jemput -> tujuan.
  double _kmMitra = 0;
  double _kmAntar = 0;
  bool _adaPosisiMitra = false;
  List<TitikPeta> _garis = const <TitikPeta>[];

  /// Teks alamat saat titiknya terakhir ditetapkan. Kalau teks berubah,
  /// titik lama sudah tidak berlaku.
  String _teksJemputTitik = '';
  String _teksTujuanTitik = '';
  bool _mencariJemput = false;
  bool _mencariTujuan = false;
  int _urutan = 0;

  @override
  void dispose() {
    _jemput.dispose();
    _tujuan.dispose();
    _catatan.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<MitraJasa> mitra = ref.watch(mitraTersediaProvider(
      JenisOrder.ojek,
    )).valueOrNull ??
        mitraContoh;

    return Scaffold(
      appBar: AppBar(title: const Text('Pesan Ojek')),
      body: SafeArea(
        top: false,
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen, 8, AppSpacing.screen, 120),
            children: <Widget>[
              _IntroOjek(),
              const SizedBox(height: AppSpacing.section),
              SubOrder('Lokasi jemput', ikon: Ik.person),
              AlamatAutocomplete(
                controller: _jemput,
                label: 'Alamat jemput',
                hint: 'Ketik sebagian alamat, lalu pilih dari saran',
                ikon: Ik.place,
                onUbah: _alamatJemputBerubah,
                validator: (String? v) =>
                    _wajib(v, 'Alamat jemput', min: 3),
              ),
              const SizedBox(height: AppSpacing.md),
              _TombolLokasiOjek(
                detail: _titikJemput.valid
                    ? _titikJemput.teks
                    : 'Belum diambil. Tekan untuk memakai lokasi HP sekarang.',
                sibuk: _sibukLokasi,
                onTekan: _ambilLokasi,
              ),
              const SizedBox(height: AppSpacing.section),
              SubOrder('Lokasi tujuan', ikon: Ik.pinMitra),
              AlamatAutocomplete(
                controller: _tujuan,
                label: 'Mau pergi ke mana',
                hint: 'Ketik sebagian alamat, lalu pilih dari saran',
                ikon: Ik.place,
                onUbah: _alamatTujuanBerubah,
                validator: (String? v) => _wajib(v, 'Lokasi tujuan', min: 3),
              ),
              const SizedBox(height: AppSpacing.md),
              PetaOrder(
                // Key berubah bersama titiknya supaya kamera peta ikut pindah.
                key: ValueKey<String>(
                    '${_titikJemput.teks}|${_titikTujuan.teks}|${_garis.length}'),
                titik: <TitikPeta>[_titikJemput, _titikTujuan],
                // Rute jalan dari OSRM; kalau tidak ada, garis lurus.
                garis: _garis.length > 1
                    ? _garis
                    : <TitikPeta>[_titikJemput, _titikTujuan],
                tinggi: 190,
                lokasiSaya: _titikJemput.valid,
              ),
              const SizedBox(height: AppSpacing.xs),
              _RincianJarak(
                kmMitra: _kmMitra,
                kmAntar: _kmAntar,
                adaPosisiMitra: _adaPosisiMitra,
                ringkasan: _ringkasan,
                sibuk: _sibukTarif || _mencariJemput || _mencariTujuan,
                status: _statusLokasi(),
                onHitungUlang: _hitungUlang,
              ),
              const SizedBox(height: AppSpacing.section),
              SubOrder('Tarif', ikon: Ik.wallet),
              KartuTarif(
                ringkasan: _ringkasan,
                judul: 'Tarif ojek',
                catatanTambahan: _ringkasan.adaJarak
                    ? _ringkasan.sumberTeks
                    : 'Isi jemput dan tujuan untuk melihat tarif.',
              ),
              const SizedBox(height: AppSpacing.section),
              SubOrder('Pilih mitra', ikon: Ik.person),
              _PilihanMitra(
                mitra: mitra,
                terpilih: _mitra,
                onUbah: (MitraJasa? m) {
                  setState(() => _mitra = m);
                  _hitungUlang();
                },
              ),
              const SizedBox(height: AppSpacing.section),
              SubOrder('Catatan untuk mitra', ikon: Ik.chat),
              _FieldOjek(
                controller: _catatan,
                label: 'Catatan',
                hint: 'Contoh: bawa koper, titip di jalan Otherwise',
                ikon: Ik.chat,
                maksBaris: 3,
              ),
              const SizedBox(height: AppSpacing.section),
              SubOrder('Pembayaran', ikon: Ik.cash),
              KartuBayar(dipilih: _bayar, onUbah: (MetodeBayar m) {
                setState(() => _bayar = m);
              }),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _TombolKirimOjek(
        sibuk: _sibukKirim,
        total: _ringkasan.tarif,
        onTekan: _kirim,
      ),
    );
  }

  // ------------------------------------------------------------------ aksi

  String? _wajib(String? nilai, String nama, {int min = 2}) {
    final String v = nilai?.trim() ?? '';
    if (v.length < min) return '$nama belum diisi dengan benar.';
    return null;
  }

  Future<void> _ambilLokasi() async {
    setState(() => _sibukLokasi = true);
    final LokasiService svc = ref.read(lokasiServiceProvider);
    final Hasil<TitikPeta> hasil = await svc.posisiSaya();
    if (!mounted) return;
    setState(() => _sibukLokasi = false);
    if (!hasil.berhasil) {
      _snak(hasil.galat?.pesan ?? 'Gagal membaca lokasi.', galat: true);
      return;
    }
    setState(() {
      _titikJemput = hasil.data!;
      _titikHp = hasil.data!;
      if (_jemput.text.trim().isEmpty) {
        _jemput.text = hasil.data!.teks;
      }
      _teksJemputTitik = _jemput.text.trim();
    });
    await _hitungUlang();
  }

  // ------------------------------------------------------ lokasi & tarif

  /// Pesan bila alamat sudah diisi tetapi belum ditemukan di peta.
  String? _statusLokasi() {
    if (_jemput.text.trim().length >= 3 && !_titikJemput.valid) {
      return 'Alamat jemput belum ada titiknya. Pilih dari saran yang muncul, '
          'tekan ikon peta, atau pakai lokasi HP.';
    }
    if (_tujuan.text.trim().length >= 3 && !_titikTujuan.valid) {
      return 'Alamat tujuan belum ada titiknya. Pilih dari saran yang muncul '
          'atau tekan ikon peta.';
    }
    return null;
  }

  /// Alamat jemput berubah. [titik] null berarti belum ada koordinat: saran
  /// yang diketuk pengguna atau titik dari peta sudah memberikan koordinat.
  void _alamatJemputBerubah(String teks, TitikPeta? titik) {
    setState(() {
      _teksJemputTitik = titik == null ? '' : teks.trim();
      _titikJemput = titik ?? const TitikPeta(lat: 0, lng: 0);
      _mencariJemput = titik == null && teks.trim().length >= 3;
    });
    _hitungUlang();
  }

  /// Alamat tujuan berubah, sama seperti jemput.
  void _alamatTujuanBerubah(String teks, TitikPeta? titik) {
    setState(() {
      _teksTujuanTitik = titik == null ? '' : teks.trim();
      _titikTujuan = titik ?? const TitikPeta(lat: 0, lng: 0);
      _mencariTujuan = titik == null && teks.trim().length >= 3;
    });
    _hitungUlang();
  }

  /// Total jarak = mitra -> jemput + jemput -> tujuan. Tarif dari total itu.
  ///
  /// Posisi mitra: koordinat mitra terpilih; kalau tidak ada, lokasi HP warga
  /// yang terakhir terbaca; kalau keduanya tidak ada, bagian itu 0 dan
  /// rinciannya memberi tahu.
  Future<void> _hitungUlang() async {
    final int urutan = ++_urutan;
    if (!_titikJemput.valid || !_titikTujuan.valid) {
      if (!mounted) return;
      setState(() {
        _ringkasan = RingkasanTarif.kosong;
        _kmMitra = 0;
        _kmAntar = 0;
        _adaPosisiMitra = false;
        _garis = const <TitikPeta>[];
        _sibukTarif = false;
      });
      return;
    }
    setState(() => _sibukTarif = true);
    final LokasiService svc = ref.read(lokasiServiceProvider);

    final Rute antar = await svc.rute(_titikJemput, _titikTujuan);
    final TitikPeta posMitra =
        (_mitra != null && _mitra!.lokasi.valid) ? _mitra!.lokasi : _titikHp;
    Rute? mitraKeJemput;
    if (posMitra.valid) {
      mitraKeJemput = await svc.rute(posMitra, _titikJemput);
    }

    // Ada perhitungan yang lebih baru: abaikan hasil ini.
    if (!mounted || urutan != _urutan) return;

    final double km1 = mitraKeJemput?.jarakKm ?? 0;
    final Rute total = Rute(
      jarakKm: km1 + antar.jarakKm,
      durasiMenit: (mitraKeJemput?.durasiMenit ?? 0) + antar.durasiMenit,
      dariServer: antar.dariServer && (mitraKeJemput?.dariServer ?? true),
    );
    setState(() {
      _kmMitra = km1;
      _kmAntar = antar.jarakKm;
      _adaPosisiMitra = mitraKeJemput != null;
      _garis = antar.garis ?? const <TitikPeta>[];
      _ringkasan = OjekService.hitungTarif(total);
      _sibukTarif = false;
    });
  }

  Future<void> _kirim() async {
    FocusScope.of(context).unfocus();
    if (!(_form.currentState?.validate() ?? false)) {
      _snak('Masih ada kolom yang perlu diperbaiki.', galat: true);
      return;
    }
    final String? pesan = OjekService.validasi(
      lokasiJemput: _jemput.text,
      lokasiTujuan: _tujuan.text,
    ).pesan;
    if (pesan != null) {
      _snak(pesan, galat: true);
      return;
    }
    if (!_ringkasan.adaJarak) {
      _snak(
        _statusLokasi() ??
            'Tarif belum dihitung. Tunggu sampai jarak muncul.',
        galat: true,
      );
      return;
    }
    Haptics.medium();
    setState(() => _sibukKirim = true);

    final KunciWarga kunci = await ref.read(kunciWargaProvider.future);
    final Session sesi = ref.read(sessionProvider);
    final OjekService svc = ref.read(ojekServiceProvider);

    final Hasil<OrderRingkas> hasil = await svc.createOrder(
      kunciWarga: kunci.nilai,
      wargaNama: sesi.user?.name.isNotEmpty == true ? sesi.user!.name : 'Warga KUBAR',
      wargaNomor: sesi.user?.phone ?? '',
      lokasiJemput: _jemput.text,
      titikJemput: _titikJemput,
      lokasiTujuan: _tujuan.text,
      titikTujuan: _titikTujuan,
      ringkasan: _ringkasan,
      mitra: _mitra,
      catatan: _catatan.text,
      metodeBayar: _bayar,
    );

    if (!mounted) return;
    setState(() => _sibukKirim = false);
    if (!hasil.berhasil) {
      Haptics.error();
      _snak(hasil.galat?.pesan ?? 'Order gagal dikirim.', galat: true);
      return;
    }
    Haptics.success();
    await ref.read(orderProvider.notifier).tambah(hasil.data!);
    if (!mounted) return;
    context.push('/order/tracking/${hasil.data!.jenis.name}/${hasil.data!.id}');
  }

  void _snak(String pesan, {bool galat = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: <Widget>[
              AppIcon(
                galat ? Ik.xCircle : Ik.checkCircle,
                size: 18,
                color: AppColors.white,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(pesan)),
            ],
          ),
          backgroundColor: galat ? AppColors.error : AppColors.success,
        ),
      );
  }
}

// ------------------------------------------------------------- potong layar

/// Rincian jarak dan tarif ojek di bawah peta.
class _RincianJarak extends StatelessWidget {
  const _RincianJarak({
    required this.kmMitra,
    required this.kmAntar,
    required this.adaPosisiMitra,
    required this.ringkasan,
    required this.sibuk,
    required this.status,
    required this.onHitungUlang,
  });

  final double kmMitra;
  final double kmAntar;
  final bool adaPosisiMitra;
  final RingkasanTarif ringkasan;
  final bool sibuk;
  final String? status;
  final VoidCallback onHitungUlang;

  static String _km(double v) => '${v.toStringAsFixed(1)} km';

  @override
  Widget build(BuildContext context) {
    final TextStyle? kecil = context.text.bodySmall
        ?.copyWith(color: context.semantic.textSecondary);

    Widget baris(String kiri, String kanan, {bool tebal = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(kiri,
                    style: tebal ? context.text.titleSmall : kecil),
              ),
              Text(kanan, style: tebal ? context.text.titleSmall : kecil),
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (ringkasan.adaJarak) ...<Widget>[
          baris(
            'Jarak mitra ke jemput',
            adaPosisiMitra ? _km(kmMitra) : 'posisi mitra belum ada',
          ),
          baris('Jarak jemput ke tujuan', _km(kmAntar)),
          baris('Total jarak', _km(ringkasan.jarakKm), tebal: true),
          baris('Tarif', rupiah(ringkasan.tarif), tebal: true),
        ] else
          Text(
            status ?? 'Isi alamat jemput dan tujuan untuk melihat jarak.',
            style: kecil,
          ),
        if (ringkasan.adaJarak && status != null)
          Text(status!, style: kecil),
        Align(
          alignment: Alignment.centerRight,
          child: sibuk
              ? const Padding(
                  padding: EdgeInsets.all(AppSpacing.sm),
                  child: LoadingDots(size: 7),
                )
              : TextButton.icon(
                  onPressed: onHitungUlang,
                  icon: const AppIcon(Ik.refresh, size: 16),
                  label: const Text('Hitung ulang'),
                ),
        ),
      ],
    );
  }
}

class _IntroOjek extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      color: AppColors.accent.withValues(alpha: 0.08),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppIcon(Ik.motorcycle, size: 26, color: AppColors.accent),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Ojek komunitas untuk Kuningan Barat dan sekitarnya. '
              'Tarif dari total jarak (mitra ke titik jemput + jemput ke tujuan). Bayar tunai ke mitra setelah sampai.',
              style: context.text.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldOjek extends StatelessWidget {
  const _FieldOjek({
    required this.controller,
    required this.label,
    required this.hint,
    required this.ikon,
    this.validator,
    this.onChanged,
    this.maksBaris = 1,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final Ik ikon;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final int maksBaris;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      validator: validator,
      maxLines: maksBaris,
      textInputAction:
          maksBaris > 1 ? TextInputAction.newline : TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: AppIcon(ikon, size: 20),
      ),
    );
  }
}

class _TombolLokasiOjek extends StatelessWidget {
  const _TombolLokasiOjek({
    required this.detail,
    required this.sibuk,
    required this.onTekan,
  });

  final String detail;
  final bool sibuk;
  final VoidCallback onTekan;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: sibuk ? null : onTekan,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: context.colors.primary),
        ),
        child: Row(
          children: <Widget>[
            if (sibuk)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              AppIcon(Ik.qrScan, size: 20, color: context.colors.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Pakai lokasi HP sekarang', style: context.text.bodyMedium),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    style: context.text.bodySmall
                        ?.copyWith(color: context.semantic.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pilih mitra: "biarkan sistem" atau pilih sendiri.
class _PilihanMitra extends ConsumerWidget {
  const _PilihanMitra({
    required this.mitra,
    required this.terpilih,
    required this.onUbah,
  });

  final List<MitraJasa> mitra;
  final MitraJasa? terpilih;
  final ValueChanged<MitraJasa?> onUbah;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: <Widget>[
        _BarisMitra(
          nama: 'Pilih otomatis',
          detail: 'Mitra terdekat yang sedang online',
          aktif: true,
          terpilih: terpilih == null,
          onTekan: () => onUbah(null),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final MitraJasa m in mitra) ...<Widget>[
          _BarisMitra(
            nama: m.nama,
            detail: '${m.peran.label} · ${m.rating.toStringAsFixed(1)}',
            aktif: true,
            terpilih: terpilih?.id == m.id,
            onTekan: () => onUbah(m),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: context.semantic.line,
            borderRadius: BorderRadius.circular(AppRadius.field),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AppIcon(Ik.shieldCheck,
                  size: 16, color: context.semantic.textSecondary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Daftar mitra masih data contoh. Begitu backend menyala, '
                  'nama dan rating di sini diambil dari server.',
                  style: context.text.bodySmall
                      ?.copyWith(color: context.semantic.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BarisMitra extends StatelessWidget {
  const _BarisMitra({
    required this.nama,
    required this.detail,
    required this.aktif,
    required this.terpilih,
    required this.onTekan,
  });

  final String nama;
  final String detail;
  final bool aktif;
  final bool terpilih;
  final VoidCallback onTekan;

  @override
  Widget build(BuildContext context) {
    final Color w = context.colors.primary;
    return InkWell(
      onTap: aktif
          ? () {
              Haptics.selection();
              onTekan();
            }
          : null,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: terpilih ? w.withValues(alpha: 0.08) : context.semantic.card,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: terpilih ? w : context.semantic.line,
            width: terpilih ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: <Widget>[
            AppIcon(Ik.person, size: 22, color: w),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(nama, style: context.text.bodyMedium),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    style: context.text.bodySmall
                        ?.copyWith(color: context.semantic.textSecondary),
                  ),
                ],
              ),
            ),
            if (terpilih) AppIcon(Ik.checkCircle, size: 20, color: w),
          ],
        ),
      ),
    );
  }
}

class _TombolKirimOjek extends StatelessWidget {
  const _TombolKirimOjek({
    required this.sibuk,
    required this.total,
    required this.onTekan,
  });

  final bool sibuk;
  final double total;
  final VoidCallback onTekan;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.md),
        child: PrimaryButton(
          label: total > 0 ? 'Pesan ojek (${rupiah(total)})' : 'Pesan ojek',
          icon: Ik.motorcycle,
          loading: sibuk,
          onPressed: sibuk ? null : onTekan,
        ),
      ),
    );
  }
}