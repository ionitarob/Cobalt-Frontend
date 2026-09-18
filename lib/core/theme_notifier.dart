import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.dark);

Future<void> initTheme() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('cobalt_theme') == 'light') {
      themeNotifier.value = ThemeMode.light;
    }
  } catch (_) {}
}

Future<void> saveTheme(ThemeMode mode) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cobalt_theme', mode == ThemeMode.light ? 'light' : 'dark');
  } catch (_) {}
}
