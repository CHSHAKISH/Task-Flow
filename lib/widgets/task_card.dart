import 'package:flutter/material.dart';
import 'package:task_flow/models/task.dart';
import 'package:task_flow/theme/app_theme.dart';
import 'package:task_flow/widgets/highlighted_text.dart';

/// TaskCard widget displays a single task in the list
class TaskCard extends StatelessWidget {
  final Task task;
  final bool isBlocked;
  final String? blockerTitle;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final ValueChanged<bool?>? onCheckboxChanged;
  final String searchQuery;

  const TaskCard({
    super.key,
    required this.task,
    this.isBlocked = false,
    this.blockerTitle,
    this.onTap,
    this.onDelete,
    this.onCheckboxChanged,
    this.searchQuery = '',
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isBlocked ? 0.5 : 1.0,
      child: Dismissible(
        key: Key('task-${task.id}'),
        background: Container(
          color: Colors.red,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(
            Icons.delete,
            color: Colors.white,
            size: 32,
          ),
        ),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) => _confirmDelete(context),
        onDismissed: (direction) => onDelete?.call(),
        child: Card(
          child: ListTile(
            onTap: isBlocked ? null : onTap,
            leading: isBlocked
                ? const Icon(
                    Icons.lock_outline,
                    color: Colors.grey,
                    size: 32,
                  )
                : Checkbox(
                    value: task.isCompleted,
                    onChanged: onCheckboxChanged,
                  ),
            title: HighlightedText(
              text: task.title,
              query: searchQuery,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                decoration: task.isCompleted
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
                color: isBlocked ? Colors.grey : null,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isBlocked ? Colors.grey : null,
                  ),
                ),
                if (isBlocked && blockerTitle != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.block,
                        size: 14,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Blocked by: $blockerTitle',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            trailing: Chip(
              label: Text(
                isBlocked ? 'Blocked' : task.statusEnum.displayName,
              ),
              backgroundColor: isBlocked
                  ? Colors.grey
                  : AppTheme.getStatusColor(task.statusEnum),
              labelStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
