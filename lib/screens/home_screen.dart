import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
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
      type: FileType.any,
      withData: true
    );

    if (result != null) {
      final file = result.files.single;
      final fileName = file.name.toLowerCase();

      if (fileName.endsWith('.json')) {
        try {
          final content =
              file.bytes != null
                  ? utf8.decode(file.bytes!)
                  : await File(file.path!).readAsString();

          final List data = json.decode(content);
          for (var item in data) {
            await TaskDB.insertTask(Task.fromMap(item));
          }

          _loadTasks();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tasks imported successfully!')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error importing: ${e.toString()}')),
          );
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Please select a .json file')));
      }
    }
  }

void _exportTasks() async {
    // Request storage permission
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Storage permission is required to export.')),
      );
      return;
    }

    final tasks = await TaskDB.getTasks();
    final content = json.encode(tasks.map((t) => t.toMap()).toList());

    String path;
    if (Platform.isAndroid) {
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export directory not found.')));
        return;
      }

      // Optional: create directory if not exists
      final exportDir = Directory('${directory.path}/MyTasks');
      if (!(await exportDir.exists())) {
        await exportDir.create(recursive: true);
      }

      path = '${exportDir.path}/tasks_export.json';
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
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            task.title,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (task.description.isNotEmpty) ...[
                  Text(
                    'Description:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(task.description),
                  SizedBox(height: 8),
                ],
                if (task.note.isNotEmpty) ...[
                  Text('Note:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(task.note),
                  SizedBox(height: 8),
                ],
                if (task.tags.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    children:
                        task.tags.map((tag) => Chip(label: Text(tag))).toList(),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
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
