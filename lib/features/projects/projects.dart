import 'package:flutter/material.dart';
import 'widgets/project_row.dart';
import '../../widgets/status_badge.dart';

// Entry point for the Projects feature
class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final List<Map<String, dynamic>> _projects = [
    {
      'title': 'Kitchen Remodel - 19 Pine St.',
      'subtitle': 'Acme Contracting • 2 new updates',
      'status': ProjectStatus.inProgress,
    },
    {
      'title': 'Porch Repair - 42 Maple Ave.',
      'subtitle': 'Client: J. Donovan',
      'status': ProjectStatus.blocked,
    },
    {
      'title': 'Roof Inspection - 9 Harbor Rd.',
      'subtitle': 'Completed & invoiced',
      'status': ProjectStatus.completed,
    },
  ];

  void _addProject() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const AddProjectDialog(),
    );
    if (result != null) {
      setState(() {
        _projects.add(result);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Projects')),
      body: ListView(
        children: _projects
            .map((p) => ProjectRow(
                  title: p['title'],
                  subtitle: p['subtitle'],
                  status: p['status'],
                ))
            .toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addProject,
        child: const Icon(Icons.add),
        tooltip: 'Add Project',
      ),
    );
  }
}

class AddProjectDialog extends StatefulWidget {
  const AddProjectDialog({super.key});

  @override
  State<AddProjectDialog> createState() => _AddProjectDialogState();
}

class _AddProjectDialogState extends State<AddProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _subtitle = '';
  ProjectStatus _status = ProjectStatus.inProgress;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Project'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (v) => v == null || v.isEmpty ? 'Enter a title' : null,
              onSaved: (v) => _title = v ?? '',
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Subtitle'),
              onSaved: (v) => _subtitle = v ?? '',
            ),
            DropdownButtonFormField<ProjectStatus>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: ProjectStatus.values
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s.name),
                      ))
                  .toList(),
              onChanged: (s) => setState(() => _status = s ?? ProjectStatus.inProgress),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              _formKey.currentState?.save();
              Navigator.of(context).pop({
                'title': _title,
                'subtitle': _subtitle,
                'status': _status,
              });
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
