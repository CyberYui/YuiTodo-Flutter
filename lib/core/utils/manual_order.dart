import '../../models/task_occurrence.dart';

/// Sort a list by the user's manual order.
///
/// `task.sortOrder` is the primary key; the occurrence day is only a tie-breaker
/// so equal values (e.g. legacy rows that all default to 0) keep a stable,
/// date-based order.
List<TaskOccurrence> sortForManualOrder(
  Iterable<TaskOccurrence> items, {
  Map<int, int>? sortOrderOverrides,
}) {
  final out = items.toList();
  int orderOf(TaskOccurrence o) =>
      sortOrderOverrides?[o.task.id] ?? o.task.sortOrder;
  out.sort((a, b) {
    final byOrder = orderOf(a).compareTo(orderOf(b));
    if (byOrder != 0) return byOrder;
    return a.day.compareTo(b.day);
  });
  return out;
}
