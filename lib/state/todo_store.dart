import 'package:neon_framework/neon.dart';
import '../models/todo_item.dart';

/// Central reactive store for Todo items and global app state.
class TodoStore {
  static final TodoStore instance = TodoStore();

  final NeonSignal<List<TodoItem>> tasks = NeonSignal<List<TodoItem>>([
    TodoItem(
      id: 'task_1',
      title: 'Explore Neon Framework architecture',
      description: 'Review decoupled Dart backend and native JSON bridge pattern.',
      isCompleted: true,
      priority: TodoPriority.high,
      category: 'Work',
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    TodoItem(
      id: 'task_2',
      title: 'Implement Navigation & Routing engine',
      description: 'Add named routes, path matcher, and nested stacks.',
      isCompleted: true,
      priority: TodoPriority.high,
      category: 'Work',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    TodoItem(
      id: 'task_3',
      title: 'Test Android Predictive Back gestures',
      description: 'Ensure OnBackInvokedCallback smoothly interacts with canPop state.',
      isCompleted: false,
      priority: TodoPriority.medium,
      category: 'Study',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    TodoItem(
      id: 'task_4',
      title: 'Benchmark widget tree diffing performance',
      description: 'Compare full tree transmission vs RFC-6902 incremental patches.',
      isCompleted: false,
      priority: TodoPriority.medium,
      category: 'Study',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    TodoItem(
      id: 'task_5',
      title: 'Weekly grocery shopping',
      description: 'Apples, almond milk, sourdough bread, and green tea.',
      isCompleted: false,
      priority: TodoPriority.low,
      category: 'Personal',
      createdAt: DateTime.now(),
    ),
  ]);

  final NeonSignal<String> statusFilter = NeonSignal<String>('All');
  final NeonSignal<String> categoryFilter = NeonSignal<String>('All');
  final NeonSignal<String> searchQuery = NeonSignal<String>('');
  final NeonSignal<bool> diffingEnabled = NeonSignal<bool>(true);

  final List<String> availableCategories = [
    'All',
    'Work',
    'Personal',
    'Study',
    'Shopping',
    'Health',
  ];

  List<TodoItem> get filteredTasks {
    final all = tasks.value;
    final status = statusFilter.value;
    final category = categoryFilter.value;
    final query = searchQuery.value.trim().toLowerCase();

    return all.where((task) {
      if (status == 'Active' && task.isCompleted) return false;
      if (status == 'Completed' && !task.isCompleted) return false;
      if (category != 'All' && task.category != category) return false;
      if (query.isNotEmpty) {
        final matchesTitle = task.title.toLowerCase().contains(query);
        final matchesDesc = task.description.toLowerCase().contains(query);
        if (!matchesTitle && !matchesDesc) return false;
      }
      return true;
    }).toList();
  }

  TodoItem? getTaskById(String id) {
    try {
      return tasks.value.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  void addTask(TodoItem item) {
    tasks.value = [item, ...tasks.value];
  }

  void updateTask(TodoItem updated) {
    tasks.value = tasks.value.map((t) => t.id == updated.id ? updated : t).toList();
  }

  void toggleTask(String id) {
    tasks.value = tasks.value.map((t) {
      if (t.id == id) {
        return t.copyWith(isCompleted: !t.isCompleted);
      }
      return t;
    }).toList();
  }

  void deleteTask(String id) {
    tasks.value = tasks.value.where((t) => t.id != id).toList();
  }

  void clearCompleted() {
    tasks.value = tasks.value.where((t) => !t.isCompleted).toList();
  }

  void resetSampleData() {
    tasks.value = [
      TodoItem(
        id: 'task_1',
        title: 'Explore Neon Framework architecture',
        description: 'Review decoupled Dart backend and native JSON bridge pattern.',
        isCompleted: true,
        priority: TodoPriority.high,
        category: 'Work',
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
      TodoItem(
        id: 'task_2',
        title: 'Implement Navigation & Routing engine',
        description: 'Add named routes, path matcher, and nested stacks.',
        isCompleted: true,
        priority: TodoPriority.high,
        category: 'Work',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      TodoItem(
        id: 'task_3',
        title: 'Test Android Predictive Back gestures',
        description: 'Ensure OnBackInvokedCallback smoothly interacts with canPop state.',
        isCompleted: false,
        priority: TodoPriority.medium,
        category: 'Study',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ];
    statusFilter.value = 'All';
    categoryFilter.value = 'All';
    searchQuery.value = '';
  }
}
