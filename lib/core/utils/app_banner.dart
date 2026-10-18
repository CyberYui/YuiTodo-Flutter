import 'dart:async';

import 'package:flutter/material.dart';

Timer? _appBannerTimer;

/// Shows a single-line banner pinned to the top of the nearest [Scaffold].
///
/// The message and the optional action / close buttons share one row, which
/// keeps the banner compact and avoids the two-line layout of the default
/// [MaterialBanner]. The background matches the page (no divider), so it feels
/// like a transient strip rather than a separate panel.
extension AppBanner on BuildContext {
  void showTopBanner(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    final messenger = ScaffoldMessenger.of(this);
    final theme = Theme.of(this);
    _appBannerTimer?.cancel();
    messenger.hideCurrentMaterialBanner();

    final buttonStyle = TextButton.styleFrom(
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      minimumSize: const Size(0, 32),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    messenger.showMaterialBanner(
      MaterialBanner(
        dividerColor: Colors.transparent,
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        minActionBarHeight: 0,
        padding: const EdgeInsetsDirectional.only(start: 16, top: 4),
        content: Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (actionLabel != null && onAction != null)
              TextButton(
                style: buttonStyle,
                onPressed: () {
                  _appBannerTimer?.cancel();
                  onAction();
                  messenger.hideCurrentMaterialBanner();
                },
                child: Text(actionLabel),
              ),
            TextButton(
              style: buttonStyle,
              onPressed: () {
                _appBannerTimer?.cancel();
                messenger.hideCurrentMaterialBanner();
              },
              child: const Text('关闭'),
            ),
          ],
        ),
        // MaterialBanner asserts a non-empty action list; a zero-size action
        // keeps the single-row layout without rendering a second row.
        actions: const [SizedBox.shrink()],
      ),
    );

    _appBannerTimer = Timer(duration, () {
      messenger.hideCurrentMaterialBanner();
    });
  }
}
