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
  late String status;
  int? blockedBy;
  late int sortOrder;
  String? recurringType;
  late DateTime createdAt;
  late DateTime updatedAt;

  Task();

  @ignore
  TaskStatus get statusEnum => TaskStatus.fromString(status);
  
  set statusEnum(TaskStatus value) {
    status = value.name;
  }

  @ignore
  bool get isBlocked => blockedBy != null;
  
  @ignore
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
      'recurringType': recurringType,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    final task = Task()
      ..title = json['title'] as String
      ..description = json['description'] as String
      ..dueDate = DateTime.parse(json['dueDate'] as String)
      ..status = json['status'] as String
      ..blockedBy = json['blockedBy'] as int?
      ..sortOrder = json['sortOrder'] as int
      ..recurringType = json['recurringType'] as String?
      ..createdAt = DateTime.parse(json['createdAt'] as String)
      ..updatedAt = DateTime.parse(json['updatedAt'] as String);
    
    if (json['id'] != null) {
      task.id = json['id'] as int;
    }
    return task;
  }

  @override
  String toString() {
    return 'Task(id: $id, title: $title, status: $status, dueDate: $dueDate, blockedBy: $blockedBy, recurringType: $recurringType)';
  }
}
