
class Todo {
  final int? id;
  final String title;
  final String description;
  final DateTime? dueDate;
  final bool isCompleted;

  // 1 = niedrig, 2 = mittel, 3 = hoch
  final int priority;

  const Todo({
    this.id,
    required this.title,
    this.description = '',
    this.dueDate,
    this.isCompleted = false,
    this.priority = 2,
  });

  // Dart-Objekt in Datenbankwerte umwandeln
  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'due_date': dueDate?.toIso8601String(),
      'is_completed': isCompleted ? 1 : 0,
      'priority': priority,
    };
  }

  // Datenbankwerte in Dart-Objekt umwandeln
  factory Todo.fromMap(Map<String, Object?> map) {
    return Todo(
      id: map['id'] as int,
      title: map['title'] as String,
      description: (map['description'] as String?) ?? '',
      dueDate: map['due_date'] == null
          ? null
          : DateTime.parse(map['due_date'] as String),
      isCompleted: (map['is_completed'] as int) == 1,
      priority: (map['priority'] as int?) ?? 2,
    );
  }

  // Einzelne Eigenschaften eines Todos ändern,
  // ohne die übrigen Werte zu verlieren.
  Todo copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    bool? isCompleted,
    int? priority,
  }) {
    return Todo(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
    );
  }
}
