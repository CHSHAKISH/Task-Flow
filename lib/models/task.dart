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
class Task {
  int? id;
  late String title;
  late String description;
  late DateTime dueDate;
  late String status;
  int? blockedBy;
  late int sortOrder;
  late DateTime createdAt;
  late DateTime updatedAt;

  Task();

  TaskStatus get statusEnum => TaskStatus.fromString(status);
  set statusEnum(TaskStatus value) {
    status = value.name;
  }

  bool get isBlocked => blockedBy != null;
  bool get isCompleted => statusEnum == TaskStatus.done;

  @override
  String toString() {
    return 'Task(id: $id, title: $title, status: $status, dueDate: $dueDate, blockedBy: $blockedBy)';
  }
}
