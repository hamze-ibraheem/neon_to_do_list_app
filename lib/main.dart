import 'package:neon_framework/neon.dart';
import 'app.dart';

void main() {
  NeonApp.run(
    const TodoApp(),
    config: const NeonConfig(
      environment: NeonEnvironment.development,
    ),
  );
}
