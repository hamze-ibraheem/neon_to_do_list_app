import 'package:neon_framework/neon.dart';
import '../models/todo_item.dart';
import '../state/todo_store.dart';

class NewTaskScreen extends StatefulWidget {
  const NewTaskScreen({super.key});

  @override
  NeonState<NewTaskScreen> createState() => _NewTaskScreenState();
}

class _NewTaskScreenState extends NeonState<NewTaskScreen> {
  final TodoStore _store = TodoStore.instance;
  String _title = '';
  String _description = '';
  TodoPriority _priority = TodoPriority.medium;
  String _category = 'Work';

  void _createTask() {
    final cleanTitle = _title.trim();
    if (cleanTitle.isEmpty) return;

    final newTask = TodoItem(
      id: 'task_${DateTime.now().millisecondsSinceEpoch}',
      title: cleanTitle,
      description: _description.trim(),
      isCompleted: false,
      priority: _priority,
      category: _category,
      createdAt: DateTime.now(),
    );

    _store.addTask(newTask);
    NeonRouter.of(context).pop(newTask);
  }

  @override
  NeonWidget build(NeonBuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: const NeonEdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            Row(
              children: [
                FilledButton(
                  key: 'btn_cancel_new_task',
                  color: const NeonColor(0xFF64748B),
                  child: const Text(
                    'Cancel',
                    style: NeonTextStyle(
                      color: NeonColor.white,
                      fontWeight: NeonFontWeight.bold,
                    ),
                  ),
                  onPressed: () => NeonRouter.of(context).pop(),
                ),
                const Spacer(),
                const Text(
                  'Create New Task',
                  style: NeonTextStyle(
                    fontSize: 18,
                    fontWeight: NeonFontWeight.bold,
                    color: NeonColor.textPrimary,
                  ),
                ),
                const Spacer(),
                FilledButton(
                  key: 'btn_create_task_submit',
                  color: NeonColor.primary,
                  child: const Text(
                    'Create',
                    style: NeonTextStyle(
                      color: NeonColor.white,
                      fontWeight: NeonFontWeight.bold,
                    ),
                  ),
                  onPressed: _createTask,
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Form Fields Card
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
                    key: 'input_new_task_title',
                    value: _title,
                    hintText: 'What needs to be accomplished?',
                    onChanged: (val) {
                      setState(() => _title = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Description & Details (Optional)',
                    style: NeonTextStyle(
                      fontSize: 14,
                      fontWeight: NeonFontWeight.bold,
                      color: NeonColor.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    key: 'input_new_task_desc',
                    value: _description,
                    maxLines: 4,
                    hintText: 'Add extra details, checklist, or instructions...',
                    onChanged: (val) {
                      setState(() => _description = val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Priority Selection Card
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
                          key: 'chip_new_priority_${p.name}',
                          label: Text(p.label),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _priority = p);
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

            // Category Selection Card
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
                            key: 'chip_new_cat_${cat.toLowerCase()}',
                            label: Text(cat),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _category = cat);
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
            const SizedBox(height: 24),

            // Submit Button
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    key: 'btn_confirm_add_task',
                    color: NeonColor.primary,
                    child: const Text(
                      '+ Create Task',
                      style: NeonTextStyle(
                        color: NeonColor.white,
                        fontSize: 16,
                        fontWeight: NeonFontWeight.bold,
                      ),
                    ),
                    onPressed: _createTask,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
