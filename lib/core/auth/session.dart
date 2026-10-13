import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'user_role.dart';

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
  const Session({this.user, this.role = UserRole.guest});

  final AuthUser? user;
  final UserRole role;

  bool get sudahLogin => user != null;

  /// Role efektif: kalau tidak login, selalu guest.
  UserRole get efektif =>
      user == null ? UserRole.guest : (role == UserRole.guest ? UserRole.warga : role);

  Session copyWith({AuthUser? user, UserRole? role}) => Session(
        user: user ?? this.user,
        role: role ?? this.role,
      );
}

class SessionNotifier extends StateNotifier<Session> {
  SessionNotifier() : super(const Session()) {
    _muat();
  }

  static const String _kRole = 'kubar_role';

  /// Baca role tersimpan saat aplikasi dibuka.
  Future<void> _muat() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? tersimpan = prefs.getString(_kRole);
    if (tersimpan == null) return;
    final UserRole? role = UserRole.values.asNameMap()[tersimpan];
    if (role == null) return;
    state = Session(user: state.user, role: role);
  }

  Future<void> simpanRole(UserRole role) async {
    state = state.copyWith(role: role);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kRole, roleToDb(role));
  }

  /// Setelah OTP terverifikasi. Role awal = warga.
  Future<void> masuk(AuthUser user) async {
    state = Session(user: user, role: UserRole.warga);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kRole, roleToDb(UserRole.warga));
  }

  Future<void> keluar() async {
    state = const Session();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kRole);
  }
}

final StateNotifierProvider<SessionNotifier, Session> sessionProvider =
    StateNotifierProvider<SessionNotifier, Session>((ref) => SessionNotifier());

/// Shortcut: apakah session sekarang punya akses minimal [role].
bool bisaAkses(Session session, UserRole role) =>
    session.sudahLogin && session.efektif.bisa(role);