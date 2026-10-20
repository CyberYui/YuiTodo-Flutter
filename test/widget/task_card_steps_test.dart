import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yuitodo/models/task.dart';
import 'package:yuitodo/ui/widgets/task_card.dart';

void main() {
  Task taskWithSteps(int count) {
    return Task(
      id: 1,
      title: '任务 A',
      createdAt: 0,
      updatedAt: 0,
      steps: [
        for (var i = 0; i < count; i++)
          TaskStep(id: i + 1, taskId: 1, title: '子任务 $i', sortOrder: i),
      ],
    );
  }

  Widget wrap(Widget child) => ProviderScope(
        child: MaterialApp(home: Scaffold(body: child)),
      );

  testWidgets('collapsed card previews three steps and shows expand action',
      (tester) async {
    var toggled = false;
    await tester.pumpWidget(
      wrap(
        TaskCard(
          task: taskWithSteps(5),
          isSelected: false,
          onTap: () {},
          onLongPress: () {},
          index: 0,
          showAllSteps: false,
          onToggleSteps: () => toggled = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('子任务 0/5'), findsOneWidget);
    expect(find.byIcon(Icons.circle_outlined), findsNWidgets(3));
    expect(find.text('展开全部（还有 2 个）'), findsOneWidget);
    expect(find.text('子任务 4'), findsNothing);

    await tester.tap(find.text('展开全部（还有 2 个）'));
    expect(toggled, isTrue);
  });

  testWidgets('expanded card shows every step and a collapse action',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        TaskCard(
          task: taskWithSteps(5),
          isSelected: false,
          onTap: () {},
          onLongPress: () {},
          index: 0,
          showAllSteps: true,
          onToggleSteps: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.circle_outlined), findsNWidgets(5));
    expect(find.text('收起子任务'), findsOneWidget);
    expect(find.text('子任务 4'), findsOneWidget);
  });

  testWidgets('tapping a step reports the toggle', (tester) async {
    TaskStep? toggledStep;
    await tester.pumpWidget(
      wrap(
        TaskCard(
          task: taskWithSteps(4),
          isSelected: false,
          onTap: () {},
          onLongPress: () {},
          index: 0,
          showAllSteps: true,
          onStepToggle: (_, step) => toggledStep = step,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.circle_outlined).last);
    expect(toggledStep?.title, '子任务 3');
  });
}
