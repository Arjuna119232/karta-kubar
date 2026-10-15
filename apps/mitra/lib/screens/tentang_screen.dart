import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Tentang aplikasi + FAQ ringkas (satu halaman, tidak perlu navigasi).
class TentangScreen extends StatelessWidget {
  const TentangScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Tentang & Bantuan')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            _KartuJudul('Tentang KUNBAR Mitra', [
              'Aplikasi untuk mitra dan kurir jastip serta ojek di Kuningan Barat.',
              'Semua data di aplikasi ini dihitung dari order yang benar-benar '
                  'selesai di perangkat kamu. Tidak ada data contoh yang disamarkan '
                  'jadi data asli.',
              'Peta memakai MapLibre dan OpenFreeMap - tidak memakai Google Maps '
                  'sehingga tidak ada biaya API.',
            ]),
            _KartuJudul('Pertanyaan sering muncul', [
              'Bagaimana cara ONLINE? - Tekan tombol AKTIFKAN di Beranda. '
                  'Selama ONLINE ada notifikasi yang tidak bisa dihapus.',
              'Kenapa order hilang sendiri? - Order yang tidak dibalas selama '
                  '30 detik otomatis dibatalkan.',
              'Kenapa GPS saya harus menyala? - Warga melihat posisi kamu '
                  'selama order aktif, dan sistem menandai GPS mati sebagai '
                  'peringatan.',
              'Bagaimana cara menarik saldo? - Pendapatan > Saldo Aktif > '
                  'Tarik Saldo, lalu pilih bank atau e-wallet.',
              'Kenapa chat tidak terkirim? - Chat memakai koneksi internet. '
                  'Cek banner sinyal hilang di Beranda.',
            ]),
            _KartuJudul('Data & privasi', [
              'Aplikasi hanya meminta izin yang dipakai: lokasi (saat order '
                  'aktif), notifikasi (order masuk), kamera/foto (bukti barang), '
                  'dan telepon (menelepon warga).',
              'Izin bisa dicabut kapan saja lewat menu Profil > Izin Aplikasi.',
            ]),
            SizedBox(height: 24),
            Center(
              child: Text('KUNBAR Mitra - From KATAR KUNBAR',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ),
          ],
        ),
      );
}

/// Halaman FAQ (dipisah supaya bisa dipanggil dari menu).
class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});
  @override
  Widget build(BuildContext context) => const TentangScreen();
}

class VerifikasiScreen extends StatelessWidget {
  const VerifikasiScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verifikasi Mitra')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Status dokumen',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  _baris('KTP', 'Menunggu verifikasi admin'),
                  _baris('SIM', 'Belum diunggah'),
                  _baris('STNK', 'Belum diunggah'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Kenapa tidak ada verifikasi otomatis? Karena tidak ada API publik '
            'untuk memeriksa KTP, SIM, atau STNK. Dokumen diverifikasi=subreti '
            'manual oleh pengurus lewat web panel, lalu statusnya muncul di sini.',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 10),
          const Text(
            'Sambil menunggu, mitra tetap bisa menerima order. '
            'Unggah dokumen lewat chat ke admin atau saat pendaftaran.',
            style: TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _baris(String kunci, String nilai) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(width: 60, child: Text(kunci, style: const TextStyle(fontSize: 13))),
            Expanded(
              child: Text(nilai,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
}

class _KartuJudul extends StatelessWidget {
  const _KartuJudul(this.judul, this.baris);
  final String judul;
  final List<String> baris;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(judul,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                for (final b in baris)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 6, right: 8),
                          child: Icon(Icons.circle, size: 6, color: AppColors.primary),
                        ),
                        Expanded(child: Text(b, style: const TextStyle(fontSize: 13))),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
}
