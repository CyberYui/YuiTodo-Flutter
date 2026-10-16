import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/app_prefs.dart';

/// Index of the selected font pair. Persisted via [AppPrefs] so it survives
/// an app restart.
final fontIndexProvider =
    StateNotifierProvider<FontIndexNotifier, int>((ref) {
      return FontIndexNotifier(ref.watch(appPrefsProvider));
    });

class FontIndexNotifier extends StateNotifier<int> {
  final AppPrefs _prefs;

  FontIndexNotifier(this._prefs) : super(_prefs.fontIndex);

  void setIndex(int index) {
    _prefs.fontIndex = index;
    state = index;
  }
}
