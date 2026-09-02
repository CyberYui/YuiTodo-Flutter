import 'package:flutter/material.dart';

/// Extended color palette - 18 colors aligned in 2 rows
class TaskColors {
  static const List<String> all = [
    '#3B82F6', // Blue
    '#EF4444', // Red
    '#10B981', // Green
    '#F59E0B', // Amber
    '#8B5CF6', // Purple
    '#EC4899', // Pink
    '#06B6D4', // Cyan
    '#F97316', // Orange
    '#14B8A6', // Teal
    '#6366F1', // Indigo
    '#84CC16', // Lime
    '#D946EF', // Fuchsia
    '#0EA5E9', // Sky
    '#A855F7', // Violet
    '#E11D48', // Rose
    '#64748B', // Slate
    '#78716C', // Warm Gray
    '#000000', // Black
  ];
  
  static Color colorFromHex(String hex) {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  }
}
