import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Indeks tab aktif di bottom navigation.
final navigationIndexProvider = StateProvider<int>((ref) => 0);

/// Mode tema (system / light / dark).
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

/// Sesi pengguna (user + role) ada di `core/auth/session.dart`.
/// Dulu `authUserProvider` ada di file ini — sekarang digantikan Session
/// supaya role ikut terbawa dan bisa disimpan ke SharedPreferences.