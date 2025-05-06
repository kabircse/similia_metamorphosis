import 'package:flutter/material.dart';
import '../db/task_db.dart';
import '../models/task.dart';

class TaskEditor extends StatefulWidget {
  final Task? task;
  TaskEditor({this.task});

  @override
  _TaskEditorState createState() => _TaskEditorState();
}

class _TaskEditorState extends State<TaskEditor> {
  final _formKey = GlobalKey<FormState>();
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
    final tasks = await TaskDB.getTasks();
    final allTags = tasks.expand((t) => t.tags).toSet().toList();
    setState(() => _allTags = allTags);
  }

  void _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    final manualTags =
        _tagsController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
    final task = Task(
      id: widget.task?.id,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      note: _noteController.text.trim(),
      tags: [..._selectedTags, ...manualTags].toSet().toList(),
    );
    await TaskDB.insertTask(task);
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
        title: Text(
          widget.task == null
              ? 'New Disease Progression'
              : 'Edit Disease Progression',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: 'Title *'),
                  validator:
                      (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Title is required'
                              : null,
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
                TextFormField(
                  controller: _tagsController,
                  decoration: InputDecoration(
                    labelText: 'New tags (comma separated)',
                    suffixIcon: IconButton(
                      icon: Icon(Icons.label_outline),
                      onPressed: _showTagSelectorDialog,
                    ),
                  ),
                  validator:
                      (value) =>
                          (_selectedTags.isEmpty &&
                                  (value == null || value.trim().isEmpty))
                              ? 'At least one tag is required'
                              : null,
                ),
                SizedBox(height: 10),
                if (_allTags.isNotEmpty) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Selected Tags:',
                      style: TextStyle(fontWeight: FontWeight.bold),
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
                                onDeleted:
                                    () => setState(
                                      () => _selectedTags.remove(tag),
                                    ),
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
                    OutlinedButton(
                      onPressed: _cancelTask,
                      child: Text('Cancel'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
