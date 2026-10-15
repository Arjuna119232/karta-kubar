import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/session.dart';
import '../../../core/data/hasil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_icon.dart';
import '../../../shared/widgets/fade_slide_in.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/status_views.dart';
import '../data/aspirasi_state.dart';
import '../domain/aspirasi.dart';
import '../../../core/utils/haptics.dart';
import '../../../shared/widgets/animated_fab.dart';
import '../../../shared/widgets/shimmer_box.dart';

/// Papan FISH warga: kirim aspirations / laporan, lalu pantau penanganannya.
class AspirasiScreen extends ConsumerStatefulWidget {
  const AspirasiScreen({super.key});

  @override
  ConsumerState<AspirasiScreen> createState() => _AspirasiScreenState();
}

class _AspirasiScreenState extends ConsumerState<AspirasiScreen> {
  /// null = semua status.
  StatusAspirasi? _filter;

  @override
  Widget build(BuildContext context) {
    final Session session = ref.watch(sessionProvider);
    final AsyncValue<List<Aspirasi>> state = ref.watch(aspirasiProvider);
    final List<Aspirasi> semua =
        state.valueOrNull ?? <Aspirasi>[];
    final List<Aspirasi> data = _filter == null
        ? semua
        : semua
            .where((Aspirasi a) => a.status == _filter)
            .toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aspirasi & Laporan'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: () =>
                ref.read(aspirasiProvider.notifier).muatUlang(),
            icon: const AppIcon(Ik.refresh),
          ),
        ],
      ),
      floatingActionButton: session.sudahLogin
          ? AnimatedFab(
              icon: Ik.chat,
              label: 'Kirim FISH',
              onPressed: () => _bukaForm(context, session),
            )
          : null,
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () => ref.read(aspirasiProvider.notifier).muatUlang(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen, 8, AppSpacing.screen, 110),
            children: <Widget>[
              const _Ringkasan(),
              const SizedBox(height: 18),
              _FilterBar(
                aktif: _filter,
                onPilih: (StatusAspirasi? v) {
                  Haptics.selection();
                  setState(() => _filter = v);
                },
              ),
              const SizedBox(height: 18),
              if (state.isLoading && semua.isEmpty)
                const ShimmerListSkeleton(
                    itemCount: 4, itemHeight: 104, padding: EdgeInsets.zero)
              else if (state.hasError && semua.isEmpty)
                AppErrorState(
                  onRetry: () =>
                      ref.read(aspirasiProvider.notifier).muatUlang(),
                )
              else if (semua.isEmpty)
                AppEmptyState(
                  title: 'Belum ada FISH masuk',
                  message: session.sudahLogin
                      ? 'Kirim aspirations atau laporan kamu lewat tombol di bawah.'
                      : 'Papan ini akan menampilkan aspirasi dan laporan warga Kuningan Barat.',
                )
              else if (data.isEmpty)
                AppEmptyState(
                  title: 'Tidak ada di filter ini',
                  message: 'Ubah filter status di atas untuk melihat yang lain.',
                  actionLabel: 'Lihat semua',
                  onAction: () => setState(() => _filter = null),
                )
              else
                for (final (int i, Aspirasi a) in data.indexed)
                  FadeSlideIn(
                    index: i,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.gap),
                      child: AspirasiCard(item: a),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _bukaForm(BuildContext context, Session session) async {
    final AuthUser? user = session.user;
    Haptics.medium();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext _) => FormFish(
        pengirim: user?.name ?? 'Warga KUNBAR',
        rt: user?.rt,
        rw: user?.rw,
      ),
    );
  }
}

/// Tiga angka ringkas di atas daftar.
class _Ringkasan extends ConsumerWidget {
  const _Ringkasan();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RekapAspirasi rekap = ref.watch(rekapAspirasiProvider);
    final AsyncValue<List<Aspirasi>> state = ref.watch(aspirasiProvider);

    if (state.isLoading) {
      return const AppSkeleton(height: 84, radius: 20);
    }

