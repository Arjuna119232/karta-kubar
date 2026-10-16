import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/session.dart';
import '../../../core/auth/user_role.dart';
import '../../../core/providers.dart';
import '../../../core/data/data_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_id.dart';
import '../../../core/utils/haptics.dart';
import '../../../shared/models/order_ringkas.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_icon.dart';
import '../../../shared/widgets/fade_slide_in.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/stat_tile.dart';

import '../../kegiatan/domain/kegiatan.dart';
import '../../order/data/order_state.dart';
import '../../order/presentation/order_history.dart';
import '../../shell/data/app_tabs.dart';
import '../../../shared/widgets/cover_pilih.dart';
import '../../../shared/widgets/berita_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Kegiatan> upcoming = (ref.watch(kegiatanProvider).valueOrNull ??
            const <Kegiatan>[])
        .where((Kegiatan a) => a.mendatang)
        .toList();
    final Session session = ref.watch(sessionProvider);
    final String nama = session.user?.name ?? 'Warga KUNBAR';

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: context.colors.primary,
        backgroundColor: context.semantic.card,
        onRefresh: () async {
          Haptics.medium();
          ref.invalidate(kegiatanProvider);
          ref.invalidate(beritaProvider);
          ref.invalidate(ringkasanBerandaProvider);
          ref.invalidate(orderProvider);
          await Future<void>.delayed(const Duration(milliseconds: 700));
        },
        child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen, 12, AppSpacing.screen, 96),
        children: <Widget>[
          FadeSlideIn(index: 0, child: _Greeting(nama: nama)),
          const SizedBox(height: 18),
          const FadeSlideIn(index: 1, child: _AnnouncementCarousel()),
          const SizedBox(height: 18),
          const FadeSlideIn(index: 2, child: _StatistikBeranda()),
          const SizedBox(height: 22),
          const _KartuDarurat(),
          const SizedBox(height: 22),
          const _MenuOrder(),
          const SizedBox(height: 22),
          const _OrderAktif(),
          const SizedBox(height: 22),
          const SectionHeader(title: 'Aksi Cepat'),
          const FadeSlideIn(index: 3, child: _QuickActions()),
          const SizedBox(height: 22),
          SectionHeader(
            title: 'Agenda Terdekat',
            actionLabel: 'Lihat semua',
            onAction: () =>
                ref.read(navigationIndexProvider.notifier).state =
                    indeksTab(session.efektif, 'Kegiatan'),
          ),
          for (final (int i, Kegiatan a) in upcoming.indexed)
            FadeSlideIn(
              index: 4 + i,
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.gap),
                child: _AgendaTile(activity: a),
              ),
            ),
          const SizedBox(height: 10),
          const SectionHeader(title: 'Berita Terbaru'),
          for (final (int i, Berita n) in
              (ref.watch(beritaProvider).valueOrNull ?? const <Berita>[]).indexed)
            FadeSlideIn(
              index: 6 + i,
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.gap),
                child: _NewsTile(item: n),
              ),
            ),
        ],
      ),
      ),
    );
  }
}

/// Angka anggota + kegiatan bulan ini, diambil dari repository.
///
/// Angkanya TIDAK dipatok di layar. Kalau backend belum ada, repository lokal
/// mengembalikan jumlah baris datanya sendiri; kalau pemuatannya gagal,
/// tampilannya "-" - bukan angka karangan yang terlihat seperti data asli.
class _StatistikBeranda extends ConsumerWidget {
  const _StatistikBeranda();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (int, int)? angka = ref.watch(ringkasanBerandaProvider).valueOrNull;

    return Row(
      children: <Widget>[
        Expanded(
          child: StatTile(
            icon: Ik.groups,
            value: angka == null ? '-' : '${angka.$1}',
            label: 'Anggota terdaftar',
            tint: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.gap),
        Expanded(
          child: StatTile(
            icon: Ik.calendarCheck,
            value: angka == null ? '-' : '${angka.$2}',
            label: 'Kegiatan bulan ini',
            tint: AppColors.accent,
          ),
        ),
      ],
    );
  }
}

