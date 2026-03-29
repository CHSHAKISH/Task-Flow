import re

with open("lib/main.dart", "r", encoding="utf-8") as f:
    text = f.read()

# Add import
if "import 'package:task_flow/widgets/task_form_dialog.dart';" not in text:
    text = text.replace("import 'package:task_flow/models/task_draft.dart';", "import 'package:task_flow/models/task_draft.dart';\nimport 'package:task_flow/widgets/task_form_dialog.dart';")

# Remove with WidgetsBindingObserver
text = text.replace("with WidgetsBindingObserver {", "{")

# Remove draft controllers
text = re.sub(r"\s*// Draft form controllers.*?\n\s*DateTime\? _draftSelectedDate;\s*", "", text, flags=re.DOTALL)

# Remove Observer additions/removals
text = text.replace("WidgetsBinding.instance.addObserver(this);", "")
text = text.replace("WidgetsBinding.instance.removeObserver(this);", "")

# Remove observer dispose
text = re.sub(r"\s*_draftTitleController\?\.dispose\(\);\s*_draftDescriptionController\?\.dispose\(\);\s*", "\n", text)

# Remove didChangeAppLifecycleState
text = re.sub(r"\s*@override\s*void didChangeAppLifecycleState.*?\}\s*\}", "", text, flags=re.DOTALL)

# Remove _saveDraftIfFormOpen
text = re.sub(r"\s*void _saveDraftIfFormOpen\(\)\s*\{.*?_repository\.saveDraft\(draft\);\s*\}", "", text, flags=re.DOTALL)

# Replace _showCreateTaskDialog
replacement_create = """
  void _showCreateTaskDialog({TaskDraft? loadDraft}) async {
    final allTasks = await _repository.getAllTasks();
    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => TaskFormDialog(
        draft: loadDraft,
        allTasks: allTasks,
        onSave: (task) async {
          await _repository.createTask(task);
        },
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task created successfully')),
      );
      setState(() {
        _loadTasks();
      });
    }
  }
"""

text = re.sub(r"\s*void _showCreateTaskDialog\(\{TaskDraft\? loadDraft\}\) \{.*?\}\s*\}\s*barrierDismissible: false, // Prevent accidental dismissal\s*\)\.then\(\(_\) \{\s*// Clear draft form references when dialog closes\s*_draftTitleController = null;\s*_draftDescriptionController = null;\s*_draftSelectedDate = null;\s*\}\);\s*\}", replacement_create, text, flags=re.DOTALL)

# Replace _showEditTaskDialog
replacement_edit = """
  void _showEditTaskDialog(Task task) async {
    final allTasks = await _repository.getAllTasks();
    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => TaskFormDialog(
        task: task,
        allTasks: allTasks,
        onSave: (updatedTask) async {
          await _repository.updateTask(updatedTask);
        },
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task updated successfully')),
      );
      setState(() {
        _loadTasks();
      });
    }
  }
"""
text = re.sub(r"\s*void _showEditTaskDialog\(Task task\) async \{.*?\}\s*\}\s*\}\s*\)\.then\(\(_\) \{\s*\}\);\s*\}", replacement_edit, text, flags=re.DOTALL)

with open("lib/main.dart", "w", encoding="utf-8") as f:
    f.write(text)

