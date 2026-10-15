import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';

/// Edit profil mitra: nama, telepon (kunci), email, alamat.
class EditProfilScreen extends StatefulWidget {
  const EditProfilScreen({super.key});
  @override
  State<EditProfilScreen> createState() => _EditProfilScreenState();
}

class _EditProfilScreenState extends State<EditProfilScreen> {
  late final TextEditingController _nama;
  late final TextEditingController _telepon;
  late final TextEditingController _alamat;
  bool _simpan = false;

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>();
    _nama = TextEditingController(text: s.name);
    _telepon = TextEditingController(text: s.telepon);
    _alamat = TextEditingController(text: s.alamat);
  }

  @override
  void dispose() {
    _nama.dispose();
    _telepon.dispose();
    _alamat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: const Color(0xFFE8F5E9),
                  child: Text(
                    (_nama.text.trim().isEmpty ? 'M' : _nama.text.trim()[0]).toUpperCase(),
                    style: const TextStyle(
                        fontSize: 34, fontWeight: FontWeight.w800, color: Color(0xFF1B5E20)),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: const Color(0xFF1B5E20),
                    child: const Icon(Icons.camera_alt_rounded, size: 15, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nama,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Nama lengkap'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _telepon,
            keyboardType: TextInputType.phone,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Nomor HP',
              helperText: 'Nomor HP belum bisa diubah sendiri. Hubungi admin.',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Email',
              helperText: s.email.isEmpty ? 'Belum diisi' : s.email,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _alamat,
            decoration: const InputDecoration(
              labelText: 'Alamat',
              hintText: 'Contoh: RT 05 RW 05 Kuningan Barat',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _simpan || _nama.text.trim().length < 3
                ? null
                : () async {
                    setState(() => _simpan = true);
                    context.read<AppState>().simpanProfil(
                          namaBaru: _nama.text,
                          teleponBaru: _telepon.text,
                          alamatBaru: _alamat.text,
                        );
                    if (!mounted) return;
                    setState(() => _simpan = false);
                    Navigator.pop(context);
                  },
            child: _simpan
                ? const SizedBox(
                    height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 3))
                : const Text('SIMPAN'),
          ),
        ],
      ),
    );
  }
}
