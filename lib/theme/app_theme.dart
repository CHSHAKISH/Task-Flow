import 'package:flutter/material.dart';
import 'package:task_flow/models/task.dart';

/// AppTheme provides centralized theming for the Task Flow app
class AppTheme {
  static const primarySeed = Colors.blue;
  static const danger = Colors.red;

  /// Light theme configuration with Material Design 3
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      useMaterial3: true,

      // Card theme
      cardTheme: CardThemeData(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: const TextStyle(fontWeight: FontWeight.w500),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        filled: false,
      ),

      // App bar theme
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
    );
  }

  /// Get color for task status
  static Color getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return Colors.orange;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.done:
        return Colors.green;
    }
  }

  /// Get icon for task status
  static IconData getStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return Icons.circle_outlined;
      case TaskStatus.inProgress:
        return Icons.timelapse;
      case TaskStatus.done:
        return Icons.check_circle;
    }
  }
}
