import 'package:test/test.dart';
import 'package:neon_to_do_list_app/app.dart';
import 'package:neon_to_do_list_app/state/todo_store.dart';
import 'package:neon_to_do_list_app/models/todo_item.dart';

void main() {
  group('Todo App Navigation & Multi-Screen Tests', () {
    setUp(() async {
      TodoStore.instance.resetSampleData();
      await todoRouter.initialize();
    });

    test('router boots at /tasks as initial location', () {
      expect(todoRouter.rootNavigator.currentEntry?.state.location, equals('/tasks'));
      expect(todoRouter.rootNavigator.canPop, isFalse);
    });

    test('can push and navigate to /new-task', () async {
      final entry = await todoRouter.push('/new-task');
      expect(entry, isNotNull);
      expect(todoRouter.rootNavigator.currentEntry?.state.location, equals('/new-task'));
      expect(todoRouter.rootNavigator.canPop, isTrue);

      // Pop back to tasks
      final popped = await todoRouter.pop();
      expect(popped, isTrue);
      expect(todoRouter.rootNavigator.currentEntry?.state.location, equals('/tasks'));
    });

    test('can navigate to /tasks/:id and read parameters', () async {
      final entry = await todoRouter.push('/tasks/task_1');
      expect(entry, isNotNull);
      expect(todoRouter.rootNavigator.currentEntry?.state.location, equals('/tasks/task_1'));
      expect(entry!.state.param('id'), equals('task_1'));

      await todoRouter.pop();
      expect(todoRouter.rootNavigator.currentEntry?.state.location, equals('/tasks'));
    });

    test('can navigate between tabs (/analytics and /settings)', () async {
      await todoRouter.replace('/analytics');
      expect(todoRouter.rootNavigator.currentEntry?.state.location, equals('/analytics'));

      await todoRouter.replace('/settings');
      expect(todoRouter.rootNavigator.currentEntry?.state.location, equals('/settings'));

      await todoRouter.replace('/tasks');
      expect(todoRouter.rootNavigator.currentEntry?.state.location, equals('/tasks'));
    });

    test('TodoStore reactive updates work across screens', () {
      final initialCount = TodoStore.instance.tasks.value.length;
      final newTask = TodoItem(
        id: 'test_task_99',
        title: 'New Navigation Integration Task',
        priority: TodoPriority.high,
        category: 'Work',
        createdAt: DateTime.now(),
      );

      TodoStore.instance.addTask(newTask);
      expect(TodoStore.instance.tasks.value.length, equals(initialCount + 1));
      expect(TodoStore.instance.getTaskById('test_task_99'), isNotNull);

      TodoStore.instance.toggleTask('test_task_99');
      expect(TodoStore.instance.getTaskById('test_task_99')?.isCompleted, isTrue);

      TodoStore.instance.deleteTask('test_task_99');
      expect(TodoStore.instance.getTaskById('test_task_99'), isNull);
    });

    test('exports snapshot containing active route and history', () {
      final snapshot = todoRouter.exportSnapshot();
      expect(snapshot['restorationVersion'], equals(1));
      expect(snapshot['rootNavigator'], isNotNull);
      expect(snapshot['rootNavigator']['history'], isNotEmpty);
    });
  });
}
