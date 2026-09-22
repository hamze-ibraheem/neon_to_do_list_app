import 'package:neon_framework/neon.dart';
import 'screens/todo_screen.dart';
import 'screens/task_detail_screen.dart';
import 'screens/new_task_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/settings_screen.dart';

/// Global router for the Todo application.
final NeonRouter todoRouter = NeonRouter(
  routes: [
    NeonRoute(
      path: '/',
      name: 'root',
      builder: (ctx, state) => const TodoScreen(),
    ),
    NeonRoute(
      path: '/tasks',
      name: 'tasks_list',
      builder: (ctx, state) => const TodoScreen(),
    ),
    NeonRoute(
      path: '/tasks/:id',
      name: 'task_detail',
      builder: (ctx, state) {
        final taskId = state.param('id') ?? '';
        return TaskDetailScreen(taskId: taskId);
      },
    ),
    NeonRoute(
      path: '/new-task',
      name: 'new_task',
      builder: (ctx, state) => const NewTaskScreen(),
    ),
    NeonRoute(
      path: '/analytics',
      name: 'analytics',
      builder: (ctx, state) => const AnalyticsScreen(),
    ),
    NeonRoute(
      path: '/settings',
      name: 'settings',
      builder: (ctx, state) => const SettingsScreen(),
    ),
  ],
  initialLocation: '/tasks',
);

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  NeonWidget build(NeonBuildContext context) {
    return NeonNavigator(
      controller: todoRouter.rootNavigator,
      transition: 'slideHorizontal',
    );
  }
}
