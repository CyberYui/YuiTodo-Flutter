import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/storage/app_prefs.dart';

/// Calendar week start: 0 = Monday, 1 = Sunday.
final weekStartProvider = StateNotifierProvider<WeekStartNotifier, int>((ref) {
  return WeekStartNotifier(ref.watch(appPrefsProvider));
});

class WeekStartNotifier extends StateNotifier<int> {
  WeekStartNotifier(this._prefs) : super(_prefs.weekStart);

  final AppPrefs _prefs;

  void set(int value) {
    _prefs.weekStart = value;
    state = value;
  }
}
