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
    } else if (widget.draft != null) {
      _titleController = TextEditingController(text: widget.draft!.title);
      _descriptionController = TextEditingController(text: widget.draft!.description);
      _selectedDate = widget.draft!.dueDate;
      _selectedStatus = widget.draft!.status != null
          ? TaskStatus.fromString(widget.draft!.status!)
          : TaskStatus.todo;
      _selectedBlocker = widget.draft!.blockedBy;
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
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
        .toList();

    return AlertDialog(
      title: Text(_isEdit ? 'Edit Task' : (widget.draft != null ? 'Resume Draft' : 'Create New Task')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title *', border: OutlineInputBorder()),
              onChanged: (_) => setState(() {}),
              enabled: !_isSaving,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description *', border: OutlineInputBorder()),
              minLines: 2,
              maxLines: 4,
              onChanged: (_) => setState(() {}),
              enabled: !_isSaving,
            ),
            const SizedBox(height: 12),
            ListTile(
              title: Text(
                _selectedDate == null ? 'Select due date *' : 'Due: ${_selectedDate!.toLocal().toString().split(' ')[0]}',
                style: TextStyle(color: _selectedDate == null ? Colors.grey : null),
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: _isSaving ? null : _showDatePicker,
              shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(height: 12),
            if (_isEdit)
              DropdownButtonFormField<TaskStatus>(
                initialValue: _selectedStatus,
                decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                items: TaskStatus.values.map((status) => DropdownMenuItem(value: status, child: Text(status.displayName))).toList(),
                onChanged: _isSaving ? null : (value) {
                  if (value != null) setState(() => _selectedStatus = value);
                },
              ),
            if (_isEdit) const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              initialValue: _selectedBlocker,
              decoration: const InputDecoration(labelText: 'Blocked By (Optional)', border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('None')),
                ...availableTasks.map((t) => DropdownMenuItem<int?>(value: t.id, child: Text(t.title))),
              ],
              onChanged: _isSaving ? null : (value) {
                setState(() => _selectedBlocker = value);
              },
            ),
          ],
        ),
      ),
      actions: [
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
