import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import 'widgets.dart';

/// Daftar jadi mitra. Ini menggantikan verifikasi otomatis: KTP/SIM/STNK diverifikasi
/// admin di web panel, jadi di sini hanya data diri + kendaraan.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nama = TextEditingController();
  final _email = TextEditingController();
  final _sandi = TextEditingController();
  final _telepon = TextEditingController();
  final _plat = TextEditingController();
  String _kendaraan = 'Motor';
  bool _setuju = false;
  bool _sembunyi = true;

  @override
  void dispose() {
    _nama.dispose();
    _email.dispose();
    _sandi.dispose();
    _telepon.dispose();
    _plat.dispose();
    super.dispose();
  }

  String? _validasi() {
    if (_nama.text.trim().length < 3) return 'Nama minimal 3 huruf';
    if (!_email.text.contains('@')) return 'Email belum benar';
    if (_sandi.text.length < 6) return 'Password minimal 6 karakter';
    final t = _telepon.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (t.length < 9) return 'Nomor HP minimal 9 angka';
    if (_plat.text.trim().isEmpty) return 'Plat nomor masih kosong';
    if (!_setuju) return 'Centang syarat dulu';
    return null;
  }

  Future<void> _kirim() async {
    final salah = _validasi();
    if (salah != null) {
      toast(context, salah);
      return;
    }
    final s = context.read<AppState>();
    final err = await s.daftar(
      nama: _nama.text.trim(),
      email: _email.text.trim(),
      password: _sandi.text,
      telepon: _telepon.text.trim(),
      kendaraan: _kendaraan,
      plat: _plat.text.trim(),
    );
    if (!mounted) return;
    if (err != null) {
      toast(context, err);
    } else {
      toast(context, 'Akun mitra dibuat. Lanjut isi izin aplikasi.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Mitra')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Lengkapi data berikut',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text(
            'Data KTP/SIM/STNK diverifikasi pengurus lewat web panel, jadi di sini cukup data diri dan kendaraan.',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nama,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Nama lengkap'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _sandi,
            obscureText: _sembunyi,
            decoration: InputDecoration(
              labelText: 'Password',
              suffixIcon: IconButton(
                icon: Icon(_sembunyi ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _sembunyi = !_sembunyi),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _telepon,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Nomor HP / WhatsApp'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _kendaraan,
            decoration: const InputDecoration(labelText: 'Kendaraan'),
            items: const [
              DropdownMenuItem(value: 'Motor', child: Text('Motor')),
              DropdownMenuItem(value: 'Mobil', child: Text('Mobil')),
              DropdownMenuItem(value: 'Sepeda', child: Text('Sepeda')),
            ],
            onChanged: (v) => setState(() => _kendaraan = v ?? 'Motor'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _plat,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(labelText: 'Plat nomor'),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            value: _setuju,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text(
              'Saya setuju data saya dipakai untuk keperluan layanan mitra KUNBAR.',
              style: TextStyle(fontSize: 14),
            ),
            onChanged: (v) => setState(() => _setuju = v ?? false),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: s.loading ? null : _kirim,
            child: s.loading
                ? const SizedBox(
                    height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3))
                : const Text('DAFTAR'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Sudah punya akun? Masuk'),
          ),
        ],
      ),
    );
  }
}