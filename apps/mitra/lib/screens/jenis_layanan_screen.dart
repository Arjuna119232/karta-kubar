import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../state/app_state.dart';

/// Layanan yang diterima mitra: jastip, ojek, kurir.
class JenisLayananScreen extends StatelessWidget {
  const JenisLayananScreen({super.key});

  static const _layanan = [
    (
      'jastip',
      'Jastip (Jasa Titip)',
      'Beli atau ambil barang di toko, lalu antar ke warga.',
      Icons.shopping_bag_rounded,
    ),
    (
      'ojek',
      'Ojek (Antar Jemput)',
      'Antar warga ke tujuan nearer di sekitar kelurahan.',
      Icons.two_wheeler_rounded,
    ),
    (
      'kurir',
      'Kurir (Antar Barang)',
      'Antar barang antar warga tanpa harus naik motor.',
      Icons.local_shipping_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    bool aktif(String kode) => switch (kode) {
          'jastip' => s.jenisJastip,
          'ojek' => s.jenisOjek,
          _ => s.jenisKurir,
        };

    return Scaffold(
      appBar: AppBar(title: const Text('Jenis Layanan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Matikan layanan yang tidak kamu kerjakan. Order dari layanan yang '
            'dimatikan tidak akan masuk ke daftar kamu.',
          ),
          const SizedBox(height: 16),
          for (final (kode, judul, isi, ikon) in _layanan)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primarySoft,
                      child: Icon(ikon, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(judul,
                              style:
                                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          Text(isi, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    Switch(
                      value: aktif(kode),
                      onChanged: (v) => s.setToggle(kode, v),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          const Text(
            'Perubahan langsung tersimpan di perangkat ini.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
