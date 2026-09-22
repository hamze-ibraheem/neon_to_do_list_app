import 'package:neon_framework/neon.dart';
import '../models/todo_item.dart';
import '../state/todo_store.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  NeonState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends NeonState<AnalyticsScreen> {
  final TodoStore _store = TodoStore.instance;

  @override
  void initState() {
    super.initState();
    _store.tasks.listen(_onTasksChanged);
  }

  void _onTasksChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _store.tasks.removeListener(_onTasksChanged);
    super.dispose();
  }

  @override
  NeonWidget build(NeonBuildContext context) {
    final allTasks = _store.tasks.value;
    final total = allTasks.length;
    final completed = allTasks.where((t) => t.isCompleted).length;
    final pending = total - completed;
    final progress = total > 0 ? (completed / total) : 0.0;
    final percentage = (progress * 100).toInt();

    // Priority counts
    final highCount = allTasks.where((t) => t.priority == TodoPriority.high).length;
    final medCount = allTasks.where((t) => t.priority == TodoPriority.medium).length;
    final lowCount = allTasks.where((t) => t.priority == TodoPriority.low).length;

    return Column(
      children: [
        // Main Scrollable Area
        Expanded(
          child: SingleChildScrollView(
            child: Container(
              padding: const NeonEdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      const Text(
                        'Productivity Analytics',
                        style: NeonTextStyle(
                          fontSize: 24,
                          fontWeight: NeonFontWeight.bold,
                          color: NeonColor.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Badge(
                        backgroundColor: NeonColor.primary,
                        label: Text('$percentage% Done'),
                        child: const SizedBox(width: 0, height: 0),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Completion Progress Card
                  Card(
                    padding: const NeonEdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Overall Completion Rate',
                              style: NeonTextStyle(
                                fontSize: 16,
                                fontWeight: NeonFontWeight.bold,
                                color: NeonColor.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '$completed of $total Tasks',
                              style: const NeonTextStyle(
                                fontSize: 14,
                                color: NeonColor.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        LinearProgressIndicator(
                          value: progress,
                          minHeight: 12,
                          borderRadius: 6,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const NeonEdgeInsets.all(12),
                                color: const NeonColor(0x1510B981),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Completed',
                                      style: NeonTextStyle(
                                        fontSize: 12,
                                        color: NeonColor.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$completed',
                                      style: const NeonTextStyle(
                                        fontSize: 22,
                                        fontWeight: NeonFontWeight.bold,
                                        color: NeonColor.success,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const NeonEdgeInsets.all(12),
                                color: const NeonColor(0x15F59E0B),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'In Progress',
                                      style: NeonTextStyle(
                                        fontSize: 12,
                                        color: NeonColor.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$pending',
                                      style: const NeonTextStyle(
                                        fontSize: 22,
                                        fontWeight: NeonFontWeight.bold,
                                        color: NeonColor.warning,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Priority Breakdown
                  const Text(
                    'Tasks by Priority',
                    style: NeonTextStyle(
                      fontSize: 16,
                      fontWeight: NeonFontWeight.bold,
                      color: NeonColor.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          padding: const NeonEdgeInsets.all(14),
                          child: Column(
                            children: [
                              const Text(
                                'High',
                                style: NeonTextStyle(
                                  fontWeight: NeonFontWeight.bold,
                                  color: NeonColor.danger,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$highCount',
                                style: const NeonTextStyle(
                                  fontSize: 20,
                                  fontWeight: NeonFontWeight.bold,
                                  color: NeonColor.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Card(
                          padding: const NeonEdgeInsets.all(14),
                          child: Column(
                            children: [
                              const Text(
                                'Medium',
                                style: NeonTextStyle(
                                  fontWeight: NeonFontWeight.bold,
                                  color: NeonColor.warning,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$medCount',
                                style: const NeonTextStyle(
                                  fontSize: 20,
                                  fontWeight: NeonFontWeight.bold,
                                  color: NeonColor.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Card(
                          padding: const NeonEdgeInsets.all(14),
                          child: Column(
                            children: [
                              const Text(
                                'Low',
                                style: NeonTextStyle(
                                  fontWeight: NeonFontWeight.bold,
                                  color: NeonColor.success,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$lowCount',
                                style: const NeonTextStyle(
                                  fontSize: 20,
                                  fontWeight: NeonFontWeight.bold,
                                  color: NeonColor.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Quick Actions Card
                  Card(
                    padding: const NeonEdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quick Actions',
                          style: NeonTextStyle(
                            fontSize: 16,
                            fontWeight: NeonFontWeight.bold,
                            color: NeonColor.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            FilledButton(
                              key: 'btn_analytics_add_task',
                              color: NeonColor.primary,
                              child: const Text(
                                '+ New Task',
                                style: NeonTextStyle(
                                  color: NeonColor.white,
                                  fontWeight: NeonFontWeight.bold,
                                ),
                              ),
                              onPressed: () {
                                NeonRouter.of(context).push('/new-task');
                              },
                            ),
                            const SizedBox(width: 12),
                            FilledButton(
                              key: 'btn_analytics_view_tasks',
                              color: const NeonColor(0xFF64748B),
                              child: const Text(
                                'View All Tasks',
                                style: NeonTextStyle(
                                  color: NeonColor.white,
                                  fontWeight: NeonFontWeight.bold,
                                ),
                              ),
                              onPressed: () {
                                NeonRouter.of(context).replace('/tasks');
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),

        // Permanently Docked Bottom Navigation Bar
        NavigationBar(
          selectedIndex: 1,
          onDestinationSelected: (idx) {
            if (idx == 0) NeonRouter.of(context).replace('/tasks');
            if (idx == 1) NeonRouter.of(context).replace('/analytics');
            if (idx == 2) NeonRouter.of(context).replace('/settings');
          },
          destinations: const [
            NavigationDestination(icon: Text('📋'), label: 'Tasks'),
            NavigationDestination(icon: Text('📊'), label: 'Analytics'),
            NavigationDestination(icon: Text('⚙️'), label: 'Settings'),
          ],
        ),
      ],
    );
  }
}
