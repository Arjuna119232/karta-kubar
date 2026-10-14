import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_env.dart';
import 'hasil.dart';

/// Klien Supabase **tanpa paket pihak ketiga**.
///
/// Kenapa tidak pakai `supabase_flutter`?
///  - Adds fast 8-10 MB ke APK karena menarik banyak dependensi native.
///  - App ini butuh 3 hal saja: login, baca/tulis baris PostgREST, unggah
///    foto. Ketiganya adalah HTTP + JSON, jadi menulisnya ~200 baris lebih
///    ringan, transparan, dan jalan sama persis di Android maupun iOS.
///
/// Protocol yang dipakai (semua API resmi Supabase, bukan SOS):
///  - Auth   : POST /auth/v1/token?grant_type=password  (sign in)
///             POST /auth/v1/signup                      (daftar)
///             POST /auth/v1/logout                      (keluar)
///  - Data   : /rest/v1/<tabel>                          (PostgREST)
///  - Storage: POST /storage/v1/object/<bucket>/<path>   (unggah)
///
/// JWT Disimpan di [PenyimpanToken]. Implementasi bawaannya memakai
/// `shared_preferences`. Untuk rilis sungguhan, ganti dengan penyimpanan aman
/// (lihat `tool/README-keystore.md` bagian token).
class SupabaseRest {
  SupabaseRest({required AppEnv env, PenyimpanToken? penyimpanan})
      : _env = env,
        _token = penyimpanan ?? PenyimpanToken();

  final AppEnv _env;
  final PenyimpanToken _token;

  String? _accessToken;
  String? _userId;

  /// Token sesi terakhir (null kalau belum masuk).
  String? get accessToken => _accessToken;

  /// ID pengguna di Supabase (`auth.users.id`). Dipakai repository profil
  /// untuk membaca satu baris milik dirinya sendiri.
  String? get userId => _userId;

  void _setHeaderAkses(Map<String, String> h) {
    final String? t = _accessToken;
    if (t != null && t.isNotEmpty) {
      h['Authorization'] = 'Bearer $t';
    }
  }

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('${_env.supabaseUrl}$path').replace(
        queryParameters: query == null || query.isEmpty ? null : query,
      );

  /// Bangun header wajib: kunci API + preferensi bahasa.
  Map<String, String> _header({bool json = true}) {
    final Map<String, String> h = <String, String>{
      'apikey': _env.supabaseAnonKey,
      if (json) 'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Accept-Profile': _env.scheme,
      'Content-Profile': _env.scheme,
    };
    _setHeaderAkses(h);
    return h;
  }

  /// Ubah [GalatData] HTTP jadi bahasa manusia.
  GalatData _galatDari(int kode, String body) {
    String pesan;
    String? kodeMesin;
    try {
      final dynamic j = jsonDecode(body);
      if (j is Map && j['error_description'] != null) {
        pesan = j['error_description'].toString();
        kodeMesin = j['error_code']?.toString();
      } else if (j is Map && j['message'] != null) {
        pesan = j['message'].toString();
      } else {
        pesan = 'Server menjawab $kode.';
      }
    } catch (_) {
      pesan = 'Server menjawab $kode.';
    }
    if (kode == 401) pesan = 'Sesi tidak valid. Masuk ulang.';
    if (kode == 403) pesan = 'Kamu tidak punya izin untuk ini.';
    if (kode == 404) pesan = 'Data tidak ditemukan.';
    if (kode == 42501) pesan = 'Akses ditolak oleh aturan database (RLS).';
    return GalatData(pesan, kode: kodeMesin ?? '$kode', asli: body);
  }

