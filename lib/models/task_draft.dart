import 'package:isar/isar.dart';

part 'task_draft.g.dart';

/// TaskDraft model for persisting unsaved task form data
///
/// When user is filling out task form and minimizes the app,
/// the form data is saved as a draft. When they return,
/// the form is pre-filled with the draft data.
///
/// Only one draft exists at a time (id is always 0)
@collection
class TaskDraft {
  /// Always 0 - we only keep one draft at a time
  /// Overwrites previous draft on each save
  Id id = 0;

  /// Task title from form (optional - user might not have typed yet  )
  String? title;

  /// Task description from form (optional)
  String? description;

  /// Due date selected in form (optional)
  DateTime? dueDate;

  /// Status selected in form (optional)
  /// Stored as string: 'todo', 'inProgress', or 'done'
  String? status;

  /// Blocked by task ID selected in form (optional)
  int? blockedBy;

  /// When this draft was last updated
  /// Helps determine if draft is stale
  late DateTime updatedAt;

  /// Empty constructor for Isar
  TaskDraft();

  /// Check if draft has any data
  /// Returns true if at least one field is filled
  @ignore
  bool get hasData {
    return title != null ||
        description != null ||
        dueDate != null ||
        status != null ||
        blockedBy != null;
  }

  /// Check if draft is recent (less than 24 hours old)
  /// Stale drafts might be cleared to avoid confusion
  @ignore
  bool get isRecent {
    final now = DateTime.now();
    final difference = now.difference(updatedAt);
    return difference.inHours < 24;
  }

  /// Convert draft to string representation (useful for debugging)
  @override
  String toString() {
    return 'TaskDraft(title: $title, status: $status, hasData: $hasData, updatedAt: $updatedAt)';
  }
}
