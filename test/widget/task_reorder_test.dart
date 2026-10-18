import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yuitodo/models/task.dart';
import 'package:yuitodo/ui/widgets/task_card.dart';

void main() {
  Task task(int id, String title) => Task(
        id: id,
        title: title,
        createdAt: 0,
        updatedAt: 0,
      );

  testWidgets('long-pressing the drag handle starts a reorder', (tester) async {
    final tasks = [task(1, '任务 A'), task(2, '任务 B')];
    var reordered = false;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ReorderableListView.builder(
              itemCount: tasks.length,
              onReorder: (oldIndex, newIndex) => reordered = true,
              itemBuilder: (context, index) => TaskCard(
                key: ValueKey(tasks[index].id),
                task: tasks[index],
                isSelected: false,
                onTap: () {},
                onLongPress: () {},
                index: index,
                sortEnabled: true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final handle = find.byIcon(Icons.drag_indicator).first;
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await tester.pump(const Duration(milliseconds: 650));
    await gesture.moveBy(const Offset(0, 260));
    await tester.pump(const Duration(milliseconds: 120));
    await gesture.moveBy(const Offset(0, 80));
    await tester.pump(const Duration(milliseconds: 120));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(reordered, isTrue);
  });

  testWidgets('handle long-press shows the sort-disabled hint when disabled',
      (tester) async {
    var hint = false;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: TaskCard(
              task: task(1, '任务 A'),
              isSelected: false,
              onTap: () {},
              onLongPress: () {},
              index: 0,
              sortEnabled: false,
              onSortDisabled: () => hint = true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.byIcon(Icons.drag_indicator));
    await tester.pumpAndSettle();

    expect(hint, isTrue);
  });
}