    return Row(
      children: <Widget>[
        Expanded(
          child: _Mini(
            warna: StatusAspirasi.baru.warna,
            nilai: '${rekap.baru}',
            label: 'Baru',
          ),
        ),
        const SizedBox(width: AppSpacing.gap),
        Expanded(
          child: _Mini(
            warna: StatusAspirasi.diproses.warna,
            nilai: '${rekap.diproses}',
            label: 'Diproses',
          ),
        ),
        const SizedBox(width: AppSpacing.gap),
        Expanded(
          child: _Mini(
            warna: StatusAspirasi.selesai.warna,
            nilai: '${rekap.selesai}',
            label: 'Selesai',
          ),
        ),
      ],
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini({required this.warna, required this.nilai, required this.label});

  final Color warna;
  final String nilai;
  final String label;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      child: Column(
        children: <Widget>[
          Container(
            width: 30,
            height: 4,
            decoration: BoxDecoration(
              color: warna,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 10),
          Text(nilai, style: context.text.headlineSmall),
          const SizedBox(height: 2),
          Text(
            label,
            style: context.text.bodySmall
                ?.copyWith(color: context.semantic.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Chip filter status.
class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.aktif, required this.onPilih});

  final StatusAspirasi? aktif;
  final ValueChanged<StatusAspirasi?> onPilih;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          _Chip(
            label: 'Semua',
            selected: aktif == null,
            warna: context.colors.primary,
            onTap: () => onPilih(null),
          ),
          for (final StatusAspirasi s in StatusAspirasi.values)
            _Chip(
              label: s.label,
              selected: aktif == s,
              warna: s.warna,
              onTap: () => onPilih(s),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.warna,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color warna;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? warna : context.semantic.card,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.button),
              border: Border.all(color: selected ? warna : context.semantic.line),
            ),
            child: Text(
              label,
              style: context.text.labelLarge?.copyWith(
                color: selected ? AppColors.white : context.semantic.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Kartu satu FISH. Dipakai juga di layar pengurus (aksi ubah status
/// disuntikkan lewat [onUbahStatus]).
class AspirasiCard extends StatelessWidget {
  const AspirasiCard({super.key, required this.item, this.onUbahStatus});

  final Aspirasi item;
  final void Function(StatusAspirasi baru)? onUbahStatus;

  @override
  Widget build(BuildContext context) {
    final Color tinta = context.semantic.textSecondary;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              _Lencana(
                ikon: item.kategori.ikon,
                warna: item.kategori.warna,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.kategori.label,
                      style: context.text.labelSmall?.copyWith(
                        color: item.kategori.warna,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.judul,
                      style: context.text.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusBadge(status: item.status),
            ],
          ),
          const SizedBox(height: 12),
          Text(item.isi, style: context.text.bodyMedium),
          if (item.balasan != null && item.balasan!.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.semantic.success.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  AppIcon(Ik.checkCircle,
                      size: 18, color: context.semantic.success),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Balasan pengurus: ${item.balasan}',
                      style: context.text.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              AppIcon(Ik.person, size: 14, color: tinta),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  '${item.pengirim} - ${item.zona}',
                  style: context.text.bodySmall?.copyWith(color: tinta),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              AppIcon(Ik.clock, size: 14, color: tinta),
              const SizedBox(width: 5),
              Text(
                item.umur,
                style: context.text.bodySmall?.copyWith(color: tinta),
              ),
              if (item.contoh) ...<Widget>[
                const Spacer(),
                const _TandaContoh(),
              ],
            ],
          ),
          if (onUbahStatus != null && !item.contoh) ...<Widget>[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final StatusAspirasi s in item.status.berikutnya)
                  OutlinedButton.icon(
                    onPressed: () => onUbahStatus!(s),
                    icon: AppIcon(s.ikon, size: 16, color: s.warna),
                    label: Text(
                      switch (s) {
                        StatusAspirasi.baru => 'Kembalikan ke Baru',
                        _ => 'Tandai ${s.label}',
                      },
                      style: TextStyle(color: s.warna),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: s.warna.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Lencana extends StatelessWidget {
  const _Lencana({required this.ikon, required this.warna});

  final Ik ikon;
  final Color warna;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: warna.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: AppIcon(ikon, color: warna, size: 22),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final StatusAspirasi status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: status.warna.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppIcon(status.ikon, size: 13, color: status.warna),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: context.text.labelSmall?.copyWith(
              color: status.warna,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TandaContoh extends StatelessWidget {
  const _TandaContoh();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: context.semantic.line),
      ),
      child: Text(
        'data contoh',
        style: context.text.labelSmall?.copyWith(
          color: context.semantic.textSecondary,
        ),
      ),
    );
  }
}

/// Formulir kirim FISH (bottom sheet).
///
/// Validasi sengaja dibuat di layar, bukan cuma di repository: laporan dengan
/// judul kosong tidak pernah sampai ke daftar.
class FormFish extends ConsumerStatefulWidget {
  const FormFish({
    super.key,
    required this.pengirim,
    this.rt,
    this.rw,
  });

  final String pengirim;
  final String? rt;
  final String? rw;

  @override
  ConsumerState<FormFish> createState() => _FormFishState();
}

class _FormFishState extends ConsumerState<FormFish> {
  final TextEditingController _judul = TextEditingController();
  final TextEditingController _isi = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  KategoriAspirasi _kategori = KategoriAspirasi.layanan;
  bool _kirim = false;
  String? _galat;

  @override
  void dispose() {
    _judul.dispose();
    _isi.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double bawah = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.screen, 0, AppSpacing.screen, bawah + 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SectionHeader(title: 'Kirim FISH'),
              Text(
                'Aspirasi, laporan, atau pengaduan. Oleh ${widget.pengirim}'
                '${widget.rt == null ? '' : ' (RT ${widget.rt})'}.',
                style: context.text.bodySmall
                    ?.copyWith(color: context.semantic.textSecondary),
              ),
              const SizedBox(height: 16),
              Text('Topik', style: context.text.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final KategoriAspirasi k in KategoriAspirasi.values)
                    ChoiceChip(
                      label: Text(k.label),
                      avatar: AppIcon(k.ikon, size: 16, color: k.warna),
                      selected: _kategori == k,
                      selectedColor: k.warna.withValues(alpha: 0.16),
                      side: BorderSide(
                        color: _kategori == k
                            ? k.warna
                            : context.semantic.line,
                      ),
                      onSelected: (bool v) {
                        if (!v) return;
                        Haptics.selection();
                        setState(() => _kategori = k);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _judul,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Judul singkat',
                  hintText: 'Contoh: lampu jalan mati di RT 03',
                  border: OutlineInputBorder(),
                ),
                validator: (String? v) => (v == null || v.trim().length < 5)
                    ? 'Judul minimal 5 huruf.'
                    : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _isi,
                textCapitalization: TextCapitalization.sentences,
                minLines: 4,
                maxLines: 7,
                maxLength: 800,
                decoration: const InputDecoration(
                  labelText: 'Ceritakan detailnya',
                  hintText: 'Di mana, kapan, dan apa yang perlu diperbaiki.',
                  border: OutlineInputBorder(),
                ),
                validator: (String? v) => (v == null || v.trim().length < 15)
                    ? 'Ceritakan minimal 15 huruf biar warga lain paham.'
                    : null,
              ),
              if (_galat != null) ...<Widget>[
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    AppIcon(Ik.xCircle, size: 16, color: context.colors.error),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _galat!,
                        style: context.text.bodySmall
                            ?.copyWith(color: context.colors.error),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              PrimaryButton(
                label: 'Kirim',
                icon: Ik.chat,
                loading: _kirim,
                onPressed: _kirim ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _kirim = true;
      _galat = null;
    });

    final Hasil<Aspirasi> h = await ref.read(aspirasiProvider.notifier).kirim(
          judul: _judul.text,
          isi: _isi.text,
          kategori: _kategori,
          pengirim: widget.pengirim,
          rt: widget.rt,
          rw: widget.rw,
        );

    if (!mounted) return;
    if (h.berhasil) {
      // Pesan diambil SEBELUM pop. Setelah bottom sheet ditutup, context-nya
      // sudah tidak terpasang dan ScaffoldMessenger.of(context) akan
      // melempar exception tepat di layar yang paling baru saja sukses.
      final ScaffoldMessengerState snack = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      snack.showSnackBar(
        const SnackBar(content: Text('FISH terkirim. Terima kasih.')),
      );
    } else {
      setState(() {
        _kirim = false;
        _galat = h.galat?.pesan ?? 'Tidak diketahui kenapa gagal.';
      });
    }
  }
}
