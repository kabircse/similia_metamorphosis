import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';

class TaskDB {
  static final TaskDB _instance = TaskDB._internal();
  factory TaskDB() => _instance;
  TaskDB._internal();

  Database? _db;

  // Get database instance
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  // Initialize the database and create the tasks table
  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'tasks.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute('''
        CREATE TABLE tasks (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          description TEXT,
          tags TEXT,
          isCompleted INTEGER
        )
      ''');
      },
    );
  }

  // Insert a new task into the database
  Future<void> insertTask(Task task) async {
    final db = await database;
    await db.insert(
      'tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all tasks, with optional search filtering by title, description, and tags
  Future<List<Task>> getTasks({String? keyword}) async {
    final db = await database;
    String where = '';
    List<String> whereArgs = [];

    if (keyword != null && keyword.isNotEmpty) {
      where += "(title LIKE ? OR description LIKE ? OR tags LIKE ?)";
      whereArgs.add('%$keyword%');
      whereArgs.add('%$keyword%');
      whereArgs.add('%$keyword%');
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: where.isEmpty ? null : where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
    );

    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  // Update an existing task in the database
  Future<void> updateTask(Task task) async {
    final db = await database;
    await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  // Delete a task by ID
  Future<void> deleteTask(int id) async {
    final db = await database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  // Delete all tasks in the database
  Future<void> deleteAllTasks() async {
    final db = await database;
    await db.delete('tasks');
  }

  // Retrieve all tasks in the database
  Future<List<Task>> getAllTasks() async {
    final db = await database;
    final maps = await db.query('tasks');
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }
}
