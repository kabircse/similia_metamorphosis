import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../db/disease_db.dart';
import '../models/disease.dart';
import 'disease_editor.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<Disease> _diseases = [];
  String _searchQuery = '';
  int _limit = 10;
  bool _isLoading = false;
  bool _hasMore = true;
  String _filterTag = '';
  Map<String, bool> _selectedTags = {};

  @override
  void initState() {
    super.initState();
    _loadDiseases();
    _scrollController.addListener(_scrollListener);
    _searchController.addListener(_resetAndSearch);
  }

  void _resetAndSearch() {
    setState(() {
      _diseases.clear();
      _hasMore = true;
      _searchQuery = _searchController.text.trim();
    });
    _loadDiseases();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !_isLoading &&
        _hasMore) {
      _loadDiseases();
    }
  }

  Future<void> _loadDiseases() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    final newDiseases = await DiseaseDB.getFilteredDiseases(
      search: _searchQuery,
      tag: _filterTag,
      offset: _diseases.length,
      limit: _limit,
    );

    setState(() {
      _diseases.addAll(newDiseases);
      _hasMore = newDiseases.length == _limit;
      _isLoading = false;
    });
  }

void _showDiseaseDetailsModal(Disease disease) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            contentPadding: const EdgeInsets.all(16.0),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          disease.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          softWrap: true,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.edit_rounded, size: 18),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DiseaseEditor(disease: disease),
                            ),
                          ).then((_) => _resetAndSearch());
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  if (disease.description.isNotEmpty) ...[
                    Text(
                      'Description:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(disease.description),
                    SizedBox(height: 8),
                  ],
                  if (disease.note.isNotEmpty) ...[
                    Text(
                      disease.note,
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF28a745),
                      ),
                    ),
                    SizedBox(height: 8),
                  ],
                  if (disease.tags.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children:
                          disease.tags
                              .map((tag) => Chip(label: Text(tag)))
                              .toList(),
                    ),
                ],
              ),
            ),
          ),
    );
  }


Future<void> _exportDiseases() async {  
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final diseases = await DiseaseDB.getFilteredDiseases(
        offset: 0,
        limit: 1000000,
      );
      final jsonString = jsonEncode(diseases.map((t) => t.toMap()).toList());

      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Export JSON file',
        fileName: 'diseases.json',
      );

      if (result != null) {
        final file = File(result);
        await file.writeAsString(jsonString);
        Navigator.of(context).pop(); // Close loading spinner
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Exported successfully')));
      } else {
        Navigator.of(context).pop(); // Close loading spinner
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading spinner
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed')));
    }
  }

Future<void> _importDiseases() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();

      try {
        final List<dynamic> data = jsonDecode(content);
        int importedCount = 0;

        for (var item in data) {
          if (item is Map<String, dynamic>) {
            item.remove('id');
            await DiseaseDB.insertDisease(Disease.fromMap(item));
            importedCount++;
          }
        }

        if (mounted) {
          _resetAndSearch(); // Refresh UI
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Imported $importedCount diseases successfully'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Invalid JSON file')));
        }
      }
    }
  }


  void _resetFilters() {
    _searchController.clear();

    setState(() {
      _selectedTags.clear();
      _filterTag = '';
      _diseases.clear();
      _hasMore = true;
      _searchQuery = '';
    });

    _loadDiseases();
  }

  void _showTagSelectionModal() async {
    final allTags = await DiseaseDB.getAllTags();
    const int pageSize = 30;

    List<String> filteredTags = [];
    List<String> visibleTags = [];
    String searchQuery = '';
    int page = 0;

    void updateVisibleTags(StateSetter setModalState) {
      final matched =
          searchQuery.isEmpty
              ? allTags
              : allTags
                  .where(
                    (tag) =>
                        tag.toLowerCase().contains(searchQuery.toLowerCase()),
                  )
                  .toList();
      filteredTags = matched;
      visibleTags = filteredTags.take((page + 1) * pageSize).toList();
      setModalState(() {}); // Safe here
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            updateVisibleTags(setModalState);

            return AlertDialog(
              title: Text(
                "Select Tags to Filter",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Container(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Search tags',
                        suffixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        searchQuery = value;
                        page = 0;
                        // Defer update to avoid build phase update error
                        Future.microtask(
                          () => updateVisibleTags(setModalState),
                        );
                      },
                    ),
                    SizedBox(height: 10),
                    Expanded(
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (scrollInfo) {
                          if (scrollInfo.metrics.pixels ==
                                  scrollInfo.metrics.maxScrollExtent &&
                              visibleTags.length < filteredTags.length) {
                            page++;
                            Future.microtask(
                              () => updateVisibleTags(setModalState),
                            );
                          }
                          return false;
                        },
                        child: ListView.builder(
                          itemCount: visibleTags.length,
                          itemBuilder: (context, index) {
                            final tag = visibleTags[index];
                            return CheckboxListTile(
                              title: Text(tag),
                              value: _selectedTags[tag] ?? false,
                              onChanged: (value) {
                                setModalState(() {
                                  _selectedTags[tag] = value ?? false;
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    final selected =
                        _selectedTags.entries
                            .where((e) => e.value)
                            .map((e) => e.key)
                            .toList();
                    setState(() {
                      _filterTag = selected.join(',');
                      _diseases.clear();
                      _hasMore = true;
                    });
                    _loadDiseases();
                    Navigator.of(context).pop();
                  },
                  child: Text("Apply"),
                ),
              ],
            );
          },
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
      appBar: AppBar(
        title: Text('Disease Progressions'),
        actions: [
          IconButton(icon: Icon(Icons.upload_file), onPressed: _exportDiseases),
          IconButton(icon: Icon(Icons.download), onPressed: _importDiseases),
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
                        'Are you sure you want to clear all diseases? This action cannot be undone.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(
                            'Clear All',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('Cancel'),
                        ),
                      ],
                    ),
              );

              if (confirm == true) {
                await DiseaseDB.clearDiseases();
                setState(() => _selectedTags.clear());
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('All diseases cleared'),
                    backgroundColor: Colors.green,
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
              itemCount: _diseases.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _diseases.length) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                final disease = _diseases[index];
                return ListTile(
                  title: Text(
                    disease.title,
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    disease.note,
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF28a745),
                    ),
                  ),
                  onTap: () => _showDiseaseDetailsModal(disease),
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
            MaterialPageRoute(builder: (_) => DiseaseEditor()),
          );
          _resetAndSearch();
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
