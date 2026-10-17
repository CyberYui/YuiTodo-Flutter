import '../core/date/date_utils.dart';
import 'task.dart';

/// A single occurrence of a task on a specific local date.
///
/// This is a read-side view object: it is produced by the date query engine
/// from a recurring template plus the `task_occurrence` exception table. It is
/// never stored as a row on its own.
class TaskOccurrence {
  final Task task;

  /// Local date of this occurrence (time component is midnight).
  final DateTime day;

  /// `pending` | `done` | `skipped`
  final String state;

  /// True when the task is a recurring template (Skip applies).
  final bool isRecurring;

  const TaskOccurrence({
    required this.task,
    required this.day,
    this.state = 'pending',
    this.isRecurring = false,
  });

  bool get isDone => state == 'done';
  bool get isSkipped => state == 'skipped';
  bool get isPending => state == 'pending';

  int get dayKey => ymdKey(day);

  TaskOccurrence copyWith({
    Task? task,
    DateTime? day,
    String? state,
    bool? isRecurring,
  }) {
    return TaskOccurrence(
      task: task ?? this.task,
      day: day ?? this.day,
      state: state ?? this.state,
      isRecurring: isRecurring ?? this.isRecurring,
    );
  }

  @override
  String toString() =>
      'TaskOccurrence(task=${task.id}, day=${ymdKey(day)}, state=$state)';
}
