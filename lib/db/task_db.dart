import 'package:sqflite/sqflite.dart';
import '../helpers/db_helper.dart';
import '../models/task.dart';

class TaskDB {
  // Insert task
  static Future<int> insertTask(Task task) async {
    final db = await DBHelper.database;
    return await db.insert(
      'tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Update task
  static Future<int> updateTask(Task task) async {
    final db = await DBHelper.database;
    return await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  // Delete task
  static Future<int> deleteTask(int id) async {
    final db = await DBHelper.database;
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  // Delete all
  static Future<void> deleteAllTasks() async {
    final db = await DBHelper.database;
    await db.delete('tasks');
  }

  // Fetch tasks with search and AND-based tag filtering
  static Future<List<Task>> getTasks({
    String? search,
    List<String>? filterTags,
  }) async {
    final db = await DBHelper.database;
    String where = '';
    List<String> whereArgs = [];

    if (search != null && search.isNotEmpty) {
      where += '(title LIKE ? OR description LIKE ? OR tags LIKE ?)';
      whereArgs.add('%$search%');
      whereArgs.add('%$search%');
      whereArgs.add('%$search%');
    }

    if (filterTags != null && filterTags.isNotEmpty) {
      for (var tag in filterTags) {
        if (where.isNotEmpty) where += ' AND ';
        where += 'tags LIKE ?';
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
}
