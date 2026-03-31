import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_flow/repositories/task_repository.dart';
import 'package:task_flow/screens/task_list_screen.dart';
import 'package:task_flow/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // We no longer preserve the native splash - let Flutter remove it immediately
  // as soon as the first frame is rendered to make it move to the home screen faster.

  runApp(
    const ProviderScope(
      child: TaskFlowApp(),
    ),
  );
}

class TaskFlowApp extends StatefulWidget {
  const TaskFlowApp({super.key});

  @override
  State<TaskFlowApp> createState() => _TaskFlowAppState();
}

class _TaskFlowAppState extends State<TaskFlowApp> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Initialize repository asynchronously
    final repository = TaskRepository();
    await repository.initialize();

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          backgroundColor: Colors.white,
          // Show a very brief branded loading indicator instead of freezing on the native splash
          body: Center(
            child: CircularProgressIndicator(
              color: Color(0xFF00B4D8), // Primary brand color
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Task Flow',
      theme: AppTheme.lightTheme,
      home: const TaskListScreen(),
    );
  }
}
