import 'package:isar/isar.dart';

part 'task_draft.g.dart';

/// TaskDraft model for persisting unsaved task form data across app restarts
@collection
class TaskDraft {
  Id id = Isar.autoIncrement;

  String? title;
  String? description;
  DateTime? dueDate;
  String? status;
  int? blockedBy;
  late DateTime updatedAt;

  TaskDraft();

  @ignore
  bool get hasData {
    return (title != null && title!.isNotEmpty) ||
        (description != null && description!.isNotEmpty) ||
        dueDate != null ||
        status != null ||
        blockedBy != null;
  }

  @ignore
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
