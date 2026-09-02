import 'package:flutter/material.dart';

/// Theme color schemes
enum AppThemeScheme {
  blue,
  green,
  purple,
  orange,
  monokai,
  dracula,
  nord,
  gruvbox,
  black,
}

class ThemeScheme {
  final String name;
  final Color lightPrimary;
  final Color lightSecondary;
  final Color lightBackground;
  final Color lightSurface;
  final Color darkPrimary;
  final Color darkSecondary;
  final Color darkBackground;
  final Color darkSurface;
  
  const ThemeScheme({
    required this.name,
    required this.lightPrimary,
    required this.lightSecondary,
    required this.lightBackground,
    required this.lightSurface,
    required this.darkPrimary,
    required this.darkSecondary,
    required this.darkBackground,
    required this.darkSurface,
  });
}

const Map<AppThemeScheme, ThemeScheme> themeSchemes = {
  AppThemeScheme.blue: ThemeScheme(
    name: '默认蓝',
    lightPrimary: Color(0xFF3B82F6),
    lightSecondary: Color(0xFF60A5FA),
    lightBackground: Color(0xFFF8FAFC),
    lightSurface: Color(0xFFFFFFFF),
    darkPrimary: Color(0xFF60A5FA),
    darkSecondary: Color(0xFF3B82F6),
    darkBackground: Color(0xFF0F172A),
    darkSurface: Color(0xFF1E293B),
  ),
  AppThemeScheme.green: ThemeScheme(
    name: '森林绿',
    lightPrimary: Color(0xFF10B981),
    lightSecondary: Color(0xFF34D399),
    lightBackground: Color(0xFFF0FDF4),
    lightSurface: Color(0xFFFFFFFF),
    darkPrimary: Color(0xFF34D399),
    darkSecondary: Color(0xFF10B981),
    darkBackground: Color(0xFF022C22),
    darkSurface: Color(0xFF064E3B),
  ),
  AppThemeScheme.purple: ThemeScheme(
    name: '紫罗兰',
    lightPrimary: Color(0xFF8B5CF6),
    lightSecondary: Color(0xFFA78BFA),
    lightBackground: Color(0xFFFAF5FF),
    lightSurface: Color(0xFFFFFFFF),
    darkPrimary: Color(0xFFA78BFA),
    darkSecondary: Color(0xFF8B5CF6),
    darkBackground: Color(0xFF1E1B4B),
    darkSurface: Color(0xFF312E81),
  ),
  AppThemeScheme.orange: ThemeScheme(
    name: '日落橙',
    lightPrimary: Color(0xFFF59E0B),
    lightSecondary: Color(0xFFFBBF24),
    lightBackground: Color(0xFFFFFBEB),
    lightSurface: Color(0xFFFFFFFF),
    darkPrimary: Color(0xFFFBBF24),
    darkSecondary: Color(0xFFF59E0B),
    darkBackground: Color(0xFF451A03),
    darkSurface: Color(0xFF78350F),
  ),
  AppThemeScheme.monokai: ThemeScheme(
    name: 'Monokai',
    lightPrimary: Color(0xFFA6E22E),
    lightSecondary: Color(0xFF66D9EF),
    lightBackground: Color(0xFFF8F8F2),
    lightSurface: Color(0xFFFFFFFF),
    darkPrimary: Color(0xFFA6E22E),
    darkSecondary: Color(0xFF66D9EF),
    darkBackground: Color(0xFF272822),
    darkSurface: Color(0xFF3E3D32),
  ),
  AppThemeScheme.dracula: ThemeScheme(
    name: 'Dracula',
    lightPrimary: Color(0xFFFF79C6),
    lightSecondary: Color(0xFFBD93F9),
    lightBackground: Color(0xFFF8F8F2),
    lightSurface: Color(0xFFFFFFFF),
    darkPrimary: Color(0xFFFF79C6),
    darkSecondary: Color(0xFFBD93F9),
    darkBackground: Color(0xFF282A36),
    darkSurface: Color(0xFF44475A),
  ),
  AppThemeScheme.nord: ThemeScheme(
    name: 'Nord',
    lightPrimary: Color(0xFF81A1C1),
    lightSecondary: Color(0xFF88C0D0),
    lightBackground: Color(0xFFECEFF4),
    lightSurface: Color(0xFFFFFFFF),
    darkPrimary: Color(0xFF81A1C1),
    darkSecondary: Color(0xFF88C0D0),
    darkBackground: Color(0xFF2E3440),
    darkSurface: Color(0xFF3B4252),
  ),
  AppThemeScheme.gruvbox: ThemeScheme(
    name: 'Gruvbox',
    lightPrimary: Color(0xFFB16286),
    lightSecondary: Color(0xFF458588),
    lightBackground: Color(0xFFFBF1C7),
    lightSurface: Color(0xFFFFFFFF),
    darkPrimary: Color(0xFFD3869B),
    darkSecondary: Color(0xFF83A598),
    darkBackground: Color(0xFF282828),
    darkSurface: Color(0xFF3C3836),
  ),
  AppThemeScheme.black: ThemeScheme(
    name: '纯黑',
    lightPrimary: Color(0xFF1A1A1A),
    lightSecondary: Color(0xFF424242),
    lightBackground: Color(0xFFF5F5F5),
    lightSurface: Color(0xFFFFFFFF),
    darkPrimary: Color(0xFFE0E0E0),
    darkSecondary: Color(0xFF9E9E9E),
    darkBackground: Color(0xFF000000),
    darkSurface: Color(0xFF121212),
  ),
};

/// Light theme for a scheme
ThemeData lightThemeForScheme(ThemeScheme scheme) {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: scheme.lightPrimary,
      secondary: scheme.lightSecondary,
      background: scheme.lightBackground,
      surface: scheme.lightSurface,
    ),
    scaffoldBackgroundColor: scheme.lightBackground,
    cardColor: scheme.lightSurface,
  );
}

/// Dark theme for a scheme
ThemeData darkThemeForScheme(ThemeScheme scheme) {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.dark(
      primary: scheme.darkPrimary,
      secondary: scheme.darkSecondary,
      background: scheme.darkBackground,
      surface: scheme.darkSurface,
    ),
    scaffoldBackgroundColor: scheme.darkBackground,
    cardColor: scheme.darkSurface,
  );
}
