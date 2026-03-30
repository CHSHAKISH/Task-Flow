/// TaskDraft model for persisting unsaved task form data
class TaskDraft {
  int id = 0;
  String? title;
  String? description;
  DateTime? dueDate;
  String? status;
  int? blockedBy;
  late DateTime updatedAt;

  TaskDraft();

  bool get hasData {
    return title != null ||
        description != null ||
        dueDate != null ||
        status != null ||
        blockedBy != null;
  }

  bool get isRecent {
    final now = DateTime.now();
    final difference = now.difference(updatedAt);
    return difference.inHours < 24;
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
      'status': status,
      'blockedBy': blockedBy,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory TaskDraft.fromJson(Map<String, dynamic> json) {
    final draft = TaskDraft()
      ..id = json['id'] as int? ?? 0
      ..title = json['title'] as String?
      ..description = json['description'] as String?
      ..dueDate = json['dueDate'] != null ? DateTime.parse(json['dueDate'] as String) : null
      ..status = json['status'] as String?
      ..blockedBy = json['blockedBy'] as int?
      ..updatedAt = DateTime.parse(json['updatedAt'] as String);
    return draft;
  }

  @override
  String toString() {
    return 'TaskDraft(title: $title, status: $status, hasData: $hasData, updatedAt: $updatedAt)';
  }
}
