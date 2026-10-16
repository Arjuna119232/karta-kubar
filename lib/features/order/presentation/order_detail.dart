import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../shared/models/order.dart';
import '../../../shared/models/order_jastip.dart';
import '../../../shared/models/order_ojek.dart';
import '../../../shared/models/order_ringkas.dart';
import '../../../shared/models/review_order.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_icon.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/shimmer_box.dart';
import '../../../shared/widgets/status_views.dart';
import '../data/order_state.dart';
import 'widgets_order.dart';

/// Detail satu order, untuk jastip maupun ojek.
///
/// Berbeda dengan layar tracking: layar ini tidak meng-polling, jadi ringan
/// dan tetap bisa dibuka dari riwayat lama.
class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({
    super.key,
    required this.jenis,
    required this.orderId,
  });

  /// `jastip` atau `ojek`.
  final String jenis;

  /// Id order.
  final String orderId;

  static OrderRingkas? _cari(List<OrderRingkas> semua, String id) {
    for (final OrderRingkas o in semua) {
      if (o.id == id) return o;
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<OrderRingkas>> async = ref.watch(orderProvider);
    final OrderRingkas? order = async.valueOrNull == null
        ? null
        : _cari(async.value!, orderId);

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail order')),
        body: SafeArea(
          top: false,
          child: async.isLoading
              ? const Padding(
                  padding: EdgeInsets.all(AppSpacing.screen),
                  child: ShimmerListSkeleton(itemCount: 3, itemHeight: 120),
                )
              : AppEmptyState(
                  art: 'empty_kegiatan',
                  title: 'Order tidak ditemukan',
                  message: 'Order ini sudah tidak ada di perangkat ini.',
                  actionLabel: 'Lihat semua order',
                  onAction: () => context.push('/order/list'),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail order'),
        actions: <Widget>[
          if (order.status.aktif)
            IconButton(
              onPressed: () {
                Haptics.light();
                context.push(
                  '/order/tracking/${order.jenis.name}/${order.id}',
                );
              },
              icon: const AppIcon(Ik.route),
              tooltip: 'Lacak',
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen, 8, AppSpacing.screen, 48),
          children: <Widget>[
            _Kepala(order: order),
            const SizedBox(height: AppSpacing.section),
            PetaOrder(titik: titik, garis: titik, tinggi: 200),
            const SizedBox(height: AppSpacing.section),
            SubOrder('Status', ikon: Ik.checkCircle),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: TimelineStatus(status: order.status, jenis: order.jenis),
            ),
            const SizedBox(height: AppSpacing.section),
            SubOrder('Rincian', ikon: Ik.badge),
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
                  BarisInfo(
                    label: 'Jenis',
                    nilai: order.jenis.labelJamak,
                    ikon: OrderCard.ikonUntuk(order.jenis),
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
                    if (jastip.catatan.isNotEmpty)
                      BarisInfo(
                        label: 'Catatan',
                        nilai: jastip.catatan,
                        ikon: Ik.chat,
                      ),
                    BarisInfo(
                      label: 'Jarak',
                      nilai: jarakPendek(jastip.jarakKm),
                      ikon: Ik.route,
                    ),
                    BarisInfo(
                      label: 'Fee',
                      nilai: rupiah(jastip.tarif),
                      ikon: Ik.wallet,
                    ),
                    if (jastip.estimasiBiayaBarang != null)
                      BarisInfo(
                        label: 'Perkiraan barang',
                        nilai: rupiah(jastip.estimasiBiayaBarang!),
                        ikon: Ik.cart,
                      ),
                    BarisInfo(
                      label: 'Total',
                      nilai: rupiah(jastip.total),
                      ikon: Ik.wallet,
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
                    if (ojek.catatan.isNotEmpty)
                      BarisInfo(
                        label: 'Catatan',
                        nilai: ojek.catatan,
                        ikon: Ik.chat,
                      ),
                    BarisInfo(
                      label: 'Jarak',
                      nilai: jarakPendek(ojek.jarakKm),
                      ikon: Ik.route,
                    ),
                    BarisInfo(
                      label: 'Tarif',
                      nilai: rupiah(ojek.tarif),
                      ikon: Ik.wallet,
                    ),
                  ],
                  BarisInfo(
                    label: 'Bayar',
                    nilai: order.jenis == JenisOrder.jastip && jastip != null
                        ? jastip.metodeBayar.label
                        : (ojek?.metodeBayar.label ?? 'Tunai'),
                    ikon: Ik.cash,
                  ),
                  BarisInfo(
                    label: 'Dibuat',
                    nilai: waktuRelatif(order.dibuat),
                    ikon: Ik.clock,
                  ),
                ],
              ),
            ),
            if (order.status == StatusOrder.selesai) ...<Widget>[
              const SizedBox(height: AppSpacing.section),
              _PanelNilai(order: order),
            ],
          ],
        ),
      ),
    );
  }
}

class _Kepala extends StatelessWidget {
  const _Kepala({required this.order});

  final OrderRingkas order;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: KepalaOrder(
            judul: order.jenis.labelJamak,
            subjudul: order.kode,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        StatusBadge(status: order.status),
      ],
    );
  }
}

/// Panel penilaian: kalau sudah ada rating, tampilkan; kalau belum, tombol.
class _PanelNilai extends ConsumerWidget {
  const _PanelNilai({required this.order});

  final OrderRingkas order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ReviewOrder>> async =
        ref.watch(ulasanMitraProvider(order.sebagaiJastip?.mitraId ?? ''));
    final List<ReviewOrder> ulasan =
        async.valueOrNull ?? const <ReviewOrder>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SubOrder('Penilaian', ikon: Ik.star),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ulasan.isEmpty
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Order ini belum dinilai.',
                      style: context.text.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: PrimaryButton(
                        label: 'Beri penilaian',
                        icon: Ik.star,
                        onPressed: () => context.push(
                          '/order/rating/${order.jenis.name}/${order.id}',
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    BintangRating(nilai: ulasan.first.rating),
                    if (!ulasan.first.tanpaKomentar) ...<Widget>[
                      const SizedBox(height: AppSpacing.sm),
                      Text(ulasan.first.komentar, style: context.text.bodyMedium),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}
