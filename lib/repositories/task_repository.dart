import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:task_flow/models/task.dart';
import 'package:task_flow/models/task_draft.dart';

/// TaskRepository handles all database operations for tasks
///
/// This repository pattern provides a clean separation between
/// the data layer (Isar database) and the business logic layer (providers).
///
/// All create and update operations include a 2-second artificial delay
/// to simulate network latency, as per assignment requirements.
class TaskRepository {
  /// Isar database instance
  late Isar _isar;

  /// Singleton pattern for repository
  static final TaskRepository _instance = TaskRepository._internal();
  factory TaskRepository() => _instance;
  TaskRepository._internal();

  /// Initialize the Isar database
  ///
  /// Must be called before any database operations.
  /// Opens the Isar database in the application documents directory.
  ///
  /// Example:
  /// ```dart
  /// final repo = TaskRepository();
  /// await repo.initialize();
  /// ```
  Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [TaskSchema, TaskDraftSchema],
      directory: dir.path,
    );
  }

  // =============================
  // CRUD Operations for Tasks
  // =============================

  /// Create a new task in the database
  ///
  /// Includes a 2-second delay to simulate network latency.
  /// Returns the ID of the newly created task.
  ///
  /// Example:
  /// ```dart
  /// final task = Task()
  ///   ..title = 'Buy groceries'
  ///   ..description = 'Milk, eggs, bread'
  ///   ..dueDate = DateTime.now().add(Duration(days: 1))
  ///   ..status = TaskStatus.todo.name
  ///   ..sortOrder = 0
  ///   ..createdAt = DateTime.now()
  ///   ..updatedAt = DateTime.now();
  ///
  /// final id = await repository.createTask(task);
  /// print('Created task with ID: $id');
  /// ```

  Future<int> createTask(Task task) async {
    // Simulate network delay (assignment requirement)
    await Future.delayed(const Duration(seconds: 2));

    // Ensure timestamps are set
    task.createdAt = DateTime.now();
    task.updatedAt = DateTime.now();

    // Save to database in a write transaction
    final id = await _isar.writeTxn(() async {
      return await _isar.tasks.put(task);
    });

    return id;
  }

  /// Get all tasks from the database
  ///
  /// Returns tasks sorted by creation date (newest first).
  ///
  /// Example:
  /// ```dart
  /// final tasks = await repository.getAllTasks();
  /// print('Found ${tasks.length} tasks');
  /// ```
  Future<List<Task>> getAllTasks() async {
    return await _isar.tasks.where().sortByCreatedAtDesc().findAll();
  }

  /// Get a single task by ID
  ///
  /// Returns null if task not found.
  ///
  /// Example:
  /// ```dart
  /// final task = await repository.getTaskById(1);
  /// if (task != null) {
  ///   print('Found task: ${task.title}');
  /// }
  /// ```
  Future<Task?> getTaskById(int id) async {
    return await _isar.tasks.get(id);
  }

  /// Update an existing task
  ///
  /// Includes a 2-second delay to simulate network latency.
  /// Updates the `updatedAt` timestamp automatically.
  ///
  /// Example:
  /// ```dart
  /// task.title = 'Updated title';
  /// await repository.updateTask(task);
  /// ```
  Future<void> updateTask(Task task) async {
    // Simulate network delay (assignment requirement)
    await Future.delayed(const Duration(seconds: 2));

    // Update timestamp
    task.updatedAt = DateTime.now();

    // Save to database
    await _isar.writeTxn(() async {
      await _isar.tasks.put(task);
    });
  }

  /// Delete a task by ID
  ///
  /// Example:
  /// ```dart
  /// await repository.deleteTask(1);
  /// ```
  Future<void> deleteTask(int id) async {
    await _isar.writeTxn(() async {
      await _isar.tasks.delete(id);
    });
  }

  /// Delete multiple tasks at once
  ///
  /// More efficient than deleting one by one.
  ///
  /// Example:
  /// ```dart
  /// await repository.deleteTasks([1, 2, 3]);
  /// ```
  Future<void> deleteTasks(List<int> ids) async {
    await _isar.writeTxn(() async {
      await _isar.tasks.deleteAll(ids);
    });
  }

  // =============================
  // Search and Filter Operations
  // =============================

  /// Search tasks by title or description
  ///
  /// Case-insensitive search that matches partial strings.
  /// Thanks to @Index() annotations, this is very fast even with many tasks.
  ///
  /// Example:
  /// ```dart
  /// final results = await repository.searchTasks('meeting');
  /// // Returns all tasks with 'meeting' in title or description
  /// ```
  Future<List<Task>> searchTasks(String query) async {
    if (query.isEmpty) {
      return await getAllTasks();
    }

    final lowerQuery = query.toLowerCase();

    return await _isar.tasks
        .filter()
        .titleContains(lowerQuery, caseSensitive: false)
        .or()
        .descriptionContains(lowerQuery, caseSensitive: false)
        .sortByCreatedAtDesc()
        .findAll();
  }

  /// Filter tasks by status
  ///
  /// Example:
  /// ```dart
  /// final todoTasks = await repository.filterByStatus(TaskStatus.todo);
  /// final doneTasks = await repository.filterByStatus(TaskStatus.done);
  /// ```
  Future<List<Task>> filterByStatus(TaskStatus status) async {
    return await _isar.tasks
        .filter()
        .statusEqualTo(status.name)
        .sortByCreatedAtDesc()
        .findAll();
  }

  /// Get tasks that are blocked by a specific task
  ///
  /// Useful to find which tasks depend on completion of another task.
  ///
  /// Example:
  /// ```dart
  /// final blockedTasks = await repository.getTasksBlockedBy(5);
  /// // Returns all tasks where blockedBy == 5
  /// ```
  Future<List<Task>> getTasksBlockedBy(int taskId) async {
    return await _isar.tasks.filter().blockedByEqualTo(taskId).findAll();
  }

  /// Get all tasks that are currently blocked
  ///
  /// Returns tasks where blockedBy is not null.
  ///
  /// Example:
  /// ```dart
  /// final blockedTasks = await repository.getBlockedTasks();
  /// ```
  Future<List<Task>> getBlockedTasks() async {
    return await _isar.tasks.filter().blockedByIsNotNull().findAll();
  }

  // =============================
  // Draft Persistence Operations
  // =============================

  /// Save form data as a draft
  ///
  /// Always uses ID 0 - only one draft exists at a time.
  /// Overwrites previous draft automatically.
  ///
  /// Example:
  /// ```dart
  /// final draft = TaskDraft()
  ///   ..title = 'Buy groceries'
  ///   ..description = 'Partial description...'
  ///   ..updatedAt = DateTime.now();
  ///
  /// await repository.saveDraft(draft);
  /// ```
  Future<void> saveDraft(TaskDraft draft) async {
    draft.id = 0; // Always use ID 0
    draft.updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.taskDrafts.put(draft);
    });
  }

  /// Get the current draft
  ///
  /// Returns null if no draft exists.
  ///
  /// Example:
  /// ```dart
  /// final draft = await repository.getDraft();
  /// if (draft != null && draft.hasData) {
  ///   // Pre-fill form with draft data
  ///   titleController.text = draft.title ?? '';
  /// }
  /// ```
  Future<TaskDraft?> getDraft() async {
    return await _isar.taskDrafts.get(0);
  }

  /// Clear the current draft
  ///
  /// Called after successful task creation to clean up.
  ///
  /// Example:
  /// ```dart
  /// await repository.createTask(task);
  /// await repository.clearDraft(); // Clean up
  /// ```
  Future<void> clearDraft() async {
    await _isar.writeTxn(() async {
      await _isar.taskDrafts.delete(0);
    });
  }

  /// Check if a draft exists
  ///
  /// Example:
  /// ```dart
  /// final hasDraft = await repository.hasDraft();
  /// if (hasDraft) {
  ///   // Show "Resume draft" button
  /// }
  /// ```
  Future<bool> hasDraft() async {
    final draft = await getDraft();
    return draft != null && draft.hasData;
  }

  // =============================
  // Utility Operations
  // =============================

  /// Get count of tasks by status
  ///
  /// Useful for dashboard/statistics.
  ///
  /// Example:
  /// ```dart
  /// final todoCount = await repository.getTaskCountByStatus(TaskStatus.todo);
  /// final doneCount = await repository.getTaskCountByStatus(TaskStatus.done);
  /// ```
  Future<int> getTaskCountByStatus(TaskStatus status) async {
    return await _isar.tasks.filter().statusEqualTo(status.name).count();
  }

  /// Get total task count
  ///
  /// Example:
  /// ```dart
  /// final total = await repository.getTotalTaskCount();
  /// ```
  Future<int> getTotalTaskCount() async {
    return await _isar.tasks.count();
  }

  /// Clear all tasks (dangerous!)
  ///
  /// Only use for testing or reset functionality.
  ///
  /// Example:
  /// ```dart
  /// await repository.clearAllTasks();
  /// ```
  Future<void> clearAllTasks() async {
    await _isar.writeTxn(() async {
      await _isar.tasks.clear();
    });
  }

  /// Watch tasks for real-time updates
  ///
  /// Returns a stream that emits whenever tasks change.
  /// Useful for reactive UI updates.
  ///
  /// Example:
  /// ```dart
  /// repository.watchTasks().listen((tasks) {
  ///   print('Tasks changed! New count: ${tasks.length}');
  ///   // Update UI
  /// });
  /// ```
  Stream<List<Task>> watchTasks() {
    return _isar.tasks.where().sortByCreatedAtDesc().watch(fireImmediately: true);
  }

  /// Close the database
  ///
  /// Call this when the app is shutting down (rarely needed).
  ///
  /// Example:
  /// ```dart
  /// await repository.close();
  /// ```
  Future<void> close() async {
    await _isar.close();
  }
}
