import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DBHelper {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    String path;

    if (Platform.isAndroid || Platform.isIOS) {
      final dbDir = await getApplicationDocumentsDirectory();
      path = join(dbDir.path, 'tasks.db');
    } else {
      final dbPath = await getDatabasesPath();
      path = join(dbPath, 'tasks.db');
    }

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT UNIQUE NOT NULL,
            description TEXT,
            note TEXT,
            tags TEXT NOT NULL
          )
        ''');
      },
    );
  }
}
