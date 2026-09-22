import 'package:neon_framework/neon.dart';
import 'app.dart';

void main() async {
  // Initialize the router with the initial route
  await todoRouter.initialize();

  NeonApp.run(
    const TodoApp(),
    config: const NeonConfig(
      environment: NeonEnvironment.development,
      enableDiffing: true, // Enables RFC-6902 incremental JSON widget tree diffing
      port: 8080,
    ),
  );
}
