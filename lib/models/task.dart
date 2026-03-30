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

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'status': status,
      'blockedBy': blockedBy,
      'sortOrder': sortOrder,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    final task = Task()
      ..id = json['id'] as int?
      ..title = json['title'] as String
      ..description = json['description'] as String
      ..dueDate = DateTime.parse(json['dueDate'] as String)
      ..status = json['status'] as String
      ..blockedBy = json['blockedBy'] as int?
      ..sortOrder = json['sortOrder'] as int
      ..createdAt = DateTime.parse(json['createdAt'] as String)
      ..updatedAt = DateTime.parse(json['updatedAt'] as String);
    return task;
  }

  @override
  String toString() {
    return 'Task(id: $id, title: $title, status: $status, dueDate: $dueDate, blockedBy: $blockedBy)';
  }
}