  Future<Hasil<Map<String, dynamic>>> _kirim(
    String method,
    Uri url,
    Object? body, {
    Map<String, String>? header,
  }) async {
    if (!_env.supabaseSiap) {
      return Hasil<Map<String, dynamic>>.galat(
        const GalatData(
          'Backend belum dikonfigurasi. Isi .env lalu build dengan '
          '--dart-define=SUMBER_DATA=supabase.',
          kode: 'env_kosong',
        ),
      );
    }
    try {
      final HttpClient client = _klien();
      final HttpClientRequest req = await client.openUrl(method, url);
      final Map<String, String> h = header ?? _header();
      h.forEach(req.headers.add);
      if (body != null) req.write(jsonEncode(body));
      final HttpClientResponse res = await req.close().timeout(
            const Duration(seconds: 20),
          );
      final String teks = await res.transform(utf8.decoder).join();
      if (res.statusCode < 200 || res.statusCode >= 300) {
        return Hasil<Map<String, dynamic>>.gagal(_galatDari(res.statusCode, teks));
      }
      if (teks.trim().isEmpty) {
        return const Hasil<Map<String, dynamic>>.berhasil(<String, dynamic>{});
      }
      final dynamic j = jsonDecode(teks);
      return Hasil<Map<String, dynamic>>.berhasil(
        j is Map<String, dynamic> ? j : <String, dynamic>{'data': j},
      );
    } on TimeoutException {
      return Hasil<Map<String, dynamic>>.galat(
        const GalatData('Server tidak menjawab dalam 20 detik.', kode: 'timeout'),
      );
    } catch (e) {
      return Hasil<Map<String, dynamic>>.gagal(
        GalatData(
          'Tidak bisa menghubungi server. Cek internet dan konfigurasi backend.',
          kode: 'jaringan',
          asli: e.toString(),
        ),
      );
    }
  }

  // ---------------- AUTH ----------------

  /// Masuk dengan email + sandi. [password] tidak pernah dicatat di log.
  Future<Hasil<SesiSupabase>> masuk(String email, String password) async {
    final Hasil<Map<String, dynamic>> r = await _kirim(
      'POST',
      _uri('/auth/v1/token', <String, String>{'grant_type': 'password'}),
      <String, String>{'email': email, 'password': password},
    );
    return r.peta((j) => _sesiDari(j));
  }

  /// Daftar akun baru.
  Future<Hasil<SesiSupabase>> daftar(
    String email,
    String password,
  ) async {
    final Hasil<Map<String, dynamic>> r = await _kirim(
      'POST',
      _uri('/auth/v1/signup'),
      <String, String>{'email': email, 'password': password},
    );
    return r.peta((j) => _sesiDari(j));
  }

  Future<Hasil<void>> keluar() async {
    _accessToken = null;
    _userId = null;
    await _token.hapus();
    return _kirim('POST', _uri('/auth/v1/logout'), null);
  }

  /// Coba pakai token hasil login sebelumnya.
  Future<bool> pulihkanSesi() async {
    final String? t = await _token.baca();
    if (t == null || t.isEmpty) return false;
    _accessToken = t;
    return true;
  }

  SesiSupabase _sesiDari(Map<String, dynamic> j) {
    final String? token = j['access_token'] as String?;
    if (token != null && token.isNotEmpty) {
      _accessToken = token;
      _token.simpan(token);
    }
    final Map<String, dynamic>? u = j['user'] as Map<String, dynamic>?;
    final String id = u?['id'] as String? ?? '';
    if (id.isNotEmpty) _userId = id;
    return SesiSupabase(
      tokenAkses: token ?? '',
      userId: id,
      email: u?['email'] as String? ?? '',
    );
  }

  // ---------------- DATA (PostgREST) ----------------

