import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/database/database_service.dart';
import '../../data/database/sample_data_seeder.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyHaptics = 'haptics_enabled';
  static const String _keyAutoCommentary = 'auto_commentary';

  ThemeMode _themeMode = ThemeMode.dark;
  bool _hapticsEnabled = true;
  bool _autoCommentaryEnabled = true;
  bool _isLoading = false;

  ThemeMode get themeMode => _themeMode;
  bool get hapticsEnabled => _hapticsEnabled;
  bool get autoCommentaryEnabled => _autoCommentaryEnabled;
  bool get isLoading => _isLoading;

  SettingsProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_keyThemeMode);
    if (themeIndex != null && themeIndex >= 0 && themeIndex < ThemeMode.values.length) {
      _themeMode = ThemeMode.values[themeIndex];
    }
    _hapticsEnabled = prefs.getBool(_keyHaptics) ?? true;
    _autoCommentaryEnabled = prefs.getBool(_keyAutoCommentary) ?? true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyThemeMode, mode.index);
  }

  Future<void> setHapticsEnabled(bool enabled) async {
    _hapticsEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHaptics, enabled);
  }

  Future<void> setAutoCommentaryEnabled(bool enabled) async {
    _autoCommentaryEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoCommentary, enabled);
  }

  Future<void> resetAndReseedDatabase() async {
    _isLoading = true;
    notifyListeners();
    try {
      await DatabaseService.instance.resetDatabase();
      await SampleDataSeeder.seedSampleData();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
