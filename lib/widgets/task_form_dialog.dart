import 'package:flutter/material.dart';
import 'package:task_flow/models/task.dart';
import 'package:task_flow/models/task_draft.dart';
import 'package:task_flow/repositories/task_repository.dart';

class TaskFormDialog extends StatefulWidget {
  final Task? task; // null for create, non-null for edit
  final TaskDraft? draft; // For resuming drafts
  final List<Task> allTasks; // For blocked-by dropdown
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

class _TaskFormDialogState extends State<TaskFormDialog> with WidgetsBindingObserver {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  DateTime? _selectedDate;
  TaskStatus _selectedStatus = TaskStatus.todo;
  int? _selectedBlocker;
  String? _selectedRecurringType;
  bool _isSaving = false;

  final _repository = TaskRepository();

  bool get _isEdit => widget.task != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (_isEdit) {
      _titleController = TextEditingController(text: widget.task!.title);
      _descriptionController = TextEditingController(text: widget.task!.description);
      _selectedDate = widget.task!.dueDate;
      _selectedStatus = widget.task!.statusEnum;
      _selectedBlocker = widget.task!.blockedBy;
      _selectedRecurringType = widget.task!.recurringType;
    } else if (widget.draft != null) {
      _titleController = TextEditingController(text: widget.draft!.title);
      _descriptionController = TextEditingController(text: widget.draft!.description);
      _selectedDate = widget.draft!.dueDate;
      _selectedStatus = widget.draft!.status != null
          ? TaskStatus.fromString(widget.draft!.status!)
          : TaskStatus.todo;
      _selectedBlocker = widget.draft!.blockedBy;
      _selectedRecurringType = widget.draft!.recurringType;
    } else {
      _titleController = TextEditingController();
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
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _saveDraftIfFormOpen();
    }
  }

  void _saveDraftIfFormOpen() {
    if (_isEdit) return; // Don't save draft if editing

    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final draft = TaskDraft()
      ..id = 0
      ..title = title
      ..description = _descriptionController.text.trim()
      ..dueDate = _selectedDate
      ..status = _selectedStatus.name
      ..blockedBy = _selectedBlocker
      ..recurringType = _selectedRecurringType
      ..updatedAt = DateTime.now();

    _repository.saveDraft(draft);
  }

  bool _validateForm() {
    return _titleController.text.trim().isNotEmpty &&
        _descriptionController.text.trim().isNotEmpty &&
        _selectedDate != null;
  }

  Future<void> _handleSave() async {
    if (!_validateForm()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields'), duration: Duration(seconds: 2)),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final taskToSave = Task()
      ..title = _titleController.text.trim()
      ..description = _descriptionController.text.trim()
      ..dueDate = _selectedDate!
      ..status = _selectedStatus.name
      ..blockedBy = _selectedBlocker
      ..recurringType = _selectedRecurringType
      ..sortOrder = _isEdit ? widget.task!.sortOrder : 0
      ..createdAt = _isEdit ? widget.task!.createdAt : DateTime.now()
      ..updatedAt = DateTime.now();

    if (_isEdit) {
      taskToSave.id = widget.task!.id;
    }

    if (widget.onSave != null) {
      await widget.onSave!(taskToSave);
      
      if (!_isEdit) {
        await _repository.clearDraft(); // Clear draft on successful create save
      }
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _showDatePicker() async {
    final now = DateTime.now();
    // Allow initial date if past (during edit), but don't allow selecting new past dates.
    final initial = _selectedDate ?? now;
    final first = initial.isBefore(now) ? initial : DateTime(now.year, now.month, now.day);
    
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: now.add(const Duration(days: 365 * 5)),
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableTasks = widget.allTasks
        .where((t) => _isEdit ? t.id != widget.task!.id : true)
        .where((t) => t.statusEnum != TaskStatus.done || t.id == _selectedBlocker)
        .toList();

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Text(_isEdit ? 'Edit Task' : (widget.draft != null ? 'Resume Draft' : 'Create New Task'), style: const TextStyle(fontWeight: FontWeight.w700)),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Padding(padding: const EdgeInsets.only(top: 12.0, bottom: 24.0), child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title *'),
              onChanged: (_) => setState(() {}),
              enabled: !_isSaving,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description *'),
              minLines: 2,
              maxLines: 4,
              onChanged: (_) => setState(() {}),
              enabled: !_isSaving,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(
                _selectedDate == null ? 'Select due date *' : 'Due: ${_selectedDate!.toLocal().toString().split(' ')[0]}',
                style: TextStyle(color: _selectedDate == null ? Colors.grey : null),
              ),
              trailing: const Icon(Icons.calendar_today, color: Colors.grey),
              onTap: _isSaving ? null : _showDatePicker,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              tileColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            ),
            const SizedBox(height: 16),
            if (_isEdit)
              DropdownButtonFormField<TaskStatus>(
                initialValue: _selectedStatus,
                decoration: const InputDecoration(labelText: 'Status'),
                items: TaskStatus.values.map((status) => DropdownMenuItem(value: status, child: Text(status.displayName))).toList(),
                onChanged: _isSaving ? null : (value) {
                  if (value != null) setState(() => _selectedStatus = value);
                },
              ),
            if (_isEdit) const SizedBox(height: 16),
            DropdownButtonFormField<int?>(
              initialValue: _selectedBlocker,
              decoration: const InputDecoration(labelText: 'Blocked By (Optional)'),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('None')),
                ...availableTasks.map((t) => DropdownMenuItem<int?>(value: t.id, child: Text(t.title))),
              ],
              onChanged: _isSaving ? null : (value) {
                setState(() => _selectedBlocker = value);
              },
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String?>(
              initialValue: _selectedRecurringType,
              decoration: const InputDecoration(labelText: 'Recurring (Optional)'),
              items: const [
                DropdownMenuItem(value: null, child: Text('None')),
                DropdownMenuItem(value: 'Daily', child: Text('Daily')),
                DropdownMenuItem(value: 'Weekly', child: Text('Weekly')),
              ],
              onChanged: _isSaving ? null : (value) {
                setState(() => _selectedRecurringType = value);
              },
            ),
          ],
        ),
      ),
      ),      ),      actions: [
        TextButton(
          onPressed: _isSaving ? null : () {
            if (!_isEdit) {
              // Optionally we can keep the draft around, or save it on cancel
              _saveDraftIfFormOpen();
            }
            Navigator.pop(context, false);
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving || !_validateForm() ? null : _handleSave,
          child: _isSaving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(_isEdit ? 'Update' : 'Create'),
        ),
      ],
    );
  }
}


