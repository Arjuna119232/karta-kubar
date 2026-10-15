import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/boot.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_icon.dart';
import '../../../shared/widgets/onboarding_art.dart';
import '../../../shared/widgets/primary_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  /// Urutan: aspirasi, komunitas, terhubung (sesuai [OnbArt]).
  static const List<_Slide> _slides = <_Slide>[
    _Slide(
      art: OnbArt.aspirasi,
      title: 'Sampaikan tanpa ribet',
      body:
          'Kirim aspirasi, laporan masalah, sampai kondisi darurat keamanan. Semua tercatat dan bisa dilacak statusnya.',
    ),
    _Slide(
      art: OnbArt.komunitas,
      title: 'Selamat datang di KUNBAR Connect',
      body:
          'Untuk seluruh warga Kuningan Barat — dari anak muda, orang tua, RT/RW, UMKM, sampai pengurus kelurahan.',
    ),
    _Slide(
      art: OnbArt.terhubung,
      title: 'Terhubung & terbuka',
      body:
          'Baca pengumuman RT/RW, lihat agenda, dukung UMKM warga, dan pesan fasilitas balai tanpa datang langsung.',
    ),
  ];

  bool get _isLast => _page == _slides.length - 1;

  Future<void> _finish() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kPrefsOnboardingSeen, true);
    if (!mounted) return;
    context.go('/auth');
  }

  void _next() {
    if (_isLast) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _isLast ? null : _finish,
                child: const Text('Lewati'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (int i) => setState(() => _page = i),
                itemBuilder: (BuildContext context, int i) => AnimatedBuilder(
                  animation: _controller,
                  // Parallax: slide bergeser lebih lambat dari jari dan
                  // memudar saat meninggalkan layar.
                  builder: (BuildContext context, Widget? child) {
                    double d = 0;
                    if (_controller.hasClients &&
                        _controller.position.haveDimensions) {
                      d = (_controller.page ?? _page.toDouble()) - i;
                    }
                    return Opacity(
                      opacity: (1 - d.abs() * 0.6).clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(d * -60, 0),
                        child: child,
                      ),
                    );
                  },
                  child: _SlideView(
                    slide: _slides[i],
                    // Hanya slide yang sedang terlihat yang menjalankan
                    // animasi masuknya.
                    aktif: i == _page,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen + 8, 0, AppSpacing.screen + 8, 24),
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List<Widget>.generate(_slides.length, (int i) {
                      final bool active = i == _page;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutBack,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: active ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active
                              ? context.colors.primary
                              : context.semantic.line,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 22),
                  PrimaryButton(
                    label: _isLast ? 'Masuk KUNBAR Connect' : 'Lanjut',
                    icon: _isLast ? Ik.check : null,
                    onPressed: _next,
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

class _Slide {
  const _Slide({
    required this.art,
    required this.title,
    required this.body,
  });

  final OnbArt art;
  final String title;
  final String body;

  /// Warna cahaya lembut di belakang ilustrasi.
  Color get tint => art.warna;
}

/// Satu sampul onboarding.
///
/// Semua elemen masuk berurutan dari bawah dengan lengkung emphasized, lalu
/// ilustrasinya melayang pelan-pelan. Tinggi ilustrasi mengikuti lebar layar
/// (viewBox ilustrasi 320x240), bukan angka mati 230 yang bisa meluber di HP
/// kecil atau terlihat kecil di HP besar.
class _SlideView extends StatefulWidget {
  const _SlideView({required this.slide, required this.aktif});

  final _Slide slide;
  final bool aktif;

  @override
  State<_SlideView> createState() => _SlideViewState();
}

class _SlideViewState extends State<_SlideView>
    with TickerProviderStateMixin {
  late final AnimationController _masuk = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 860),
  );
  late final AnimationController _ngambang = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3800),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    if (widget.aktif) _masuk.forward();
  }

  @override
  void didUpdateWidget(_SlideView old) {
    super.didUpdateWidget(old);
    // Dik ketika: ulangi animasi dari awal.
    if (widget.aktif && !old.aktif) _masuk.forward(from: 0);
  }

  @override
  void dispose() {
    _masuk.dispose();
    _ngambang.dispose();
    super.dispose();
  }

  /// Nilai 0..1 untuk potongan animasi antara [mulai] dan [akhir].
  double _fase(double mulai, double akhir) =>
      ((_masuk.value - mulai) / (akhir - mulai)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    // WAJIB didengarkan, bukan hanya dibaca `.value` di dalam build.
    // Kalau tidak ada listener, controller beranimasi tapi widget tidak pernah
    // dibangun ulang -> opacity tetap 0 -> sampul tampil KOSONG.
    return AnimatedBuilder(
      animation: _masuk,
      builder: (_, __) => AnimatedBuilder(
        animation: _ngambang,
        builder: (_, __) => _isi(context),
      ),
    );
  }

  Widget _isi(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints b) {
        final double u = (MediaQuery.sizeOf(context).shortestSide / 360)
            .clamp(1.0, 1.22);
        final double pad = 28 * u;
        final double lebar = b.maxWidth - pad * 2;
        // Rasio viewBox ilustrasi 320 x 240 = 4:3.
        final double tinggiIlus = (lebar / (4 / 3)).clamp(150.0, 250.0);
        final double jarakTeks = 26 * u;

        // Posisi ilustrasi DIKUNCI, tidak ikut bergerak karena panjang judul
        // tiap sampul berbeda. Kalau blok semuanya di-center, sampul dengan
        // judul 2 baris membuat ilustrasi melompat ~27dp saat digeser.
        // Sisa tinggi dibagi dua: separuh untuk sumber daya teks.
        final double tinggiTeks = b.maxHeight * 0.46;
        final double atas =
            (b.maxHeight - tinggiTeks - tinggiIlus - jarakTeks).clamp(0.0, 96.0);

        final double vGlow = Curves.easeOut.transform(_fase(0.0, 0.90));
        final double vIlus = _fase(0.0, 1.0);
        final double vJudul = _fase(0.24, 0.88);
        final double vIsi = _fase(0.44, 1.0);
        final double angkat = _ngambang.value;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: pad),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: b.maxHeight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(height: atas),
                Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    // Cahaya lembut dengan warna tiap sampul.
                    Opacity(
                      opacity: vGlow,
                      child: Container(
                        width: tinggiIlus * 1.30,
                        height: tinggiIlus * 1.30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: <Color>[
                              widget.slide.tint.withValues(alpha: 0.16),
                              widget.slide.tint.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Melayang + sedikit zoom sangat lambat (efek Ken Burns).
                    Transform.translate(
                      offset: Offset(0, -5 * angkat),
                      child: Transform.scale(
                        scale: (0.88 + 0.12 * Curves.easeOutBack.transform(vIlus) +
                                0.035 * angkat)
                            .clamp(0.0, 1.05),
                        child: Opacity(
                          opacity: _fase(0.04, 0.60),
                          child: OnboardingArt(
                            widget.slide.art,
                            height: tinggiIlus,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: jarakTeks),
                // Slot teks: tingginya TEPAT sisa ruang di bawah ilustrasi.
                // Kalau(minHeight) memakai `tinggiTeks` saja, blok jadi lebih
                // tinggi dari area slide dan teks terdorong keluar layar.
                ConstrainedBox(
                  constraints: BoxConstraints(minHeight: tinggiTeks),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Opacity(
                        opacity: vJudul,
                        child: Transform.translate(
                          offset: Offset(0, 22 * (1 - vJudul)),
                          child: Text(
                            widget.slide.title,
                            textAlign: TextAlign.center,
                            style: context.text.headlineMedium,
                          ),
                        ),
                      ),
                      SizedBox(height: 12 * u),
                      Opacity(
                        opacity: vIsi,
                        child: Transform.translate(
                          offset: Offset(0, 22 * (1 - vIsi)),
                          child: Text(
                            widget.slide.body,
                            textAlign: TextAlign.center,
                            style: context.text.bodyLarge?.copyWith(
                              color: context.semantic.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
