import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/auth/session.dart';
import '../../../core/data/hasil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/app_icon.dart';
import '../../../shared/widgets/fade_slide_in.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/status_views.dart';
import '../data/umkm_repository.dart';
import '../domain/umkm.dart';
import '../../../shared/widgets/loading_dots.dart';
import '../../../core/utils/haptics.dart';
import '../../../shared/widgets/animated_fab.dart';
import '../../../shared/widgets/shimmer_box.dart';

/// Katalog UMKM warga: lihat semua, ajukan usaha baru.
class UmkmScreen extends ConsumerStatefulWidget {
  const UmkmScreen({super.key});

  @override
  ConsumerState<UmkmScreen> createState() => _UmkmScreenState();
}

class _UmkmScreenState extends ConsumerState<UmkmScreen> {
  /// null = semua kategori.
  KategoriUmkm? _filter;

  @override
  Widget build(BuildContext context) {
    final Session session = ref.watch(sessionProvider);
    final AsyncValue<List<Umkm>> state = ref.watch(umkmProvider);
    final List<Umkm> semua = state.valueOrNull ?? <Umkm>[];
    final List<Umkm> data = _filter == null
        ? semua
        : semua
            .where((Umkm u) => u.kategori == _filter)
            .toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: const Text('UMKM Warga')),
      floatingActionButton: AnimatedFab(
        icon: Ik.addPhoto,
        label: 'Ajukan Usaha',
        onPressed: () => _bukaForm(session),
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () => ref.read(umkmProvider.notifier).muatUlang(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen, 8, AppSpacing.screen, 110),
            children: <Widget>[
              _Ringkasan(jumlah: semua.length),
              const SizedBox(height: 16),
              _Filter(
                aktif: _filter,
                onPilih: (KategoriUmkm? v) {
                  Haptics.selection();
                  setState(() => _filter = v);
                },
              ),
              const SizedBox(height: 16),
              if (state.isLoading && semua.isEmpty)
                const ShimmerListSkeleton(
                    itemCount: 4, itemHeight: 104, padding: EdgeInsets.zero)
              else if (state.hasError && semua.isEmpty)
                AppErrorState(
                  onRetry: () => ref.read(umkmProvider.notifier).muatUlang(),
                )
              else if (semua.isEmpty)
                AppEmptyState(
                  title: 'Belum ada UMKM terdaftar',
                  message: session.sudahLogin
                      ? 'Jadilah yang pertama. Ajukan usaha lewat tombol di bawah.'
                      : 'Katalog akan terisi setelah warga mengajukan usaha.',
                )
              else if (data.isEmpty)
                AppEmptyState(
                  title: 'Kosong di kategori ini',
                  message: 'Ubah filter di atas untuk melihat yang lain.',
                  actionLabel: 'Lihat semua',
                  onAction: () => setState(() => _filter = null),
                )
              else
                for (final (int i, Umkm u) in data.indexed)
                  FadeSlideIn(
                    index: i,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.gap),
                      child: _KartuUmkm(item: u),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  void _bukaForm(Session session) {
    Haptics.medium();
    AppSheet.tampilkan<void>(
      context,
      judul: 'Ajukan UMKM',
      isi: const FormUmkm(),
    );
  }
}

class _Ringkasan extends StatelessWidget {
  const _Ringkasan({required this.jumlah});

  final int jumlah;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: AppIcon(Ik.handHeart, color: context.colors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('$jumlah usaha warga',
                    style: context.text.titleMedium),
                const SizedBox(height: 2),
                Text(
                  'Usaha bertanda centang sudah diverifikasi pengurus.',
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

class _Filter extends StatelessWidget {
  const _Filter({required this.aktif, required this.onPilih});

  final KategoriUmkm? aktif;
  final ValueChanged<KategoriUmkm?> onPilih;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          _ChipUmkm(
            label: 'Semua',
            selected: aktif == null,
            onTap: () => onPilih(null),
          ),
          for (final KategoriUmkm k in KategoriUmkm.values)
            _ChipUmkm(
              label: k.label,
              selected: aktif == k,
              onTap: () => onPilih(k),
            ),
        ],
      ),
    );
  }
}

class _ChipUmkm extends StatelessWidget {
  const _ChipUmkm({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? context.colors.primary : context.semantic.card,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.button),
              border: Border.all(
                color: selected ? context.colors.primary : context.semantic.line,
              ),
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

class _KartuUmkm extends StatelessWidget {
  const _KartuUmkm({required this.item});

  final Umkm item;

  @override
  Widget build(BuildContext context) {
    final Color tinta = context.semantic.textSecondary;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: context.colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: AppIcon(item.kategori.ikon,
                    color: context.colors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(item.nama,
                        style: context.text.titleSmall, maxLines: 1),
                    const SizedBox(height: 2),
                    Text(
                      item.kategori.label,
                      style: context.text.labelSmall
                          ?.copyWith(color: context.colors.primary),
                    ),
                  ],
                ),
              ),
              if (item.diverifikasi)
                AppIcon(Ik.checkCircle, size: 20, color: context.semantic.success),
            ],
          ),
          const SizedBox(height: 12),
          Text(item.deskripsi, style: context.text.bodyMedium),
          const SizedBox(height: 12),
          if (item.alamat.isNotEmpty)
            Row(
              children: <Widget>[
                AppIcon(Ik.place, size: 14, color: tinta),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.alamat,
                    style: context.text.bodySmall?.copyWith(color: tinta),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          if (item.jamBuka != null && item.jamBuka!.isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            Row(
              children: <Widget>[
                AppIcon(Ik.clock, size: 14, color: tinta),
                const SizedBox(width: 6),
                Text(
                  item.jamBuka!,
                  style: context.text.bodySmall?.copyWith(color: tinta),
                ),
              ],
            ),
          ],
          if (item.noTelepon != null && item.noTelepon!.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _telepon(context, item.noTelepon!),
              icon: const AppIcon(Ik.phone, size: 18),
              label: const Text('Hubungi'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
            ),
          ],
          if (item.contoh) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              'data contoh',
              style: context.text.labelSmall?.copyWith(color: tinta),
            ),
          ],
        ],
      ),
    );
  }

  void _telepon(BuildContext context, String nomor) {
    Haptics.selection();
    launchUrl(Uri(scheme: 'tel', path: nomor));
  }
}

