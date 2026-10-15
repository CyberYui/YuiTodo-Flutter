import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'yuitodo.db');

    return openDatabase(
      path,
      version: 5,
      onCreate: _createTables,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS task (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        note TEXT DEFAULT '',
        status TEXT DEFAULT 'pending',
        start_time INTEGER,
        end_time INTEGER,
        deadline INTEGER,
        start_date INTEGER,
        color TEXT DEFAULT '#3B82F6',
        icon TEXT,
        recurrence_id INTEGER,
        is_starred INTEGER DEFAULT 0,
        sort_order INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER,
        reminder_time INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS task_step (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        sort_order INTEGER DEFAULT 0,
        status TEXT DEFAULT 'pending',
        FOREIGN KEY (task_id) REFERENCES task(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS tag (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        color TEXT DEFAULT '#6B7280',
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS task_tag (
        task_id INTEGER NOT NULL,
        tag_id INTEGER NOT NULL,
        PRIMARY KEY (task_id, tag_id),
        FOREIGN KEY (task_id) REFERENCES task(id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES tag(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS recurrence_rule (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        interval INTEGER DEFAULT 1,
        days_of_week TEXT,
        day_of_month INTEGER,
        month_of_year INTEGER,
        end_date INTEGER,
        is_paused INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_setting (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_usage (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        open_time INTEGER NOT NULL,
        date TEXT NOT NULL
      )
    ''');

    // Create indexes
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_task_status ON task(status)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_task_start_date ON task(start_date)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_task_deleted_at ON task(deleted_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_step_task_id ON task_step(task_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_task_tag_task_id ON task_tag(task_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_task_tag_tag_id ON task_tag(tag_id)',
    );

    // Insert test data if tables are empty (for testing purposes)
    final taskCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM task'),
    );
    if (taskCount == 0) {
      await _insertTestData(db);
    }
  }

  Future<void> _insertTestData(Database db) async {
    final now = DateTime.now();
    final dayMs = 86400000;
    final nowMs = now.millisecondsSinceEpoch;

    // Insert tags
    await db.insert('tag', {'name': '工作', 'color': '#EF4444', 'created_at': nowMs});
    await db.insert('tag', {'name': '学习', 'color': '#3B82F6', 'created_at': nowMs});
    await db.insert('tag', {'name': '生活', 'color': '#10B981', 'created_at': nowMs});
    await db.insert('tag', {'name': '健康', 'color': '#F59E0B', 'created_at': nowMs});
    await db.insert('tag', {'name': '娱乐', 'color': '#8B5CF6', 'created_at': nowMs});

    // Insert tasks spread across multiple days (including current month)
    final tasks = [
      ['完成项目报告', '整理季度项目进度', 'done', nowMs - dayMs, nowMs, nowMs, nowMs, '#EF4444', null, null, 1, 0, nowMs - dayMs, nowMs, null, null],
      ['晨跑30分钟', '保持健康生活习惯', 'done', nowMs - dayMs, nowMs, nowMs, nowMs, '#10B981', null, null, 0, 1, nowMs - dayMs, nowMs, null, null],
      ['阅读《Flutter实战》', '完成第5-8章内容', 'done', nowMs - dayMs, nowMs, nowMs, nowMs, '#3B82F6', null, null, 0, 2, nowMs - dayMs, nowMs, null, null],
      ['准备周会材料', '整理本周工作内容', 'pending', nowMs, nowMs + dayMs, nowMs + dayMs, nowMs, '#F59E0B', null, null, 0, 3, nowMs, nowMs, null, null],
      ['看电影《奥本海默》', '周末放松娱乐', 'pending', nowMs + 5 * dayMs, nowMs + 7 * dayMs, nowMs + 7 * dayMs, nowMs, '#8B5CF6', null, null, 0, 4, nowMs, nowMs, null, null],
      ['学习Rust语言', '完成所有权和借用章节', 'done', nowMs - 2 * dayMs, nowMs - dayMs, nowMs - dayMs, nowMs - 2 * dayMs, '#EC4899', null, null, 0, 5, nowMs - 2 * dayMs, nowMs - dayMs, null, null],
      ['健身房锻炼', '胸肌和三头肌训练', 'done', nowMs - 2 * dayMs, nowMs - dayMs, nowMs - dayMs, nowMs - 2 * dayMs, '#06B6D4', null, null, 0, 6, nowMs - 2 * dayMs, nowMs - dayMs, null, null],
      ['购买生活用品', '超市采购清单', 'done', nowMs - 2 * dayMs, nowMs - dayMs, nowMs - dayMs, nowMs - 2 * dayMs, '#64748B', null, null, 0, 7, nowMs - 2 * dayMs, nowMs - dayMs, null, null],
      ['阅读《深入理解计算机系统》', '第3章 程序的机器级表示', 'done', nowMs - 3 * dayMs, nowMs - 2 * dayMs, nowMs - 2 * dayMs, nowMs - 3 * dayMs, '#8B5CF6', null, null, 0, 8, nowMs - 3 * dayMs, nowMs - 2 * dayMs, null, null],
      ['周末爬山', '香山公园一日游', 'done', nowMs - 3 * dayMs, nowMs - 2 * dayMs, nowMs - 2 * dayMs, nowMs - 3 * dayMs, '#10B981', null, null, 0, 9, nowMs - 3 * dayMs, nowMs - 2 * dayMs, null, null],
      ['写技术博客', '分享Flutter开发经验', 'done', nowMs - 4 * dayMs, nowMs - 3 * dayMs, nowMs - 3 * dayMs, nowMs - 4 * dayMs, '#3B82F6', null, null, 0, 10, nowMs - 4 * dayMs, nowMs - 3 * dayMs, null, null],
      ['整理房间', '大扫除', 'done', nowMs - 4 * dayMs, nowMs - 3 * dayMs, nowMs - 3 * dayMs, nowMs - 4 * dayMs, '#F59E0B', null, null, 0, 11, nowMs - 4 * dayMs, nowMs - 3 * dayMs, null, null],
      ['学习Python数据分析', 'pandas和numpy基础', 'done', nowMs - 5 * dayMs, nowMs - 4 * dayMs, nowMs - 4 * dayMs, nowMs - 5 * dayMs, '#3B82F6', null, null, 0, 12, nowMs - 5 * dayMs, nowMs - 4 * dayMs, null, null],
      ['看电影《盗梦空间》', '经典重温', 'done', nowMs - 5 * dayMs, nowMs - 4 * dayMs, nowMs - 4 * dayMs, nowMs - 5 * dayMs, '#8B5CF6', null, null, 0, 13, nowMs - 5 * dayMs, nowMs - 4 * dayMs, null, null],
      ['准备面试材料', '整理简历和项目经验', 'done', nowMs - 6 * dayMs, nowMs - 5 * dayMs, nowMs - 5 * dayMs, nowMs - 6 * dayMs, '#EF4444', null, null, 0, 14, nowMs - 6 * dayMs, nowMs - 5 * dayMs, null, null],
      ['晨跑5公里', '提升耐力', 'done', nowMs - 6 * dayMs, nowMs - 5 * dayMs, nowMs - 5 * dayMs, nowMs - 6 * dayMs, '#10B981', null, null, 0, 15, nowMs - 6 * dayMs, nowMs - 5 * dayMs, null, null],
      ['学习Dart语言进阶', '异步编程和Stream', 'done', nowMs - 7 * dayMs, nowMs - 6 * dayMs, nowMs - 6 * dayMs, nowMs - 7 * dayMs, '#3B82F6', null, null, 0, 16, nowMs - 7 * dayMs, nowMs - 6 * dayMs, null, null],
      ['整理代码仓库', '清理无用分支', 'done', nowMs - 7 * dayMs, nowMs - 6 * dayMs, nowMs - 6 * dayMs, nowMs - 7 * dayMs, '#64748B', null, null, 0, 17, nowMs - 7 * dayMs, nowMs - 6 * dayMs, null, null],
    ];

    // Add tasks in current month for heatmap testing
    // 使用当前月份的实际日期范围
    final currentDay = now.day;
    for (int i = 1; i <= currentDay && i <= 30; i++) {
      final taskDate = DateTime(now.year, now.month, i);
      final taskTime = taskDate.millisecondsSinceEpoch;
      tasks.add([
        '本月任务$i',
        '测试月度贡献图',
        'done',
        taskTime,
        taskTime,
        nowMs,
        nowMs,
        ['#EF4444', '#10B981', '#3B82F6', '#F59E0B', '#8B5CF6'][i % 5],
        null,
        null,
        0,
        17 + i,
        taskTime,
        taskTime,
        null,
        null,
      ]);
    }

    for (final task in tasks) {
      await db.insert('task', {
        'title': task[0],
        'note': task[1],
        'status': task[2],
        'start_time': task[3],
        'end_time': task[4],
        'deadline': task[5],
        'start_date': task[6],
        'color': task[7],
        'icon': task[8],
        'recurrence_id': task[9],
        'is_starred': task[10],
        'sort_order': task[11],
        'created_at': task[12],
        'updated_at': task[13],
        'deleted_at': task[14],
        'reminder_time': task[15],
      });
    }

    // Insert steps
    final steps = [
      [1, '收集项目数据', 0, 'completed'], [1, '编写进度报告', 1, 'completed'], [1, '制作PPT', 2, 'pending'],
      [2, '热身5分钟', 0, 'completed'], [2, '慢跑20分钟', 1, 'completed'], [2, '拉伸5分钟', 2, 'completed'],
      [3, '阅读第5章', 0, 'completed'], [3, '做笔记', 1, 'completed'],
      [4, '整理会议议程', 0, 'pending'], [4, '准备演示文稿', 1, 'pending'],
      [5, '购买电影票', 0, 'pending'], [5, '准备零食', 1, 'pending'],
      [6, '阅读第1章', 0, 'completed'], [6, '练习所有权', 1, 'completed'],
      [7, '热身', 0, 'completed'], [7, '杠铃卧推', 1, 'completed'], [7, '哑铃飞鸟', 2, 'completed'],
      [8, '去超市', 0, 'completed'], [8, '结账', 1, 'completed'],
      [9, '阅读第3章', 0, 'completed'], [9, '做笔记', 1, 'completed'],
      [10, '准备装备', 0, 'completed'], [10, '早起出发', 1, 'completed'],
    ];
    for (final step in steps) {
      await db.insert('task_step', {
        'task_id': step[0],
        'title': step[1],
        'sort_order': step[2],
        'status': step[3],
      });
    }

    // Insert task-tag relations
    final taskTags = [
      [1, 1], [1, 2], [2, 4], [3, 2], [4, 1], [5, 5], [6, 2], [7, 4], [8, 3],
      [9, 2], [10, 5], [11, 2], [12, 3], [13, 2], [14, 5], [15, 1], [16, 4], [17, 2], [18, 1],
    ];
    for (final tt in taskTags) {
      await db.insert('task_tag', {'task_id': tt[0], 'tag_id': tt[1]});
    }

    // Insert app usage data
    for (int i = 0; i < 7; i++) {
      for (int j = 0; j <= i; j++) {
        final date = DateTime(now.year, now.month, now.day - i);
        await db.insert('app_usage', {
          'open_time': nowMs - i * dayMs + j * 3600000,
          'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        });
      }
    }
  }

  Future<void> _upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE task ADD COLUMN reminder_time INTEGER');
    }
    if (oldVersion < 3) {
      // Check if column already exists before adding
      final columns = await db.rawQuery('PRAGMA table_info(task)');
      final columnNames = columns.map((c) => c['name'] as String).toList();
      if (!columnNames.contains('recurrence_id')) {
        await db.execute('ALTER TABLE task ADD COLUMN recurrence_id INTEGER');
      }
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS app_usage (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          open_time INTEGER NOT NULL,
          date TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 5) {
      // Add task_id to recurrence_rule (fix: column was missing)
      final columns = await db.rawQuery('PRAGMA table_info(recurrence_rule)');
      final columnNames = columns.map((c) => c['name'] as String).toList();
      if (!columnNames.contains('task_id')) {
        await db.execute('ALTER TABLE recurrence_rule ADD COLUMN task_id INTEGER');
      }
    }
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
