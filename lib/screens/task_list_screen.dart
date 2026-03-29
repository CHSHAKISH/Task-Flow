import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:task_flow/models/task.dart';
import 'package:task_flow/models/task_draft.dart';
import 'package:task_flow/providers/task_provider.dart';
import 'package:task_flow/repositories/task_repository.dart';
import 'package:task_flow/theme/app_theme.dart';
import 'package:task_flow/widgets/search_filter_bar.dart';
import 'package:task_flow/widgets/task_card.dart';
import 'package:task_flow/widgets/task_form_dialog.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen>
    with WidgetsBindingObserver {
  final _repository = TaskRepository();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Check for saved draft once rendered
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForDraft());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The TaskFormDialog handles its own draft saving via WidgetsBindingObserver
    // Nothing to do here at the screen level
  }

  // ─────────────────────── Draft Handling ─────────────────────────────────

  Future<void> _checkForDraft() async {
    if (!mounted) return;
    final hasDraft = await _repository.hasDraft();
    if (!hasDraft || !mounted) return;

    final draft = await _repository.getDraft();
    if (draft == null || !mounted) return;

    // Stale draft (>24h): silently discard
    if (!draft.isRecent) {
      await _repository.clearDraft();
      return;
    }

    final now = DateTime.now();
    final age = now.difference(draft.updatedAt);

    final shouldResume = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _DraftResumeDialog(draft: draft, age: age),
    );

    if (shouldResume == true && mounted) {
      final allTasks = await _repository.getAllTasks();
      if (mounted) _showCreateDialog(draft: draft, allTasks: allTasks);
    } else if (shouldResume == false) {
      await _repository.clearDraft();
    }
  }

  // ─────────────────────── Task Dialogs ───────────────────────────────────

  Future<void> _showCreateDialog({
    TaskDraft? draft,
    List<Task>? allTasks,
  }) async {
    final tasks = allTasks ?? await _repository.getAllTasks();
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => TaskFormDialog(
        draft: draft,
        allTasks: tasks,
        onSave: (task) async {
          await _repository.createTask(task);
          ref.invalidate(tasksProvider);
          if (mounted) {
            _showSnack('✅ Task created!', success: true);
          }
        },
      ),
    );
    ref.invalidate(tasksProvider);
  }

  Future<void> _showEditDialog(Task task) async {
    final allTasks = await _repository.getAllTasks();
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => TaskFormDialog(
        task: task,
        allTasks: allTasks,
        onSave: (updated) async {
          await _repository.updateTask(updated);
          ref.invalidate(tasksProvider);
          if (mounted) {
            _showSnack('✅ Task updated!', success: true);
          }
        },
      ),
    );
    ref.invalidate(tasksProvider);
  }

  // ─────────────────────── Task Actions ───────────────────────────────────

  Future<void> _deleteTask(Task task) async {
    await _repository.deleteTask(task.id);
    ref.invalidate(tasksProvider);
    if (mounted) _showSnack('🗑️ "${task.title}" deleted');
  }

  Future<void> _toggleComplete(Task task, bool? value) async {
    task.statusEnum = value == true ? TaskStatus.done : TaskStatus.todo;
    task.updatedAt = DateTime.now();
    // Quick toggle bypasses the 2-second simulated delay (delete also has no delay)
    await _repository.isar.writeTxn(() async {
      await _repository.isar.tasks.put(task);
    });
    ref.invalidate(tasksProvider);
  }

  void _showSnack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  // ─────────────────────── Build ───────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(searchQueryProvider);
    final selectedFilter = ref.watch(selectedFilterProvider);
    final tasksAsync = ref.watch(tasksProvider);

    return Scaffold(
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          SearchFilterBar(
            searchQuery: searchQuery,
            selectedFilter: selectedFilter,
            onSearchChanged: (q) =>
                ref.read(searchQueryProvider.notifier).state = q,
            onFilterChanged: (f) =>
                ref.read(selectedFilterProvider.notifier).state = f,
          ),
          Expanded(
            child: tasksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorState(error: e.toString()),
              data: (tasks) => _buildTaskList(tasks, searchQuery, selectedFilter),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        tooltip: 'New Task',
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primarySeed,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.task_alt_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          Text(
            'Task Flow',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: const Color(0xFF1A1A2E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(
    List<Task> tasks,
    String searchQuery,
    TaskStatus? selectedFilter,
  ) {
    if (tasks.isEmpty) {
      return _EmptyState(
        isFiltered: searchQuery.isNotEmpty || selectedFilter != null,
        onCreateTap: _showCreateDialog,
      );
    }

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(tasksProvider),
      color: AppTheme.primarySeed,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 4, bottom: 100),
        itemCount: tasks.length,
        itemBuilder: (ctx, i) {
          final task = tasks[i];
          final isBlocked = TaskOperations.isTaskBlocked(task, tasks);
          final blockerTitle = TaskOperations.getBlockerTitle(task, tasks);

          return TaskCard(
            key: ValueKey('task-${task.id}'),
            task: task,
            isBlocked: isBlocked,
            blockerTitle: blockerTitle,
            searchQuery: searchQuery,
            onTap: () => _showEditDialog(task),
            onDelete: () => _deleteTask(task),
            onCheckboxChanged: (v) => _toggleComplete(task, v),
          );
        },
      ),
    );
  }
}

// ─── Supporting Widgets ──────────────────────────────────────────────────────

class _DraftResumeDialog extends StatelessWidget {
  final TaskDraft draft;
  final Duration age;

  const _DraftResumeDialog({required this.draft, required this.age});

  String _formatAge() {
    if (age.inMinutes < 1) return 'just now';
    if (age.inMinutes < 60) {
      return '${age.inMinutes} minute${age.inMinutes > 1 ? 's' : ''} ago';
    }
    if (age.inHours < 24) {
      return '${age.inHours} hour${age.inHours > 1 ? 's' : ''} ago';
    }
    return '${age.inDays} day${age.inDays > 1 ? 's' : ''} ago';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.edit_note_rounded, size: 36, color: AppTheme.primarySeed),
      title: const Text('Unsaved Draft'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You have an unfinished task from ${_formatAge()}:',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  draft.title ?? 'Untitled',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                if (draft.description != null &&
                    draft.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    draft.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
          child: const Text('Discard'),
        ),
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(context, true),
          icon: const Icon(Icons.edit_rounded, size: 16),
          label: const Text('Resume'),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isFiltered;
  final VoidCallback onCreateTap;

  const _EmptyState({required this.isFiltered, required this.onCreateTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF0FF),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                isFiltered ? Icons.search_off_rounded : Icons.task_alt_rounded,
                size: 44,
                color: AppTheme.primarySeed,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isFiltered ? 'No tasks found' : 'All clear! 🎉',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isFiltered
                  ? 'Try adjusting your search or filter.'
                  : 'Create your first task to get started.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.grey.shade500,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            if (!isFiltered) ...[
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: onCreateTap,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create Task'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: AppTheme.danger),
            const SizedBox(height: 16),
            Text('Something went wrong',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 8),
            Text(error,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}
