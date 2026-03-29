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

  @override
  String toString() {
    return 'TaskDraft(title: $title, status: $status, hasData: $hasData, updatedAt: $updatedAt)';
  }
}
