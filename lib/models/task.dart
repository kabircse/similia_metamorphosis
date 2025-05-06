class Task {
  final int? id;
  final String title;
  final String description;
  final String note;
  final List<String> tags;

  Task({
    this.id,
    required this.title,
    required this.description,
    required this.note,
    required this.tags,
  });

  // Convert Task to Map (for database storage)
  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'note': note, // Add the name field here
    'tags': tags.join(';'), // Store tags as a semicolon-separated string
  };

  // Convert Map to Task (for retrieval from database)
  factory Task.fromMap(Map<String, dynamic> map) => Task(
    id: map['id'],
    title: map['title'],
    description: map['description'],
    note: map['note'], // Retrieve name from the map
    tags: map['tags'].toString().split(';'), // Split tags back to List<String>
  );
}
