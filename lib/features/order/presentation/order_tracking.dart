import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/hasil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../shared/models/order.dart';
import '../../../shared/models/order_jastip.dart';
import '../../../shared/models/order_ojek.dart';
import '../../../shared/models/order_ringkas.dart';
import '../../../shared/models/review_order.dart';
import '../../../shared/services/order_service_base.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_dialogs.dart';
import '../../../shared/widgets/app_icon.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/shimmer_box.dart';
import '../../../shared/widgets/status_views.dart';
import '../data/order_state.dart';
import 'widgets_order.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/models/mitra_jasa.dart';

/// Satu layar untuk tracking JASTIP maupun OJEK.
///
/// Kunci rute dibentuk `"<jenis>:<id>"`. Statusnya di-poll tiap beberapa
/// detik lewat `orderPantauProvider`; begitu Supabase Auth menyala, cukup
/// ganti isi stream itu dengan WebSocket tanpa menyentuh layar ini.
class OrderTrackingScreen extends ConsumerWidget {
  const OrderTrackingScreen({
    super.key,
    required this.jenis,
    required this.orderId,
  });

  /// `jastip` atau `ojek`.
  final String jenis;

  /// Id order (uuid dari server, atau `local-...` dari perangkat).
  final String orderId;

  /// Kunci untuk provider: `"<jenis>|<id>"`.
  String get kunci => '$jenis|$orderId';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<OrderRingkas?> async = ref.watch(orderPantauProvider(kunci));
    final OrderRingkas? order = async.valueOrNull;

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lacak order')),
        body: SafeArea(
          top: false,
          child: async.isLoading
              ? const Padding(
                  padding: EdgeInsets.all(AppSpacing.screen),
                  child: ShimmerListSkeleton(itemCount: 3, itemHeight: 120),
                )
              : AppErrorState(
                  message: 'Order ini sudah tidak ada di perangkat ini, atau '
                      'ID-nya salah. Tarik ke bawah untuk mencoba lagi.',
                  onRetry: () => ref.invalidate(orderPantauProvider(kunci)),
                ),
        ),
      );
    }

    final OrderJastip? jastip = order.sebagaiJastip;
    final OrderOjek? ojek = order.sebagaiOjek;
    final List<TitikPeta> titik = <TitikPeta>[
      if (jastip != null) ...<TitikPeta>[jastip.titikBeli, jastip.titikAntar],
      if (ojek != null) ...<TitikPeta>[ojek.titikJemput, ojek.titikTujuan],
    ];

    // Jejak yang sudah dikirim mitra. Belum ada apa-apa sebelum Mitra aktif,
    // jadi peta tetap menampilkan jemput dan tujuan saja.
    final List<TitikPeta> jejak =
        ref.watch(trackingTitikProvider(kunci)).valueOrNull ??
            const <TitikPeta>[];
    final List<TitikPeta> semuaTitik = <TitikPeta>[...jejak, ...titik];

    return Scaffold(
      appBar: AppBar(
        title: Text('Lacak ${order.jenis.label}'),
        actions: <Widget>[
          if (order.status.bisaDibatalWarga)
            TextButton(
              onPressed: () => _konfirmasiBatal(context, ref, order),
              child: const Text('Batalkan'),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(orderPantauProvider(kunci));
            await ref.read(orderProvider.notifier).muatUlang();
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen, 8, AppSpacing.screen, 48),
            children: <Widget>[
              _KepalaStatus(order: order),
              const SizedBox(height: AppSpacing.section),
              PetaOrder(
                titik: semuaTitik,
                garis: jejak.length > 1 ? jejak : titik,
                tinggi: 230,
                lokasiSaya: ojek != null,
              ),
              if (jejak.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Garis menunjukkan ${jejak.length} titik yang sudah dikirim mitra.',
                  style: context.text.bodySmall
                      ?.copyWith(color: context.semantic.textSecondary),
                ),
              ],
              const SizedBox(height: AppSpacing.section),
              SubOrder('Perjalanan order', ikon: Ik.route),
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: TimelineStatus(
                  status: order.status,
                  jenis: order.jenis,
                  catatan: _catatan(order),
                ),
              ),
              const SizedBox(height: AppSpacing.section),
              SubOrder('Ringkasan', ikon: Ik.badge),
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    BarisInfo(
                      label: 'Kode order',
                      nilai: order.kode,
                      ikon: Ik.badge,
                    ),
                    if (jastip != null) ...<Widget>[
                      BarisInfo(
                        label: 'Barang',
                        nilai: jastip.ringkas,
                        ikon: Ik.package,
                      ),
                      BarisInfo(
                        label: 'Beli di',
                        nilai: jastip.lokasiBeli,
                        ikon: Ik.cart,
                      ),
                      BarisInfo(
                        label: 'Diantar ke',
                        nilai: jastip.alamatAntar,
                        ikon: Ik.home,
                      ),
                    ],
                    if (ojek != null) ...<Widget>[
                      BarisInfo(
                        label: 'Jemput',
                        nilai: ojek.lokasiJemput,
                        ikon: Ik.person,
                      ),
                      BarisInfo(
                        label: 'Tujuan',
                        nilai: ojek.lokasiTujuan,
                        ikon: Ik.pinMitra,
                      ),
                    ],
                    BarisInfo(
                      label: 'Biaya jasa',
                      nilai: rupiah(order.tarif),
                      ikon: Ik.wallet,
                    ),
                    BarisInfo(
                      label: 'Dibuat',
                      nilai: waktuRelatif(order.dibuat),
                      ikon: Ik.clock,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.section),
              _PanelMitra(order: order),
              const SizedBox(height: AppSpacing.section),
              _PanelCatatanPenting(jenis: order.jenis),
              if (order.status == StatusOrder.selesai) ...<Widget>[
                const SizedBox(height: AppSpacing.section),
                PrimaryButton(
                  label: 'Beri penilaian',
                  icon: Ik.star,
                  onPressed: () =>
                      context.push('/order/rating/${order.jenis.name}/${order.id}'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String? _catatan(OrderRingkas o) {
    if (!o.status.aktif) {
      return o.status == StatusOrder.batal
          ? 'Order dibatalkan oleh warga.'
          : 'Order dibatalkan oleh mitra atau pengurus.';
    }
    if (o.status == StatusOrder.menunggu) {
      return 'Mitra yang online akan menerima order ini. Tarik ke bawah untuk '
          'memeriksa lagi.';
    }
    return null;
  }

  Future<void> _konfirmasiBatal(
    BuildContext context,
    WidgetRef ref,
    OrderRingkas order,
  ) async {
    final bool ya = await AppDialog.konfirmasi(
      context,
      judul: 'Batalkan order?',
      pesan: 'Order ${order.kode.isEmpty ? "ini" : order.kode} akan berhenti '
          'dikerjakan. Tindakan ini tidak bisa dibatalkan.',
      labelYa: 'Batalkan order',
      labelBatal: 'Kembali',
      ikon: Ik.xCircle,
    );
    if (!ya || !context.mounted) return;

    Haptics.medium();
    final String alasan = await AppDialog.catatan(
          context,
          judul: 'Alasan pembatalan',
          subjudul: 'Bantu mitra supaya tidak salah paham. Boleh dikosongkan.',
          labelYa: 'Batalkan',
        ) ??
        '';

    final OrderServiceDasar svc = order.jenis == JenisOrder.ojek
        ? ref.read(ojekServiceProvider)
        : ref.read(jastipServiceProvider);
    final Hasil<void> hasil = await svc.batal(order.id, alasan);

    if (!context.mounted) return;
    if (!hasil.berhasil) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(hasil.galat?.pesan ?? 'Gagal membatalkan order.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    Haptics.success();
    await ref.read(orderProvider.notifier).muatUlang();
    ref.invalidate(orderPantauProvider(order.jenis.name + '|' + order.id));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order dibatalkan.'),
        backgroundColor: AppColors.success,
      ),
    );
    context.pop();
  }
}

class _KepalaStatus extends StatelessWidget {
  const _KepalaStatus({required this.order});

  final OrderRingkas order;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      color: warnaStatus(context, order.status).withValues(alpha: 0.08),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: warnaStatus(context, order.status).withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
            child: AppIcon(
              OrderCard.ikonUntuk(order.jenis),
              size: 26,
              color: warnaStatus(context, order.status),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(order.jenis.labelJamak, style: context.text.titleSmall),
                const SizedBox(height: 2),
                Text(
                  order.status.label,
                  style: context.text.bodyMedium
                      ?.copyWith(color: warnaStatus(context, order.status)),
                ),
              ],
            ),
          ),
          StatusBadge(status: order.status),
        ],
      ),
    );
  }
}

