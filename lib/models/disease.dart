class Disease {
  final int? id;
  final String title;
  final String description;
  final String note;
  final List<String> tags;

  Disease({
    this.id,
    required this.title,
    required this.description,
    required this.note,
    required this.tags,
  });

  // Convert Disease to Map (for database storage)
  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'note': note,
    'tags': tags.join(';'), // Convert list to semicolon-separated string
  };

  // Convert Map to Disease (for retrieval from database)
  factory Disease.fromMap(Map<String, dynamic> map) {
    List<String> parsedTags;

    if (map['tags'] is String) {
      // Semicolon-separated string from DB
      parsedTags =
          (map['tags'] as String).split(';').map((e) => e.trim()).toList();
    } else if (map['tags'] is List) {
      // JSON array during import
      parsedTags = List<String>.from(
        (map['tags'] as List).map((e) => e.toString()),
      );
    } else {
      parsedTags = [];
    }

    return Disease(
      id: map['id'],
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      note: map['note'] ?? '',
      tags: parsedTags,
    );
  }
}
