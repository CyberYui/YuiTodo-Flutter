import 'package:flutter/material.dart';

/// Extended color palette - 16 colors + 1 custom slot
class TaskColors {
  static const List<String> all = [
    '#3B82F6', // Blue
    '#EF4444', // Red
    '#10B981', // Green
    '#F59E0B', // Amber
    '#EC4899', // Pink
    '#06B6D4', // Cyan
    '#F97316', // Orange
    '#6366F1', // Indigo
    '#84CC16', // Lime
    '#D946EF', // Fuchsia
    '#64748B', // Slate
    '#78716C', // Warm Gray
    '#F43F5E', // Rose
    '#000000', // Black
    '#FFFFFF', // White
    '#CUSTOM', // Custom color placeholder
  ];
  
  static Color colorFromHex(String hex) {
    if (hex == '#CUSTOM') return Colors.grey.withOpacity(0.3);
    if (hex == '#FFFFFF') return Colors.white;
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  }
  
  static bool isCustom(String hex) => hex == '#CUSTOM';
  
  static Color fromHex(String hex) {
    if (hex.isEmpty || hex == '#CUSTOM') return Colors.grey.withOpacity(0.3);
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.grey.withOpacity(0.3);
    }
  }
}
