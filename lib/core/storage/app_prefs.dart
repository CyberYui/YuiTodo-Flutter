import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around [SharedPreferences] for app-wide settings that must
/// survive an app restart (theme mode/schemes, timed dark mode, font, ...).
class AppPrefs {
  AppPrefs(this._prefs);

  final SharedPreferences _prefs;

  static Future<AppPrefs> load() async {
    return AppPrefs(await SharedPreferences.getInstance());
  }

  // ---- Theme ----
  ThemeMode get themeMode =>
      ThemeMode.values[_prefs.getInt(_kThemeMode) ?? ThemeMode.system.index];
  set themeMode(ThemeMode value) {
    _prefs.setInt(_kThemeMode, value.index);
  }

  String get lightSchemeName => _prefs.getString(_kLightScheme) ?? 'blue';
  set lightSchemeName(String value) {
    _prefs.setString(_kLightScheme, value);
  }

  String get darkSchemeName => _prefs.getString(_kDarkScheme) ?? 'monokai';
  set darkSchemeName(String value) {
    _prefs.setString(_kDarkScheme, value);
  }

  bool get autoSwitchByTime => _prefs.getBool(_kAutoSwitch) ?? false;
  set autoSwitchByTime(bool value) {
    _prefs.setBool(_kAutoSwitch, value);
  }

  int get darkStartMinutes => _prefs.getInt(_kDarkStart) ?? 18 * 60;
  set darkStartMinutes(int value) {
    _prefs.setInt(_kDarkStart, value);
  }

  int get darkEndMinutes => _prefs.getInt(_kDarkEnd) ?? 8 * 60;
  set darkEndMinutes(int value) {
    _prefs.setInt(_kDarkEnd, value);
  }

  // ---- Home sections ----
  bool getSectionCollapsed(String name) =>
      _prefs.getBool('section_collapsed_$name') ?? false;
  void setSectionCollapsed(String name, bool value) {
    _prefs.setBool('section_collapsed_$name', value);
  }

  String get sectionOrder => _prefs.getString('section_order') ?? '';
  set sectionOrder(String value) {
    _prefs.setString('section_order', value);
  }

  // ---- Statistics ----
  bool get statsExcludeHabits =>
      _prefs.getBool('stats_exclude_habits') ?? false;
  set statsExcludeHabits(bool value) {
    _prefs.setBool('stats_exclude_habits', value);
  }

  // ---- Font ----
  int get fontIndex => _prefs.getInt(_kFontIndex) ?? 0;
  set fontIndex(int value) {
    _prefs.setInt(_kFontIndex, value);
  }

  static const _kThemeMode = 'theme_mode';
  static const _kLightScheme = 'light_scheme';
  static const _kDarkScheme = 'dark_scheme';
  static const _kAutoSwitch = 'auto_switch_by_time';
  static const _kDarkStart = 'dark_start_minutes';
  static const _kDarkEnd = 'dark_end_minutes';
  static const _kFontIndex = 'font_index';
}

/// Provided once at the root via `ProviderScope(overrides: [...])` (see
/// `main.dart`). Overriding it throws to fail fast if that wiring is missed.
final appPrefsProvider = Provider<AppPrefs>((ref) {
  throw UnimplementedError(
    'appPrefsProvider must be overridden before runApp (see main.dart)',
  );
});
