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
  
  static const List<String> basicColors = [
    '#3B82F6',
    '#EF4444',
    '#10B981',
    '#F59E0B',
    '#EC4899',
    '#06B6D4',
    '#F97316',
    '#6366F1',
    '#84CC16',
    '#D946EF',
    '#64748B',
    '#78716C',
    '#000000',
    '#FFFFFF',
  ];
}
