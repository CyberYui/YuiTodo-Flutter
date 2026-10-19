import 'package:flutter_test/flutter_test.dart';
import 'package:yuitodo/models/task.dart';
import 'package:yuitodo/models/task_occurrence.dart';
import 'package:yuitodo/providers/occurrence_provider.dart';

void main() {
  Task task({
    int id = 1,
    String status = 'pending',
    List<TaskStep> steps = const [],
  }) {
    return Task(
      id: id,
      title: 'T',
      status: status,
      createdAt: 0,
      updatedAt: 0,
      steps: steps,
    );
  }

  test('non-recurring completion updates state and task status', () {
    final occ = TaskOccurrence(task: task(), day: DateTime(2026, 10, 19));
    final updated = applyOccurrenceState([occ], 1, occ.dayKey, 'done');
    expect(updated.single.state, 'done');
    expect(updated.single.task.status, 'done');
  });

  test('recurring completion changes only the matching day', () {
    final first = TaskOccurrence(
      task: task(),
      day: DateTime(2026, 10, 19),
      isRecurring: true,
    );
    final second = TaskOccurrence(
      task: task(),
      day: DateTime(2026, 10, 20),
      isRecurring: true,
    );
    final updated = applyOccurrenceState([first, second], 1, first.dayKey, 'done');
    expect(updated[0].state, 'done');
    expect(updated[0].task.status, 'pending');
    expect(updated[1].state, 'pending');
  });

  test('step state updates only the matching occurrence step', () {
    final step = TaskStep(
      id: 7,
      taskId: 1,
      title: 'sub',
      status: 'pending',
    );
    final occ = TaskOccurrence(
      task: task(steps: [step]),
      day: DateTime(2026, 10, 19),
    );
    final updated = applyStepState([occ], 1, occ.dayKey, 7, 'completed');
    expect(updated.single.task.steps.single.status, 'completed');
  });

  test('other tasks stay untouched', () {
    final first = TaskOccurrence(task: task(id: 1), day: DateTime(2026, 10, 19));
    final second = TaskOccurrence(task: task(id: 2), day: DateTime(2026, 10, 19));
    final updated = applyOccurrenceState([first, second], 1, first.dayKey, 'done');
    expect(updated[1].state, 'pending');
  });
}