/// Kartu "Lapor Darurat". Ditaruh di atas aksi cepat karena ini satu-satunya
/// tombol yang tidak boleh tergali: warna merah, tinggi, dan.copywriting-nya
/// langsung jelas tanpa perlu ditebak.
class _KartuDarurat extends StatelessWidget {
  const _KartuDarurat();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.push('/darurat'),
      color: AppColors.error,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      child: Row(
        children: <Widget>[
          const AppIcon(Ik.megaphone, size: 30, color: AppColors.white),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Lapor Darurat',
                  style: context.text.titleMedium?.copyWith(color: AppColors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  'Kebakaran, kecelakaan, kekerasan, atau banjir di RW 05.',
                  style: context.text.bodySmall
                      ?.copyWith(color: AppColors.heroSubtext),
                ),
              ],
            ),
          ),
          const AppIcon(Ik.chevronRight, color: AppColors.white),
        ],
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.nama});

  final String nama;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '${DateId.greeting()},',
                style: context.text.bodyMedium
                    ?.copyWith(color: context.semantic.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(nama, style: context.text.headlineMedium),
            ],
          ),
        ),
        _IconBadge(
          icon: Ik.bell,
          showDot: true,
          onTap: () {
            Haptics.selection();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Belum ada notifikasi baru')),
            );
          },
        ),
        const SizedBox(width: 10),
        Container(
          width: 46,
          height: 46,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[AppColors.primary, AppColors.success],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              _inisial(nama),
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, this.showDot = false, this.onTap});

  final Ik icon;
  final bool showDot;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Material(
          color: context.semantic.card,
          shape: CircleBorder(side: BorderSide(color: context.semantic.line)),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: const SizedBox(
              width: 46,
              height: 46,
              child: AppIcon(Ik.bell, size: 22),
            ),
          ),
        ),
        if (showDot)
          Positioned(
            right: 11,
            top: 11,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: context.colors.error,
                shape: BoxShape.circle,
                border: Border.all(color: context.semantic.card, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}

class _AnnouncementCarousel extends ConsumerStatefulWidget {
  const _AnnouncementCarousel();

  @override
  ConsumerState<_AnnouncementCarousel> createState() =>
      _AnnouncementCarouselState();
}

class _AnnouncementCarouselState extends ConsumerState<_AnnouncementCarousel> {
  final PageController _controller = PageController(viewportFraction: 0.92);
  int _page = 0;
  late final Future<List<Pengumuman>> _memuat;

  @override
  void initState() {
    super.initState();
    // Dimuat sekali. Sebelumnya dipanggil di build(), jadi tiap geser
    // halaman memicu pemuatan ulang.
    _memuat = ref.read(beritaProvider.notifier).pengumuman();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Pengumuman>>(
      future: _memuat,
      builder: (BuildContext context, AsyncSnapshot<List<Pengumuman>> snap) {
        final List<Pengumuman> items =
            snap.data ?? const <Pengumuman>[];
        return _carousel(items);
      },
    );
  }

  Widget _carousel(List<Pengumuman> items) {
    if (items.isEmpty) return const SizedBox(height: 158);
    return Column(
      children: <Widget>[
        SizedBox(
          height: 158,
          child: PageView.builder(
            controller: _controller,
            itemCount: items.length,
            onPageChanged: (int i) => setState(() => _page = i),
            itemBuilder: (BuildContext context, int i) {
              final Pengumuman a = items[i];
              return AnimatedBuilder(
                animation: _controller,
                builder: (BuildContext context, Widget? child) {
                  double d = 0;
                  if (_controller.hasClients &&
                      _controller.position.haveDimensions) {
                    d = (_controller.page ?? _page.toDouble()) - i;
                  }
                  final double skala = (1 - d.abs() * 0.06).clamp(0.9, 1.0);
                  return Transform.scale(scale: skala, child: child);
                },
                child: _AnnouncementCard(item: a),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List<Widget>.generate(items.length, (int i) {
            final bool active = i == _page;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 20 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: active
                    ? context.colors.primary
                    : context.semantic.line,
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.item});

  final Pengumuman item;

  @override
  Widget build(BuildContext context) {
    final List<Color> grad = context.semantic.heroGradient;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: grad,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              item.tag,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.08,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            item.judul,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.isi,
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.85),
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Row(
            children: <Widget>[
              AppIcon(Ik.megaphone,
                  color: AppColors.white.withValues(alpha: 0.9), size: 16),
              const SizedBox(width: 6),
              Text(
                'Pengumuman',
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              const AppIcon(Ik.arrowForward,
                  color: AppColors.white, size: 18),
            ],
          ),
        ],
      ),
    );
  }
}

/// Dua menu besar order: Jastip dan Ojek.
class _MenuOrder extends StatelessWidget {
  const _MenuOrder();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _KartuMenuOrder(
            judul: 'Jastip',
            keterangan: 'Titip belanja, diantar ke rumah',
            ikon: Ik.package,
            warna: AppColors.primary,
            onTekan: () => context.push('/jastip/form'),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _KartuMenuOrder(
            judul: 'Ojek',
            keterangan: 'Antar-jemput searah',
            ikon: Ik.motorcycle,
            warna: AppColors.accent,
            onTekan: () => context.push('/ojek/form'),
          ),
        ),
      ],
    );
  }
}

class _KartuMenuOrder extends StatelessWidget {
  const _KartuMenuOrder({
    required this.judul,
    required this.keterangan,
    required this.ikon,
    required this.warna,
    required this.onTekan,
  });

  final String judul;
  final String keterangan;
  final Ik ikon;
  final Color warna;
  final VoidCallback onTekan;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: warna.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () {
          Haptics.medium();
          onTekan();
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AppIcon(ikon, size: 26, color: warna),
              const SizedBox(height: AppSpacing.md),
              Text(judul, style: context.text.titleSmall),
              const SizedBox(height: 2),
              Text(
                keterangan,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodySmall
                    ?.copyWith(color: context.semantic.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Order yang masih berjalan. Kalau tidak ada, section ini disembunyikan
/// supaya beranda tidak penuh dengan pesan kosong.
class _OrderAktif extends ConsumerWidget {
  const _OrderAktif();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<OrderRingkas> aktif = ref.watch(orderAktifProvider);
    if (aktif.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SectionHeader(
          title: 'Order Berjalan',
          actionLabel: 'Lihat semua',
          onAction: () => context.push('/order/list'),
        ),
        SizedBox(
          width: double.infinity,
          child: OrderAktifCard(
            order: aktif.first,
            sisa: aktif.length - 1,
          ),
        ),
      ],
    );
  }
}

class _QuickActions extends ConsumerWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Setiap aksi disaring sesuai role. Tanpa penyaringan, tamu menekan
    // "Iuran" (tab "Kas" hanya untuk anggota) dan "Absen" (minimal
    // anggota) lalu hanya berakhir di layar "Akses perlu ...".
    final UserRole role = ref.watch(sessionProvider).efektif;
    final List<_QuickItem> items = <_QuickItem>[
      if (role.bisa(UserRole.anggota))
        _QuickItem(Ik.qrScan, 'Absen', AppColors.primary,
            () => context.push('/absen')),
      if (role.bisa(UserRole.anggota))
        _QuickItem(Ik.wallet, 'Iuran', AppColors.accent,
            () => _keTab(ref, 'Kas')),
      if (role.bisa(UserRole.warga))
        _QuickItem(Ik.chat, 'Aspirasi', AppColors.warning,
            () => context.push('/aspirasi')),
      _QuickItem(Ik.handHeart, 'UMKM', AppColors.social,
          () => context.push('/umkm')),
      // PUSH, bukan pindah tab: tab "Galeri" hanya ada untuk tamu/warga.
      // Anggota ke atas memakai tab "Kas", jadi tanpa rute /galeri mereka
      // tidak punya cara membuka Galeri sama sekali.
      _QuickItem(Ik.gallery, 'Galeri', AppColors.success,
          () => context.push('/galeri')),
      _QuickItem(Ik.cart, 'Mitra Usaha', AppColors.warning,
          () => context.push('/mitra-usaha')),
      _QuickItem(Ik.package, 'Jastip', AppColors.primary,
          () => context.push('/jastip/form')),
      _QuickItem(Ik.motorcycle, 'Ojek', AppColors.accent,
          () => context.push('/ojek/form')),
    ];

    // BUKAN `Row` dengan 5 `Expanded`: di layar 360 dp tiap kolom tinggal
    // ~66 dp, sehingga nama tombol seperti "Aspirasi" terpotong atau meluber.
    // `Wrap` + lebar item yang dihitung dari lebar layar selalu aman, dan
    // otomatis jadi 2 baris kalau tombolnya bertambah.
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        const double jarak = 8;
        // Jumlah kolom ikut jumlah tombol yang benar-benar tampil, supaya
        // tamu (cuma UMKM + Galeri) tidak mendapat baris setengah kosong.
        final int kolom = items.length <= 2 ? items.length : 4;
        final double lebarItem =
            (c.maxWidth - jarak * (kolom - 1)) / kolom;
        return Wrap(
          spacing: jarak,
          runSpacing: jarak,
          children: <Widget>[
            for (final _QuickItem it in items)
              SizedBox(
                width: lebarItem,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    Haptics.selection();
                    it.onTap();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      children: <Widget>[
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: it.tint.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(17),
                          ),
                          child: AppIcon(it.icon, color: it.tint, size: 24),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          it.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _keTab(WidgetRef ref, String label) {
    final UserRole role = ref.read(sessionProvider).efektif;
    ref.read(navigationIndexProvider.notifier).state = indeksTab(role, label);
  }
}

class _QuickItem {
  _QuickItem(this.icon, this.label, this.tint, this.onTap);
  final Ik icon;
  final String label;
  final Color tint;
  final VoidCallback onTap;
}

class _AgendaTile extends StatelessWidget {
  const _AgendaTile({required this.activity});

  final Kegiatan activity;

  @override
  Widget build(BuildContext context) {
    final bool selesai = !activity.mendatang;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: <Widget>[
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  activity.tanggal != null
                      ? '${activity.tanggal!.day}'
                      : '?',
                  style: context.text.titleLarge
                      ?.copyWith(color: context.colors.primary, height: 1),
                ),
                Text(
                  activity.tanggal != null
                      ? DateId.bulanSingkat(activity.tanggal!)
                      : '?',
                  style: context.text.labelSmall
                      ?.copyWith(color: context.colors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  activity.judul,
                  style: context.text.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: <Widget>[
                    AppIcon(Ik.place,
                        size: 14, color: context.semantic.textSecondary),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        activity.tanggal != null
                            ? '${activity.lokasi} · ${DateId.tanggal(activity.tanggal!)}'
                            : activity.lokasi,
                        style: context.text.bodySmall
                            ?.copyWith(color: context.semantic.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: selesai
                  ? context.semantic.line
                  : context.colors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              selesai ? 'Selesai' : DateId.hitungMundur(activity.tanggal),
              style: context.text.labelSmall?.copyWith(
                color: selesai
                    ? context.semantic.textSecondary
                    : context.colors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NewsTile extends StatelessWidget {
  const _NewsTile({required this.item});

  final Berita item;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () => bukaBerita(context, item),
      child: Row(
        children: <Widget>[
          AppCover(coverBerita(item.tag), width: 56, height: 56, radius: 14),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.judul,
                  style: context.text.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.sumber} · ${item.waktu}',
                  style: context.text.bodySmall
                      ?.copyWith(color: context.semantic.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          AppIcon(Ik.chevronRight,
              color: context.semantic.textSecondary),
        ],
      ),
    );
  }
}

/// Dua huruf awal dari nama (mis. "Siti Kartika" -> "SK").
String _inisial(String nama) {
  final List<String> kata = nama
      .trim()
      .split(RegExp(r'\s+'))
      .where((String k) => k.isNotEmpty)
      .toList();
  if (kata.isEmpty) return 'K';
  if (kata.length == 1) return kata.first.substring(0, 1).toUpperCase();
  return (kata.first.substring(0, 1) + kata.last.substring(0, 1)).toUpperCase();
}
