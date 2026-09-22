import 'package:neon_framework/neon.dart';
import '../models/todo_item.dart';
import '../state/todo_store.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskId;

  const TaskDetailScreen({
    super.key,
    required this.taskId,
  });

  @override
  NeonState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends NeonState<TaskDetailScreen> {
  final TodoStore _store = TodoStore.instance;
  TodoItem? _task;
  String _title = '';
  String _description = '';
  TodoPriority _priority = TodoPriority.medium;
  String _category = 'Work';
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _loadTask();
  }

  void _loadTask() {
    final item = _store.getTaskById(widget.taskId);
    if (item != null) {
      _task = item;
      _title = item.title;
      _description = item.description;
      _priority = item.priority;
      _category = item.category;
      _isCompleted = item.isCompleted;
    }
  }

  void _saveChanges() {
    if (_task == null) return;
    final updated = _task!.copyWith(
      title: _title.trim().isEmpty ? _task!.title : _title.trim(),
      description: _description.trim(),
      priority: _priority,
      category: _category,
      isCompleted: _isCompleted,
    );
    _store.updateTask(updated);
    NeonRouter.of(context).pop(updated);
  }

  void _deleteTask() {
    if (_task == null) return;
    _store.deleteTask(_task!.id);
    NeonRouter.of(context).pop('deleted');
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
    if (_task == null) {
      return Container(
        padding: const NeonEdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Task Not Found',
              style: NeonTextStyle(
                fontSize: 20,
                fontWeight: NeonFontWeight.bold,
                color: NeonColor.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'The requested task could not be located in the local store.',
              style: NeonTextStyle(color: NeonColor.textSecondary),
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: 'btn_not_found_back',
              color: NeonColor.primary,
              child: const Text(
                'Return to Tasks',
                style: NeonTextStyle(
                  color: NeonColor.white,
                  fontWeight: NeonFontWeight.bold,
                ),
              ),
              onPressed: () => NeonRouter.of(context).pop(),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Container(
        padding: const NeonEdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Navigation Bar
            Row(
              children: [
                FilledButton(
                  key: 'btn_detail_back',
                  color: const NeonColor(0xFF64748B),
                  child: const Text(
                    '← Back',
                    style: NeonTextStyle(
                      color: NeonColor.white,
                      fontWeight: NeonFontWeight.bold,
                    ),
                  ),
                  onPressed: () => NeonRouter.of(context).pop(),
                ),
                const Spacer(),
                FilledButton(
                  key: 'btn_detail_delete',
                  color: NeonColor.danger,
                  child: const Text(
                    'Delete Task',
                    style: NeonTextStyle(
                      color: NeonColor.white,
                      fontWeight: NeonFontWeight.bold,
                    ),
                  ),
                  onPressed: _deleteTask,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Hero Summary Card
            Card(
              padding: const NeonEdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Badge(
                        backgroundColor: const NeonColor(0xFF6366F1),
                        label: Text(_category),
                        child: const SizedBox(width: 0, height: 0),
                      ),
                      const SizedBox(width: 8),
                      Badge(
                        backgroundColor: _priorityColor(_priority),
                        label: Text(_priority.badgeText),
                        child: const SizedBox(width: 0, height: 0),
                      ),
                      const Spacer(),
                      Text(
                        _isCompleted ? '✓ Completed' : '○ In Progress',
                        style: NeonTextStyle(
                          color: _isCompleted ? NeonColor.success : NeonColor.textSecondary,
                          fontWeight: NeonFontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Task ID: ${_task!.id}',
                    style: const NeonTextStyle(
                      fontSize: 12,
                      color: NeonColor.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Content Fields Card
            Card(
              padding: const NeonEdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Task Title',
                    style: NeonTextStyle(
                      fontSize: 14,
                      fontWeight: NeonFontWeight.bold,
                      color: NeonColor.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    key: 'input_edit_title',
                    value: _title,
                    hintText: 'Enter task title',
                    onChanged: (val) {
                      setState(() {
                        _title = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Description & Notes',
                    style: NeonTextStyle(
                      fontSize: 14,
                      fontWeight: NeonFontWeight.bold,
                      color: NeonColor.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    key: 'input_edit_desc',
                    value: _description,
                    maxLines: 4,
                    hintText: 'Add extra details, checklist, or instructions...',
                    onChanged: (val) {
                      setState(() {
                        _description = val;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Priority Selector Card
            Card(
              padding: const NeonEdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Priority Level',
                    style: NeonTextStyle(
                      fontSize: 14,
                      fontWeight: NeonFontWeight.bold,
                      color: NeonColor.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: TodoPriority.values.map((p) {
                      final isSelected = _priority == p;
                      return Container(
                        margin: const NeonEdgeInsets.only(right: 10),
                        child: FilterChip(
                          key: 'chip_priority_${p.name}',
                          label: Text(p.label),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _priority = p;
                              });
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Category Selector Card
            Card(
              padding: const NeonEdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Category',
                    style: NeonTextStyle(
                      fontSize: 14,
                      fontWeight: NeonFontWeight.bold,
                      color: NeonColor.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: ScrollDirection.horizontal,
                    child: Row(
                      children: _store.availableCategories
                          .where((c) => c != 'All')
                          .map((cat) {
                        final isSelected = _category == cat;
                        return Container(
                          margin: const NeonEdgeInsets.only(right: 8),
                          child: FilterChip(
                            key: 'chip_cat_${cat.toLowerCase()}',
                            label: Text(cat),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _category = cat;
                                });
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Status Toggle Card
            Card(
              padding: const NeonEdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mark as Completed',
                        style: NeonTextStyle(
                          fontSize: 15,
                          fontWeight: NeonFontWeight.bold,
                          color: NeonColor.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Toggle completion state in global store',
                        style: NeonTextStyle(
                          fontSize: 12,
                          color: NeonColor.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Switch(
                    key: 'switch_complete_task',
                    value: _isCompleted,
                    onChanged: (val) {
                      setState(() {
                        _isCompleted = val;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Save CTA Button
            Container(
              padding: const NeonEdgeInsets.only(bottom: 24),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      key: 'btn_save_task_changes',
                      color: NeonColor.primary,
                      child: const Text(
                        'Save Changes',
                        style: NeonTextStyle(
                          color: NeonColor.white,
                          fontSize: 16,
                          fontWeight: NeonFontWeight.bold,
                        ),
                      ),
                      onPressed: _saveChanges,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
