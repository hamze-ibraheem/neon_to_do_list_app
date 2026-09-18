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
  final bool isCompleted;
  final TodoPriority priority;
  final String category;
  final DateTime createdAt;

  const TodoItem({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.priority = TodoPriority.medium,
    this.category = 'General',
    required this.createdAt,
  });

  TodoItem copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    TodoPriority? priority,
    String? category,
    DateTime? createdAt,
  }) {
    return TodoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
