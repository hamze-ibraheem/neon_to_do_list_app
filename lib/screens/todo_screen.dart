import 'package:neon_framework/neon.dart';
import '../models/todo_item.dart';

enum FilterStatus { all, active, completed }

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  NeonState<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends NeonState<TodoScreen> {
  final List<TodoItem> _tasks = [
    TodoItem(
      id: 'task_1',
      title: 'Explore Neon Framework architecture',
      isCompleted: true,
      priority: TodoPriority.high,
      category: 'Work',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    TodoItem(
      id: 'task_2',
      title: 'Build custom mobile app with Neon SDK',
      isCompleted: false,
      priority: TodoPriority.high,
      category: 'Work',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    TodoItem(
      id: 'task_3',
      title: 'Design native Android bridge and UI tree',
      isCompleted: false,
      priority: TodoPriority.medium,
      category: 'Study',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    TodoItem(
      id: 'task_4',
      title: 'Review local storage & networking layers',
      isCompleted: false,
      priority: TodoPriority.low,
      category: 'Personal',
      createdAt: DateTime.now(),
    ),
  ];

  String _newTaskTitle = '';
  TodoPriority _selectedPriority = TodoPriority.medium;
  String _selectedCategory = 'Work';
  FilterStatus _filterStatus = FilterStatus.all;
  String _activeCategoryFilter = 'All';

  final List<String> _categories = const [
    'Work',
    'Personal',
    'Study',
    'Shopping',
    'Health',
  ];

  void _addTask() {
    final title = _newTaskTitle.trim();
    if (title.isEmpty) return;

    final newTask = TodoItem(
      id: 'task_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      isCompleted: false,
      priority: _selectedPriority,
      category: _selectedCategory,
      createdAt: DateTime.now(),
    );

    setState(() {
      _tasks.insert(0, newTask);
      _newTaskTitle = '';
    });
  }

  void _toggleTask(String id) {
    setState(() {
      final index = _tasks.indexWhere((t) => t.id == id);
      if (index != -1) {
        final current = _tasks[index];
        _tasks[index] = current.copyWith(isCompleted: !current.isCompleted);
      }
    });
  }

  void _deleteTask(String id) {
    setState(() {
      _tasks.removeWhere((t) => t.id == id);
    });
  }

  void _clearCompleted() {
    setState(() {
      _tasks.removeWhere((t) => t.isCompleted);
    });
  }

  void _toggleAll() {
    final hasUncompleted = _tasks.any((t) => !t.isCompleted);
    setState(() {
      for (int i = 0; i < _tasks.length; i++) {
        _tasks[i] = _tasks[i].copyWith(isCompleted: hasUncompleted);
      }
    });
  }

  List<TodoItem> get _filteredTasks {
    return _tasks.where((task) {
      if (_filterStatus == FilterStatus.active && task.isCompleted) {
        return false;
      }
      if (_filterStatus == FilterStatus.completed && !task.isCompleted) {
        return false;
      }
      if (_activeCategoryFilter != 'All' &&
          task.category != _activeCategoryFilter) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  NeonWidget build(NeonBuildContext context) {
    final totalCount = _tasks.length;
    final completedCount = _tasks.where((t) => t.isCompleted).length;
    final activeCount = totalCount - completedCount;
    final progress = totalCount > 0 ? (completedCount / totalCount) : 0.0;
    final percentInt = (progress * 100).toInt();

    final filteredList = _filteredTasks;

    return Column(
      children: [
        AppBar(
          key: 'appbar_todo',
          title: const Text('Neon Task Studio'),
          variant: AppBarVariant.small,
          actions: [
            Badge(
              key: 'badge_active_tasks',
              label: Text('$activeCount'),
              backgroundColor: const NeonColor(0xFF4F46E5),
              child: const Text('📋 Tasks '),
            ),
          ],
        ),
        Expanded(
          child: Container(
            color: const NeonColor(0xFFF1F5F9),
            padding: const NeonEdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: SingleChildScrollView(
              padding: const NeonEdgeInsets.only(bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Productivity Summary Card
                  Card(
                    key: 'card_progress',
                    borderRadius: 14.0,
                    color: const NeonColor(0xFFFFFFFF),
                    padding: const NeonEdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Progress Overview',
                              style: NeonTextStyle(
                                fontSize: 16.0,
                                fontWeight: NeonFontWeight.bold,
                                color: NeonColor(0xFF1E293B),
                              ),
                            ),
                            Text(
                              '$percentInt% done ($completedCount/$totalCount)',
                              style: const NeonTextStyle(
                                fontSize: 13.0,
                                fontWeight: NeonFontWeight.bold,
                                color: NeonColor(0xFF4F46E5),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10.0),
                        LinearProgressIndicator(
                          key: 'progress_bar',
                          value: progress,
                          minHeight: 8.0,
                          borderRadius: 4.0,
                          color: const NeonColor(0xFF4F46E5),
                          backgroundColor: const NeonColor(0xFFE2E8F0),
                        ),
                        const SizedBox(height: 12.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Text(
                              'Total: $totalCount',
                              style: const NeonTextStyle(
                                fontSize: 12.0,
                                color: NeonColor(0xFF64748B),
                              ),
                            ),
                            Text(
                              'Active: $activeCount',
                              style: const NeonTextStyle(
                                fontSize: 12.0,
                                fontWeight: NeonFontWeight.bold,
                                color: NeonColor(0xFF0EA5E9),
                              ),
                            ),
                            Text(
                              'Done: $completedCount',
                              style: const NeonTextStyle(
                                fontSize: 12.0,
                                fontWeight: NeonFontWeight.bold,
                                color: NeonColor(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16.0),

                  // 2. Add Task Card
                  Card(
                    key: 'card_add_task',
                    borderRadius: 14.0,
                    color: const NeonColor(0xFFFFFFFF),
                    padding: const NeonEdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Create New Task',
                          style: NeonTextStyle(
                            fontSize: 16.0,
                            fontWeight: NeonFontWeight.bold,
                            color: NeonColor(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 10.0),
                        TextField.outlined(
                          key: 'tf_new_task',
                          value: _newTaskTitle,
                          labelText: 'Task Description',
                          hintText: 'e.g. Test iOS native bridge...',
                          onChanged: (val) {
                            setState(() {
                              _newTaskTitle = val;
                            });
                          },
                          onSubmitted: (_) => _addTask(),
                        ),
                        const SizedBox(height: 12.0),
                        const Text(
                          'Priority:',
                          style: NeonTextStyle(
                            fontSize: 12.0,
                            fontWeight: NeonFontWeight.bold,
                            color: NeonColor(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 6.0),
                        Row(
                          children: [
                            FilterChip(
                              key: 'chip_prio_low',
                              label: const Text('Low'),
                              selected: _selectedPriority == TodoPriority.low,
                              onSelected: (_) {
                                setState(() {
                                  _selectedPriority = TodoPriority.low;
                                });
                              },
                            ),
                            const SizedBox(width: 8.0),
                            FilterChip(
                              key: 'chip_prio_med',
                              label: const Text('Medium'),
                              selected: _selectedPriority == TodoPriority.medium,
                              onSelected: (_) {
                                setState(() {
                                  _selectedPriority = TodoPriority.medium;
                                });
                              },
                            ),
                            const SizedBox(width: 8.0),
                            FilterChip(
                              key: 'chip_prio_high',
                              label: const Text('High'),
                              selected: _selectedPriority == TodoPriority.high,
                              onSelected: (_) {
                                setState(() {
                                  _selectedPriority = TodoPriority.high;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12.0),
                        const Text(
                          'Category:',
                          style: NeonTextStyle(
                            fontSize: 12.0,
                            fontWeight: NeonFontWeight.bold,
                            color: NeonColor(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 6.0),
                        Row(
                          children: [
                            for (final cat in _categories) ...[
                              FilterChip(
                                key: 'chip_cat_$cat',
                                label: Text(cat),
                                selected: _selectedCategory == cat,
                                onSelected: (_) {
                                  setState(() {
                                    _selectedCategory = cat;
                                  });
                                },
                              ),
                              const SizedBox(width: 6.0),
                            ],
                          ],
                        ),
                        const SizedBox(height: 14.0),
                        FilledButton(
                          key: 'btn_submit_task',
                          color: const NeonColor(0xFF4F46E5),
                          onPressed: _addTask,
                          child: const Text(
                            '+ Add Task to List',
                            style: NeonTextStyle(
                              color: NeonColor(0xFFFFFFFF),
                              fontWeight: NeonFontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16.0),

                  // 3. Filter Controls
                  Card(
                    key: 'card_filters',
                    borderRadius: 14.0,
                    color: const NeonColor(0xFFFFFFFF),
                    padding: const NeonEdgeInsets.symmetric(
                      horizontal: 14.0,
                      vertical: 10.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            FilterChip(
                              key: 'filter_status_all',
                              label: Text('All ($totalCount)'),
                              selected: _filterStatus == FilterStatus.all,
                              onSelected: (_) {
                                setState(() {
                                  _filterStatus = FilterStatus.all;
                                });
                              },
                            ),
                            const SizedBox(width: 8.0),
                            FilterChip(
                              key: 'filter_status_active',
                              label: Text('Active ($activeCount)'),
                              selected: _filterStatus == FilterStatus.active,
                              onSelected: (_) {
                                setState(() {
                                  _filterStatus = FilterStatus.active;
                                });
                              },
                            ),
                            const SizedBox(width: 8.0),
                            FilterChip(
                              key: 'filter_status_done',
                              label: Text('Done ($completedCount)'),
                              selected: _filterStatus == FilterStatus.completed,
                              onSelected: (_) {
                                setState(() {
                                  _filterStatus = FilterStatus.completed;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8.0),
                        Row(
                          children: [
                            FilterChip(
                              key: 'filter_cat_all',
                              label: const Text('🏷️ All Tags'),
                              selected: _activeCategoryFilter == 'All',
                              onSelected: (_) {
                                setState(() {
                                  _activeCategoryFilter = 'All';
                                });
                              },
                            ),
                            const SizedBox(width: 6.0),
                            for (final cat in _categories) ...[
                              FilterChip(
                                key: 'filter_cat_$cat',
                                label: Text(cat),
                                selected: _activeCategoryFilter == cat,
                                onSelected: (_) {
                                  setState(() {
                                    _activeCategoryFilter = cat;
                                  });
                                },
                              ),
                              const SizedBox(width: 6.0),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16.0),

                  // 4. Task List Header & Batch Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tasks (${filteredList.length})',
                        style: const NeonTextStyle(
                          fontSize: 18.0,
                          fontWeight: NeonFontWeight.bold,
                          color: NeonColor(0xFF1E293B),
                        ),
                      ),
                      Row(
                        children: [
                          FilledButton(
                            key: 'btn_toggle_all_tasks',
                            color: const NeonColor(0xFF64748B),
                            onPressed: _tasks.isEmpty ? null : _toggleAll,
                            child: Text(
                              activeCount == 0 ? 'Reset' : 'Check All',
                              style: const NeonTextStyle(
                                color: NeonColor(0xFFFFFFFF),
                                fontSize: 12.0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          FilledButton(
                            key: 'btn_clear_completed_tasks',
                            color: const NeonColor(0xFFEF4444),
                            onPressed: completedCount == 0
                                ? null
                                : _clearCompleted,
                            child: const Text(
                              'Clear Done',
                              style: NeonTextStyle(
                                color: NeonColor(0xFFFFFFFF),
                                fontSize: 12.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 10.0),

                  // 5. Task Items or Empty State
                  if (filteredList.isEmpty)
                    Card(
                      key: 'card_empty_state',
                      borderRadius: 14.0,
                      color: const NeonColor(0xFFFFFFFF),
                      padding: const NeonEdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          const Text(
                            '🎉',
                            style: NeonTextStyle(fontSize: 36.0),
                          ),
                          const SizedBox(height: 8.0),
                          const Text(
                            'No Tasks Found',
                            style: NeonTextStyle(
                              fontSize: 16.0,
                              fontWeight: NeonFontWeight.bold,
                              color: NeonColor(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            _tasks.isEmpty
                                ? 'Add your first task above to get started!'
                                : 'Try changing your status or category filters.',
                            style: const NeonTextStyle(
                              fontSize: 13.0,
                              color: NeonColor(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: [
                        for (final item in filteredList) ...[
                          Card(
                            key: 'card_task_${item.id}',
                            borderRadius: 12.0,
                            color: item.isCompleted
                                ? const NeonColor(0xFFF8FAFC)
                                : const NeonColor(0xFFFFFFFF),
                            padding: const NeonEdgeInsets.symmetric(
                              horizontal: 12.0,
                              vertical: 10.0,
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  key: 'cb_task_${item.id}',
                                  value: item.isCompleted,
                                  onChanged: (_) => _toggleTask(item.id),
                                ),
                                const SizedBox(width: 12.0),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.isCompleted
                                            ? '✓ ${item.title}'
                                            : item.title,
                                        style: NeonTextStyle(
                                          fontSize: 15.0,
                                          fontWeight: item.isCompleted
                                              ? NeonFontWeight.normal
                                              : NeonFontWeight.bold,
                                          color: item.isCompleted
                                              ? const NeonColor(0xFF94A3B8)
                                              : const NeonColor(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 4.0),
                                      Row(
                                        children: [
                                          Text(
                                            item.priority.badgeText,
                                            style: const NeonTextStyle(
                                              fontSize: 11.0,
                                              fontWeight: NeonFontWeight.bold,
                                              color: NeonColor(0xFF475569),
                                            ),
                                          ),
                                          const SizedBox(width: 8.0),
                                          Text(
                                            '🏷️ ${item.category}',
                                            style: const NeonTextStyle(
                                              fontSize: 11.0,
                                              color: NeonColor(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8.0),
                                Button(
                                  key: 'btn_del_${item.id}',
                                  color: const NeonColor(0xFFFEE2E2),
                                  padding: const NeonEdgeInsets.symmetric(
                                    horizontal: 10.0,
                                    vertical: 6.0,
                                  ),
                                  onPressed: () => _deleteTask(item.id),
                                  child: const Text(
                                    '✕',
                                    style: NeonTextStyle(
                                      color: NeonColor(0xFFDC2626),
                                      fontWeight: NeonFontWeight.bold,
                                      fontSize: 12.0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8.0),
                        ],
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
