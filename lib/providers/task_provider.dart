import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_flow/models/task.dart';
import 'package:task_flow/repositories/task_repository.dart';

/// Repository provider (singleton)
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository();
});

/// Search query state provider
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Selected filter status provider
final selectedFilterProvider = StateProvider<TaskStatus?>((ref) => null);

/// Tasks provider with search and filter applied
final tasksProvider = FutureProvider<List<Task>>((ref) async {
  final repository = ref.watch(taskRepositoryProvider);
  final query = ref.watch(searchQueryProvider);
  final filter = ref.watch(selectedFilterProvider);

  // Apply search and filter
  if (query.isNotEmpty) {
    return repository.searchTasks(query);
  } else if (filter != null) {
    return repository.filterByStatus(filter);
  } else {
    return repository.getAllTasks();
  }
});

/// Helper methods for task operations
class TaskOperations {
  /// Check if a task is blocked by another task
  static bool isTaskBlocked(Task task, List<Task> allTasks) {
    if (task.blockedBy == null) return false;

    try {
      final blockingTask = allTasks.firstWhere(
        (t) => t.id == task.blockedBy,
      );
      return !blockingTask.isCompleted;
    } catch (e) {
      // Blocking task not found (might have been deleted)
      return false;
    }
  }

  /// Get the title of the task blocking this task
  static String? getBlockerTitle(Task task, List<Task> allTasks) {
    if (task.blockedBy == null) return null;

    try {
      final blockingTask = allTasks.firstWhere(
        (t) => t.id == task.blockedBy,
      );
      return blockingTask.title;
    } catch (e) {
      return 'Unknown task';
    }
  }

  /// Format draft age for display
  static String formatDraftAge(Duration age) {
    if (age.inMinutes < 1) return 'just now';
    if (age.inMinutes < 60) {
      return '${age.inMinutes} minute${age.inMinutes > 1 ? 's' : ''}';
    }
    if (age.inHours < 24) {
      return '${age.inHours} hour${age.inHours > 1 ? 's' : ''}';
    }
    return '${age.inDays} day${age.inDays > 1 ? 's' : ''}';
  }
}
