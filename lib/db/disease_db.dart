import 'package:sqflite/sqflite.dart';
import '../helpers/db_helper.dart';
import '../models/disease.dart';

class DiseaseDB {
  // Normalize tag: Converts various formats to "Title Case With Spaces"
  static String _normalizeTag(String input) {
    return input
        .replaceAll(RegExp(r'[_\-]+'), ' ') // Replace _ and - with space
        .replaceAllMapped(
          RegExp(r'(?<=[a-z])(?=[A-Z])'),
          (m) => ' ',
        ) // Split camel case
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ')
        .trim();
  }

  static Future<int> insertDisease(Disease disease) async {
    final db = await DBHelper.database;
    final normalizedTags = disease.tags
        .map((tag) => _normalizeTag(tag))
        .toSet()
        .join(';');

    return await db.insert('diseases', {
      'title': disease.title,
      'description': disease.description,
      'note': disease.note,
      'tags': normalizedTags,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<int> updateDisease(Disease disease) async {
    final db = await DBHelper.database;
    final normalizedTags = disease.tags
        .map((tag) => _normalizeTag(tag))
        .toSet()
        .join(';');

    return await db.update(
      'diseases',
      {
        'id': disease.id,
        'title': disease.title,
        'description': disease.description,
        'note': disease.note,
        'tags': normalizedTags,
      },
      where: 'id = ?',
      whereArgs: [disease.id],
    );
  }

  static Future<int> deleteDisease(int id) async {
    final db = await DBHelper.database;
    return await db.delete('diseases', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> deleteAllDiseases() async {
    final db = await DBHelper.database;
    await db.delete('diseases');
  }

  static Future<List<Disease>> getDiseases({
    String? search,
    List<String>? filterTags,
  }) async {
    final db = await DBHelper.database;
    String where = '';
    List<String> whereArgs = [];

    if (search != null && search.isNotEmpty) {
      final searchNorm = _normalizeTag(search);
      where += '(title LIKE ? OR note LIKE ? OR tags LIKE ?)';
      whereArgs.add('%$searchNorm%');
      whereArgs.add('%$searchNorm%');
      whereArgs.add('%$searchNorm%');
    }

    if (filterTags != null && filterTags.isNotEmpty) {
      for (var tag in filterTags) {
        if (where.isNotEmpty) where += ' AND ';
        where += 'tags LIKE ?';
        whereArgs.add('%${_normalizeTag(tag)}%');
      }
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'diseases',
      where: where.isEmpty ? null : where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
    );

    return List.generate(maps.length, (i) => Disease.fromMap(maps[i]));
  }

static Future<List<Disease>> getFilteredDiseases({
    String search = '',
    String tag = '',
    int offset = 0,
    int limit = 20,
  }) async {
    final db = await DBHelper.database;

    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (search.isNotEmpty) {
      whereClauses.add('(title LIKE ? OR description LIKE ? OR note LIKE ?)');
      whereArgs.addAll(['%$search%', '%$search%', '%$search%']);
    }

    if (tag.isNotEmpty) {
      final tags =
          tag
              .split(',')
              .map((t) => t.trim())
              .where((t) => t.isNotEmpty)
              .toList();
      for (final t in tags) {
        whereClauses.add('tags LIKE ?');
        whereArgs.add('%$t%');
      }
    }

    final where =
        whereClauses.isNotEmpty ? 'WHERE ${whereClauses.join(' AND ')}' : '';

    final result = await db.rawQuery(
      '''
    SELECT * FROM diseases
    $where
    ORDER BY id DESC
    LIMIT ? OFFSET ?
  ''',
      [...whereArgs, limit, offset],
    );

    return result.map((map) => Disease.fromMap(map)).toList();
  }

  static Future<List<String>> getAllTags() async {
    final db = await DBHelper.database;
    final result = await db.query('diseases', columns: ['tags']);
    final Set<String> tagSet = {};

    for (var row in result) {
      final tagString = row['tags'] as String? ?? '';
      final tags = tagString
          .split(';')
          .map((t) => _normalizeTag(t.trim()))
          .where((t) => t.isNotEmpty);
      tagSet.addAll(tags);
    }

    final tagList =
        tagSet.toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return tagList;
  }

  static Future<void> clearDiseases() async {
    final db = await DBHelper.database;
    await db.delete('diseases');
  }
}
