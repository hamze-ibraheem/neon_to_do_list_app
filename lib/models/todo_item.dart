enum TodoPriority {
  low,
  medium,
  high;

  String get label {
    switch (this) {
      case TodoPriority.low:
        return 'Low';
      case TodoPriority.medium:
        return 'Medium';
      case TodoPriority.high:
        return 'High';
    }
  }

  String get badgeText {
    switch (this) {
      case TodoPriority.low:
        return '🟢 Low';
      case TodoPriority.medium:
        return '🟡 Med';
      case TodoPriority.high:
        return '🔴 High';
    }
  }
}

class TodoItem {
  final String id;
  final String title;
  final String description;
  final bool isCompleted;
  final TodoPriority priority;
  final String category;
  final DateTime createdAt;

  const TodoItem({
    required this.id,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    this.priority = TodoPriority.medium,
    this.category = 'Work',
    required this.createdAt,
  });

  TodoItem copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    TodoPriority? priority,
    String? category,
    DateTime? createdAt,
  }) {
    return TodoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'isCompleted': isCompleted,
        'priority': priority.name,
        'category': category,
        'createdAt': createdAt.toIso8601String(),
      };

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      isCompleted: json['isCompleted'] as bool? ?? false,
      priority: TodoPriority.values.firstWhere(
        (p) => p.name == json['priority'],
        orElse: () => TodoPriority.medium,
      ),
      category: json['category'] as String? ?? 'Work',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
