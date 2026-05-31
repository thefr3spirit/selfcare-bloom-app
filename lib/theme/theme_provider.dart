import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages app theme mode (Light / Dark / System)
/// Persists preference in SharedPreferences
class ThemeNotifier extends ValueNotifier<ThemeMode> {
  static const String _key = 'theme_mode';
  static final ThemeNotifier instance = ThemeNotifier._();

  ThemeNotifier._() : super(ThemeMode.light);

  /// Load saved preference
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null) {
      value = ThemeMode.values.firstWhere(
        (m) => m.name == saved,
        orElse: () => ThemeMode.light,
      );
    }
  }

  /// Update theme mode and persist
  Future<void> setThemeMode(ThemeMode mode) async {
    value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }
}
