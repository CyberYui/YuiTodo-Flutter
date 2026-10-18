import '../../models/task_occurrence.dart';

/// Sort a list by the user's manual order.
///
/// `task.sortOrder` is the primary key; the occurrence day is only a tie-breaker
/// so equal values (e.g. legacy rows that all default to 0) keep a stable,
/// date-based order.
List<TaskOccurrence> sortForManualOrder(Iterable<TaskOccurrence> items) {
  final out = items.toList();
  out.sort((a, b) {
    final byOrder = a.task.sortOrder.compareTo(b.task.sortOrder);
    if (byOrder != 0) return byOrder;
    return a.day.compareTo(b.day);
  });
  return out;
}
