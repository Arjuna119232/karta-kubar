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
import '../../../shared/services/order_service_base.dart';
import '../../../shared/widgets/app_dialogs.dart';
import '../../../shared/widgets/app_icon.dart';
import '../../../shared/widgets/shimmer_box.dart';
import '../../../shared/widgets/status_views.dart';
import '../data/order_state.dart';
import 'widgets_order.dart';

/// Filter daftar order. `null` berarti semua jenis.
enum FilterOrder {
  semua,
  jastip,
  ojek,
  aktif,
  selesai;

  String get label => switch (this) {
        FilterOrder.semua => 'Semua',
        FilterOrder.jastip => 'Jastip',
        FilterOrder.ojek => 'Ojek',
        FilterOrder.aktif => 'Aktif',
        FilterOrder.selesai => 'Selesai',
      };

  bool cocok(OrderRingkas o) => switch (this) {
        FilterOrder.semua => true,
        FilterOrder.jastip => o.jenis == JenisOrder.jastip,
        FilterOrder.ojek => o.jenis == JenisOrder.ojek,
        FilterOrder.aktif => o.aktif,
        FilterOrder.selesai => !o.aktif,
      };
}

/// Riwayat order. Satu layar untuk jastip dan ojek; jenis awal dipakai untuk
/// memfilter tab yang aktif sejak layar dibuka.
class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({super.key, this.jenisAwal});

  final JenisOrder? jenisAwal;

  @override
  ConsumerState<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen> {
  late FilterOrder _filter = widget.jenisAwal == JenisOrder.ojek
      ? FilterOrder.ojek
      : widget.jenisAwal == JenisOrder.jastip
          ? FilterOrder.jastip
          : FilterOrder.semua;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<OrderRingkas>> async = ref.watch(orderProvider);
    final List<OrderRingkas> semua =
        async.valueOrNull ?? const <OrderRingkas>[];
    final List<OrderRingkas> tampil =
        semua.where(_filter.cocok).toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat order')),
      body: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            _FilterBar(
              aktif: _filter,
              onUbah: (FilterOrder f) => setState(() => _filter = f),
            ),
            Expanded(
              child: async.isLoading && semua.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(AppSpacing.screen),
                      child: ShimmerListSkeleton(itemCount: 4, itemHeight: 130),
                    )
                  : tampil.isEmpty
                      ? _Kosong(filter: _filter, semuaKosong: semua.isEmpty)
                      : RefreshIndicator(
                          onRefresh: () =>
                              ref.read(orderProvider.notifier).muatUlang(),
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(
                                AppSpacing.screen, 8, AppSpacing.screen, 48),
                            itemCount: tampil.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: AppSpacing.md),
                            itemBuilder: (BuildContext c, int i) =>
                                OrderCard(
                              order: tampil[i],
                              onTap: () => _bukaDetail(c, tampil[i]),
                              onBatal: () => _batal(c, tampil[i]),
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  void _bukaDetail(BuildContext context, OrderRingkas order) {
    context.push('/order/detail/${order.jenis.name}/${order.id}');
  }

  Future<void> _batal(BuildContext context, OrderRingkas order) async {
    final bool ya = await AppDialog.konfirmasi(
      context,
      judul: 'Batalkan order?',
      pesan: 'Order akan berhenti dikerjakan. Tindakan ini tidak bisa dibatalkan.',
      labelYa: 'Batalkan order',
      labelBatal: 'Kembali',
      ikon: Ik.xCircle,
    );
    if (!ya || !context.mounted) return;
    Haptics.medium();
    final OrderServiceDasar svc = order.jenis == JenisOrder.ojek
        ? ref.read(ojekServiceProvider)
        : ref.read(jastipServiceProvider);
    final Hasil<void> hasil = await svc.batal(order.id, '');
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(hasil.berhasil
            ? 'Order dibatalkan.'
            : (hasil.galat?.pesan ?? 'Gagal membatalkan order.')),
        backgroundColor: hasil.berhasil ? AppColors.success : AppColors.error,
      ),
    );
    if (hasil.berhasil) {
      await ref.read(orderProvider.notifier).muatUlang();
    }
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.aktif, required this.onUbah});

  final FilterOrder aktif;
  final ValueChanged<FilterOrder> onUbah;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
        children: <Widget>[
          for (final FilterOrder f in FilterOrder.values)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: ChoiceChip(
                label: Text(f.label),
                selected: f == aktif,
                onSelected: (_) {
                  Haptics.selection();
                  onUbah(f);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _Kosong extends StatelessWidget {
  const _Kosong({required this.filter, required this.semuaKosong});

  final FilterOrder filter;
  final bool semuaKosong;

  @override
  Widget build(BuildContext context) {
    if (!semuaKosong) {
      return AppEmptyState(
        art: 'empty_kegiatan',
        title: 'Tidak ada order ${filter.label.toLowerCase()}',
        message: 'Coba pilih filter lain, atau buat order baru.',
        actionLabel: 'Pesan Jastip',
        onAction: () => context.push('/jastip/form'),
      );
    }
    return AppEmptyState(
      art: 'empty_kegiatan',
      title: 'Belum ada order',
      message: 'Order Jastip dan Ojek yang kamu buat akan muncul di sini, '
          'lengkap dengan statusnya.',
      actionLabel: 'Pesan Ojek',
      onAction: () => context.push('/ojek/form'),
    );
  }
}

/// Daftar semua order warga dengan tab. Dipakai dari menu Profil dan dari
/// kartu "Order Aktif" di beranda.
class OrderListScreen extends ConsumerStatefulWidget {
  const OrderListScreen({super.key});

  @override
  ConsumerState<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends ConsumerState<OrderListScreen> {
  FilterOrder _filter = FilterOrder.semua;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<OrderRingkas>> async = ref.watch(orderProvider);
    final List<OrderRingkas> semua =
        async.valueOrNull ?? const <OrderRingkas>[];
    final List<OrderRingkas> tampil =
        semua.where(_filter.cocok).toList(growable: false);
    final List<OrderRingkas> aktif = semua.where((OrderRingkas o) => o.aktif).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Semua order')),
      body: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            _FilterBar(
              aktif: _filter,
              onUbah: (FilterOrder f) => setState(() => _filter = f),
            ),
            if (aktif.isNotEmpty) ...<Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, 0),
                child: _KartuOrderAktif(aktif: aktif),
              ),
            ],
            Expanded(
              child: async.isLoading && semua.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(AppSpacing.screen),
                      child: ShimmerListSkeleton(itemCount: 4, itemHeight: 130),
                    )
                  : tampil.isEmpty
                      ? AppEmptyState(
                          art: 'empty_kegiatan',
                          title: 'Belum ada order',
                          message: 'Pesan Jastip atau Ojek untuk melihat '
                              'riwayat dan statusnya di sini.',
                          actionLabel: 'Pesan Jastip',
                          onAction: () => context.push('/jastip/form'),
                        )
                      : RefreshIndicator(
                          onRefresh: () =>
                              ref.read(orderProvider.notifier).muatUlang(),
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(
                                AppSpacing.screen, 8, AppSpacing.screen, 48),
                            itemCount: tampil.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: AppSpacing.md),
                            itemBuilder: (BuildContext c, int i) => OrderCard(
                              order: tampil[i],
                              onTap: () => context.push(
                                '/order/tracking/${tampil[i].jenis.name}/${tampil[i].id}',
                              ),
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ringkasan order yang sedang berjalan: dipakai di daftar semua dan,
/// bentuknya lebih ringkas, di beranda.
class _KartuOrderAktif extends StatelessWidget {
  const _KartuOrderAktif({required this.aktif});

  final List<OrderRingkas> aktif;

  @override
  Widget build(BuildContext context) {
    final OrderRingkas pertama = aktif.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SubOrder('Sedang berjalan', ikon: Ik.trendingUp),
        SizedBox(
          width: double.infinity,
          child: _KartuRingkasAktif(
            order: pertama,
            jumlahLain: aktif.length - 1,
            onTap: () => context.push(
              '/order/tracking/${pertama.jenis.name}/${pertama.id}',
            ),
          ),
        ),
      ],
    );
  }
}

/// Kartu order aktif yang bisa ditekan, dengan peta kecil di kanan.
class _KartuRingkasAktif extends StatelessWidget {
  const _KartuRingkasAktif({
    required this.order,
    required this.onTap,
    this.jumlahLain = 0,
  });

  final OrderRingkas order;
  final VoidCallback onTap;
  final int jumlahLain;

  @override
  Widget build(BuildContext context) {
    final Color w = warnaStatus(context, order.status);
    return Material(
      color: context.semantic.card,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: w.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: w.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: AppIcon(OrderCard.ikonUntuk(order.jenis), size: 24, color: w),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      order.ringkas,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: <Widget>[
                        ChipInfo(ikon: Ik.clock, label: order.status.label),
                        if (jumlahLain > 0) ...<Widget>[
                          const SizedBox(width: AppSpacing.sm),
                          ChipInfo(
                            ikon: Ik.badge,
                            label: '+${jumlahLain} lagi',
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              AppIcon(Ik.chevronRight,
                  size: 20, color: context.semantic.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kartu ringkas order aktif untuk beranda (dipakai home_screen).
class OrderAktifCard extends StatelessWidget {
  const OrderAktifCard({super.key, required this.order, this.sisa = 0});

  final OrderRingkas order;

  /// Jumlah order aktif lain besides [order].
  final int sisa;

  @override
  Widget build(BuildContext context) {
    return _KartuRingkasAktif(
      order: order,
      jumlahLain: sisa,
      onTap: () => context.push(
        '/order/tracking/${order.jenis.name}/${order.id}',
      ),
    );
  }
}