  /// Baca baris dari [tabel], dengan urutan [urut] mis. `id.desc`.
  Future<Hasil<List<Map<String, dynamic>>>> baca(
    String tabel, {
    String? urut,
    int? batas,
    Map<String, String>? filter,
  }) async {
    final Map<String, String> q = <String, String>{'select': '*'};
    if (urut != null) q['order'] = urut;
    if (batas != null) q['limit'] = '$batas';
    if (filter != null) {
      filter.forEach((String kolom, String nilai) {
        q[kolom] = 'eq.$nilai';
      });
    }
    final Hasil<Map<String, dynamic>> r = await _kirim(
      'GET',
      _uri('/rest/v1/$tabel', q),
      null,
    );
    return r.peta((j) {
      final dynamic data = j['data'];
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .toList(growable: false);
      }
      return <Map<String, dynamic>>[];
    });
  }

  /// Tambah satu baris.
  Future<Hasil<void>> sisip(
    String tabel,
    Map<String, dynamic> baris,
  ) async {
    final Hasil<Map<String, dynamic>> r = await _kirim(
      'POST',
      _uri('/rest/v1/$tabel'),
      baris,
      header: _headerTambah(<String, String>{'Prefer': 'return=minimal'}),
    );
    return r.peta((_) {});
  }

  /// Ubah baris yang cocok dengan [filter].
  Future<Hasil<void>> ubah(
    String tabel,
    Map<String, dynamic> baris,
    Map<String, String> filter,
  ) async {
    final Map<String, String> q = <String, String>{};
    filter.forEach((String kolom, String nilai) {
      q[kolom] = 'eq.$nilai';
    });
    // ignore: unnecessary_statements
    final Hasil<Map<String, dynamic>> r = await _kirim(
      'PATCH',
      _uri('/rest/v1/$tabel', q),
      baris,
      header: _headerTambah(<String, String>{'Prefer': 'return=minimal'}),
    );
    return r.peta((_) {});
  }

  Map<String, String> _headerTambah(Map<String, String> tambahan) =>
      <String, String>{..._header(), ...tambahan};

  // ---------------- STORAGE ----------------

  /// Unggah bytes ke bucket [bucket] pada path [jalur].
  Future<Hasil<String>> unggah(
    String bucket,
    String jalur,
    List<int> bytes, {
    String tipeKonten = 'application/octet-stream',
  }) async {
    if (!_env.supabaseSiap) {
      return const Hasil<String>.galat(
        GalatData('Backend belum dikonfigurasi.', kode: 'env_kosong'),
      );
    }
    try {
      final HttpClient client = _klien();
      final Uri url = _uri(
        '/storage/v1/object/$bucket/$jalur',
      );
      final HttpClientRequest req = await client.putUrl(url);
      <String, String>{
        'apikey': _env.supabaseAnonKey,
        'Authorization': 'Bearer ${_accessToken ?? ''}',
        'Content-Type': tipeKonten,
        'x-upsert': 'true',
      }.forEach(req.headers.add);
      req.add(bytes);
      final HttpClientResponse res = await req.close().timeout(
            const Duration(seconds: 40),
          );
      if (res.statusCode < 200 || res.statusCode >= 300) {
        final String t = await res.transform(utf8.decoder).join();
        return Hasil<String>.galat(_galatDari(res.statusCode, t));
      }
      return Hasil<String>.berhasil(jalur);
    } catch (e) {
      return Hasil<String>.galat(
        GalatData('Gagal mengunggah berkas.', kode: 'unggah', asli: e.toString()),
      );
    }
  }

  HttpClient _klien() => HttpClient()
    ..connectionTimeout = const Duration(seconds: 12);
}

/// Sesi hasil login Supabase.
@immutable
class SesiSupabase {
  const SesiSupabase({
    required this.tokenAkses,
    required this.userId,
    required this.email,
  });

  final String tokenAkses;
  final String userId;
  final String email;
}

/// Tempat menyimpan token akses.
///
/// Default memakai `shared_preferences` supaya sesi masih hidup setelah aplikasi
/// ditutup. Untuk rilis sungguhan, ganti isi [baca]/[simpan] dengan penyimpanan
/// aman (`flutter_secure_storage` untuk Android + iOS, atau Keychain langsung).
/// Alasannya: `shared_preferences` menulis teks polos, dan token sesi adalah
/// kunci untuk data warga - di perangkat lama/root itu bisa dibaca.
class PenyimpanToken {
  PenyimpanToken({this.kunci = 'supabase_access_token'});

  final String kunci;

  String? _cache;

  Future<String?> baca() async {
    if (_cache != null) return _cache;
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      _cache = p.getString(kunci);
    } catch (_) {
      // Penyimpanan tidak terbaca: anggap belum masuk, bukan error fatal.
      _cache = null;
    }
    return _cache;
  }

  Future<void> simpan(String token) async {
    _cache = token;
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setString(kunci, token);
    } catch (_) {
      // Token tetap ada di memori untuk sesi berjalan ini.
    }
  }

  Future<void> hapus() async {
    _cache = null;
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.remove(kunci);
    } catch (_) {
      // Tidak fatal: pengguna sudah dianggap keluar di memori.
    }
  }
}
