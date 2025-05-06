import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/task.dart';
import '../helpers/db_helper.dart';
import 'task_editor.dart'; // Make sure this is imported

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Task> _tasks = [];
  String _searchQuery = '';
  List<String> _filterTags = [];

void _loadTasks() async {
    final tasks = await DBHelper().getTasks(
      search: _searchQuery, // This is likely where the error occurs
      filterTags: _filterTags,
    );
    setState(() => _tasks = tasks);
  }

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  // _importTasks method
  void _importTasks() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result != null) {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      List data = json.decode(content);
      for (var item in data) {
        await DBHelper().insertTask(Task.fromMap(item));
      }
      _loadTasks();
    }
  }

  // _exportTasks method - Ensure this is present in your code
  void _exportTasks() async {
    final tasks = await DBHelper().getTasks();
    final content = json.encode(tasks.map((t) => t.toMap()).toList());

    String path;
    if (Platform.isAndroid) {
      path = '/sdcard/Download/tasks_export.json';
    } else if (Platform.isWindows) {
      path = '${Directory.current.path}\\tasks_export.json';
    } else {
      final directory = await getApplicationDocumentsDirectory();
      path = '${directory.path}/tasks_export.json';
    }

    final file = File(path);
    await file.writeAsString(content);
    Share.shareFiles([path], text: 'Exported Tasks');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Disease Progression'),
        actions: [
          IconButton(icon: Icon(Icons.upload), onPressed: _exportTasks),
          IconButton(icon: Icon(Icons.download), onPressed: _importTasks),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(labelText: 'Search by title or tag'),
              onChanged: (value) {
                _searchQuery = value;
                _loadTasks();
              },
            ),
          ),
          Wrap(
            children:
                _tasks
                    .expand((t) => t.tags)
                    .toSet()
                    .map(
                      (tag) => FilterChip(
                        label: Text(tag),
                        selected: _filterTags.contains(tag),
                        onSelected: (bool selected) {
                          setState(() {
                            if (selected) {
                              _filterTags.add(tag);
                            } else {
                              _filterTags.remove(tag);
                            }
                            _loadTasks();
                          });
                        },
                      ),
                    )
                    .toList(),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                final task = _tasks[index];
                return ListTile(
                  title: Text(task.title),
                  subtitle: Text(task.note),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => TaskEditor(task: task)),
                    );
                    _loadTasks();
                  },
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: Text('Confirm Delete'),
                              content: Text(
                                'Are you sure you want to delete this task?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.pop(context, false),
                                  child: Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text('Delete'),
                                ),
                              ],
                            ),
                      );

                      if (confirm == true) {
                        await DBHelper().deleteTask(task.id!);
                        _loadTasks();
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TaskEditor()),
          );
          _loadTasks();
        },
      ),
    );
  }
}
