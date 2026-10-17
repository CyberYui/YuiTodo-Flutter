import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/storage/app_prefs.dart';

/// Home task sections (Todoery-style).
enum HomeSection { previous, today, future, completedToday }

extension HomeSectionLabel on HomeSection {
  String get label {
    switch (this) {
      case HomeSection.previous:
        return '逾期';
      case HomeSection.today:
        return '今天';
      case HomeSection.future:
        return '未来';
      case HomeSection.completedToday:
        return '今日完成';
    }
  }
}

/// Collapse state per section, persisted in SharedPreferences.
final sectionCollapseProvider =
    StateNotifierProvider<SectionCollapseNotifier, Map<HomeSection, bool>>(
        (ref) {
  return SectionCollapseNotifier(ref.watch(appPrefsProvider));
});

class SectionCollapseNotifier extends StateNotifier<Map<HomeSection, bool>> {
  final AppPrefs _prefs;

  SectionCollapseNotifier(this._prefs)
      : super({
          for (final s in HomeSection.values)
            s: _prefs.getSectionCollapsed(s.name),
        });

  void toggle(HomeSection section) {
    final next = Map<HomeSection, bool>.from(state);
    next[section] = !(next[section] ?? false);
    state = next;
    _prefs.setSectionCollapsed(section.name, next[section]!);
  }
}

/// Section display order, persisted in SharedPreferences.
final sectionOrderProvider =
    StateNotifierProvider<SectionOrderNotifier, List<HomeSection>>((ref) {
  return SectionOrderNotifier(ref.watch(appPrefsProvider));
});

class SectionOrderNotifier extends StateNotifier<List<HomeSection>> {
  final AppPrefs _prefs;

  SectionOrderNotifier(this._prefs) : super(_parse(_prefs.sectionOrder));

  static List<HomeSection> _parse(String raw) {
    final result = <HomeSection>[];
    if (raw.isNotEmpty) {
      for (final name in raw.split(',')) {
        for (final s in HomeSection.values) {
          if (s.name == name && !result.contains(s)) result.add(s);
        }
      }
    }
    for (final s in HomeSection.values) {
      if (!result.contains(s)) result.add(s);
    }
    return result;
  }

  void setOrder(List<HomeSection> order) {
    state = order;
    _prefs.sectionOrder = order.map((s) => s.name).join(',');
  }
}
