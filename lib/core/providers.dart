import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Indeks tab aktif di bottom navigation.
final navigationIndexProvider = StateProvider<int>((ref) => 0);

/// Mode tema (system / light / dark).
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

/// Data anggota yang sedang masuk (dummy sampai backend Supabase aktif).
class AuthUser {
  const AuthUser({required this.name, required this.phone});

  final String name;
  final String phone;
}

/// Null = belum masuk. Offline-first: cukup ada setelah OTP terverifikasi.
final StateProvider<AuthUser?> authUserProvider = StateProvider<AuthUser?>(
  (ref) => null,
);