import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../db/task_db.dart';
import '../models/task.dart';
import 'task_editor.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<Task> _tasks = [];
  String _searchQuery = '';
  int _limit = 10;
  bool _isLoading = false;
  bool _hasMore = true;
  String _filterTag = '';
  Map<String, bool> _selectedTags = {};

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _scrollController.addListener(_scrollListener);
    _searchController.addListener(() {
      _resetAndSearch();
    });
  }

  void _resetAndSearch() {
    setState(() {
      _tasks.clear();
      _hasMore = true;
      _searchQuery = _searchController.text.trim();
    });
    _loadTasks();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !_isLoading &&
        _hasMore &&
        _scrollController.position.maxScrollExtent > 0) {
      _loadTasks();
    }
  }

  Future<void> _loadTasks() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    final newTasks = await TaskDB.getFilteredTasks(
      search: _searchQuery,
      tag: _filterTag,
      offset: _tasks.length,
      limit: _limit,
    );

    setState(() {
      _tasks.addAll(newTasks);
      _hasMore = newTasks.length == _limit;
      _isLoading = false;
    });
  }

  void _showTaskDetailsModal(Task task) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.all(16.0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  )
                ],
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
                Text(''),
                Text(
                  task.note,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF28a745),
                  ),
                ),
                SizedBox(height: 8),
              ],
              if (task.tags.isNotEmpty) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8, // space between tags
                        runSpacing: 4, // space between lines if tags wrap
                        children:
                            task.tags
                                .map((tag) => Chip(label: Text(tag)))
                                .toList(),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit_rounded, size: 18),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TaskEditor(task: task),
                          ),
                        ).then((_) => _resetAndSearch());
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _exportTasks() async {
    final tasks = await TaskDB.getFilteredTasks(offset: 0, limit: 1000000);
    final jsonString = jsonEncode(tasks.map((t) => t.toMap()).toList());

    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Export JSON file',
      fileName: 'tasks.json',
    );

    if (result != null) {
      final file = File(result);
      await file.writeAsString(jsonString);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Exported successfully')));
    }
  }

 Future<void> _importTasks() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();

      try {
        final List<dynamic> data = jsonDecode(content);
        for (var item in data) {
          if (item is Map<String, dynamic>) {
            item.remove('id'); // Ensure ID is removed
            await TaskDB.insertTask(Task.fromMap(item));
          }
        }
        _resetAndSearch();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Imported successfully')));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Invalid JSON file')));
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Disease Progressions'),
        actions: [
          IconButton(icon: Icon(Icons.upload_file), onPressed: _exportTasks),
          IconButton(icon: Icon(Icons.download), onPressed: _importTasks),
          IconButton(
            icon: Icon(Icons.delete_forever),
            tooltip: 'Clear All',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: Text('Confirm Deletion'),
                      content: Text(
                        'Are you sure you want to clear all tasks? This action cannot be undone.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(
                            'Clear All',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
              );

              if (confirm == true) {
                await TaskDB.clearTasks();
                setState(() {
                  _selectedTags.clear();
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('All tasks cleared'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search',
                    suffixIcon: Icon(Icons.search),
                  ),
                ),
                SizedBox(height: 8),
                Row(
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
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _tasks.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _tasks.length) {
                  return Center(child: CircularProgressIndicator());
                }
                final task = _tasks[index];
                return ListTile(
                  title: Text(
                    task.title,
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    task.note,
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF28a745),
                    ),
                  ),
                  onTap: () => _showTaskDetailsModal(task),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TaskEditor()),
          );
          _resetAndSearch();
        },
        child: Icon(Icons.add),
      ),
    );
  }

  void _showTagSelectionModal() async {
    final tags = await TaskDB.getAllTags();
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text(
                "Select Tags to Filter",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(                  
                  spacing: 8,
                  mainAxisSize: MainAxisSize.min,
                  children:
                      tags.map((tag) {
                        return CheckboxListTile(
                          title: Text(tag),
                          value: _selectedTags[tag] ?? false,
                          onChanged: (bool? value) {
                            setModalState(() {
                              _selectedTags[tag] = value ?? false;
                            });
                          },
                        );
                      }).toList(),
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    final selected =
                        _selectedTags.entries
                            .where((e) => e.value)
                            .map((e) => e.key)
                            .toList();

                    setState(() {
                      _filterTag = selected.join(',');
                      _tasks.clear();
                      _hasMore = true;
                    });
                    _loadTasks();
                    Navigator.of(context).pop();
                  },
                  child: Text("Apply"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("Cancel"),
                ),
              ],
            );
          },
        );
      },
    );


  }

  void _resetFilters() {
    _searchController
        .clear(); // This only clears the text visually. Internal value is updated immediately.

    setState(() {
      _selectedTags.clear();
      _filterTag = '';
      _tasks.clear();
      _hasMore = true;
      _searchQuery = ''; // Make sure internal search query is also cleared
    });

    _loadTasks();
  }


}
