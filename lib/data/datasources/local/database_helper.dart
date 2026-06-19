import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../../../core/constants/app_constants.dart';

/// Singleton SQLite database helper.
/// All schema definitions match the spec exactly.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final fullPath = p.join(dbPath, AppConstants.dbName);
    return openDatabase(
      fullPath,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE projects (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'planning',
        user_idea TEXT,
        analyst_questions TEXT,
        analyst_mockup TEXT,
        product_spec TEXT,
        plan_approved INTEGER DEFAULT 0,
        current_step INTEGER DEFAULT 1,
        total_files INTEGER DEFAULT 0,
        completed_files INTEGER DEFAULT 0,
        deploy_type TEXT,
        deploy_url TEXT,
        zip_path TEXT,
        api_key_source TEXT DEFAULT 'default',
        custom_api_key TEXT,
        created_at INTEGER,
        updated_at INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE files (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        path TEXT NOT NULL,
        code TEXT NOT NULL,
        version INTEGER DEFAULT 1,
        language TEXT,
        status TEXT DEFAULT 'pending',
        error_log TEXT,
        FOREIGN KEY (project_id) REFERENCES projects(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE chat_history (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        agent TEXT NOT NULL,
        role TEXT NOT NULL,
        message TEXT NOT NULL,
        action TEXT,
        created_at INTEGER,
        FOREIGN KEY (project_id) REFERENCES projects(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY DEFAULT 1,
        default_kimi_key TEXT,
        default_vercel_token TEXT,
        theme TEXT DEFAULT 'dark',
        language TEXT DEFAULT 'uz'
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Future migrations go here
  }

  // --------------- Projects ---------------

  Future<List<Map<String, dynamic>>> getAllProjects() async {
    final db = await database;
    return db.query('projects', orderBy: 'updated_at DESC');
  }

  Future<Map<String, dynamic>?> getProjectById(String id) async {
    final db = await database;
    final rows = await db.query('projects', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> upsertProject(Map<String, dynamic> map) async {
    final db = await database;
    await db.insert('projects', map,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteProject(String id) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('projects', where: 'id = ?', whereArgs: [id]);
      await txn.delete('files', where: 'project_id = ?', whereArgs: [id]);
      await txn.delete('chat_history',
          where: 'project_id = ?', whereArgs: [id]);
    });
  }

  // --------------- Files ---------------

  Future<List<Map<String, dynamic>>> getFilesForProject(
      String projectId) async {
    final db = await database;
    return db.query('files',
        where: 'project_id = ?', whereArgs: [projectId], orderBy: 'path ASC');
  }

  Future<void> upsertFile(Map<String, dynamic> map) async {
    final db = await database;
    await db.insert('files', map,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> upsertFiles(List<Map<String, dynamic>> maps) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final map in maps) {
        await txn.insert('files', map,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  // --------------- Chat ---------------

  Future<List<Map<String, dynamic>>> getChatHistory(
      String projectId) async {
    final db = await database;
    return db.query('chat_history',
        where: 'project_id = ?',
        whereArgs: [projectId],
        orderBy: 'created_at ASC');
  }

  Future<void> insertChatMessage(Map<String, dynamic> map) async {
    final db = await database;
    await db.insert('chat_history', map,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --------------- Settings ---------------

  Future<Map<String, dynamic>?> getSettings() async {
    final db = await database;
    final rows = await db.query('settings', where: 'id = 1');
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> upsertSettings(Map<String, dynamic> map) async {
    final db = await database;
    await db.insert('settings', {...map, 'id': 1},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
