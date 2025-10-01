import 'package:flutter/material.dart';
import '../../models/models.dart' as models;

class EditProjectDialog extends StatefulWidget {
  final models.Project project;
  const EditProjectDialog({required this.project, super.key});

  @override
  State<EditProjectDialog> createState() => _EditProjectDialogState();
}

class _EditProjectDialogState extends State<EditProjectDialog> {
  late TextEditingController _titleController;
  late DateTime _dueDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.project.title);
    _dueDate = widget.project.dueDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Project'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Due Date:'),
              const SizedBox(width: 8),
              TextButton(
                child: Text('${_dueDate.year}-${_dueDate.month.toString().padLeft(2, '0')}-${_dueDate.day.toString().padLeft(2, '0')}'),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dueDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _dueDate = picked);
                },
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_titleController.text.trim().isEmpty) return;
            Navigator.pop(context, EditProjectResult(
              title: _titleController.text.trim(),
              dueDate: _dueDate,
            ));
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class EditProjectResult {
  final String title;
  final DateTime dueDate;
  EditProjectResult({required this.title, required this.dueDate});
}