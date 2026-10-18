import 'package:flutter_test/flutter_test.dart';
import 'package:yuitodo/core/utils/manual_order.dart';
import 'package:yuitodo/models/task.dart';
import 'package:yuitodo/models/task_occurrence.dart';

Task _task(int id, int sortOrder) => Task(
      id: id,
      title: '任务 $id',
      sortOrder: sortOrder,
      createdAt: 0,
      updatedAt: 0,
    );

TaskOccurrence _occurrence(int id, int sortOrder, int day) => TaskOccurrence(
      task: _task(id, sortOrder),
      day: DateTime(2026, 10, day),
    );

void main() {
  group('sortForManualOrder', () {
    test('sortOrder is primary and the day is a tie-breaker', () {
      final sorted = sortForManualOrder([
        _occurrence(1, 0, 16),
        _occurrence(2, 0, 18),
        _occurrence(3, 1, 17),
      ]);

      expect(sorted.map((o) => o.task.id), [1, 2, 3]);
    });

    test('renumbered sortOrder changes the visible order', () {
      // After dragging task 1 below task 3, the renumber pass writes 0/100/200.
      final sorted = sortForManualOrder([
        _occurrence(2, 0, 18),
        _occurrence(3, 100, 17),
        _occurrence(1, 200, 16),
      ]);

      expect(sorted.map((o) => o.task.id), [2, 3, 1]);
    });

    test('equal sortOrder falls back to the occurrence date', () {
      final sorted = sortForManualOrder([
        _occurrence(3, 0, 20),
        _occurrence(1, 0, 16),
        _occurrence(2, 0, 18),
      ]);

      expect(sorted.map((o) => o.task.id), [1, 2, 3]);
    });
  });
}