/// Form pengajuan usaha (bottom sheet).
class FormUmkm extends ConsumerStatefulWidget {
  const FormUmkm({super.key});

  @override
  ConsumerState<FormUmkm> createState() => _FormUmkmState();
}

class _FormUmkmState extends ConsumerState<FormUmkm> {
  final TextEditingController _nama = TextEditingController();
  final TextEditingController _deskripsi = TextEditingController();
  final TextEditingController _alamat = TextEditingController();
  final TextEditingController _telepon = TextEditingController();
  final TextEditingController _jam = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  KategoriUmkm _kategori = KategoriUmkm.makanan;
  bool _kirim = false;
  String? _galat;

  @override
  void dispose() {
    _nama.dispose();
    _deskripsi.dispose();
    _alamat.dispose();
    _telepon.dispose();
    _jam.dispose();
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
              const SectionHeader(title: 'Ajukan Usaha'),
              Text(
                'Setelah diajukan, pengurus akan memverifikasi. Usaha belum '
                'bertanda centang sampai disetujui.',
                style: context.text.bodySmall
                    ?.copyWith(color: context.semantic.textSecondary),
              ),
              const SizedBox(height: 16),
              Text('Kategori', style: context.text.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final KategoriUmkm k in KategoriUmkm.values)
                    ChoiceChip(
                      label: Text(k.label),
                      avatar: AppIcon(k.ikon, size: 16),
                      selected: _kategori == k,
                      selectedColor: context.colors.primary.withValues(alpha: 0.16),
                      side: BorderSide(
                        color: _kategori == k
                            ? context.colors.primary
                            : context.semantic.line,
                      ),
                      onSelected: (bool v) {
                        if (!v) return;
                        setState(() => _kategori = k);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nama,
                textCapitalization: TextCapitalization.words,
                maxLength: 60,
                decoration: const InputDecoration(
                  labelText: 'Nama usaha',
                  hintText: 'Contoh: Warung Bu Imas',
                  border: OutlineInputBorder(),
                ),
                validator: (String? v) => (v == null || v.trim().length < 3)
                    ? 'Nama usaha minimal 3 huruf.'
                    : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _deskripsi,
                textCapitalization: TextCapitalization.sentences,
                minLines: 3,
                maxLines: 5,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi',
                  hintText: 'Apa yang dijual atau layanan apa yang diberi.',
                  border: OutlineInputBorder(),
                ),
                validator: (String? v) => (v == null || v.trim().length < 15)
                    ? 'Deskripsi minimal 15 huruf.'
                    : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _alamat,
                textCapitalization: TextCapitalization.words,
                maxLength: 120,
                decoration: const InputDecoration(
                  labelText: 'Alamat',
                  hintText: 'Contoh: Jl. Melati RT 03 / RW 05',
                  border: OutlineInputBorder(),
                ),
                validator: (String? v) => (v == null || v.trim().isEmpty)
                    ? 'Alamat wajib diisi.'
                    : null,
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      controller: _telepon,
                      keyboardType: TextInputType.phone,
                      maxLength: 20,
                      decoration: const InputDecoration(
                        labelText: 'No. WhatsApp',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _jam,
                      maxLength: 20,
                      decoration: const InputDecoration(
                        labelText: 'Jam buka',
                        hintText: '08.00 - 21.00',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              if (_galat != null) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  _galat!,
                  style: context.text.bodySmall
                      ?.copyWith(color: context.colors.error),
                ),
              ],
              const SizedBox(height: 14),
              FilledButton(
                onPressed: _kirim ? null : _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                ),
                child: _kirim
                    ? const SizedBox(
                        height: 22,
                        child: LoadingDots(color: AppColors.white, size: 8),
                      )
                    : const Text('Kirim pengajuan'),
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

    final Hasil<Umkm> h = await ref.read(umkmProvider.notifier).ajukan(
          nama: _nama.text,
          deskripsi: _deskripsi.text,
          alamat: _alamat.text,
          kategori: _kategori,
          noTelepon: _telepon.text.trim().isEmpty ? null : _telepon.text.trim(),
          jamBuka: _jam.text.trim().isEmpty ? null : _jam.text.trim(),
        );

    if (!mounted) return;
    if (h.berhasil) {
      // Pesan diambil SEBELUM pop: setelah sheet ditutup context-nya mati.
      final ScaffoldMessengerState snack = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      snack.showSnackBar(
        const SnackBar(content: Text('Pengajuan terkirim, tunggu verifikasi.')),
      );
    } else {
      setState(() {
        _kirim = false;
        _galat = h.galat?.pesan ?? 'Tidak diketahui kenapa gagal.';
      });
    }
  }
}
