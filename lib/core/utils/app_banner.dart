import 'dart:async';

import 'package:flutter/material.dart';

Timer? _appBannerTimer;

/// Shows a banner pinned to the top of the nearest [Scaffold].
///
/// Compared with [ScaffoldMessenger.showSnackBar] — which anchors to the bottom
/// and can overlap the FAB / sit in the system gesture area — a top
/// [MaterialBanner] stays clear of the bottom edge and auto-dismisses after a
/// short delay. An optional action button (e.g. "撤销") is supported.
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

    messenger.showMaterialBanner(
      MaterialBanner(
        dividerColor: Colors.transparent,
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        content: Text(message),
        leading: const Icon(Icons.info_outline),
        actions: [
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: () {
                _appBannerTimer?.cancel();
                onAction();
                messenger.hideCurrentMaterialBanner();
              },
              child: Text(actionLabel),
            ),
          TextButton(
            onPressed: () {
              _appBannerTimer?.cancel();
              messenger.hideCurrentMaterialBanner();
            },
            child: const Text('关闭'),
          ),
        ],
      ),
    );

    _appBannerTimer = Timer(duration, () {
      messenger.hideCurrentMaterialBanner();
    });
  }
}
