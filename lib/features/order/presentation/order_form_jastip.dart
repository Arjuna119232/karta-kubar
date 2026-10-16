import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/auth/session.dart';
import '../../../core/data/hasil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../shared/models/order.dart';
import '../../../shared/models/order_ringkas.dart';
import '../../../shared/models/order_tracking.dart';
import '../../../shared/services/jastip_service.dart';
import '../../../shared/services/lokasi_service.dart';
import '../../../shared/services/tarif_service.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_icon.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/shimmer_box.dart';
import '../data/order_state.dart';
import 'widgets_order.dart';
import '../../mitra_usaha/domain/mitra_usaha.dart';

/// Form order JASTIP: warga menulis barang, lokasi beli, alamat antar.
///
/// Alur yang tampil sengaja dibuat pendek: isi barang, cek fee, kirim.
class JastipFormScreen extends ConsumerStatefulWidget {
  const JastipFormScreen({super.key, this.tokoAwal});

  /// Mitra usaha yang dipilih dari katalog; mengisi lokasi beli otomatis.
  final MitraUsaha? tokoAwal;

  @override
  ConsumerState<JastipFormScreen> createState() => _JastipFormScreenState();
}

class _JastipFormScreenState extends ConsumerState<JastipFormScreen> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _barang = TextEditingController();
  final TextEditingController _lokasiBeli = TextEditingController();
  final TextEditingController _alamatAntar = TextEditingController();
  final TextEditingController _catatan = TextEditingController();
  final TextEditingController _perkiraanHarga = TextEditingController();

  int _qty = 1;
  MetodeBayar _bayar = MetodeBayar.qris;
  File? _foto;
  TitikPeta _titikBeli = const TitikPeta(lat: 0, lng: 0);
  TitikPeta _titikAntar = const TitikPeta(lat: 0, lng: 0);
  bool _sibukLokasi = false;
  bool _sibukKirim = false;
  bool _sibukTarif = false;
  RingkasanTarif _ringkasan = RingkasanTarif.kosong;

  /// Alamat yang terakhir berhasil dipecah jadi koordinat. Kalau teks berubah,
  /// titik lama sudah tidak berlaku dan harus dibuang.
  String _teksBeli = '';
  String _teksAntar = '';
  bool _mencariBeli = false;
  bool _mencariAntar = false;
  Timer? _jedaBeli;
  Timer? _jedaAntar;
  int _urutan = 0;
  List<TitikPeta> _garis = const <TitikPeta>[];

  @override
  void initState() {
    super.initState();
    _alamatAntar.text = '';
    final MitraUsaha? toko = widget.tokoAwal;
    if (toko != null) {
      _lokasiBeli.text = toko.lokasiBeliTeks;
      _titikBeli = toko.titik;
      _teksBeli = toko.lokasiBeliTeks;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _hitungUlang();
      });
    }
  }

  @override
  void dispose() {
    _jedaBeli?.cancel();
    _jedaAntar?.cancel();
    _barang.dispose();
    _lokasiBeli.dispose();
    _alamatAntar.dispose();
    _catatan.dispose();
    _perkiraanHarga.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pesan Jastip')),
      body: SafeArea(
        top: false,
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen, 8, AppSpacing.screen, 120),
            children: <Widget>[
              _Intro(),
              const SizedBox(height: AppSpacing.section),
              SubOrder('Barang yang dititipkan', ikon: Ik.package),
              _Field(
                controller: _barang,
                label: 'Nama barang',
                hint: 'Contoh: Beras 5 kg, Minyak goreng 2 L',
                ikon: Ik.package,
                validator: (String? v) => _wajib(v, 'Nama barang'),
              ),
              const SizedBox(height: AppSpacing.md),
              _JumlahBarang(
                nilai: _qty,
                onUbah: (int n) => setState(() => _qty = n),
              ),
              const SizedBox(height: AppSpacing.section),
              SubOrder('Lokasi dan tujuan', ikon: Ik.place),
              _Field(
                controller: _lokasiBeli,
                label: 'Lokasi beli',
                hint: 'Contoh: Pasar Minggu, Jalan Melati No 12',
                ikon: Ik.cart,
                onChanged: (_) => _beliBerubah(),
                validator: (String? v) => _wajib(v, 'Lokasi beli', min: 3),
              ),
              const SizedBox(height: AppSpacing.md),
              _TombolLokasi(
                label: 'Tandai lokasi beli di peta',
                detail: _titikBeli.valid
                    ? _titikBeli.teks
                    : 'Belum ditandai. Kalau dilewati, fee memakai perkiraan kasar.',
                sibuk: _sibukLokasi,
                onTekan: _tandaiLokasiBeli,
              ),
              const SizedBox(height: AppSpacing.md),
              _Field(
                controller: _alamatAntar,
                label: 'Alamat antar',
                hint: 'Contoh: Jl. Kenanga No 4, RT 05 RW 02',
                ikon: Ik.home,
                onChanged: (_) => _antarBerubah(),
                validator: (String? v) => _wajib(v, 'Alamat antar', min: 5),
              ),
              const SizedBox(height: AppSpacing.md),
              _PetaRingkas(
                judul: 'Perkiraan jalur',
                titik: <TitikPeta>[_titikBeli, _titikAntar],
                garis: _garis.length > 1 ? _garis : null,
              ),
              const SizedBox(height: AppSpacing.section),
              SubOrder('Foto referensi (opsional)', ikon: Ik.addPhoto),
              _PemilihFoto(
                file: _foto,
                onPilih: _pilihFoto,
                onHapus: _foto == null
                    ? null
                    : () => setState(() => _foto = null),
              ),
              const SizedBox(height: AppSpacing.section),
              SubOrder('Catatan untuk mitra', ikon: Ik.chat),
              _Field(
                controller: _catatan,
                label: 'Catatan',
                hint: 'Warna, merek, atau hal lain yang perlu mitra tahu',
                ikon: Ik.chat,
                maksBaris: 3,
              ),
              const SizedBox(height: AppSpacing.section),
              SubOrder('Perkiraan biaya', ikon: Ik.wallet),
              _Field(
                controller: _perkiraanHarga,
                label: 'Perkiraan harga barang (opsional)',
                hint: '0',
                ikon: Ik.wallet,
                keyboard: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.md),
              _TarifCard(
                ringkasan: _ringkasan,
                sibuk: _sibukTarif || _mencariBeli || _mencariAntar,
                status: _statusLokasi(),
                onHitungUlang: _hitungUlang,
              ),
              const SizedBox(height: AppSpacing.section),
              SubOrder('Pembayaran', ikon: Ik.cash),
              KartuBayar(
                dipilih: _bayar,
                qrisAktif: true,
                keteranganQris:
                    'Barang dibayar via QRIS. Scan QRIS yang dikirim mitra '
                    'atau toko. Fee antar dibayar tunai ke mitra.',
                keteranganCash:
                    'Barang dan fee antar dibayar tunai ke mitra',
                onUbah: (MetodeBayar m) {
                  setState(() => _bayar = m);
                },
              ),
              const SizedBox(height: AppSpacing.section),
              _CatatanJujur(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _TombolKirim(
        sibuk: _sibukKirim,
        total: TarifService.total(
          _ringkasan.tarif,
          double.tryParse(_perkiraanHarga.text) ?? 0,
        ),
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

  Future<void> _pilihFoto() async {
    try {
      Haptics.light();
      final ImagePicker picker = ImagePicker();
      final XFile? pilihan = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 82,
      );
      if (pilihan == null) return;
      final Directory dasar = await getApplicationDocumentsDirectory();
      final Directory folder = Directory('${dasar.path}/jastip');
      if (!await folder.exists()) await folder.create(recursive: true);
      final String nama = 'ref-${DateTime.now().millisecondsSinceEpoch}.jpg';
      final File berkas = File('${folder.path}/$nama');
      await File(pilihan.path).copy(berkas.path);
      if (!mounted) return;
      setState(() => _foto = berkas);
      Haptics.success();
    } catch (e) {
      _snak('Tidak bisa mengambil foto: $e');
    }
  }

  Future<void> _tandaiLokasiBeli() async {
    setState(() => _sibukLokasi = true);
    final LokasiService svc = ref.read(lokasiServiceProvider);
    final Hasil<TitikPeta> hasil = await svc.posisiSaya();
    if (!mounted) return;
    setState(() => _sibukLokasi = false);
    if (!hasil.berhasil) {
      _snak(hasil.galat?.pesan ?? 'Gagal membaca lokasi.');
      return;
    }
    setState(() {
      _titikBeli = hasil.data!;
      _lokasiBeli.text = hasil.data!.teks;
      _teksBeli = hasil.data!.teks;
    });
    await _hitungUlang();
  }

  /// Hitung ulang fee setiap kali lokasi berubah.
  // ------------------------------------------------------- lokasi & tarif

  /// Pesan bila alamat sudah diisi tetapi belum ketemu di peta.
  String? _statusLokasi() {
    if (_mencariBeli || _mencariAntar) return 'Mencari alamat di peta...';
    if (_lokasiBeli.text.trim().length >= 3 && !_titikBeli.valid) {
      return 'Lokasi beli belum ketemu di peta. Tulis lebih lengkap, atau tekan '
          'ikon lokasi di bawah.';
    }
    if (_alamatAntar.text.trim().length >= 5 && !_titikAntar.valid) {
      return 'Alamat antar belum ketemu di peta. Tulis lebih lengkap '
          '(mis. nama jalan + nomor + RT/RW).';
    }
    return null;
  }

  /// Alamat beli berubah: titik lama dibuang, cari ulang setelah jeda.
  ///
  /// Dulu pencarian dibatasi "1x per 4 detik" sehingga kata terakhir yang
  /// diketik tidak pernah dicari, alamat tidak pernah punya koordinat, dan fee
  /// jatuh ke harga minimum yang tidak benar.
  void _beliBerubah() {
    final String teks = _lokasiBeli.text.trim();
    if (teks != _teksBeli && _titikBeli.valid) {
      setState(() => _titikBeli = const TitikPeta(lat: 0, lng: 0));
    }
    _jedaBeli?.cancel();
    if (teks.length < 3 || teks == _teksBeli) {
      setState(() => _mencariBeli = false);
      _hitungUlang();
      return;
    }
    setState(() => _mencariBeli = true);
    _jedaBeli = Timer(const Duration(milliseconds: 700), _cariBeli);
  }

  Future<void> _cariBeli() async {
    final String kueri = _lokasiBeli.text.trim();
    final List<TitikPeta> found =
        await ref.read(lokasiServiceProvider).cariAlamat(kueri);
    if (!mounted || kueri != _lokasiBeli.text.trim()) return;
    setState(() {
      _mencariBeli = false;
      if (found.isNotEmpty) {
        _titikBeli = found.first;
        _teksBeli = kueri;
      }
    });
    await _hitungUlang();
  }

  /// Alamat antar berubah: sama seperti lokasi beli.
  void _antarBerubah() {
    final String teks = _alamatAntar.text.trim();
    if (teks != _teksAntar && _titikAntar.valid) {
      setState(() => _titikAntar = const TitikPeta(lat: 0, lng: 0));
    }
    _jedaAntar?.cancel();
    if (teks.length < 5 || teks == _teksAntar) {
      setState(() => _mencariAntar = false);
      _hitungUlang();
      return;
    }
    setState(() => _mencariAntar = true);
    _jedaAntar = Timer(const Duration(milliseconds: 700), _cariAntar);
  }

  Future<void> _cariAntar() async {
    final String kueri = _alamatAntar.text.trim();
    final List<TitikPeta> found =
        await ref.read(lokasiServiceProvider).cariAlamat(kueri);
    if (!mounted || kueri != _alamatAntar.text.trim()) return;
    setState(() {
      _mencariAntar = false;
      if (found.isNotEmpty) {
        _titikAntar = found.first;
        _teksAntar = kueri;
      }
    });
    await _hitungUlang();
  }

  /// Fee antar dari jarak lokasi beli -> alamat antar.
  ///
  /// Tanpa kedua koordinat, tarif TIDAK ditampilkan. Angka minimum yang
  /// muncul tanpa koordinat pernah mengecoh warga, jadi lebih baik kosong.
  Future<void> _hitungUlang() async {
    final int urutan = ++_urutan;
    if (!_titikBeli.valid || !_titikAntar.valid) {
      if (!mounted) return;
      setState(() {
        _ringkasan = RingkasanTarif.kosong;
        _garis = const <TitikPeta>[];
        _sibukTarif = false;
      });
      return;
    }
    setState(() => _sibukTarif = true);
    final LokasiService svc = ref.read(lokasiServiceProvider);
    final Rute rute = await svc.rute(_titikBeli, _titikAntar);
    // Ada perhitungan yang lebih baru: abaikan hasil ini.
    if (!mounted || urutan != _urutan) return;
    setState(() {
      _ringkasan = ref.read(tarifServiceProvider).ringkasanJastip(rute);
      _garis = rute.garis ?? const <TitikPeta>[];
      _sibukTarif = false;
    });
  }

  Future<void> _kirim() async {
    FocusScope.of(context).unfocus();
    if (!(_form.currentState?.validate() ?? false)) {
      _snak('Masih ada kolom yang perlu diperbaiki.');
      return;
    }
    final String? pesan = JastipService.validasi(
      barang: _barang.text,
      qty: _qty,
      lokasiBeli: _lokasiBeli.text,
      alamatAntar: _alamatAntar.text,
    ).pesan;
    if (pesan != null) {
      _snak(pesan);
      return;
    }
    if (!_ringkasan.adaJarak) {
      _snak(
        _statusLokasi() ??
            'Fee belum dihitung. Tulis lokasi beli dan alamat antar sampai '
                'keduanya ketemu di peta.',
        galat: true,
      );
      return;
    }
    Haptics.medium();
    setState(() => _sibukKirim = true);

    final KunciWarga kunci = await ref.read(kunciWargaProvider.future);
    final Session sesi = ref.read(sessionProvider);
    final JastipService svc = ref.read(jastipServiceProvider);

    final Hasil<OrderRingkas> hasil = await svc.createOrder(
      kunciWarga: kunci.nilai,
      wargaNama: sesi.user?.name.isNotEmpty == true ? sesi.user!.name : 'Warga KUBAR',
      wargaNomor: sesi.user?.phone ?? '',
      barang: _barang.text,
      qty: _qty,
      lokasiBeli: _lokasiBeli.text,
      titikBeli: _titikBeli,
      alamatAntar: _alamatAntar.text,
      titikAntar: _titikAntar,
      ringkasan: _ringkasan,
      catatan: _catatan.text,
      fotoReferensi: _foto?.path,
      estimasiBiayaBarang: double.tryParse(_perkiraanHarga.text),
      metodeBayar: _bayar,
    );

    if (!mounted) return;
    setState(() => _sibukKirim = false);
    if (!hasil.berhasil) {
      Haptics.error();
      _snak(hasil.galat?.pesan ?? 'Order gagal dikirim.');
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

class _Intro extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      color: AppColors.primary.withValues(alpha: 0.08),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppIcon(Ik.handHeart, size: 26, color: context.colors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Titip barang dari toko atau pasar di sekitar Kuningan Barat. '
              'Mitra yang menerima akan belanja dan mengantar ke alamatmu. '
              'Fee antar dihitung dari jarak toko ke alamatmu. Barang dibayar via QRIS.',
              style: context.text.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.ikon,
    this.validator,
    this.onChanged,
    this.maksBaris = 1,
    this.keyboard,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final Ik ikon;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final int maksBaris;
  final TextInputType? keyboard;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      validator: validator,
      maxLines: maksBaris,
      keyboardType: keyboard,
      textInputAction:
          maksBaris > 1 ? TextInputAction.newline : TextInputAction.next,
      inputFormatters: keyboard == TextInputType.number
          ? <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(9),
            ]
          : <TextInputFormatter>[
              if (maksBaris == 1) LengthLimitingTextInputFormatter(160),
            ],
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: AppIcon(ikon, size: 20),
      ),
    );
  }
}

class _JumlahBarang extends StatelessWidget {
  const _JumlahBarang({required this.nilai, required this.onUbah});

  final int nilai;
  final ValueChanged<int> onUbah;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: <Widget>[
          AppIcon(Ik.package, size: 20, color: context.semantic.textSecondary),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text('Jumlah barang', style: context.text.bodyMedium)),
          _TombolBulat(
            ikon: Ik.minus,
            aktif: nilai > 1,
            tooltip: 'Kurangi jumlah',
            onTekan: () {
              Haptics.light();
              onUbah(nilai - 1);
            },
          ),
          SizedBox(
            width: 40,
            child: Text(
              '$nilai',
              textAlign: TextAlign.center,
              style: context.text.titleMedium,
            ),
          ),
          _TombolBulat(
            ikon: Ik.plus,
            aktif: nilai < 99,
            tooltip: 'Tambah jumlah',
            onTekan: () {
              Haptics.light();
              onUbah(nilai + 1);
            },
          ),
        ],
      ),
    );
  }
}

