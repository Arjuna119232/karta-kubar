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

/// Detail mitra usaha: peta, jam buka, layanan, dan titip belanja via Jastip.
///
/// Nomor telepon sengaja tidak ditampilkan kalau belum ada. Menampilkan
/// nomor karangan lebih buruk daripada tidak menampilkan apa pun.
class MitraUsahaDetailScreen extends StatelessWidget {
  const MitraUsahaDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final MitraUsaha? m = mitraUsahaById(id);
    if (m == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mitra Usaha')),
        body: const AppEmptyState(
          title: 'Mitra tidak ditemukan',
          message: 'Data mitra ini tidak ada atau sudah dihapus.',
        ),
      );
    }
    final KategoriMitraUsaha k = m.kategoriUtama;
    final Color w = k.warna;
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: w.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Center(child: AppIcon(k.ikon, size: 24, color: w)),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(m.nama, style: context.text.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      '${m.kelurahan.nama} - ${jarakPendek(m.jarakDariPusatKm)} '
                      'dari pusat Kuningan Barat',
                      style: context.text.bodySmall
                          ?.copyWith(color: context.semantic.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: 6,
            children: <Widget>[
              _Lencana(
                teks: m.is24Jam ? 'Buka 24 jam' : 'Buka ${m.jamBuka}',
                warna: m.isOpen ? AppColors.success : AppColors.warning,
              ),
              _Lencana(
                teks: m.isOpen ? 'Buka sekarang' : 'Tutup sekarang',
                warna: m.isOpen ? AppColors.success : AppColors.warning,
              ),
              for (final KategoriMitraUsaha x in m.kategori)
                _Lencana(teks: x.label, warna: x.warna),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(m.fitur, style: context.text.bodyMedium),
          if (m.info != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              color: AppColors.primary.withValues(alpha: 0.08),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const AppIcon(Ik.dot, size: 18, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(m.info!, style: context.text.bodySmall),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              children: <Widget>[
                _Info(ikon: Ik.pinMitra, teks: m.alamat),
                const SizedBox(height: AppSpacing.md),
                _Info(ikon: Ik.clock, teks: 'Jam buka ${m.jamBuka}'),
                if (m.layanan.isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  _Info(
                    ikon: Ik.checkCircle,
                    teks: 'Layanan: ${m.layanan.join(', ')}',
                  ),
                ],
                if (m.noHp != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  _Info(ikon: Ik.phone, teks: m.noHp!),
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
              if (m.noHp != null) ...<Widget>[
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: PrimaryButton(
                    label: 'Telepon',
                    icon: Ik.phone,
                    tone: PrimaryButtonTone.outlined,
                    onPressed: () =>
                        launchUrl(Uri(scheme: 'tel', path: m.noHp!)),
                  ),
                ),
              ],
            ],
          ),
          if (produkUmum(k).isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.xl),
            const SectionHeader(title: 'Barang yang biasa ada di sini'),
            AppCard(
              padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.sm, horizontal: AppSpacing.md),
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: <Widget>[
                  for (final ProdukUsaha p in produkUmum(k))
                    _Lencana(teks: p.nama, warna: context.semantic.textSecondary),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Barang di atas jenis yang lazim ada di kategori ini, bukan '
              'daftar pasti mitra ini. Harga di toko bisa berbeda.',
              style: context.text.bodySmall
                  ?.copyWith(color: context.semantic.textSecondary),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'Cara pesan lewat Jastip'),
          _Langkah(
            nomor: '1',
            judul: 'Tulis daftar belanja',
            isi: 'Beras, minyak, telur, atau isi ulang galon - bebas.',
          ),
          _Langkah(
            nomor: '2',
            judul: 'Mitra menyiapkan pesanan',
            isi:
                'Mitra menerima pesanan dan menyiapkan barang. Pembayaran QRIS '
                'setelah barang siap.',
          ),
          _Langkah(
            nomor: '3',
            judul: 'Kurir antar',
            isi:
                'Kurir jemput dari mitra, antar ke alamat tujuan. Fee antar '
                'dihitung dari jarak dan ditampilkan sebelum konfirmasi.',
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Titik lokasi mitra masih perkiraan per jalan, bukan hasil survei '
            'GPS. Kalau ketemu lokasi yang lebih tepat, laporkan ke pengurus '
            'supaya bisa dikoreksi.',
            style: context.text.bodySmall
                ?.copyWith(color: context.semantic.textSecondary),
          ),
        ],
      ),
    );
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

class _Lencana extends StatelessWidget {
  const _Lencana({required this.teks, required this.warna});

  final String teks;
  final Color warna;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: warna.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        teks,
        style: context.text.labelSmall?.copyWith(color: warna),
      ),
    );
  }
}

class _Langkah extends StatelessWidget {
  const _Langkah({
    required this.nomor,
    required this.judul,
    required this.isi,
  });

  final String nomor;
  final String judul;
  final String isi;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                nomor,
                style: context.text.labelSmall
                    ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(judul, style: context.text.titleSmall),
                const SizedBox(height: 2),
                Text(
                  isi,
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
