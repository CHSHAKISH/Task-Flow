import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:task_flow/models/task.dart';
import 'package:task_flow/models/task_draft.dart';
import 'package:task_flow/repositories/task_repository.dart';
import 'package:task_flow/theme/app_theme.dart';

/// TaskFormDialog handles both Create and Edit modes.
/// In Create mode it also auto-saves a draft on app pause.
class TaskFormDialog extends StatefulWidget {
  final Task? task;           // null → Create mode
  final TaskDraft? draft;     // pre-fill from saved draft
  final List<Task> allTasks;  // for Blocked-By dropdown
  final Future<void> Function(Task task)? onSave;

  const TaskFormDialog({
    super.key,
    this.task,
    this.draft,
    required this.allTasks,
    this.onSave,
  });

  @override
  State<TaskFormDialog> createState() => _TaskFormDialogState();
}

class _TaskFormDialogState extends State<TaskFormDialog>
    with WidgetsBindingObserver {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  DateTime? _selectedDate;
  TaskStatus _selectedStatus = TaskStatus.todo;
  int? _selectedBlocker;
  bool _isSaving = false;

  final _repository = TaskRepository();

  bool get _isEdit => widget.task != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (_isEdit) {
      _titleController       = TextEditingController(text: widget.task!.title);
      _descriptionController = TextEditingController(text: widget.task!.description);
      _selectedDate          = widget.task!.dueDate;
      _selectedStatus        = widget.task!.statusEnum;
      _selectedBlocker       = widget.task!.blockedBy;
    } else if (widget.draft != null) {
      _titleController       = TextEditingController(text: widget.draft!.title ?? '');
      _descriptionController = TextEditingController(text: widget.draft!.description ?? '');
      _selectedDate          = widget.draft!.dueDate;
      _selectedStatus        = widget.draft!.status != null
          ? TaskStatus.fromString(widget.draft!.status!)
          : TaskStatus.todo;
      _selectedBlocker = widget.draft!.blockedBy;
    } else {
      _titleController       = TextEditingController();
      _descriptionController = TextEditingController();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isEdit &&
        (state == AppLifecycleState.paused ||
            state == AppLifecycleState.inactive)) {
      _saveDraft();
    }
  }

  void _saveDraft() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final draft = TaskDraft()
      ..title       = title
      ..description = _descriptionController.text.trim()
      ..dueDate     = _selectedDate
      ..status      = _selectedStatus.name
      ..blockedBy   = _selectedBlocker
      ..updatedAt   = DateTime.now();

    _repository.saveDraft(draft);
  }

  bool get _isValid =>
      _titleController.text.trim().isNotEmpty &&
      _descriptionController.text.trim().isNotEmpty &&
      _selectedDate != null;

  Future<void> _handleSave() async {
    if (!_isValid) return;

    setState(() => _isSaving = true);

    final now = DateTime.now();
    final taskToSave = Task()
      ..id          = _isEdit ? widget.task!.id : 0
      ..title       = _titleController.text.trim()
      ..description = _descriptionController.text.trim()
      ..dueDate     = _selectedDate!
      ..status      = _selectedStatus.name
      ..blockedBy   = _selectedBlocker
      ..sortOrder   = _isEdit ? widget.task!.sortOrder : 0
      ..createdAt   = _isEdit ? widget.task!.createdAt : now
      ..updatedAt   = now;

    try {
      await widget.onSave?.call(taskToSave);
      if (!_isEdit) await _repository.clearDraft();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
            primary: AppTheme.primarySeed,
          ),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  @override
  Widget build(BuildContext context) {
    final availableTasks = widget.allTasks
        .where((t) => _isEdit ? t.id != widget.task!.id : true)
        .toList();

    final dialogTitle = _isEdit
        ? 'Edit Task'
        : (widget.draft != null ? '📝 Resume Draft' : 'New Task');

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────
            Text(dialogTitle, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),

            // ── Scrollable form body ─────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildField(
                      controller: _titleController,
                      label: 'Title',
                      hint: 'What needs to be done?',
                      maxLines: 1,
                      enabled: !_isSaving,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      controller: _descriptionController,
                      label: 'Description',
                      hint: 'Add more details…',
                      maxLines: 3,
                      enabled: !_isSaving,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 14),

                    // ── Date Picker ────────────────────────────────
                    _SectionLabel(label: 'Due Date'),
                    const SizedBox(height: 6),
                    _DatePickerButton(
                      selectedDate: _selectedDate,
                      enabled: !_isSaving,
                      onTap: _pickDate,
                    ),
                    const SizedBox(height: 14),

                    // ── Status (Edit only) ─────────────────────────
                    if (_isEdit) ...[
                      _SectionLabel(label: 'Status'),
                      const SizedBox(height: 6),
                      _StatusSelector(
                        selected: _selectedStatus,
                        enabled: !_isSaving,
                        onChanged: (s) => setState(() => _selectedStatus = s),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // ── Blocked By ─────────────────────────────────
                    _SectionLabel(label: 'Blocked By'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int?>(
                      initialValue: _selectedBlocker,
                      decoration: const InputDecoration(
                        hintText: 'None – not blocked',
                      ),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('None – not blocked'),
                        ),
                        ...availableTasks.map(
                          (t) => DropdownMenuItem<int?>(
                            value: t.id,
                            child: Text(
                              t.title,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: _isSaving
                          ? null
                          : (v) => setState(() => _selectedBlocker = v),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Action Buttons ───────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isSaving
                      ? null
                      : () {
                          if (!_isEdit) _saveDraft();
                          Navigator.pop(context, false);
                        },
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _isSaving
                      ? const SizedBox(
                          key: ValueKey('loading'),
                          width: 100,
                          height: 42,
                          child: Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5),
                            ),
                          ),
                        )
                      : ElevatedButton(
                          key: const ValueKey('save'),
                          onPressed: _isValid ? _handleSave : null,
                          child: Text(_isEdit ? 'Update' : 'Create Task'),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    bool enabled = true,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label: label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          onChanged: onChanged,
          decoration: InputDecoration(hintText: hint),
          style: GoogleFonts.inter(fontSize: 14),
        ),
      ],
    );
  }
}

// ─── Supporting Widgets ──────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade600,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _DatePickerButton extends StatelessWidget {
  final DateTime? selectedDate;
  final bool enabled;
  final VoidCallback onTap;

  const _DatePickerButton({
    required this.selectedDate,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final formatted = selectedDate != null
        ? DateFormat('EEE, MMM d, y').format(selectedDate!)
        : null;

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_month_rounded,
              size: 18,
              color: selectedDate != null
                  ? AppTheme.primarySeed
                  : Colors.grey.shade400,
            ),
            const SizedBox(width: 10),
            Text(
              formatted ?? 'Select due date',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: selectedDate != null
                    ? const Color(0xFF1A1A2E)
                    : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusSelector extends StatelessWidget {
  final TaskStatus selected;
  final bool enabled;
  final ValueChanged<TaskStatus> onChanged;

  const _StatusSelector({
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: TaskStatus.values.map((status) {
        final isSelected = selected == status;
        final color = AppTheme.getStatusColor(status);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: enabled ? () => onChanged(status) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? color : Colors.grey.shade300,
                    width: isSelected ? 0 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    status.displayName,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
