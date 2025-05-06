import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'tasks.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE tasks(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT,
          description TEXT,
          tags TEXT
        )
      ''');
      },
    );
  }

  Future<int> insertTask(Task task) async {
    final dbClient = await db;
    return await dbClient.insert(
      'tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Task>> getTasks({
    String? search,
    List<String>? filterTags,
  }) async {
    final dbClient = await db;
    String where = '';
    List<String> whereArgs = [];

    if (search != null && search.isNotEmpty) {
      where += "title LIKE ?";
      whereArgs.add('%$search%');
    }
    if (filterTags != null && filterTags.isNotEmpty) {
      if (where.isNotEmpty) where += " AND ";
      where += filterTags.map((_) => "tags LIKE ?").join(" OR ");
      whereArgs.addAll(filterTags.map((t) => '%$t%'));
    }

    final List<Map<String, dynamic>> maps = await dbClient.query(
      'tasks',
      where: where.isEmpty ? null : where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
    );
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  Future<int> deleteTask(int id) async {
    final dbClient = await db;
    return await dbClient.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }
}
