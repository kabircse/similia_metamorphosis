import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/task.dart';
import '../db/task_db.dart';
import 'task_editor.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Task> _tasks = [];
  String _searchQuery = '';
  List<String> _filterTags = [];

  void _loadTasks() async {
    final tasks = await TaskDB.getTasks(
      search: _searchQuery,
      filterTags: _filterTags,
    );
    setState(() => _tasks = tasks);
  }

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

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
        await TaskDB.insertTask(Task.fromMap(item));
      }
      _loadTasks();
    }
  }

  void _exportTasks() async {
    final tasks = await TaskDB.getTasks();
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

  // Show modal with task details
  void _showTaskDetailsModal(Task task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              if (task.description.isNotEmpty) ...[
                Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(task.description),
                SizedBox(height: 8),
              ],
              if (task.note.isNotEmpty) ...[
                Text('Note:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(task.note),
                SizedBox(height: 8),
              ],
              if (task.tags.isNotEmpty) ...[
                Center(
                  child: Column(
                    children: [
                      Text('Tags:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Wrap(
                        spacing: 6,
                        alignment: WrapAlignment.center,
                        children: task.tags.map((tag) => Chip(label: Text(tag))).toList(),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => TaskEditor(task: task)),
                    );
                  },
                  child: Text('Edit Task', style: TextStyle(fontSize: 14)),
                ),
              ),
            ],
          ),
        );
      },
    );
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
            children: _tasks
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
                    _showTaskDetailsModal(task);
                  },
                  trailing: IconButton(
                    icon: Icon(Icons.edit, size: 20),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TaskEditor(task: task),
                        ),
                      );
                      _loadTasks();
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
