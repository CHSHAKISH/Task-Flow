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
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87), // High contrast text
        backgroundColor: Colors.grey.shade100, // Light gray for normal state
        selectedColor: Colors.blue.withAlpha(40), // Tint for selected
        checkmarkColor: Colors.blue, // Blue checkmark instead of white to stick out
        side: const BorderSide(color: Colors.transparent), // Remove outline entirely
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), // Softer borders
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.blue.shade300, width: 1.5),
        ),
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
