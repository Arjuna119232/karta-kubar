import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/order.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_icon.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/status_views.dart';
import '../../order/presentation/widgets_order.dart';
import '../data/mitra_usaha_lokal.dart';
import '../domain/mitra_usaha.dart';

/// Detail mitra usaha: peta, info, barang, dan tombol titip belanja.
class MitraUsahaDetailScreen extends StatelessWidget {
  const MitraUsahaDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final MitraUsaha? m = cariMitraUsaha(id);
    if (m == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mitra Usaha')),
        body: const AppEmptyState(
          title: 'Mitra tidak ditemukan',
          message: 'Data mitra ini tidak ada atau sudah dihapus.',
        ),
      );
    }
    final Color w = m.jenis.warna;
    return Scaffold(
      appBar: AppBar(title: Text(m.nama)),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: PrimaryButton(
            label: 'Titip belanja di sini',
            icon: Ik.package,
            onPressed: () => context.push('/jastip/form', extra: m),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen, 8, AppSpacing.screen, AppSpacing.xxl),
        children: <Widget>[
          PetaOrder(titik: <TitikPeta>[m.titik], penanda: w, tinggi: 200),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: w.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Center(child: AppIcon(m.jenis.ikon, size: 22, color: w)),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(m.nama, style: context.text.titleMedium),
                    Text(
                      m.jenis.label,
                      style: context.text.bodySmall
                          ?.copyWith(color: context.semantic.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(m.deskripsi, style: context.text.bodyMedium),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              children: <Widget>[
                _Info(ikon: Ik.pinMitra, teks: m.alamat),
                const SizedBox(height: AppSpacing.md),
                _Info(ikon: Ik.calendar, teks: 'Buka ${m.jamBuka}'),
                if (m.telepon != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  _Info(ikon: Ik.phone, teks: m.telepon!),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: PrimaryButton(
                  label: 'Buka di peta',
                  icon: Ik.pinMitra,
                  tone: PrimaryButtonTone.outlined,
                  onPressed: () => _bukaPeta(context, m),
                ),
              ),
              if (m.telepon != null) ...<Widget>[
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: PrimaryButton(
                    label: 'Telepon',
                    icon: Ik.phone,
                    tone: PrimaryButtonTone.outlined,
                    onPressed: () =>
                        launchUrl(Uri(scheme: 'tel', path: m.telepon!)),
                  ),
                ),
              ],
            ],
          ),
          if (m.produk.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.xl),
            const SectionHeader(title: 'Barang yang biasa dibeli'),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: <Widget>[
                  for (final (int i, ProdukUsaha p) in m.produk.indexed)
                    ...<Widget>[
                      if (i > 0)
                        Divider(height: 1, color: context.semantic.line),
                      ListTile(
                        title: Text(p.nama),
                        trailing: Text(
                          p.hargaKira == null
                              ? 'Harga bervariasi'
                              : '~ Rp ${_ribuan(p.hargaKira!)}',
                          style: context.text.bodySmall?.copyWith(
                              color: context.semantic.textSecondary),
                        ),
                      ),
                    ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Harga perkiraan (data contoh). Harga di toko bisa berbeda. '
              'Barang dibayar via QRIS, ditambah fee antar.',
              style: context.text.bodySmall
                  ?.copyWith(color: context.semantic.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  static String _ribuan(int n) {
    final String s = n.toString();
    final StringBuffer b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
      b.write(s[i]);
    }
    return b.toString();
  }

  Future<void> _bukaPeta(BuildContext context, MitraUsaha m) async {
    final Uri uri = Uri.parse(
      'geo:${m.titik.lat},${m.titik.lng}?q=${m.titik.lat},${m.titik.lng}'
      '(${Uri.encodeComponent(m.nama)})',
    );
    final bool ok = await launchUrl(uri);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada aplikasi peta di perangkat.')),
      );
    }
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.ikon, required this.teks});

  final Ik ikon;
  final String teks;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AppIcon(ikon, size: 20, color: context.colors.primary),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Text(teks, style: context.text.bodyMedium)),
      ],
    );
  }
}
