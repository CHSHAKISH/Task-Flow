import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_flow/repositories/task_repository.dart';
import 'package:task_flow/models/task.dart';
import 'package:task_flow/models/task_draft.dart';
import 'package:task_flow/widgets/task_form_dialog.dart';

void main() async {
  // Initialize repository before running app
  final repository = TaskRepository();
  await repository.initialize();

  runApp(
    ProviderScope(
      child: const TaskFlowApp(),
    ),
  );
}

class TaskFlowApp extends StatelessWidget {
  const TaskFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Flow',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const TaskListScreen(),
    );
  }
}

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final _repository = TaskRepository();
  late Future<List<Task>> _tasksFuture;

  // Search and filter state
  final _searchController = TextEditingController();
  String _searchQuery = '';
  TaskStatus? _selectedFilter;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    
    _loadTasks();
    _checkForDraft();
  }

  @override
  void dispose() {
    
    _searchController.dispose();
    _debounce?.cancel();
    
    super.dispose();
  }



  void _loadTasks() {
    _tasksFuture = _repository.getAllTasks();
  }

  void _performSearch(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isEmpty && _selectedFilter == null) {
        setState(() {
          _tasksFuture = _repository.getAllTasks();
        });
      } else if (query.isNotEmpty) {
        setState(() {
          _tasksFuture = _repository.searchTasks(query);
        });
      } else if (_selectedFilter != null) {
        setState(() {
          _tasksFuture = _repository.filterByStatus(_selectedFilter!);
        });
      }
    });
  }

  void _applyFilter(TaskStatus? status) {
    setState(() {
      _selectedFilter = status;
      if (status == null && _searchQuery.isEmpty) {
        _tasksFuture = _repository.getAllTasks();
      } else if (_searchQuery.isNotEmpty) {
        _performSearch(_searchQuery);
      } else if (status != null) {
        _tasksFuture = _repository.filterByStatus(status);
      }
    });
  }

  bool _isTaskBlocked(Task task, List<Task> allTasks) {
    if (task.blockedBy == null) return false;

    try {
      final blockingTask = allTasks.firstWhere(
        (t) => t.id == task.blockedBy,
      );
      return !blockingTask.isCompleted;
    } catch (e) {
      // Blocking task not found (might have been deleted)
      return false;
    }
  }

  String? _getBlockerTitle(Task task, List<Task> allTasks) {
    if (task.blockedBy == null) return null;

    try {
      final blockingTask = allTasks.firstWhere(
        (t) => t.id == task.blockedBy,
      );
      return blockingTask.title;
    } catch (e) {
      return 'Unknown task';
    }
  }

  Future<void> _checkForDraft() async {
    final hasDraft = await _repository.hasDraft();
    if (!hasDraft || !mounted) return;

    final draft = await _repository.getDraft();
    if (draft == null || !mounted) return;

    // Check if draft is recent (within 24 hours)
    final now = DateTime.now();
    final draftAge = now.difference(draft.updatedAt);
    if (draftAge.inHours > 24) {
      // Draft too old, clear it
      await _repository.clearDraft();
      return;
    }

    // Show resume dialog
    final shouldResume = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resume Draft?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('You have an unsaved task draft:'),
            const SizedBox(height: 8),
            Text(
              draft.title ?? 'Untitled',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (draft.description != null && draft.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                draft.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Created ${_formatDraftAge(draftAge)} ago',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _repository.clearDraft();
              Navigator.pop(context, false);
            },
            child: const Text('Discard'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Resume'),
          ),
        ],
      ),
    );

    if (shouldResume == true && mounted) {
      _showCreateTaskDialog(loadDraft: draft);
    }
  }

  String _formatDraftAge(Duration age) {
    if (age.inMinutes < 1) return 'just now';
    if (age.inMinutes < 60) return '${age.inMinutes} minute${age.inMinutes > 1 ? 's' : ''}';
    if (age.inHours < 24) return '${age.inHours} hour${age.inHours > 1 ? 's' : ''}';
    return '${age.inDays} day${age.inDays > 1 ? 's' : ''}';
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Flow'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search tasks...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                          _performSearch('');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _performSearch(value);
              },
            ),
          ),
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _selectedFilter == null,
                  onSelected: (selected) {
                    if (selected) _applyFilter(null);
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('To Do'),
                  selected: _selectedFilter == TaskStatus.todo,
                  onSelected: (selected) {
                    _applyFilter(selected ? TaskStatus.todo : null);
                  },
                  avatar: Icon(
                    Icons.circle,
                    size: 12,
                    color: _selectedFilter == TaskStatus.todo
                        ? Colors.white
                        : Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('In Progress'),
                  selected: _selectedFilter == TaskStatus.inProgress,
                  onSelected: (selected) {
                    _applyFilter(selected ? TaskStatus.inProgress : null);
                  },
                  avatar: Icon(
                    Icons.circle,
                    size: 12,
                    color: _selectedFilter == TaskStatus.inProgress
                        ? Colors.white
                        : Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Done'),
                  selected: _selectedFilter == TaskStatus.done,
                  onSelected: (selected) {
                    _applyFilter(selected ? TaskStatus.done : null);
                  },
                  avatar: Icon(
                    Icons.circle,
                    size: 12,
                    color: _selectedFilter == TaskStatus.done
                        ? Colors.white
                        : Colors.green,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Task List
          Expanded(
            child: FutureBuilder<List<Task>>(
              future: _tasksFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final tasks = snapshot.data ?? [];

                if (tasks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.inbox,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty || _selectedFilter != null
                              ? 'No tasks found'
                              : 'No tasks yet',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isNotEmpty || _selectedFilter != null
                              ? 'Try adjusting your search or filter'
                              : 'Create your first task to get started',
                        ),
                        if (_searchQuery.isEmpty && _selectedFilter == null) ...[
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _showCreateTaskDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Create Task'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      _loadTasks();
                    });
                  },
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                final isBlocked = _isTaskBlocked(task, tasks);
                final blockerTitle = _getBlockerTitle(task, tasks);

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
                    confirmDismiss: (direction) => _confirmDelete(task),
                    onDismissed: (direction) => _deleteTask(task),
                    child: Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        onTap: isBlocked ? null : () => _showEditTaskDialog(task),
                        leading: isBlocked
                            ? const Icon(
                                Icons.lock_outline,
                                color: Colors.grey,
                                size: 32,
                              )
                            : Checkbox(
                                value: task.isCompleted,
                                onChanged: (value) {
                                  // Quick toggle status
                                  if (value == true) {
                                    task.statusEnum = TaskStatus.done;
                                  } else {
                                    task.statusEnum = TaskStatus.todo;
                                  }
                                  _repository.updateTask(task);
                                  setState(() {
                                    _loadTasks();
                                  });
                                },
                              ),
                        title: Text(
                          task.title,
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
                              : _getStatusColor(task.statusEnum),
                          labelStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateTaskDialog,
        tooltip: 'Add Task',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateTaskDialog({TaskDraft? loadDraft}) {
    final titleController = TextEditingController(text: loadDraft?.title ?? '');
    final descriptionController = TextEditingController(text: loadDraft?.description ?? '');
    DateTime? selectedDate = loadDraft?.dueDate;

    // Store in state for draft persistence
    _draftTitleController = titleController;
    _draftDescriptionController = descriptionController;
    _draftSelectedDate = selectedDate;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(loadDraft != null ? 'Resume Draft' : 'Create New Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _draftTitleController = titleController;
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  minLines: 2,
                  maxLines: 4,
                  onChanged: (value) {
                    setState(() {
                      _draftDescriptionController = descriptionController;
                    });
                  },
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: Text(
                    selectedDate == null
                        ? 'Select due date'
                        : 'Due: ${selectedDate!.toLocal().toString().split(' ')[0]}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setDialogState(() {
                        selectedDate = date;
                        _draftSelectedDate = date;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Clear draft when canceling
                _draftTitleController = null;
                _draftDescriptionController = null;
                _draftSelectedDate = null;
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _createTask(
                titleController,
                descriptionController,
                selectedDate,
                dialogContext,
              ),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
      barrierDismissible: false, // Prevent accidental dismissal
    ).then((_) {
      // Clear draft form references when dialog closes
      _draftTitleController = null;
      _draftDescriptionController = null;
      _draftSelectedDate = null;
    });
  }

  Future<void> _createTask(
    TextEditingController titleController,
    TextEditingController descriptionController,
    DateTime? selectedDate,
    BuildContext dialogContext,
  ) async {
    if (titleController.text.isEmpty ||
        descriptionController.text.isEmpty ||
        selectedDate == null) {
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Close the dialog
    Navigator.pop(dialogContext);

    // Show loading message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Creating task... (2 second delay)'),
        duration: Duration(seconds: 3),
      ),
    );

    // Create task
    final task = Task()
      ..title = titleController.text
      ..description = descriptionController.text
      ..dueDate = selectedDate
      ..status = TaskStatus.todo.name
      ..sortOrder = 0;

    // Save (includes 2-second delay)
    try {
      await _repository.createTask(task);

      // Clear draft after successful creation
      await _repository.clearDraft();
      _draftTitleController = null;
      _draftDescriptionController = null;
      _draftSelectedDate = null;

      if (mounted) {
        // Refresh UI
        setState(() {
          _loadTasks();
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task created successfully!'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating task: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<bool?> _confirmDelete(Task task) async {
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

  Future<void> _deleteTask(Task task) async {
    try {
      await _repository.deleteTask(task.id!);

      if (mounted) {
        setState(() {
          _loadTasks();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task "${task.title}" deleted'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting task: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showEditTaskDialog(Task task) async {
    final titleController = TextEditingController(text: task.title);
    final descriptionController = TextEditingController(text: task.description);
    DateTime? selectedDate = task.dueDate;
    TaskStatus selectedStatus = task.statusEnum;
    int? selectedBlocker = task.blockedBy;

    // Get all tasks for blocked-by dropdown
    final allTasks = await _repository.getAllTasks();
    final availableTasks = allTasks.where((t) => t.id != task.id).toList();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  minLines: 2,
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: Text(
                    selectedDate == null
                        ? 'Select due date'
                        : 'Due: ${selectedDate!.toLocal().toString().split(' ')[0]}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setDialogState(() {
                        selectedDate = date;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<TaskStatus>(
                  value: selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: TaskStatus.values.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(status.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() {
                        selectedStatus = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  value: selectedBlocker,
                  decoration: const InputDecoration(
                    labelText: 'Blocked By (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('None'),
                    ),
                    ...availableTasks.map((t) {
                      return DropdownMenuItem<int?>(
                        value: t.id,
                        child: Text(t.title),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedBlocker = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _updateTask(
                task,
                titleController,
                descriptionController,
                selectedDate,
                selectedStatus,
                selectedBlocker,
                dialogContext,
              ),
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateTask(
    Task task,
    TextEditingController titleController,
    TextEditingController descriptionController,
    DateTime? selectedDate,
    TaskStatus selectedStatus,
    int? selectedBlocker,
    BuildContext dialogContext,
  ) async {
    if (titleController.text.isEmpty ||
        descriptionController.text.isEmpty ||
        selectedDate == null) {
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Close the dialog
    Navigator.pop(dialogContext);

    // Show loading message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Updating task... (2 second delay)'),
        duration: Duration(seconds: 3),
      ),
    );

    // Update task
    task.title = titleController.text;
    task.description = descriptionController.text;
    task.dueDate = selectedDate;
    task.statusEnum = selectedStatus;
    task.blockedBy = selectedBlocker;

    // Save (includes 2-second delay)
    try {
      await _repository.updateTask(task);

      if (mounted) {
        // Refresh UI
        setState(() {
          _loadTasks();
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task updated successfully!'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating task: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return Colors.orange;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.done:
        return Colors.green;
    }
  }
}
