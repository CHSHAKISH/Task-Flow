import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:task_flow/models/task.dart';
import 'package:task_flow/theme/app_theme.dart';
import 'package:task_flow/widgets/highlighted_text.dart';

/// TaskCard displays a single task with full visual hierarchy, animations,
/// blocked-state styling, and swipe-to-delete.
class TaskCard extends StatefulWidget {
  final Task task;
  final bool isBlocked;
  final String? blockerTitle;
  final String searchQuery;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final ValueChanged<bool?>? onCheckboxChanged;

  const TaskCard({
    super.key,
    required this.task,
    this.isBlocked = false,
    this.blockerTitle,
    this.searchQuery = '',
    this.onTap,
    this.onDelete,
    this.onCheckboxChanged,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = widget.isBlocked
        ? AppTheme.blocked
        : AppTheme.getStatusColor(widget.task.statusEnum);
    final statusBg = widget.isBlocked
        ? Colors.grey.shade100
        : AppTheme.getStatusBackground(widget.task.statusEnum);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: _buildDismissible(context, theme, statusColor, statusBg),
    );
  }

  Widget _buildDismissible(
    BuildContext context,
    ThemeData theme,
    Color statusColor,
    Color statusBg,
  ) {
    return Dismissible(
      key: Key('task-${widget.task.id}'),
      direction: DismissDirection.endToStart,
      background: _buildDeleteBackground(),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => widget.onDelete?.call(),
      child: _buildCard(context, theme, statusColor, statusBg),
    );
  }

  Widget _buildDeleteBackground() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEF5350), Color(0xFFC62828)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delete_rounded, color: Colors.white, size: 26),
          SizedBox(height: 4),
          Text(
            'Delete',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    ThemeData theme,
    Color statusColor,
    Color statusBg,
  ) {
    final isCompleted = widget.task.isCompleted;
    final isBlocked = widget.isBlocked;

    return AnimatedOpacity(
      opacity: isBlocked ? 0.55 : 1.0,
      duration: const Duration(milliseconds: 250),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isBlocked ? null : widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left accent bar
                _buildStatusBar(statusColor),
                const SizedBox(width: 12),

                // Main content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row
                      Row(
                        children: [
                          Expanded(child: _buildTitle(isCompleted, isBlocked)),
                          const SizedBox(width: 8),
                          _buildStatusChip(statusColor, statusBg),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Description
                      _buildDescription(isBlocked),

                      const SizedBox(height: 6),

                      // Footer row: due date + blocked indicator OR checkbox
                      _buildFooter(context, isBlocked, isCompleted),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBar(Color color) {
    return Container(
      width: 4,
      height: 70,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildTitle(bool isCompleted, bool isBlocked) {
    final titleStyle = TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      decoration: isCompleted ? TextDecoration.lineThrough : null,
      decorationColor: Colors.grey,
      color: isBlocked ? Colors.grey.shade500 : const Color(0xFF1A1A2E),
      height: 1.3,
    );

    return HighlightedText(
      text: widget.task.title,
      query: widget.searchQuery,
      style: titleStyle,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildDescription(bool isBlocked) {
    final descStyle = TextStyle(
      fontSize: 13,
      color: isBlocked ? Colors.grey.shade400 : Colors.grey.shade600,
      height: 1.4,
    );

    return HighlightedText(
      text: widget.task.description,
      query: widget.searchQuery,
      style: descStyle,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildStatusChip(Color statusColor, Color statusBg) {
    final label = widget.isBlocked
        ? 'Blocked'
        : widget.task.statusEnum.displayName;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: statusBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: statusColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildFooter(
    BuildContext context,
    bool isBlocked,
    bool isCompleted,
  ) {
    final dueDate = widget.task.dueDate;
    final now = DateTime.now();
    final isOverdue = !isCompleted && dueDate.isBefore(now);
    final dueDateStr = DateFormat('MMM d, y').format(dueDate);

    return Row(
      children: [
        // Due date
        Icon(
          Icons.calendar_today_rounded,
          size: 12,
          color: isOverdue ? AppTheme.danger : Colors.grey.shade400,
        ),
        const SizedBox(width: 4),
        Text(
          dueDateStr,
          style: TextStyle(
            fontSize: 12,
            color: isOverdue ? AppTheme.danger : Colors.grey.shade500,
            fontWeight: isOverdue ? FontWeight.w600 : FontWeight.w400,
          ),
        ),

        // Blocked indicator or filler
        if (isBlocked && widget.blockerTitle != null) ...[
          const SizedBox(width: 8),
          const Icon(Icons.lock_rounded, size: 12, color: Color(0xFF757575)),
          const SizedBox(width: 3),
          Expanded(
            child: Text(
              'Blocked by ${widget.blockerTitle}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF757575),
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ] else ...[
          const Spacer(),

          // Quick-toggle checkbox (only when not blocked)
          if (!isBlocked)
            Transform.scale(
              scale: 0.85,
              child: Checkbox(
                value: isCompleted,
                activeColor: AppTheme.done,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                onChanged: (val) {
                  HapticFeedback.lightImpact();
                  widget.onCheckboxChanged?.call(val);
                },
              ),
            ),
        ],
      ],
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Delete "${widget.task.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
