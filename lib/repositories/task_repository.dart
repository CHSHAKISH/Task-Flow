import 'package:task_flow/models/task.dart';
import 'package:task_flow/models/task_draft.dart';

/// TaskRepository handles all database operations for tasks
/// Currently uses in-memory storage for simplicity
class TaskRepository {
  /// In-memory storage
  final Map<int, Task> _tasks = {};
  TaskDraft? _draft;
  int _nextId = 1;

  /// Singleton pattern
  static final TaskRepository _instance = TaskRepository._internal();
  factory TaskRepository() => _instance;
  TaskRepository._internal();

  /// Initialize (no-op for in-memory)
  Future<void> initialize() async {
    // Already initialized
  }

  /// Create a new task (with 2-second delay)
  Future<int> createTask(Task task) async {
    await Future.delayed(const Duration(seconds: 2));
    task.id = _nextId++;
    task.createdAt = DateTime.now();
    task.updatedAt = DateTime.now();
    _tasks[task.id!] = task;
    return task.id!;
  }

  /// Get all tasks
  Future<List<Task>> getAllTasks() async {
    final tasks = _tasks.values.toList();
    tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return tasks;
  }

  /// Get a single task by ID
  Future<Task?> getTaskById(int id) async {
    return _tasks[id];
  }

  /// Update an existing task (with 2-second delay)
  Future<void> updateTask(Task task) async {
    await Future.delayed(const Duration(seconds: 2));
    task.updatedAt = DateTime.now();
    _tasks[task.id!] = task;
  }

  /// Delete a task
  Future<void> deleteTask(int id) async {
    _tasks.remove(id);
  }

  /// Delete multiple tasks
  Future<void> deleteTasks(List<int> ids) async {
    for (final id in ids) {
      _tasks.remove(id);
    }
  }

  /// Search tasks
  Future<List<Task>> searchTasks(String query) async {
    if (query.isEmpty) {
      return await getAllTasks();
    }
    final lowerQuery = query.toLowerCase();
    final tasks = _tasks.values
        .where((task) =>
            task.title.toLowerCase().contains(lowerQuery) ||
            task.description.toLowerCase().contains(lowerQuery))
        .toList();
    tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return tasks;
  }

  /// Filter by status
  Future<List<Task>> filterByStatus(TaskStatus status) async {
    final tasks = _tasks.values
        .where((task) => task.status == status.name)
        .toList();
    tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return tasks;
  }

  /// Get tasks blocked by
  Future<List<Task>> getTasksBlockedBy(int taskId) async {
    return _tasks.values
        .where((task) => task.blockedBy == taskId)
        .toList();
  }

  /// Get blocked tasks
  Future<List<Task>> getBlockedTasks() async {
    return _tasks.values.where((task) => task.isBlocked).toList();
  }

  /// Save draft
  Future<void> saveDraft(TaskDraft draft) async {
    draft.id = 0;
    draft.updatedAt = DateTime.now();
    _draft = draft;
  }

  /// Get draft
  Future<TaskDraft?> getDraft() async {
    return _draft;
  }

  /// Clear draft
  Future<void> clearDraft() async {
    _draft = null;
  }

  /// Has draft
  Future<bool> hasDraft() async {
    return _draft != null && _draft!.hasData;
  }

  /// Get task count by status
  Future<int> getTaskCountByStatus(TaskStatus status) async {
    return _tasks.values
        .where((task) => task.status == status.name)
        .length;
  }

  /// Get total count
  Future<int> getTotalTaskCount() async {
    return _tasks.length;
  }

  /// Clear all
  Future<void> clearAllTasks() async {
    _tasks.clear();
  }

  /// Close
  Future<void> close() async {
    // No-op for in-memory
  }
}
