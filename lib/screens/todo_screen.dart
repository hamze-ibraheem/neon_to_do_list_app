import 'package:neon_framework/neon.dart';
import '../models/todo_item.dart';
import '../state/todo_store.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  NeonState<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends NeonState<TodoScreen> {
  final TodoStore _store = TodoStore.instance;

  @override
  void initState() {
    super.initState();
    _store.tasks.listen(_onStoreChanged);
    _store.statusFilter.listen(_onStoreChanged);
    _store.categoryFilter.listen(_onStoreChanged);
    _store.searchQuery.listen(_onStoreChanged);
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _store.tasks.removeListener(_onStoreChanged);
    _store.statusFilter.removeListener(_onStoreChanged);
    _store.categoryFilter.removeListener(_onStoreChanged);
    _store.searchQuery.removeListener(_onStoreChanged);
    super.dispose();
  }

  NeonColor _priorityColor(TodoPriority p) {
    switch (p) {
      case TodoPriority.high:
        return NeonColor.danger;
      case TodoPriority.medium:
        return NeonColor.warning;
      case TodoPriority.low:
        return NeonColor.success;
    }
  }

  @override
  NeonWidget build(NeonBuildContext context) {
    final tasks = _store.filteredTasks;
    final total = _store.tasks.value.length;
    final completed = _store.tasks.value.where((t) => t.isCompleted).length;
    final pct = total > 0 ? ((completed / total) * 100).toInt() : 0;
    final currentStatus = _store.statusFilter.value;
    final currentCat = _store.categoryFilter.value;

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
                  // Top App Bar / Header
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Neon Tasks',
                            style: NeonTextStyle(
                              fontSize: 26,
                              fontWeight: NeonFontWeight.bold,
                              color: NeonColor.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$completed of $total done • $pct% completed',
                            style: const NeonTextStyle(
                              fontSize: 13,
                              color: NeonColor.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      FilledButton(
                        key: 'btn_open_new_task',
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
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Search Bar
                  SearchBar(
                    key: 'search_tasks_input',
                    hintText: 'Search tasks by title or notes...',
                    value: _store.searchQuery.value,
                    onChanged: (val) {
                      _store.searchQuery.value = val;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Status Filter Chips
                  Row(
                    children: ['All', 'Active', 'Completed'].map((status) {
                      final isSelected = currentStatus == status;
                      return Container(
                        margin: const NeonEdgeInsets.only(right: 8),
                        child: FilterChip(
                          key: 'chip_filter_${status.toLowerCase()}',
                          label: Text(status),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              _store.statusFilter.value = status;
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),

                  // Category Filter Scrollable Chips
                  SingleChildScrollView(
                    scrollDirection: ScrollDirection.horizontal,
                    child: Row(
                      children: _store.availableCategories.map((cat) {
                        final isSelected = currentCat == cat;
                        return Container(
                          margin: const NeonEdgeInsets.only(right: 8),
                          child: FilterChip(
                            key: 'chip_cat_filter_${cat.toLowerCase()}',
                            label: Text(cat),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                _store.categoryFilter.value = cat;
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Task List
                  if (tasks.isEmpty) ...[
                    const Card(
                      padding: NeonEdgeInsets.all(32),
                      child: Column(
                        children: [
                          Text(
                            '🎉 All Caught Up!',
                            style: NeonTextStyle(
                              fontSize: 18,
                              fontWeight: NeonFontWeight.bold,
                              color: NeonColor.textPrimary,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'No tasks match your current filter. Tap "+ New Task" to add more.',
                            style: NeonTextStyle(
                              fontSize: 13,
                              color: NeonColor.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Column(
                      children: tasks.map((task) {
                        return Container(
                          margin: const NeonEdgeInsets.only(bottom: 10),
                          child: Card(
                            key: 'card_task_${task.id}',
                            padding: const NeonEdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  key: 'chk_task_${task.id}',
                                  value: task.isCompleted,
                                  onChanged: (_) {
                                    _store.toggleTask(task.id);
                                  },
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        task.title,
                                        style: NeonTextStyle(
                                          fontSize: 15,
                                          fontWeight: NeonFontWeight.bold,
                                          color: task.isCompleted
                                              ? const NeonColor(0xFF94A3B8)
                                              : NeonColor.textPrimary,
                                        ),
                                      ),
                                      if (task.description.isNotEmpty) ...[
                                        const SizedBox(height: 3),
                                        Text(
                                          task.description,
                                          style: const NeonTextStyle(
                                            fontSize: 12,
                                            color: NeonColor.textSecondary,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Badge(
                                            backgroundColor: const NeonColor(0xFF6366F1),
                                            label: Text(task.category),
                                            child: const SizedBox(width: 0, height: 0),
                                          ),
                                          const SizedBox(width: 6),
                                          Badge(
                                            backgroundColor: _priorityColor(task.priority),
                                            label: Text(task.priority.badgeText),
                                            child: const SizedBox(width: 0, height: 0),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                FilledButton(
                                  key: 'btn_view_task_${task.id}',
                                  color: NeonColor.primary,
                                  child: const Text(
                                    'Edit →',
                                    style: NeonTextStyle(
                                      color: NeonColor.white,
                                      fontWeight: NeonFontWeight.bold,
                                    ),
                                  ),
                                  onPressed: () {
                                    NeonRouter.of(context).push('/tasks/${task.id}');
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),

        // Permanently Docked Bottom Navigation Bar
        NavigationBar(
          selectedIndex: 0,
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