/// Tombol bulat kecil untuk penghitung jumlah.
class _TombolBulat extends StatelessWidget {
  const _TombolBulat({
    required this.ikon,
    required this.aktif,
    required this.tooltip,
    required this.onTekan,
  });

  final Ik ikon;
  final bool aktif;
  final String tooltip;
  final VoidCallback onTekan;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: aktif
            ? context.colors.primary.withValues(alpha: 0.12)
            : context.semantic.line,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: aktif ? onTekan : null,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: AppIcon(
              ikon,
              size: 20,
              color: aktif ? context.colors.primary : context.semantic.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _TombolLokasi extends StatelessWidget {
  const _TombolLokasi({
    required this.label,
    required this.detail,
    required this.sibuk,
    required this.onTekan,
  });

  final String label;
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
          border: Border.all(color: context.semantic.line),
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
              AppIcon(Ik.place, size: 20, color: context.colors.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(label, style: context.text.bodyMedium),
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

class _PetaRingkas extends StatelessWidget {
  const _PetaRingkas({
    required this.judul,
    required this.titik,
    this.garis,
  });

  final String judul;
  final List<TitikPeta> titik;

  /// Garis rute jalan dari OSRM. Null = garis lurus antar dua titik.
  final List<TitikPeta>? garis;

  @override
  Widget build(BuildContext context) {
    final List<TitikPeta> sah = titik.where((TitikPeta t) => t.valid).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(judul, style: context.text.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        // Key ikut berubah bersama titiknya supaya kamera peta ikut pindah
        // ke lokasi yang baru, bukan berhenti di tempat lama.
        PetaOrder(
          key: ValueKey<String>('${sah.length}|${garis?.length ?? 0}'),
          titik: titik,
          garis: garis ?? titik,
          tinggi: 170,
        ),
      ],
    );
  }
}

class _PemilihFoto extends StatelessWidget {
  const _PemilihFoto({
    required this.file,
    required this.onPilih,
    required this.onHapus,
  });

  final File? file;
  final VoidCallback onPilih;
  final VoidCallback? onHapus;

  @override
  Widget build(BuildContext context) {
    if (file == null) {
      return SizedBox(
        width: double.infinity,
        child: PrimaryButton(
          label: 'Pilih foto barang',
          icon: Ik.addPhoto,
          tone: PrimaryButtonTone.outlined,
          onPressed: onPilih,
        ),
      );
    }
    return Stack(
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Image.file(
            file!,
            width: double.infinity,
            height: 180,
            fit: BoxFit.cover,
            errorBuilder: (BuildContext c, Object e, StackTrace? s) =>
                const ShimmerBox(height: 180),
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: Material(
            color: AppColors.black.withValues(alpha: 0.55),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onHapus,
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: AppIcon(Ik.broom, size: 18, color: AppColors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TarifCard extends StatelessWidget {
  const _TarifCard({
    required this.ringkasan,
    required this.sibuk,
    required this.onHitungUlang,
    this.status,
  });

  final RingkasanTarif ringkasan;
  final bool sibuk;
  final VoidCallback onHitungUlang;

  /// Kenapa fee belum muncul (alamat belum ketemu di peta).
  final String? status;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        KartuTarif(
          ringkasan: ringkasan,
          judul: 'Fee antar jastip',
          catatanTambahan: ringkasan.adaJarak
              ? ringkasan.sumberTeks
              : (status ?? 'Isi lokasi beli dan alamat antar dulu.'),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: PrimaryButton(
            label: 'Hitung ulang fee',
            icon: Ik.refresh,
            tone: PrimaryButtonTone.outlined,
            onPressed: sibuk ? null : onHitungUlang,
          ),
        ),
      ],
    );
  }
}

class _CatatanJujur extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.semantic.line,
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppIcon(Ik.shieldCheck, size: 18, color: context.semantic.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Fee dihitung dari jarak dan bisa berubah kalau lokasi beli atau '
              'alamat antar diperbaiki. Fee antar hanya dari jarak toko ke alamat antar '
              '(bukan dari posisi mitra). Barang dibayar via QRIS.',
              style: context.text.bodySmall
                  ?.copyWith(color: context.semantic.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _TombolKirim extends StatelessWidget {
  const _TombolKirim({
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
          label: total > 0 ? 'Kirim order (${rupiah(total)})' : 'Kirim order',
          icon: Ik.cart,
          loading: sibuk,
          onPressed: sibuk ? null : onTekan,
        ),
      ),
    );
  }
}