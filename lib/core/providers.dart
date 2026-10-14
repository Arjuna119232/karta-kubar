import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Indeks tab aktif di bottom navigation.
final navigationIndexProvider = StateProvider<int>((ref) => 0);

/// Mode tema (system / light / dark). Pilihan disimpan di perangkat.
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _muat();
  }

  static const String _kunci = 'pref_theme_mode';

  Future<void> _muat() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      final String? v = p.getString(_kunci);
      state = ThemeMode.values.firstWhere(
        (ThemeMode m) => m.name == v,
        orElse: () => ThemeMode.system,
      );
    } catch (_) {
      // Penyimpanan gagal dibaca: pakai bawaan (ikuti sistem).
    }
  }

  Future<void> atur(ThemeMode mode) async {
    state = mode;
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setString(_kunci, mode.name);
    } catch (_) {
      // Gagal menyimpan tidak boleh mengganggu tampilan.
    }
  }
}

final StateNotifierProvider<ThemeModeNotifier, ThemeMode> themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

/// Mode lansia: teks lebih besar di seluruh aplikasi. Disimpan di perangkat.
class ElderModeNotifier extends StateNotifier<bool> {
  ElderModeNotifier() : super(false) {
    _muat();
  }

  static const String _kunci = 'pref_elder_mode';

  Future<void> _muat() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      state = p.getBool(_kunci) ?? false;
    } catch (_) {
      // Pakai bawaan (nonaktif).
    }
  }

  Future<void> atur(bool aktif) async {
    state = aktif;
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setBool(_kunci, aktif);
    } catch (_) {
      // Gagal menyimpan tidak boleh mengganggu tampilan.
    }
  }
}

final StateNotifierProvider<ElderModeNotifier, bool> elderModeProvider =
    StateNotifierProvider<ElderModeNotifier, bool>(
  (ref) => ElderModeNotifier(),
);

/// Sesi pengguna (user + role) ada di `core/auth/session.dart`.
/// Dulu `authUserProvider` ada di file ini — sekarang digantikan Session
/// supaya role ikut terbawa dan bisa disimpan ke SharedPreferences.
