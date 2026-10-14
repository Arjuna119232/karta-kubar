import '../../../core/auth/user_role.dart';
import '../../../core/config/app_config.dart';
import '../../../core/data/hasil.dart';
import '../../../core/data/supabase_rest.dart';

/// Hasil proses masuk.
class HasilMasuk {
  const HasilMasuk({required this.userId, required this.nama, required this.role});

  final String userId;
  final String nama;
  final UserRole role;
}

/// Kontrak sumber data untuk masuk dan profil sederhana.
///
/// Layar auth TIDAK boleh bicara langsung ke Supabase maupun ke penyimpanan
/// perangkat - semuanya lewat sini, supaya mode demo dan mode sungguhan punya
/// kontrak yang sama persis.
abstract class AuthRepository {
  String get namaSumber;

  /// True kalau repository ini butuh OTP / kode verifikasi (mode Supabase).
  bool get butuhOtp;

  Future<Hasil<String>> kirimOtp(String nomor);

  Future<Hasil<HasilMasuk>> masuk({
    required String nomor,
    required String kode,
  });

  Future<void> keluar();
}

/// Repository mode demo: kode OTP selalu `123456`, data disimpan di perangkat.
///
/// Dipakai kalau `SUMBER_DATA=lokal` atau konfigurasi backend belum ada.
class AuthLokalRepository implements AuthRepository {
  const AuthLokalRepository();

  @override
  String get namaSumber => 'Mode demo (data di perangkat)';

  @override
  bool get butuhOtp => true;

  static const String kodeDemo = '123456';

  @override
  Future<Hasil<String>> kirimOtp(String nomor) async {
    if (nomor.trim().length < 9) {
      return const Hasil<String>.galat(
        GalatData('Nomor HP belum benar.', kode: 'nomor'),
      );
    }
    return const Hasil<String>.berhasil(kodeDemo);
  }

  @override
  Future<Hasil<HasilMasuk>> masuk({
    required String nomor,
    required String kode,
  }) async {
    if (kode.trim() != kodeDemo) {
      return const Hasil<HasilMasuk>.galat(
        GalatData('Kode OTP salah. Untuk mode demo kodenya $kodeDemo.',
            kode: 'otp_salah'),
      );
    }
    return Hasil<HasilMasuk>.berhasil(
      HasilMasuk(
        userId: 'demo-$nomor',
        nama: 'Warga KUNBAR',
        role: UserRole.warga,
      ),
    );
  }

  @override
  Future<void> keluar() async {}
}

/// Repository Supabase: email + sandi, role diambil dari baris `profiles`.
class AuthSupabaseRepository implements AuthRepository {
  AuthSupabaseRepository(this._rest);

  final SupabaseRest _rest;

  @override
  String get namaSumber => 'Supabase';

  @override
  bool get butuhOtp => false;

  @override
  Future<Hasil<String>> kirimOtp(String nomor) async =>
      const Hasil<String>.galat(
        GalatData(
          'Supabase memakai email + sandi, bukan OTP. '
          'Form masuk akan menyesuaikan sendiri.',
          kode: 'otp_tidak_didukung',
        ),
      );

  @override
  Future<Hasil<HasilMasuk>> masuk({
    required String nomor,
    required String kode,
  }) async {
    // Pada mode ini `nomor` berisi email dan `kode` berisi sandi.
    final Hasil<SesiSupabase> r = await _rest.masuk(nomor.trim(), kode);
    if (!r.berhasil) return Hasil<HasilMasuk>.gagal(r.galat!);
    final SesiSupabase s = r.data!;
    return Hasil<HasilMasuk>.berhasil(
      HasilMasuk(
        userId: s.userId,
        nama: s.email,
        role: await _bacaRole(s.userId),
      ),
    );
  }

  Future<UserRole> _bacaRole(String userId) async {
    if (userId.isEmpty) return UserRole.warga;
    final Hasil<List<Map<String, dynamic>>> r = await _rest.baca(
      'profiles',
      filter: <String, String>{'id': userId},
      batas: 1,
    );
    if (!r.berhasil || r.data!.isEmpty) return UserRole.warga;
    return roleDariBaris(r.data!.first);
  }

  @override
  Future<void> keluar() async {
    await _rest.keluar();
  }
}

/// Petakan baris tabel `profiles` ke [UserRole].
///
/// Default selalu `warga`: kalau baris belum ada atau nilainya aneh, hak akses
/// TIDAK boleh naik diam-diam. Naik role harus lewat admin.
UserRole roleDariBaris(Map<String, dynamic> baris) {
  final String v = '${baris['role'] ?? baris['peran'] ?? ''}'.toLowerCase();
  return UserRole.values.firstWhere(
    (UserRole r) => r.name == v,
    orElse: () => UserRole.warga,
  );
}

AuthRepository buatAuthRepository() {
  if (AppConfig.pakaiSupabase) {
    return AuthSupabaseRepository(SupabaseRest(env: AppConfig.env));
  }
  return const AuthLokalRepository();
}