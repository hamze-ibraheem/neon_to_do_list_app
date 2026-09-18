import 'package:neon_framework/neon.dart';
import 'screens/todo_screen.dart';

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  NeonWidget build(NeonBuildContext context) {
    return const TodoScreen();
  }
}
