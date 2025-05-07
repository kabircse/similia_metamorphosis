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
  List<String> _allTags = [];
  final TextEditingController _searchController = TextEditingController();

  void _loadTasks() async {
    final tasks = await TaskDB.getTasks(
      search: _searchQuery,
      filterTags: _filterTags,
    );
    final allTags = tasks.expand((t) => t.tags).toSet().toList();
    setState(() {
      _tasks = tasks;
      _allTags = allTags;
    });
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

  void _resetFilters() {
    setState(() {
      _searchQuery = '';
      _filterTags.clear();
      _searchController.clear();
    });
    _loadTasks();
  }

  void _showTaskDetailsModal(Task task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Center(
          child: Container(
            margin: const EdgeInsets.all(16.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).canvasColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: SingleChildScrollView(
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
                    Text(
                      'Description:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(task.description),
                    SizedBox(height: 8),
                  ],
                  if (task.note.isNotEmpty) ...[
                    Text(
                      'Note:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(task.note),
                    SizedBox(height: 8),
                  ],
                  if (task.tags.isNotEmpty) ...[
                    Center(
                      child: Column(
                        children: [
                          Text(
                            '',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Wrap(
                            spacing: 6,
                            alignment: WrapAlignment.center,
                            children:
                                task.tags
                                    .map((tag) => Chip(label: Text(tag)))
                                    .toList(),
                          ),
                        ],
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showTagSelectionModal() async {
    List<String> selectedTags = List.from(_filterTags);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Select Tags'),
              content: SingleChildScrollView(
                child: Column(
                  children:
                      _allTags.map((tag) {
                        return CheckboxListTile(
                          title: Text(tag),
                          value: selectedTags.contains(tag),
                          onChanged: (bool? selected) {
                            setStateDialog(() {
                              if (selected != null) {
                                if (selected) {
                                  selectedTags.add(tag);
                                } else {
                                  selectedTags.remove(tag);
                                }
                              }
                            });
                          },
                        );
                      }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _filterTags = selectedTags;
                    });
                    _loadTasks();
                    Navigator.pop(context);
                  },
                  child: Text('Apply'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Cancel'),
                ),
              ],
            );
          },
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
              controller: _searchController,
              decoration: InputDecoration(labelText: 'Search by title or tag'),
              onChanged: (value) {
                _searchQuery = value;
                _loadTasks();
              },
            ),
          ),
          if (_allTags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      icon: Icon(Icons.filter_list),
                      label: Text("Filter Tags"),
                      onPressed: _showTagSelectionModal,
                    ),
                  ),
                  TextButton(onPressed: _resetFilters, child: Text("Reset")),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                final task = _tasks[index];
                return ListTile(
                  title: Text(task.title),
                  subtitle: Text(task.note),
                  onTap: () => _showTaskDetailsModal(task),
                  trailing: IconButton(
                    icon: Icon(Icons.edit_rounded, size: 12),
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
