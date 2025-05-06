import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/task.dart';
import '../db/task_db.dart';

Future<void> exportTasks() async {
  final tasks = await TaskDB().getAllTasks();
  final jsonTasks = jsonEncode(tasks.map((e) => e.toMap()).toList());

  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/tasks_export.json');
  await file.writeAsString(jsonTasks);

  Share.shareFiles([file.path], text: 'Exported Tasks');
}

Future<void> importTasks() async {
  final result = await FilePicker.platform.pickFiles();
  if (result != null) {
    final file = File(result.files.single.path!);
    final jsonStr = await file.readAsString();
    final List<dynamic> decoded = jsonDecode(jsonStr);

    await TaskDB().deleteAllTasks();
    for (var item in decoded) {
      await TaskDB().insertTask(Task.fromMap(item));
    }
  }
}
