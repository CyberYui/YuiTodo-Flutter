import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/app_prefs.dart';
import 'theme_schemes.dart';

/// Theme mode provider with enhanced features
final themeStateProvider =
    StateNotifierProvider<ThemeStateNotifier, ThemeState>((ref) {
      return ThemeStateNotifier(ref.watch(appPrefsProvider));
    });

class ThemeState {
  final ThemeMode mode;
  final AppThemeScheme lightScheme;
  final AppThemeScheme darkScheme;
  final bool autoSwitchByTime;
  final TimeOfDay? darkStartTime;
  final TimeOfDay? darkEndTime;

  ThemeState({
    required this.mode,
    required this.lightScheme,
    required this.darkScheme,
    required this.autoSwitchByTime,
    this.darkStartTime,
    this.darkEndTime,
  });

  ThemeState copyWith({
    ThemeMode? mode,
    AppThemeScheme? lightScheme,
    AppThemeScheme? darkScheme,
    bool? autoSwitchByTime,
    TimeOfDay? darkStartTime,
    TimeOfDay? darkEndTime,
  }) {
    return ThemeState(
      mode: mode ?? this.mode,
      lightScheme: lightScheme ?? this.lightScheme,
      darkScheme: darkScheme ?? this.darkScheme,
      autoSwitchByTime: autoSwitchByTime ?? this.autoSwitchByTime,
      darkStartTime: darkStartTime ?? this.darkStartTime,
      darkEndTime: darkEndTime ?? this.darkEndTime,
    );
  }

  bool get isDarkMode {
    // Timed switching wins when enabled so the configured window always applies.
    if (autoSwitchByTime) {
      final now = TimeOfDay.now();
      final start = darkStartTime ?? const TimeOfDay(hour: 18, minute: 0);
      final end = darkEndTime ?? const TimeOfDay(hour: 8, minute: 0);

      final nowMinutes = now.hour * 60 + now.minute;
      final startMinutes = start.hour * 60 + start.minute;
      final endMinutes = end.hour * 60 + end.minute;

      if (startMinutes < endMinutes) {
        return nowMinutes >= startMinutes && nowMinutes < endMinutes;
      } else {
        return nowMinutes >= startMinutes || nowMinutes < endMinutes;
      }
    }
    if (mode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    }
    return mode == ThemeMode.dark;
  }
}

class ThemeStateNotifier extends StateNotifier<ThemeState> {
  final AppPrefs _prefs;

  ThemeStateNotifier(this._prefs)
    : super(
        ThemeState(
          mode: _prefs.themeMode,
          lightScheme: _schemeByName(
            _prefs.lightSchemeName,
            AppThemeScheme.blue,
          ),
          darkScheme: _schemeByName(
            _prefs.darkSchemeName,
            AppThemeScheme.monokai,
          ),
          autoSwitchByTime: _prefs.autoSwitchByTime,
          darkStartTime: _minutesToTimeOfDay(_prefs.darkStartMinutes),
          darkEndTime: _minutesToTimeOfDay(_prefs.darkEndMinutes),
        ),
      );

  static AppThemeScheme _schemeByName(String name, AppThemeScheme fallback) {
    for (final scheme in AppThemeScheme.values) {
      if (scheme.name == name) return scheme;
    }
    return fallback;
  }

  static TimeOfDay _minutesToTimeOfDay(int minutes) {
    return TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
  }

  void setMode(ThemeMode mode) {
    _prefs.themeMode = mode;
    state = state.copyWith(mode: mode);
  }

  void setLightScheme(AppThemeScheme scheme) {
    _prefs.lightSchemeName = scheme.name;
    state = state.copyWith(lightScheme: scheme);
  }

  void setDarkScheme(AppThemeScheme scheme) {
    _prefs.darkSchemeName = scheme.name;
    state = state.copyWith(darkScheme: scheme);
  }

  void setAutoSwitchByTime(bool value) {
    _prefs.autoSwitchByTime = value;
    state = state.copyWith(autoSwitchByTime: value);
  }

  void setDarkStart(TimeOfDay time) {
    _prefs.darkStartMinutes = time.hour * 60 + time.minute;
    state = state.copyWith(darkStartTime: time);
  }

  void setDarkEnd(TimeOfDay time) {
    _prefs.darkEndMinutes = time.hour * 60 + time.minute;
    state = state.copyWith(darkEndTime: time);
  }
}
