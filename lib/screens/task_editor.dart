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
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _tagsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descController.text = widget.task!.description;
      _tagsController.text = widget.task!.tags.join(',');
    }
  }

  void _saveTask() async {
    final task = Task(
      id: widget.task?.id,
      title: _titleController.text,
      description: _descController.text,
      tags: _tagsController.text.split(',').map((e) => e.trim()).toList(),
    );
    await DBHelper().insertTask(task);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'New Task' : 'Edit Task'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _descController,
              decoration: InputDecoration(labelText: 'Description'),
            ),
            TextField(
              controller: _tagsController,
              decoration: InputDecoration(labelText: 'Tags (comma separated)'),
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _saveTask, child: Text('Save')),
          ],
        ),
      ),
    );
  }
}
