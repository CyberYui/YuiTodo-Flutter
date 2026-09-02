import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme_schemes.dart';

/// Theme mode provider with enhanced features
final themeStateProvider = StateNotifierProvider<ThemeStateNotifier, ThemeState>((ref) {
  return ThemeStateNotifier();
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
    if (mode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
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
    return mode == ThemeMode.dark;
  }
}

class ThemeStateNotifier extends StateNotifier<ThemeState> {
  ThemeStateNotifier() : super(ThemeState(
    mode: ThemeMode.system,
    lightScheme: AppThemeScheme.blue,
    darkScheme: AppThemeScheme.monokai,
    autoSwitchByTime: false,
  ));
  
  void setMode(ThemeMode mode) {
    state = state.copyWith(mode: mode);
  }
  
  void setLightScheme(AppThemeScheme scheme) {
    state = state.copyWith(lightScheme: scheme);
  }
  
  void setDarkScheme(AppThemeScheme scheme) {
    state = state.copyWith(darkScheme: scheme);
  }
  
  void setAutoSwitchByTime(bool value) {
    state = state.copyWith(autoSwitchByTime: value);
  }
  
  void setDarkStart(TimeOfDay time) {
    state = state.copyWith(darkStartTime: time);
  }
  
  void setDarkEnd(TimeOfDay time) {
    state = state.copyWith(darkEndTime: time);
  }
}
