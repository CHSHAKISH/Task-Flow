import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:task_flow/models/task.dart';
import 'package:task_flow/models/task_draft.dart';

/// TaskRepository handles all database operations for tasks using Isar
class TaskRepository {
  late Isar _isar;

  /// Singleton pattern
  static final TaskRepository _instance = TaskRepository._internal();
  factory TaskRepository() => _instance;
  TaskRepository._internal();

  /// Open the Isar database
  Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [TaskSchema, TaskDraftSchema],
      directory: dir.path,
      name: 'task_flow_db',
    );
  }

  /// Get the Isar instance (for advanced queries if needed)
  Isar get isar => _isar;

  // ─────────────────────────────────── TASKS ────────────────────────────────

  /// Create a new task (with 2-second simulated delay)
  Future<int> createTask(Task task) async {
    await Future.delayed(const Duration(seconds: 2));
    task.createdAt = DateTime.now();
    task.updatedAt = DateTime.now();
    await _isar.writeTxn(() async {
      task.id = await _isar.tasks.put(task);
    });
    return task.id;
  }

  /// Get all tasks sorted by creation date descending
  Future<List<Task>> getAllTasks() async {
    return _isar.tasks.where().sortByCreatedAtDesc().findAll();
  }

  /// Get a single task by ID
  Future<Task?> getTaskById(int id) async {
    return _isar.tasks.get(id);
  }

  /// Update an existing task (with 2-second simulated delay)
  Future<void> updateTask(Task task) async {
    await Future.delayed(const Duration(seconds: 2));
    task.updatedAt = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.tasks.put(task);
    });
  }

  /// Delete a task by ID
  Future<void> deleteTask(int id) async {
    await _isar.writeTxn(() async {
      await _isar.tasks.delete(id);
    });
  }

  /// Delete multiple tasks
  Future<void> deleteTasks(List<int> ids) async {
    await _isar.writeTxn(() async {
      await _isar.tasks.deleteAll(ids);
    });
  }

  /// Search tasks by title or description (case-insensitive)
  Future<List<Task>> searchTasks(String query) async {
    if (query.isEmpty) return getAllTasks();
    final lower = query.toLowerCase();
    final all = await getAllTasks();
    return all
        .where((t) =>
            t.title.toLowerCase().contains(lower) ||
            t.description.toLowerCase().contains(lower))
        .toList();
  }

  /// Filter tasks by status
  Future<List<Task>> filterByStatus(TaskStatus status) async {
    return _isar.tasks
        .where()
        .filter()
        .statusEqualTo(status.name)
        .sortByCreatedAtDesc()
        .findAll();
  }

  /// Get tasks blocked by a specific task
  Future<List<Task>> getTasksBlockedBy(int taskId) async {
    return _isar.tasks
        .where()
        .filter()
        .blockedByEqualTo(taskId)
        .findAll();
  }

  /// Get task count by status
  Future<int> getTaskCountByStatus(TaskStatus status) async {
    return _isar.tasks
        .where()
        .filter()
        .statusEqualTo(status.name)
        .count();
  }

  /// Get total task count
  Future<int> getTotalTaskCount() async {
    return _isar.tasks.count();
  }

  /// Clear all tasks
  Future<void> clearAllTasks() async {
    await _isar.writeTxn(() async {
      await _isar.tasks.clear();
    });
  }

  // ────────────────────────────────── DRAFTS ────────────────────────────────

  /// Save (upsert) the current draft
  Future<void> saveDraft(TaskDraft draft) async {
    draft.updatedAt = DateTime.now();
    await _isar.writeTxn(() async {
      // Always use id=1 so there's only ever one draft
      draft.id = 1;
      await _isar.taskDrafts.put(draft);
    });
  }

  /// Get the current draft
  Future<TaskDraft?> getDraft() async {
    return _isar.taskDrafts.get(1);
  }

  /// Check if a draft with data exists
  Future<bool> hasDraft() async {
    final draft = await getDraft();
    return draft != null && draft.hasData;
  }

  /// Clear the current draft
  Future<void> clearDraft() async {
    await _isar.writeTxn(() async {
      await _isar.taskDrafts.delete(1);
    });
  }

  /// Close the Isar instance
  Future<void> close() async {
    await _isar.close();
  }
}
