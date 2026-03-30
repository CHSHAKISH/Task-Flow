import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_flow/repositories/task_repository.dart';
import 'package:task_flow/screens/task_list_screen.dart';
import 'package:task_flow/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize repository before running app
  final repository = TaskRepository();
  await repository.initialize();

  runApp(
    const ProviderScope(
      child: TaskFlowApp(),
    ),
  );
}

class TaskFlowApp extends StatelessWidget {
  const TaskFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Task Flow',
      theme: AppTheme.lightTheme,
      home: const TaskListScreen(),
    );
  }
}
