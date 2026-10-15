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
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_icon.dart';
import '../../../shared/widgets/fade_slide_in.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/stat_tile.dart';

import '../../kegiatan/domain/kegiatan.dart';
import '../../shell/data/app_tabs.dart';
import '../../../shared/widgets/cover_pilih.dart';
import '../../../shared/widgets/haptics.dart';

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
      child: ListView(
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
          const AppIcon(Ik.megaphone, size: 30, color: Colors.white),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Lapor Darurat',
                  style: context.text.titleMedium?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  'Kebakaran, kecelakaan, kekerasan, atau banjir di RW 05.',
                  style: context.text.bodySmall
                      ?.copyWith(color: AppColors.onErrorSoft),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white),
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
            Haptics.ringan();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Belum ada notifikasi baru')),
            );
          },
        ),
        const SizedBox(width: 10),
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: context.semantic.heroGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              _inisial(nama),
              style: const TextStyle(
                color: Colors.white,
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
  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Pengumuman lewat repository, sama seperti berita di atas.
    final Future<List<Pengumuman>> memuat =
        ref.read(beritaProvider.notifier).pengumuman();
    return FutureBuilder<List<Pengumuman>>(
      future: memuat,
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
              return _AnnouncementCard(item: a);
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
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              item.tag,
              style: const TextStyle(
                color: Colors.white,
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
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.isi,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Row(
            children: <Widget>[
              AppIcon(Ik.megaphone,
                  color: Colors.white.withValues(alpha: 0.9), size: 16),
              const SizedBox(width: 6),
              Text(
                'Pengumuman',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              const AppIcon(Ik.arrowForward,
                  color: Colors.white, size: 18),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends ConsumerWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final UserRole role = ref.watch(sessionProvider).efektif;
    // Aksi cepat WAJIB ikut role. Dulu daftar ini tetap sama untuk semua
    // role lalu mencari tab via label - hasilnya: tombol "Iuran" tidak
    // melakukan apa-apa untuk tamu (tab "Kas" tidak ada di sana).
    // "Galeri" untuk anggota mendarat di tab "Kas".
    final List<_QuickItem> items = <_QuickItem>[
      if (role.bisa(UserRole.anggota))
        _QuickItem(Ik.qrScan, 'Absen', AppColors.primary, () => context.push('/absen')),
      _QuickItem(Ik.chat, 'Aspirasi', AppColors.warning, () => context.push('/aspirasi')),
      _QuickItem(Ik.handHeart, 'UMKM', AppColors.social, () => context.push('/umkm')),
      if (role.bisa(UserRole.anggota))
        _QuickItem(Ik.wallet, 'Iuran', AppColors.accent, () => _keTab(ref, 'Kas'))
      else
        _QuickItem(Ik.gallery, 'Galeri', AppColors.success, () => context.push('/galeri')),
    ];
;

    // BUKAN `Row` dengan 5 `Expanded`: di layar 360 dp tiap kolom tinggal
    // ~66 dp, sehingga nama tombol seperti "Aspirasi" terpotong atau meluber.
    // `Wrap` + lebar item yang dihitung dari lebar layar selalu aman, dan
    // otomatis jadi 2 baris kalau tombolnya bertambah.
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        const double jarak = 8;
        final double lebarItem = (c.maxWidth - jarak * 3) / 4;
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
                    Haptics.ringan();
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
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Membuka: ${item.judul}')),
        );
      },
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
