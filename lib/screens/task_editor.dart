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
      _tagsController.text = '';
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

    final updatedTags = {..._selectedTags, ...manualTags}.toList();

    final task = Task(
      id: widget.task?.id,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      note: _noteController.text.trim(),
      tags: updatedTags,
    );

    if (widget.task != null && widget.task!.id != null) {
      await TaskDB.updateTask(task);
    } else {
      await TaskDB.insertTask(task);
    }

    Navigator.pop(context);
  }

  void _deleteTask() async {
    if (widget.task != null && widget.task!.id != null) {
      await TaskDB.deleteTask(widget.task!.id!);
      Navigator.pop(context);
    }
  }

  void _cancelTask() {
    Navigator.pop(context);
  }

void _showTagSelectionModal() async {
    final sortedTags = List<String>.from(_allTags)
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final ScrollController _scrollController = ScrollController();
    final Set<String> tempSelectedTags = Set.from(_selectedTags);

    await showDialog(
      context: context,
      builder:
          (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              padding: EdgeInsets.all(16),
              constraints: BoxConstraints(maxHeight: 400, maxWidth: 360),
              child: StatefulBuilder(
                builder: (context, setModalState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Select Tags',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      Expanded(
                        child: Scrollbar(
                          controller: _scrollController,
                          thumbVisibility: true,
                          child: ListView.builder(
                            controller: _scrollController,
                            itemCount: sortedTags.length,
                            itemBuilder: (context, index) {
                              final tag = sortedTags[index];
                              final isChecked = tempSelectedTags.contains(tag);
                              return CheckboxListTile(
                                title: Text(tag),
                                value: isChecked,
                                onChanged: (checked) {
                                  setModalState(() {
                                    if (checked == true) {
                                      tempSelectedTags.add(tag);
                                    } else {
                                      tempSelectedTags.remove(tag);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedTags
                                  ..clear()
                                  ..addAll(tempSelectedTags);
                              });
                              Navigator.pop(context);
                            },
                            child: Text('Done'),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
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
                      onPressed: _showTagSelectionModal,
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
                if (_selectedTags.isNotEmpty) ...[
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
                    if (widget.task != null)
                      ElevatedButton(
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
                                      onPressed:
                                          () => Navigator.pop(context, true),
                                      child: Text('Delete'),
                                    ),
                                  ],
                                ),
                          );
                          if (confirm == true) {
                            _deleteTask();
                          }
                        },
                        child: Text('Delete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                      ),
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
