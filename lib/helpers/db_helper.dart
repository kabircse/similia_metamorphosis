import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/task.dart';

class DBHelper {
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'tasks.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        note TEXT,
        tags TEXT NOT NULL
      )
    ''');
  }

  // Insert task into the database
  Future<int> insertTask(Task task) async {
    final db = await database;
    return await db.insert(
      'tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Delete task by id
  Future<int> deleteTask(int id) async {
    final db = await database;
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  // Fetch tasks from the database
Future<List<Task>> getTasks({
    String? search,
    List<String>? filterTags,
  }) async {
    final db = await database;
    String where = '';
    List<String> whereArgs = [];

    if (search != null && search.isNotEmpty) {
      where += "(title LIKE ? OR description LIKE ? OR tags LIKE ?)";
      whereArgs.add('%$search%');
      whereArgs.add('%$search%');
      whereArgs.add('%$search%');
    }

    if (filterTags != null && filterTags.isNotEmpty) {
      if (where.isNotEmpty) where += " AND ";
      where += "tags LIKE ?";
      for (var tag in filterTags) {
        whereArgs.add('%$tag%');
      }
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: where.isEmpty ? null : where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
    );

    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }



  // Update a task in the database
  Future<int> updateTask(Task task) async {
    final db = await database;
    return await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  // Delete all tasks from the database
  Future<void> deleteAllTasks() async {
    final db = await database;
    await db.delete('tasks');
  }
}
