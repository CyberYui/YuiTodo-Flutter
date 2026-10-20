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
      version: 14,
      onCreate: createTables,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> createTables(Database db, int version) async {
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
        reminder_time INTEGER,
        reminder_sound TEXT,
        is_habit INTEGER DEFAULT 0,
        habit_target_per_week INTEGER DEFAULT 7
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
        end_type TEXT DEFAULT 'none',
        end_date INTEGER,
        end_count INTEGER,
        month_mode TEXT DEFAULT 'day',
        week_index INTEGER,
        skip_weekends INTEGER DEFAULT 0,
        workday_only INTEGER DEFAULT 0,
        is_paused INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS task_occurrence (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task_id INTEGER NOT NULL,
        occurrence_day INTEGER NOT NULL,
        state TEXT NOT NULL,
        completed_at INTEGER,
        created_at INTEGER NOT NULL,
        UNIQUE(task_id, occurrence_day),
        FOREIGN KEY (task_id) REFERENCES task(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_occ_task_day ON task_occurrence(task_id, occurrence_day)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_occ_day ON task_occurrence(occurrence_day)',
    );

    await db.execute('''
      CREATE TABLE IF NOT EXISTS task_step_occurrence (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        step_id INTEGER NOT NULL,
        task_id INTEGER NOT NULL,
        occurrence_day INTEGER NOT NULL,
        status TEXT NOT NULL,
        updated_at INTEGER NOT NULL,
        UNIQUE(step_id, occurrence_day),
        FOREIGN KEY (step_id) REFERENCES task_step(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_step_occ_task_day ON task_step_occurrence(task_id, occurrence_day)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_step_occ_day ON task_step_occurrence(occurrence_day)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_recurrence_task ON recurrence_rule(task_id)',
    );

    await db.execute('''
      CREATE TABLE IF NOT EXISTS focus_session (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task_id INTEGER,
        mode INTEGER NOT NULL,
        status INTEGER NOT NULL,
        start_time INTEGER NOT NULL,
        end_time INTEGER,
        target_duration INTEGER NOT NULL,
        actual_duration INTEGER NOT NULL DEFAULT 0,
        pause_count INTEGER NOT NULL DEFAULT 0,
        rest_count INTEGER NOT NULL DEFAULT 0,
        rest_duration INTEGER NOT NULL DEFAULT 0,
        focus_name TEXT,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (task_id) REFERENCES task(id) ON DELETE SET NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_focus_start ON focus_session(start_time)',
    );

    await db.execute('''
      CREATE TABLE IF NOT EXISTS focus_rest_segment (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        start_time INTEGER NOT NULL,
        end_time INTEGER,
        duration INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (session_id) REFERENCES focus_session(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS task_reminder (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task_id INTEGER NOT NULL,
        offset_minutes INTEGER,
        absolute_time INTEGER,
        is_enabled INTEGER DEFAULT 1,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (task_id) REFERENCES task(id) ON DELETE CASCADE
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
      'CREATE INDEX IF NOT EXISTS idx_task_reminder_task_id ON task_reminder(task_id)',
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
    if (oldVersion < 6) {
      // 1) Add the richer recurrence-rule columns (idempotent).
      final ruleColumns = await db.rawQuery('PRAGMA table_info(recurrence_rule)');
      final ruleNames =
          ruleColumns.map((c) => c['name'] as String).toSet();
      Future<void> addRuleColumn(String name, String ddl) async {
        if (!ruleNames.contains(name)) {
          await db.execute('ALTER TABLE recurrence_rule ADD COLUMN $ddl');
        }
      }

      await addRuleColumn('end_type', "end_type TEXT DEFAULT 'none'");
      await addRuleColumn('end_count', 'end_count INTEGER');
      await addRuleColumn('month_mode', "month_mode TEXT DEFAULT 'day'");
      await addRuleColumn('week_index', 'week_index INTEGER');
      await addRuleColumn('skip_weekends', 'skip_weekends INTEGER DEFAULT 0');
      await addRuleColumn('workday_only', 'workday_only INTEGER DEFAULT 0');

      // 2) Occurrence exception table.
      await db.execute('''
        CREATE TABLE IF NOT EXISTS task_occurrence (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          task_id INTEGER NOT NULL,
          occurrence_day INTEGER NOT NULL,
          state TEXT NOT NULL,
          completed_at INTEGER,
          created_at INTEGER NOT NULL,
          UNIQUE(task_id, occurrence_day),
          FOREIGN KEY (task_id) REFERENCES task(id) ON DELETE CASCADE
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_occ_task_day ON task_occurrence(task_id, occurrence_day)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_occ_day ON task_occurrence(occurrence_day)',
      );

      // 3) Fold previously-materialized instances into task_occurrence, then
      //    remove them so only templates remain.
      final tplRows = await db.rawQuery(
        'SELECT task_id FROM recurrence_rule WHERE task_id IS NOT NULL',
      );
      final templateIds =
          tplRows.map((r) => r['task_id'] as int).toSet();

      final instanceRows = await db.query(
        'task',
        columns: ['id', 'recurrence_id', 'status', 'start_date', 'updated_at'],
        where: 'recurrence_id IS NOT NULL',
      );
      for (final row in instanceRows) {
        final taskId = row['id'] as int;
        if (templateIds.contains(taskId)) {
          // Original task misused recurrence_id as the rule id; clear it.
          await db.update(
            'task',
            {'recurrence_id': null},
            where: 'id = ?',
            whereArgs: [taskId],
          );
          continue;
        }
        final sourceId = row['recurrence_id'] as int;
        if (!templateIds.contains(sourceId)) {
          // Orphan instance (template gone) — drop it.
          await db.delete('task', where: 'id = ?', whereArgs: [taskId]);
          continue;
        }
        if (row['status'] == 'done') {
          final startDate = row['start_date'] as int?;
          if (startDate != null) {
            final d = DateTime.fromMillisecondsSinceEpoch(startDate);
            final day = d.year * 10000 + d.month * 100 + d.day;
            await db.insert(
              'task_occurrence',
              {
                'task_id': sourceId,
                'occurrence_day': day,
                'state': 'done',
                'completed_at': row['updated_at'],
                'created_at': DateTime.now().millisecondsSinceEpoch,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
        await db.delete('task', where: 'id = ?', whereArgs: [taskId]);
      }
    }
    if (oldVersion < 7) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS task_step_occurrence (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          step_id INTEGER NOT NULL,
          task_id INTEGER NOT NULL,
          occurrence_day INTEGER NOT NULL,
          status TEXT NOT NULL,
          updated_at INTEGER NOT NULL,
          UNIQUE(step_id, occurrence_day),
          FOREIGN KEY (step_id) REFERENCES task_step(id) ON DELETE CASCADE
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_step_occ_task_day ON task_step_occurrence(task_id, occurrence_day)',
      );
    }
    if (oldVersion < 8) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS focus_session (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          task_id INTEGER,
          mode INTEGER NOT NULL,
          status INTEGER NOT NULL,
          start_time INTEGER NOT NULL,
          end_time INTEGER,
          target_duration INTEGER NOT NULL,
          actual_duration INTEGER NOT NULL DEFAULT 0,
          pause_count INTEGER NOT NULL DEFAULT 0,
          rest_count INTEGER NOT NULL DEFAULT 0,
          rest_duration INTEGER NOT NULL DEFAULT 0,
          focus_name TEXT,
          created_at INTEGER NOT NULL,
          FOREIGN KEY (task_id) REFERENCES task(id) ON DELETE SET NULL
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_focus_start ON focus_session(start_time)',
      );
      await db.execute('''
        CREATE TABLE IF NOT EXISTS focus_rest_segment (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          session_id INTEGER NOT NULL,
          start_time INTEGER NOT NULL,
          end_time INTEGER,
          duration INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (session_id) REFERENCES focus_session(id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 9) {
      final columns = await db.rawQuery('PRAGMA table_info(task)');
      final names = columns.map((c) => c['name'] as String).toSet();
      if (!names.contains('is_habit')) {
        await db.execute('ALTER TABLE task ADD COLUMN is_habit INTEGER DEFAULT 0');
      }
      if (!names.contains('habit_target_per_week')) {
        await db.execute('ALTER TABLE task ADD COLUMN habit_target_per_week INTEGER DEFAULT 7');
      }
      await db.execute('''
        CREATE TABLE IF NOT EXISTS task_reminder (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          task_id INTEGER NOT NULL,
          offset_minutes INTEGER,
          absolute_time INTEGER,
          is_enabled INTEGER DEFAULT 1,
          created_at INTEGER NOT NULL,
          FOREIGN KEY (task_id) REFERENCES task(id) ON DELETE CASCADE
        )
      ''');
    }

    if (oldVersion < 10) {
      // Recurring tasks store step completion per occurrence. Older editor
      // versions wrote the occurrence statuses back to task_step, which made
      // every future instance look completed. Preserve today's completion as
      // today's occurrence, then reset the template statuses to pending.
      final now = DateTime.now();
      final todayKey = now.year * 10000 + now.month * 100 + now.day;
      final nowMs = now.millisecondsSinceEpoch;
      await db.rawInsert(
        '''INSERT OR REPLACE INTO task_step_occurrence
           (step_id, task_id, occurrence_day, status, updated_at)
           SELECT ts.id, ts.task_id, ?, 'completed', ?
           FROM task_step ts
           WHERE ts.status = 'completed'
             AND ts.task_id IN (SELECT task_id FROM recurrence_rule)''',
        [todayKey, nowMs],
      );
      await db.rawUpdate(
        '''UPDATE task_step SET status = 'pending'
           WHERE task_id IN (SELECT task_id FROM recurrence_rule)''',
      );
    }

    if (oldVersion < 11) {
      // The table itself has existed since v9; add the lookup index used when
      // loading extra reminders for the editor and the scheduler.
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_task_reminder_task_id ON task_reminder(task_id)',
      );
    }

    if (oldVersion < 12) {
      // Older hard deletes did not remove child reminder rows (foreign keys
      // are not enforced by default). Drop any orphans left behind.
      await db.execute(
        'DELETE FROM task_reminder '
        'WHERE task_id NOT IN (SELECT id FROM task)',
      );
    }

    if (oldVersion < 13) {
      final columns = await db.rawQuery('PRAGMA table_info(task)');
      final names = columns.map((c) => c['name'] as String).toSet();
      if (!names.contains('reminder_sound')) {
        await db.execute('ALTER TABLE task ADD COLUMN reminder_sound TEXT');
      }
    }

    if (oldVersion < 14) {
      // Range queries filter occurrence rows by day; add the missing day
      // indexes and the per-task recurrence lookup index.
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_step_occ_day ON task_step_occurrence(occurrence_day)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_recurrence_task ON recurrence_rule(task_id)',
      );
    }
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
