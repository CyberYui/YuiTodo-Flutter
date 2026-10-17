import 'package:sqflite/sqflite.dart';

import '../date/date_utils.dart';

/// Seeds a small, editable set of sample tasks and habits on a fresh install.
///
/// The samples double as an in-app manual: they demonstrate sections, tags,
/// subtasks, recurrence, habits, stats and the swipe actions. Seeding only
/// happens when the task table is empty, so existing users are never touched.
class SampleData {
  static Future<void> seedIfNeeded(Database db) async {
    final flags = await db.query(
      'app_setting',
      where: 'key = ?',
      whereArgs: ['sample_seeded'],
    );
    if (flags.isNotEmpty) return;

    final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM task'),
        ) ??
        0;
    if (count == 0) {
      await _seed(db);
    }

    await db.insert(
      'app_setting',
      {'key': 'sample_seeded', 'value': '1'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> _seed(Database db) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final nowMs = now.millisecondsSinceEpoch;

    Future<int> tag(String name, String color) => db.insert('tag', {
          'name': name,
          'color': color,
          'created_at': nowMs,
        });

    final life = await tag('生活', '#22C55E');
    final work = await tag('工作', '#3B82F6');
    final study = await tag('学习', '#8B5CF6');
    final habitTag = await tag('习惯', '#F59E0B');

    Future<int> task({
      required String title,
      String note = '',
      String status = 'pending',
      required String color,
      String? icon,
      required DateTime date,
      DateTime? end,
      bool isHabit = false,
      int target = 7,
      int sort = 0,
      bool starred = false,
      List<int> tags = const [],
    }) async {
      final startMs = date.millisecondsSinceEpoch;
      final endMs =
          (end ?? date.add(const Duration(days: 1))).millisecondsSinceEpoch;
      final id = await db.insert('task', {
        'title': title,
        'note': note,
        'status': status,
        'start_time': startMs,
        'end_time': endMs,
        'deadline': endMs,
        'start_date': startMs,
        'color': color,
        'icon': icon,
        'recurrence_id': null,
        'is_starred': starred ? 1 : 0,
        'sort_order': sort,
        'created_at': nowMs,
        'updated_at': nowMs,
        'deleted_at': null,
        'reminder_time': null,
        'is_habit': isHabit ? 1 : 0,
        'habit_target_per_week': target,
      });
      for (final tagId in tags) {
        await db.insert('task_tag', {'task_id': id, 'tag_id': tagId});
      }
      return id;
    }

    Future<int> step(int taskId, String title, int order,
        {String status = 'pending'}) {
      return db.insert('task_step', {
        'task_id': taskId,
        'title': title,
        'sort_order': order,
        'status': status,
      });
    }

    Future<void> rule(
      int taskId, {
      String type = 'daily',
      int interval = 1,
      String? daysOfWeek,
    }) {
      return db.insert('recurrence_rule', {
        'task_id': taskId,
        'type': type,
        'interval': interval,
        'days_of_week': daysOfWeek,
        'end_type': 'none',
        'month_mode': 'day',
        'is_paused': 0,
        'created_at': nowMs,
      });
    }

    Future<void> occurrence(int taskId, DateTime day, String state) {
      return db.insert(
        'task_occurrence',
        {
          'task_id': taskId,
          'occurrence_day': ymdKey(day),
          'state': state,
          'completed_at': state == 'done'
              ? day.add(const Duration(hours: 9)).millisecondsSinceEpoch
              : null,
          'created_at': nowMs,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    // 1) In-app manual.
    await task(
      title: '👋 欢迎使用 YuiTodo',
      note: '这是一条示例任务，也是使用说明：\n'
          '• 左滑任务 → 星标；右滑任务 → 完成\n'
          '• 长按任务 → 多选；点击左侧圆圈 → 快速完成\n'
          '• 顶部「=」展开筛选与标签\n'
          '• 右上角「⋮」→ 日历 / 专注 / 统计 / 设置\n'
          '• 设置 → 功能 → 习惯打卡\n\n'
          '示例数据可以随时删除，删除后不会再次出现。',
      color: '#3B82F6',
      date: today,
      sort: 0,
      tags: [life],
    );

    // 2) Daily recurring task with subtasks + history.
    final checkin = await task(
      title: '每日签到',
      note: '每天的小习惯，坚持打卡',
      color: '#EF4444',
      date: today.subtract(const Duration(days: 7)),
      sort: 1,
      tags: [life, habitTag],
    );
    final step1 = await step(checkin, 'OPPO 签到', 0);
    final step2 = await step(checkin, '小米签到', 1);
    await step(checkin, '国家电网', 2);
    await rule(checkin);
    await occurrence(checkin, today, 'done');
    for (final stepId in [step1, step2]) {
      await db.insert(
        'task_step_occurrence',
        {
          'step_id': stepId,
          'task_id': checkin,
          'occurrence_day': ymdKey(today),
          'status': 'completed',
          'updated_at': nowMs,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    for (var i = 1; i <= 7; i++) {
      final day = today.subtract(Duration(days: i));
      await occurrence(checkin, day, 'done');
      for (final stepId in [step1, step2]) {
        await db.insert(
          'task_step_occurrence',
          {
            'step_id': stepId,
            'task_id': checkin,
            'occurrence_day': ymdKey(day),
            'status': 'completed',
            'updated_at': nowMs,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }

    // 3) Weekly recurring task.
    final review = await task(
      title: '每周复盘',
      note: '回顾本周完成的任务，规划下周重点',
      color: '#8B5CF6',
      date: today,
      sort: 2,
      tags: [work],
    );
    await rule(review, type: 'weekly', daysOfWeek: '5');

    // 4) One-off tasks (past completed ones feed the statistics).
    await task(
      title: '买咖啡豆',
      note: '浅烘 200g',
      color: '#F59E0B',
      date: today.add(const Duration(days: 2)),
      sort: 3,
      tags: [life],
    );
    await task(
      title: '读书 30 分钟',
      note: '《深度工作》',
      color: '#10B981',
      status: 'done',
      date: today.subtract(const Duration(days: 1)),
      sort: 4,
      tags: [study],
    );
    await task(
      title: '晨跑 5 公里',
      note: '配速 5:30',
      color: '#06B6D4',
      status: 'done',
      date: today.subtract(const Duration(days: 3)),
      sort: 5,
      tags: [life],
    );
    await task(
      title: '整理桌面',
      note: '清理文件与书签',
      color: '#64748B',
      status: 'done',
      date: today.subtract(const Duration(days: 5)),
      sort: 6,
      tags: [work],
    );
    await task(
      title: '回顾季度目标',
      note: '检查进度并调整计划',
      color: '#EC4899',
      status: 'done',
      date: today.subtract(const Duration(days: 2)),
      sort: 7,
      tags: [work],
      starred: true,
    );

    // 5) Habits with history for the streak/grid.
    final water = await task(
      title: '喝水',
      note: '每天 8 杯水',
      color: '#06B6D4',
      date: today.subtract(const Duration(days: 12)),
      isHabit: true,
      target: 7,
      sort: 8,
      tags: [habitTag],
    );
    await rule(water);
    await occurrence(water, today, 'done');
    for (var i = 1; i <= 12; i++) {
      final day = today.subtract(Duration(days: i));
      await occurrence(water, day, i == 4 || i >= 11 ? 'skipped' : 'done');
    }

    final reading = await task(
      title: '睡前阅读',
      note: '每天读 20 页',
      color: '#8B5CF6',
      date: today.subtract(const Duration(days: 12)),
      isHabit: true,
      target: 5,
      sort: 9,
      tags: [habitTag],
    );
    await rule(reading);
    for (var i = 1; i <= 12; i++) {
      final day = today.subtract(Duration(days: i));
      await occurrence(
        reading,
        day,
        i <= 6 || i == 9 ? 'done' : 'skipped',
      );
    }
  }
}
