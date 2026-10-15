import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme.dart';
import '../services/kotak_masuk.dart';
import 'widgets.dart';

/// Detail notifikasi: kategori, waktu, isi lengkap, tombol aksi.
class DetailNotifikasiScreen extends StatelessWidget {
  const DetailNotifikasiScreen({super.key, required this.n});
  final NotifikasiMk n;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(n.kategori.label)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: n.kategori.warna.withValues(alpha: 0.16),
                child: Icon(n.kategori.ikon, color: n.kategori.warna, size: 30),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: n.kategori.warna.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(n.kategori.label,
                        style: TextStyle(
                            color: n.kategori.warna, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(height: 4),
                  Text('${n.waktu.day}/${n.waktu.month}/${n.waktu.year} - '
                      '${n.waktu.hour.toString().padLeft(2, '0')}:'
                      '${n.waktu.minute.toString().padLeft(2, '0')}'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(n.judul, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text(n.isi, style: const TextStyle(fontSize: 16, height: 1.5)),
          if (n.lampiranUrl != null) ...[
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.attach_file_rounded),
                title: const Text('Lampiran'),
                subtitle: Text(n.lampiranUrl!),
                onTap: () => launchUrl(Uri.parse(n.lampiranUrl!),
                    mode: LaunchMode.externalApplication),
              ),
            ),
          ],
          const SizedBox(height: 20),
          if (n.ctaUrl != null)
            FilledButton.icon(
              onPressed: () => launchUrl(Uri.parse(n.ctaUrl!),
                  mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.open_in_new_rounded),
              label: Text(n.ctaLabel ?? 'Buka'),
            ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => NotifikasiService.instance.tandaiBelumDibaca(n.id),
            icon: const Icon(Icons.mark_email_unread_outlined),
            label: const Text('Tandai belum dibaca'),
          ),
          const SizedBox(height: 20),
          const Text(
            'Kotak Masuk hanya berisi informasi resmi dari pengurus KUNBAR. '
            'Tidak ada iklan dan tidak ada permintaan data pribadi.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
