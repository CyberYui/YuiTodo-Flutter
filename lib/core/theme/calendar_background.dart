import 'package:flutter/material.dart';

/// Optional artwork behind the calendar header.
///
/// Drop a portrait image at [assetPath] (and keep [enabled] = true) to use it.
/// The image is drawn with [BoxFit.cover] behind the theme gradient scrim, so
/// the date grid and task list stay readable. If the file is missing, the
/// calendar automatically falls back to the theme gradient.
///
/// Recommended artwork:
/// - Size: **1240 x 1600 px** (portrait, ~0.775 aspect ratio)
/// - Safe focal area: top 60% (behind the calendar grid); the bottom 40% is
///   covered by the scrim and blends into the task list.
/// - Format: PNG or WebP, sRGB, no baked-in text.
/// - The image is center-cropped on smaller screens, so keep important
///   details away from the left/right edges.
class CalendarBackground {
  const CalendarBackground._();

  static const String assetPath = 'assets/images/calendar_bg.png';
  static const double recommendedWidth = 1240;
  static const double recommendedHeight = 1600;

  /// Set to false to force the plain theme gradient even when an image exists.
  static const bool enabled = true;

  static Widget layer() {
    if (!enabled) return const SizedBox.shrink();
    return Image.asset(
      assetPath,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
  }
}