/// Panel mitra: nama, rating, dan tombol hubungi.
///
/// Catatan jujur: belum ada chat bawaan KUNBAR dan belum ada akun WhatsApp
/// Business, jadi tombolnya membuka aplikasi telepon atau WhatsApp milik
/// pengguna. Kalau nomor mitra kosong, tombolnya dimatikan (bukan tombol
/// palsu yang tidak melakukan apa-apa).
class _PanelMitra extends ConsumerWidget {
  const _PanelMitra({required this.order});

  final OrderRingkas order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? mitraId = order.sebagaiJastip?.mitraId ?? order.sebagaiOjek?.mitraId;
    if (mitraId == null || mitraId.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SubOrder('Mitra', ikon: Ik.person),
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: <Widget>[
                AppIcon(Ik.person, size: 22, color: context.semantic.textSecondary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Mitra belum ditugaskan ke order ini.',
                    style: context.text.bodyMedium
                        ?.copyWith(color: context.semantic.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final AsyncValue<RingkasanRating> rating =
        ref.watch(ringkasanRatingProvider(mitraId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SubOrder('Mitra', ikon: Ik.person),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: context.colors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: AppIcon(Ik.person, size: 22, color: context.colors.primary),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Mitra Anda', style: context.text.bodyMedium),
                        const SizedBox(height: 2),
                        Text(
                          rating.valueOrNull?.labelTeks ?? 'Belum ada penilaian',
                          style: context.text.bodySmall
                              ?.copyWith(color: context.semantic.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _TombolHubung(mitraId: mitraId),
            ],
          ),
        ),
      ],
    );
  }
}

/// Tombol telepon untuk mitra. Membuka aplikasi telepon bila nomor ada;
/// bila belum ada (data contoh), warga diberi tahu.
class _TombolHubung extends ConsumerWidget {
  const _TombolHubung({required this.mitraId});

  final String mitraId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PrimaryButton(
      label: 'Hubungi mitra',
      icon: Ik.phone,
      tone: PrimaryButtonTone.outlined,
      onPressed: () => _hubungi(context, ref),
    );
  }

  Future<void> _hubungi(BuildContext context, WidgetRef ref) async {
    final Hasil<MitraJasa> h =
        await ref.read(mitraRepositoryProvider).byId(mitraId);
    if (!context.mounted) return;
    final String nomor = h.berhasil ? h.data!.nomor.trim() : '';
    if (nomor.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nomor mitra belum tersedia. Coba lagi nanti.'),
        ),
      );
      return;
    }
    final bool ok = await launchUrl(Uri(scheme: 'tel', path: nomor));
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak bisa membuka aplikasi telepon.')),
      );
    }
  }
}

/// Penjelasan jujur kenapa peta belum bergerak.
class _PanelCatatanPenting extends StatelessWidget {
  const _PanelCatatanPenting({required this.jenis});

  final JenisOrder jenis;

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
              jenis == JenisOrder.jastip
                  ? 'Titik lokasi mitra muncul di peta setelah aplikasi Mitra '
                      'mengirimnya. Status di atas tetap diperbarui otomatis.'
                  : 'Titik driver muncul di peta setelah aplikasi Mitra mengirimnya. '
                      'Status dan perkiraan tiba diperbarui otomatis.',
              style: context.text.bodySmall
                  ?.copyWith(color: context.semantic.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}