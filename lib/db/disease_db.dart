import 'package:sqflite/sqflite.dart';
import '../helpers/db_helper.dart';
import '../models/disease.dart';

class DiseaseDB {
  // Insert disease
  static Future<int> insertDisease(Disease disease) async {
    final db = await DBHelper.database;
    return await db.insert(
      'diseases',
      disease.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Update disease
  static Future<int> updateDisease(Disease disease) async {
    final db = await DBHelper.database;
    return await db.update(
      'diseases',
      disease.toMap(),
      where: 'id = ?',
      whereArgs: [disease.id],
    );
  }

  // Delete disease
  static Future<int> deleteDisease(int id) async {
    final db = await DBHelper.database;
    return await db.delete('diseases', where: 'id = ?', whereArgs: [id]);
  }

  // Delete all
  static Future<void> deleteAllDiseases() async {
    final db = await DBHelper.database;
    await db.delete('diseases');
  }

  // Fetch diseases with search and AND-based tag filtering (legacy)
  static Future<List<Disease>> getDiseases({
    String? search,
    List<String>? filterTags,
  }) async {
    final db = await DBHelper.database;
    String where = '';
    List<String> whereArgs = [];

    if (search != null && search.isNotEmpty) {
      where += '(title LIKE ? OR note LIKE ? OR tags LIKE ?)';
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
      'diseases',
      where: where.isEmpty ? null : where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
    );

    return List.generate(maps.length, (i) => Disease.fromMap(maps[i]));
  }

  // Get diseases with pagination and filtering (used in home_screen.dart)
  static Future<List<Disease>> getFilteredDiseases({
    String? search,
    String? tag,
    int offset = 0,
    int limit = 20,
  }) async {
    final db = await DBHelper.database;

    String where = '';
    List<String> whereArgs = [];

    if (search != null && search.isNotEmpty) {
      where +=
          '(title LIKE ? OR description LIKE ? OR note LIKE ? OR tags LIKE ?)';
      whereArgs.add('%$search%');
      whereArgs.add('%$search%');
      whereArgs.add('%$search%');
      whereArgs.add('%$search%');
    }

    if (tag != null && tag.isNotEmpty) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'tags LIKE ?';
      whereArgs.add('%$tag%');
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'diseases',
      where: where.isEmpty ? null : where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      offset: offset,
      limit: limit,
      orderBy: 'id DESC',
    );

    return List.generate(maps.length, (i) => Disease.fromMap(maps[i]));
  }

static Future<List<String>> getAllTags() async {
    final db = await DBHelper.database;
    final result = await db.query('diseases', columns: ['tags']);

    final tagSet = <String>{};
    for (var row in result) {
      final tagString = row['tags'] as String? ?? '';
      tagSet.addAll(
        tagString.split(';').map((t) => t.trim()).where((t) => t.isNotEmpty),
      );
    }

    final tagList = tagSet.toList();
    tagList.sort(
      (a, b) => a.toLowerCase().compareTo(b.toLowerCase()),
    ); // Sort alphabetically
    return tagList;
  }

  static Future<void> clearDiseases() async {
    final db = await DBHelper.database;
    await db.delete('diseases');
  }


}
