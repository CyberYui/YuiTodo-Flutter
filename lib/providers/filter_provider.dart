import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Smart filter provider
final smartFilterProvider = StateNotifierProvider<SmartFilterNotifier, String>((ref) {
  return SmartFilterNotifier();
});

class SmartFilterNotifier extends StateNotifier<String> {
  SmartFilterNotifier() : super('all');

  void setFilter(String filter) {
    state = filter;
  }
}

/// Tag filter provider
final tagFilterProvider = StateNotifierProvider<TagFilterNotifier, int?>((ref) {
  return TagFilterNotifier();
});

class TagFilterNotifier extends StateNotifier<int?> {
  TagFilterNotifier() : super(null);

  void setTag(int? tagId) {
    state = tagId;
  }
}
