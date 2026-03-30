import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:task_flow/repositories/task_repository.dart';
import 'package:task_flow/screens/task_list_screen.dart';
import 'package:task_flow/theme/app_theme.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
  // Initialize repository before running app
  final repository = TaskRepository();
  await repository.initialize();
  
  FlutterNativeSplash.remove();

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
