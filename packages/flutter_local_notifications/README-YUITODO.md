# YuiTodo patch for flutter_local_notifications

Vendored from `flutter_local_notifications` **17.2.4** (BSD-3-Clause — see
`LICENSE`). Only the changes below are YuiTodo-specific; everything else is
upstream.

## Changes

1. `AndroidNotificationDetails.useCustomLayout` (Dart + `NotificationDetails`
   Java model + platform-channel mapper).
2. When the flag is set, `createNotification` builds two app-provided
   `RemoteViews` layouts:
   - `res/layout/yuitodo_notification_collapsed.xml`
   - `res/layout/yuitodo_notification_expanded.xml`
   with an accent bar, title, body and sub-text. Colours follow the system
   night mode; the accent colour comes from the notification colour.
3. `analysis_options.yaml` silences upstream `Color` deprecation infos so the
   host app keeps a zero-issue `flutter analyze`.

## Updating

When bumping the upstream version, re-apply items 1–2 and keep the layouts.
The public Dart API is source-compatible; the new flag defaults to `false`.

No other behaviour is changed.
