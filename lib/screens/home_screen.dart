import 'package:flutter/material.dart';
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
  int _limit = 20;
  bool _isLoading = false;
  bool _hasMore = true;
  String _filterTag = '';

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
        _hasMore) {
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
                'Title: ${task.title}',
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
                Text('Note:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(task.note),
                SizedBox(height: 8),
              ],
              if (task.tags.isNotEmpty) ...[
                Text('Tags:', style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 6,
                  children:
                      task.tags.map((tag) => Chip(label: Text(tag))).toList(),
                ),
              ],
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TaskEditor(task: task)),
                  ).then((_) => _resetAndSearch());
                },
                child: Text('Edit Task'),
              ),
            ],
          ),
        );
      },
    );
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
      appBar: AppBar(title: Text('Task List')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search',
                suffixIcon: Icon(Icons.search),
              ),
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
                  title: Text(task.title),
                  subtitle: Text(task.description),
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
}
