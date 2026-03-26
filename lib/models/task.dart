import 'package:isar/isar.dart';

part 'task.g.dart';

/// TaskStatus enum represents the three states a task can be in
enum TaskStatus {
  todo,        // Task not started yet
  inProgress,  // Task currently being worked on
  done;        // Task completed

  /// Convert string to TaskStatus enum
  /// Useful for storage and API communication
  static TaskStatus fromString(String value) {
    switch (value) {
      case 'inProgress':
        return TaskStatus.inProgress;
      case 'done':
        return TaskStatus.done;
      case 'todo':
      default:
        return TaskStatus.todo;
    }
  }

  /// Convert enum to display-friendly string
  String get displayName {
    switch (this) {
      case TaskStatus.todo:
        return 'To Do';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.done:
        return 'Done';
    }
  }
}

/// Task model represents a single task in the application
/// Uses Isar for local database storage with automatic indexing
@collection
class Task {
  /// Auto-incremented ID, managed by Isar
  /// null until saved to database
  Id? id;

  /// Task title - indexed for fast searching
  @Index()
  late String title;

  /// Detailed description of the task
  @Index()
  late String description;

  /// Due date for task completion
  late DateTime dueDate;

  /// Current status: 'todo', 'inProgress', or 'done'
  /// Stored as string for Isar compatibility
  @Index()
  late String status;

  /// Optional: ID of task that blocks this one
  /// If set, this task cannot be marked as done until blocker is done
  int? blockedBy;

  /// Sort order for manual reordering (drag & drop)
  /// Lower numbers appear first
  @Index()
  late int sortOrder;

  /// Timestamp when task was created
  late DateTime createdAt;

  /// Timestamp when task was last modified
  late DateTime updatedAt;

  /// Empty constructor for Isar
  Task();

  /// Get status as enum for type-safe operations
  @ignore
  TaskStatus get statusEnum => TaskStatus.fromString(status);

  /// Set status from enum
  set statusEnum(TaskStatus value) {
    status = value.name;
  }

  /// Check if task is blocked by another task
  @ignore
  bool get isBlocked => blockedBy != null;

  /// Check if task is completed
  @ignore
  bool get isCompleted => statusEnum == TaskStatus.done;

  /// Convert task to string representation (useful for debugging)
  @override
  String toString() {
    return 'Task(id: $id, title: $title, status: $status, dueDate: $dueDate, blockedBy: $blockedBy)';
  }
}
