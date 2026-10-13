import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'user_role.dart';

/// Kunci penyimpanan sesi.
///
/// Dipublikasikan supaya file lain (splash) membaca kunci yang sama persis —
/// jangan tulis ulang string "kubar_role" di tempat lain, karena nanti
/// bisa berbeda diam-diam.
abstract final class SessionKeys {
  /// Nama-nama user tersimpan sebagai JSON.
  static const String user = 'kubar_user';

  /// Role aktif, disimpan sebagai `UserRole.name`.
  static const String role = 'kubar_role';
}

/// Data dasar warga yang sedang masuk.
@immutable
class AuthUser {
  const AuthUser({
    required this.name,
    required this.phone,
    this.nik,
    this.alamat,
    this.rt,
    this.rw,
  });

  factory AuthUser.dariJson(Map<String, dynamic> json) => AuthUser(
        name: json['name'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        nik: json['nik'] as String?,
        alamat: json['alamat'] as String?,
        rt: json['rt'] as String?,
        rw: json['rw'] as String?,
      );

  Map<String, dynamic> keJson() => <String, dynamic>{
        'name': name,
        'phone': phone,
        if (nik != null) 'nik': nik,
        if (alamat != null) 'alamat': alamat,
        if (rt != null) 'rt': rt,
        if (rw != null) 'rw': rw,
      };

  final String name;
  final String phone;
  final String? nik;
  final String? alamat;
  final String? rt;
  final String? rw;

  String get inisial {
    final List<String> parts =
        name.trim().split(RegExp(r'\s+')).where((String p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final String satu = parts.first;
      return satu.isEmpty ? '?' : satu.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  String get zona {
    if (rt == null && rw == null) return 'Domisili belum dilengkapi';
    return 'RT ${rt ?? '-'} / RW ${rw ?? '-'}';
  }
}

/// State sesi: user + role. Null user = Tamu (guest).
@immutable
class Session {
  const Session({this.user, this.role = UserRole.guest, this.siap = false});

  final AuthUser? user;
  final UserRole role;

  /// False selama [_muat] belum selesai membaca SharedPreferences.
  ///
  /// WAJIB dipakai guard/UI: tanpa ini, begitu aplikasi dibuka `[sudahLogin]`
  /// masih false selama beberapa milidetik, sehingga RoleGate sempat
  /// menampilkan "Akses Ditolak" padahal user sebenarnya masih masuk.
  final bool siap;

  bool get sudahLogin => user != null;

  /// Role efektif: kalau tidak login, selalu guest.
  UserRole get efektif =>
      user == null ? UserRole.guest : (role == UserRole.guest ? UserRole.warga : role);

  Session copyWith({AuthUser? user, UserRole? role, bool? siap}) => Session(
        user: user ?? this.user,
        role: role ?? this.role,
        siap: siap ?? this.siap,
      );
}

class SessionNotifier extends StateNotifier<Session> {
  SessionNotifier() : super(const Session()) {
    _muat();
  }

  /// Baca user + role tersimpan saat aplikasi dibuka.
  ///
  /// SEBELUMNYA fungsi ini hanya memulihkan role lewat
  /// `Session(user: state.user, ...)` - padahal `state.user` SELALU null
  /// di sini, jadi hasilnya `sudahLogin == false` terus. Akibatnya user
  /// logout setiap aplikasi ditutup lalu dibuka lagi, dan role yang
  /// disimpan tidak pernah terpakai.
  Future<void> _muat() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? jsonUser = prefs.getString(SessionKeys.user);
    final String? namaRole = prefs.getString(SessionKeys.role);

    AuthUser? user;
    if (jsonUser != null && jsonUser.isNotEmpty) {
      try {
        user = AuthUser.dariJson(jsonDecode(jsonUser) as Map<String, dynamic>);
      } on FormatException {
        // Data rusak (mis. versi app sebelumnya): buang, jangan bikin crash.
        await prefs.remove(SessionKeys.user);
      }
    }

    // Tanpa user tidak ada sesi, apa pun isi role.
    UserRole role = UserRole.guest;
    if (user != null) {
      role = (namaRole == null ? null : UserRole.values.asNameMap()[namaRole]) ??
          UserRole.warga;
    }

    state = Session(user: user, role: role, siap: true);
  }

  Future<void> simpanRole(UserRole role) async {
    state = state.copyWith(role: role);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(SessionKeys.role, roleToDb(role));
  }

  /// Setelah OTP terverifikasi. Role awal = warga.
  Future<void> masuk(AuthUser user) async {
    state = Session(user: user, role: UserRole.warga, siap: true);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(SessionKeys.user, jsonEncode(user.keJson()));
    await prefs.setString(SessionKeys.role, roleToDb(UserRole.warga));
  }

  Future<void> keluar() async {
    state = const Session(siap: true);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(SessionKeys.user);
    await prefs.remove(SessionKeys.role);
  }
}

final StateNotifierProvider<SessionNotifier, Session> sessionProvider =
    StateNotifierProvider<SessionNotifier, Session>((ref) => SessionNotifier());

/// Shortcut: apakah session sekarang punya akses minimal [role].
bool bisaAkses(Session session, UserRole role) =>
    session.sudahLogin && session.efektif.bisa(role);