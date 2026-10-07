import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final themeProvider =
NotifierProvider<ThemeNotifier, ThemeMode>(
  ThemeNotifier.new,
);

class ThemeNotifier extends Notifier<ThemeMode> {
  static const String _boxName = 'spendly_box';
  static const String _themeKey = 'theme_mode';

  @override
  ThemeMode build() {
    final box = Hive.box(_boxName);

    final savedTheme = box.get(_themeKey);

    switch (savedTheme) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;

    final box = Hive.box(_boxName);

    await box.put(
      _themeKey,
      mode.name,
    );
  }
}