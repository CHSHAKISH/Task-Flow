import 'package:isar/isar.dart';

part 'task.g.dart';

/// TaskStatus enum represents the three states a task can be in
enum TaskStatus {
  todo,        // Task not started yet
  inProgress,  // Task currently being worked on
  done;        // Task completed

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
@collection
class Task {
  Id id = Isar.autoIncrement;

  late String title;
  late String description;
  late DateTime dueDate;

  /// Status stored as a String ('todo', 'inProgress', 'done')
  late String status;

  int? blockedBy;
  late int sortOrder;

  @Index()
  late DateTime createdAt;
  late DateTime updatedAt;

  Task();

  /// Computed getter – ignored by Isar schema generator
  @ignore
  TaskStatus get statusEnum => TaskStatus.fromString(status);

  set statusEnum(TaskStatus value) {
    status = value.name;
  }

  /// Computed getters – ignored by Isar
  @ignore
  bool get isBlocked => blockedBy != null;

  @ignore
  bool get isCompleted => statusEnum == TaskStatus.done;

  @override
  String toString() {
    return 'Task(id: $id, title: $title, status: $status, dueDate: $dueDate, blockedBy: $blockedBy)';
  }
}
