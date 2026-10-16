import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/hasil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../shared/models/order.dart';
import '../../../shared/models/order_ringkas.dart';
import '../../../shared/models/review_order.dart';
import '../../../shared/services/review_service.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_icon.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/shimmer_box.dart';
import '../../../shared/widgets/status_views.dart';
import '../data/order_state.dart';
import 'widgets_order.dart';

/// Form penilaian mitra setelah order selesai.
///
/// Satu order hanya boleh dinilai sekali (dijaga unique constraint di
/// database dan dicek lagi di penyimpanan lokal), jadi kalau warga membuka
/// ulang, layar ini menampilkan penilaian yang sudah ada, bukan form kosong.
class RatingScreen extends ConsumerStatefulWidget {
  const RatingScreen({
    super.key,
    required this.jenis,
    required this.orderId,
  });

  /// `jastip` atau `ojek`.
  final String jenis;

  /// Id order.
  final String orderId;

  @override
  ConsumerState<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends ConsumerState<RatingScreen> {
  final TextEditingController _komentar = TextEditingController();
  int _bintang = 0;
  bool _sibuk = false;

  @override
  void dispose() {
    _komentar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<OrderRingkas>> async = ref.watch(orderProvider);
    final OrderRingkas? order = async.valueOrNull == null
        ? null
        : _cari(async.value!, widget.orderId);

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Beri penilaian')),
        body: SafeArea(
          top: false,
          child: async.isLoading
              ? const Padding(
                  padding: EdgeInsets.all(AppSpacing.screen),
                  child: ShimmerListSkeleton(itemCount: 2, itemHeight: 100),
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

    return Scaffold(
      appBar: AppBar(title: const Text('Beri penilaian')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen, 8, AppSpacing.screen, 120),
          children: <Widget>[
            _RingkasanOrder(order: order),
            const SizedBox(height: AppSpacing.section),
            SubOrder('Seberapa puas kamu?', ikon: Ik.star),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: <Widget>[
                  BintangRating(
                    nilai: _bintang,
                    ukuran: 36,
                    onUbah: (int n) => setState(() => _bintang = n),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _labelBintang,
                    style: context.text.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.section),
            SubOrder('Ceritakan kalau perlu', ikon: Ik.chat),
            TextField(
              controller: _komentar,
              maxLines: 4,
              maxLength: 400,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Contoh: mitra cepat dan barang sampai dengan aman.',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _UlasanLama(jenis: order.jenis, idOrder: widget.orderId),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.md),
          child: PrimaryButton(
            label: 'Kirim penilaian',
            icon: Ik.check,
            loading: _sibuk,
            onPressed: _bintang == 0 || _sibuk ? null : () => _kirim(order),
          ),
        ),
      ),
    );
  }

  static OrderRingkas? _cari(List<OrderRingkas> semua, String id) {
    for (final OrderRingkas o in semua) {
      if (o.id == id) return o;
    }
    return null;
  }

  String get _labelBintang => switch (_bintang) {
        1 => 'Buruk. Ada yang perlu dibbaiki.',
        2 => 'Kurang memuaskan.',
        3 => 'Cukup baik.',
        4 => 'Bagus.',
        5 => 'Sangat bagus.',
        _ => 'Ketuk bintang untuk menilai.',
      };

  Future<void> _kirim(OrderRingkas order) async {
    Haptics.medium();
    setState(() => _sibuk = true);
    final KunciWarga kunci = await ref.read(kunciWargaProvider.future);
    final ReviewService svc = ref.read(reviewServiceProvider);
    final Hasil<ReviewOrder> hasil = await svc.kirim(
      orderId: order.id,
      jenis: order.jenis,
      reviewerKunci: kunci.nilai,
      mitraId: order.sebagaiJastip?.mitraId ?? order.sebagaiOjek?.mitraId,
      rating: _bintang,
      komentar: _komentar.text,
    );
    if (!mounted) return;
    setState(() => _sibuk = false);
    if (!hasil.berhasil) {
      Haptics.error();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(hasil.galat?.pesan ?? 'Gagal menyimpan penilaian.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    Haptics.success();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Terima kasih, penilaianmu tersimpan.'),
        backgroundColor: AppColors.success,
      ),
    );
    context.pop();
  }
}

class _RingkasanOrder extends StatelessWidget {
  const _RingkasanOrder({required this.order});

  final OrderRingkas order;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
            child: AppIcon(
              OrderCard.ikonUntuk(order.jenis),
              size: 24,
              color: context.colors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(order.kode, style: context.text.titleSmall),
                const SizedBox(height: 2),
                Text(
                  order.ringkas,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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

/// Ulasan yang sudah pernah ditulis untuk order ini.
class _UlasanLama extends ConsumerWidget {
  const _UlasanLama({required this.jenis, required this.idOrder});

  final JenisOrder jenis;
  final String idOrder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Hasil<List<ReviewOrder>>>(
      future: ref.watch(reviewServiceProvider).untukOrder(idOrder, jenis),
      builder: (BuildContext context, AsyncSnapshot<Hasil<List<ReviewOrder>>> snap) {
        if (snap.connectionState != ConnectionState.done || !snap.hasData) {
          return const SizedBox.shrink();
        }
        final List<ReviewOrder> list = snap.data?.data ?? const <ReviewOrder>[];
        if (list.isEmpty) return const SizedBox.shrink();
        final ReviewOrder lama = list.first;
        return AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          color: context.colors.primary.withValues(alpha: 0.06),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AppIcon(Ik.checkCircle, size: 20, color: context.colors.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Sudah dinilai ${lama.rating} bintang',
                      style: context.text.bodyMedium,
                    ),
                    if (!lama.tanpaKomentar) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(lama.komentar, style: context.text.bodySmall),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      'Penilaian baru akan menggantikan yang lama.',
                      style: context.text.bodySmall
                          ?.copyWith(color: context.semantic.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
