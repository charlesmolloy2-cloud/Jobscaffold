import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../models/models.dart' as models;
import '../../widgets/status_badge.dart';
import 'project_detail_screen.dart';
import '../projects/widgets/project_row.dart' as rows;

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  models.ProjectStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final items = MockDB.projects.where((p) => _filter == null || p.status == _filter).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(
            children: [
              const Text('Projects', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const Spacer(),
              PopupMenuButton<models.ProjectStatus?>(
                itemBuilder: (_) => const [
                  PopupMenuItem(value: null, child: Text('All')),
                  PopupMenuItem(value: models.ProjectStatus.inProgress, child: Text('In Progress')),
                  PopupMenuItem(value: models.ProjectStatus.completed, child: Text('Completed')),
                  PopupMenuItem(value: models.ProjectStatus.blocked, child: Text('Blocked')),
                ],
                onSelected: (v) => setState(() => _filter = v),
                child: Row(children: [
                  const Icon(Icons.filter_list),
                  const SizedBox(width: 6),
                  Text(_filter == null ? 'All' : _filter!.name),
                ]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (_, i) {
              final p = items[i];
              final subtitle = '${p.client}${p.updates.isNotEmpty ? " • ${p.updates.length} updates" : ""}';
              return rows.ProjectRow(
                title: p.title,
                subtitle: subtitle,
                status: p.status,
                date: p.dueDate,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ProjectDetailScreen(projectId: p.id)),
                  );
                  setState(() {});
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
