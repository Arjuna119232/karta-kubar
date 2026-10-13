import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Indeks tab aktif di bottom navigation.
final navigationIndexProvider = StateProvider<int>((ref) => 0);

/// Mode tema (system / light / dark).
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
