import 'package:flutter/material.dart';
import '../db/disease_db.dart';
import '../models/disease.dart';

class DiseaseEditor extends StatefulWidget {
  final Disease? disease;
  DiseaseEditor({this.disease});

  @override
  _DiseaseEditorState createState() => _DiseaseEditorState();
}

class _DiseaseEditorState extends State<DiseaseEditor> {
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
    if (widget.disease != null) {
      _titleController.text = widget.disease!.title;
      _descController.text = widget.disease!.description;
      _noteController.text = widget.disease!.note;
      _selectedTags.addAll(widget.disease!.tags);
      _tagsController.text = '';
    }
    _loadAllTags();
  }

  void _loadAllTags() async {
    final diseases = await DiseaseDB.getDiseases();
    final allTags = diseases.expand((t) => t.tags).toSet().toList();
    setState(() {
      _allTags = allTags;
    });
  }

  void _saveDisease() async {
    if (!_formKey.currentState!.validate()) return;

    final manualTags =
        _tagsController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

    final updatedTags = {..._selectedTags, ...manualTags}.toList();

    final disease = Disease(
      id: widget.disease?.id,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      note: _noteController.text.trim(),
      tags: updatedTags,
    );

    if (widget.disease != null && widget.disease!.id != null) {
      await DiseaseDB.updateDisease(disease);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Disease updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      await DiseaseDB.insertDisease(disease);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Disease added successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _deleteDisease() async {
    if (widget.disease != null && widget.disease!.id != null) {
      await DiseaseDB.deleteDisease(widget.disease!.id!);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Disease deleted'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _cancelDisease() {
    Navigator.pop(context);
  }

  void _showTagSelectionModal() async {
    final sortedTags = List<String>.from(_allTags)
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final ScrollController _scrollController = ScrollController();
    final TextEditingController _searchController = TextEditingController();
    final Set<String> tempSelectedTags = Set.from(_selectedTags);

    await showDialog(
      context: context,
      builder:
          (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: StatefulBuilder(
              builder: (context, setModalState) {
                List<String> _filteredTags =
                    sortedTags
                        .where(
                          (tag) => tag.toLowerCase().contains(
                            _searchController.text.toLowerCase(),
                          ),
                        )
                        .toList();

                return Container(
                  padding: EdgeInsets.all(16),
                  constraints: BoxConstraints(maxHeight: 500, maxWidth: 360),
                  child: Column(
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
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search tags...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (query) {
                          setModalState(() {});
                        },
                      ),
                      SizedBox(height: 12),
                      Expanded(
                        child: Scrollbar(
                          controller: _scrollController,
                          thumbVisibility: true,
                          child: ListView.builder(
                            controller: _scrollController,
                            itemCount: _filteredTags.length,
                            itemBuilder: (context, index) {
                              final tag = _filteredTags[index];
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
                  ),
                );
              },
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.disease == null
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
                    OutlinedButton(
                      onPressed: _cancelDisease,
                      child: Text('Cancel'),
                    ),
                    if (widget.disease != null)
                      ElevatedButton(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: Text('Confirm Delete'),
                                  content: Text(
                                    'Are you sure you want to delete this disease?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(context, true),
                                      child: Text('Delete'),
                                    ),
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(context, false),
                                      child: Text('Cancel'),
                                    ),
                                  ],
                                ),
                          );
                          if (confirm == true) {
                            _deleteDisease();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: Text('Delete'),
                      ),
                    ElevatedButton(
                      onPressed: _saveDisease,
                      child: Text('Save'),
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
