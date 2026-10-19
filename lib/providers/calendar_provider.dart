import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/date/task_date_query_engine.dart';
import '../models/task_occurrence.dart';
import 'occurrence_provider.dart';

/// Occurrences for the calendar's visible range (focused month plus the
/// leading/trailing days of the adjacent months).
final calendarProvider =
    StateNotifierProvider<CalendarNotifier, AsyncValue<List<TaskOccurrence>>>(
        (ref) {
  return CalendarNotifier(ref.watch(taskDateQueryEngineProvider));
});

class CalendarNotifier
    extends StateNotifier<AsyncValue<List<TaskOccurrence>>> {
  final TaskDateQueryEngine _engine;

  /// Recently queried months, keyed by `year-month`.
  final Map<String, _CalendarCacheEntry> _cache = {};
  static const int _maxCachedMonths = 12;

  CalendarNotifier(this._engine) : super(const AsyncValue.loading());

  Future<void> loadMonth(DateTime month, {bool showLoading = true}) async {
    final key = '${month.year}-${month.month}';
    final version = await _engine.repo.getDataVersion();
    final cached = _cache[key];
    if (cached != null && cached.version == version) {
      state = AsyncValue.data(cached.occurrences);
      return;
    }

    if (showLoading || !state.hasValue) {
      state = const AsyncValue.loading();
    }
    try {
      // Cover the previous month's trailing days and the next month's
      // leading days that can appear in the month grid.
      final start = DateTime(month.year, month.month - 1, 1);
      final end = DateTime(month.year, month.month + 2, 0);
      final list = await _engine.queryRange(
        start,
        end,
        includeAllNonRecurring: false,
      );
      _cache[key] = _CalendarCacheEntry(version, list);
      while (_cache.length > _maxCachedMonths) {
        _cache.remove(_cache.keys.first);
      }
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

class _CalendarCacheEntry {
  final int version;
  final List<TaskOccurrence> occurrences;

  const _CalendarCacheEntry(this.version, this.occurrences);
}
