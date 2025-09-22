import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trashit/theme.dart';

/// App-wide theme controller with persistence.
class ThemeService extends ChangeNotifier {
  ThemeService._();
  static final ThemeService instance = ThemeService._();

  static const _kThemeModeKey = 'prefs_theme_mode';
  static const _kThemeVariantKey = 'prefs_theme_variant';

  ThemeMode _mode = ThemeMode.system;
  AppThemeVariant _variant = AppThemeVariant.red; // original red theme

  ThemeMode get mode => _mode;
  AppThemeVariant get variant => _variant;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final modeStr = prefs.getString(_kThemeModeKey);
    final varStr = prefs.getString(_kThemeVariantKey);
    _mode = _decodeMode(modeStr) ?? ThemeMode.system;
    _variant = _decodeVariant(varStr) ?? AppThemeVariant.red;
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeModeKey, _encodeMode(mode));
  }

  Future<void> setVariant(AppThemeVariant variant) async {
    _variant = variant;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeVariantKey, _encodeVariant(variant));
  }

  String _encodeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
      default:
        return 'system';
    }
  }

  ThemeMode? _decodeMode(String? s) {
    switch (s) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
    }
    return null;
  }

  String _encodeVariant(AppThemeVariant v) => v.name;
  AppThemeVariant? _decodeVariant(String? s) {
    if (s == null) return null;
    for (final v in AppThemeVariant.values) {
      if (v.name == s) return v;
    }
    return null;
  }
}
