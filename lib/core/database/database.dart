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
      version: 1,
      onCreate: _createTables,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE task (
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
        deleted_at INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE task_step (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        sort_order INTEGER DEFAULT 0,
        status TEXT DEFAULT 'pending',
        FOREIGN KEY (task_id) REFERENCES task(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE tag (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        color TEXT DEFAULT '#6B7280',
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE task_tag (
        task_id INTEGER NOT NULL,
        tag_id INTEGER NOT NULL,
        PRIMARY KEY (task_id, tag_id),
        FOREIGN KEY (task_id) REFERENCES task(id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES tag(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE recurrence_rule (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
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
      CREATE TABLE app_setting (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Create indexes
    await db.execute('CREATE INDEX idx_task_status ON task(status)');
    await db.execute('CREATE INDEX idx_task_start_date ON task(start_date)');
    await db.execute('CREATE INDEX idx_task_deleted_at ON task(deleted_at)');
    await db.execute('CREATE INDEX idx_step_task_id ON task_step(task_id)');
    await db.execute('CREATE INDEX idx_task_tag_task_id ON task_tag(task_id)');
    await db.execute('CREATE INDEX idx_task_tag_tag_id ON task_tag(tag_id)');
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    // Future migration logic here
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
