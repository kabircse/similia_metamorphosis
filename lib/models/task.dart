class Task {
  final int? id;
  final String title;
  final String description;
  final List<String> tags;

  Task({
    this.id,
    required this.title,
    required this.description,
    required this.tags,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'tags': tags.join(','),
  };

  factory Task.fromMap(Map<String, dynamic> map) => Task(
    id: map['id'],
    title: map['title'],
    description: map['description'],
    tags: map['tags'].toString().split(','),
  );
}
