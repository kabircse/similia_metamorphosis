import 'package:flutter/material.dart';
import '../helpers/db_helper.dart';
import '../models/task.dart';

class TaskEditor extends StatefulWidget {
  final Task? task;
  TaskEditor({this.task});

  @override
  _TaskEditorState createState() => _TaskEditorState();
}

class _TaskEditorState extends State<TaskEditor> {
  final _noteController = TextEditingController();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _tagsController = TextEditingController();
  final Set<String> _selectedTags = {};

  List<String> _allTags = [];

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descController.text = widget.task!.description;
      _noteController.text = widget.task!.note;
      _selectedTags.addAll(widget.task!.tags);
      _tagsController.text = widget.task!.tags.join(',');
    }
    _loadAllTags();
  }

  void _loadAllTags() async {
    final tasks = await DBHelper().getTasks();
    final allTags = tasks.expand((t) => t.tags).toSet().toList();
    setState(() => _allTags = allTags);
  }

  void _saveTask() async {
    if (_tagsController.text.isEmpty || _titleController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Title and Tags are required')));
      return;
    }

    final manualTags =
        _tagsController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
    final task = Task(
      id: widget.task?.id,
      title: _titleController.text,
      description: _descController.text,
      note: _noteController.text,
      tags: [..._selectedTags, ...manualTags].toSet().toList(),
    );
    await DBHelper().insertTask(task);
    Navigator.pop(context);
  }

  void _cancelTask() {
    Navigator.pop(context);
  }

  void _showTagSelectorDialog() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('Select Tags'),
            content: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    _allTags.map((tag) {
                      final isSelected = _selectedTags.contains(tag);
                      return FilterChip(
                        label: Text(tag),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedTags.add(tag);
                            } else {
                              _selectedTags.remove(tag);
                            }
                          });
                        },
                      );
                    }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Done'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'New Task' : 'Edit Task'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Title *'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _descController,
                decoration: InputDecoration(labelText: 'Description'),
                maxLines: 4,
              ),
              SizedBox(height: 10),
              TextField(
                controller: _noteController,
                decoration: InputDecoration(labelText: 'Note'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _tagsController,
                decoration: InputDecoration(
                  labelText: 'New tags (comma separated)',
                ),
              ),
              SizedBox(height: 10),
              if (_allTags.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select existing tags:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        icon: Icon(Icons.label_outline),
                        label: Text('Choose Tags'),
                        onPressed: _showTagSelectorDialog,
                      ),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 8,
                  children:
                      _selectedTags
                          .map(
                            (tag) => Chip(
                              label: Text(tag),
                              backgroundColor: Colors.blue.shade50,
                            ),
                          )
                          .toList(),
                ),
              ],
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(onPressed: _saveTask, child: Text('Save')),
                  ElevatedButton(onPressed: _cancelTask, child: Text('Cancel')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

