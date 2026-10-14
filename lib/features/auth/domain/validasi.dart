/// Aturan validasi form masuk/daftar.
///
/// Dipisah ke `domain` supaya aturannya murni: tanpa `BuildContext`, tanpa
/// `TextFormField`, tanpa Flutter. Kalau nanti ada mode Supabase (email + sandi),
/// aturan email tinggal ditambah di sini dan dipakai dua form sekaligus.
///
/// Dipakai juga oleh unit test - kalau aturan validasi hanya hidup di dalam
/// widget, tidak ada cara mengujinya tanpa merakit seluruh form.
class ValidasiAkun {
  ValidasiAkun._();

  /// Nama wajib minimal 3 huruf. Tidak berlaku saat mode "masuk".
  static String? nama(String? nilai, {required bool wajib}) {
    if (!wajib) return null;
    if (nilai == null || nilai.trim().length < 3) return 'Nama minimal 3 huruf';
    return null;
  }

  /// Nomor telepon: 9-15 digit setelah semua karakter non-angka dibuang.
  static String? telepon(String? nilai) {
    final String t = hanyaAngka(nilai);
    if (t.length < 9) return 'Nomor WhatsApp tidak valid';
    if (t.length > 15) return 'Nomor terlalu panjang';
    return null;
  }

  /// Email sederhana - cukup untuk menangkap salah ketik, bukan RFC 5322.
  static String? email(String? nilai, {required bool wajib}) {
    if (!wajib) return null;
    final String v = (nilai ?? '').trim();
    if (v.isEmpty) return 'Email wajib diisi';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
      return 'Format email belum benar';
    }
    return null;
  }

  /// Buang semua karakter kecuali angka.
  static String hanyaAngka(String? nilai) =>
      (nilai ?? '').replaceAll(RegExp(r'\D'), '');

  /// Ubah `08xx` menjadi `+628xx` supaya format sama dengan data stored.
  static String keFormatInternasional(String? nilai) {
    final String t = hanyaAngka(nilai);
    if (t.isEmpty) return '';
    if (t.startsWith('62')) return '+$t';
    if (t.startsWith('0')) return '+62${t.substring(1)}';
    return '+$t';
  }
}