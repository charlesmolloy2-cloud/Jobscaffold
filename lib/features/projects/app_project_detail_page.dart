import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../services/firestore_repository.dart';
import '../../models/project.dart' as app_models;
import '../../models/update.dart' as app_updates;

class AppProjectDetailPage extends StatelessWidget {
  const AppProjectDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final projectId = (args is Map && args['projectId'] is String) ? args['projectId'] as String : null;
    final appState = context.watch<AppState>();
    final repo = context.read<FirestoreRepository?>();
    if (projectId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Project')),
        body: const Center(child: Text('Project not found.')),
      );
    }

    return StreamBuilder<app_models.Project?>(
      stream: repo?.watchProject(projectId),
      builder: (context, snap) {
        final project = snap.data ?? _findLocalProject(appState, projectId);
        if (project == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Project')),
            body: const Center(child: Text('Project not found.')),
          );
        }
  final p = project;
  final repo = context.read<FirestoreRepository?>();

        return Scaffold(
      appBar: AppBar(
  title: Text(p.title),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              String newStatus = p.status;
              if (value == 'Active') newStatus = 'active';
              if (value == 'Planning') newStatus = 'planning';
              if (value == 'Completed') newStatus = 'completed';
              if (value == 'Requested') newStatus = 'requested';
              final updated = app_models.Project(
                id: p.id,
                title: p.title,
                address: p.address,
                status: newStatus,
                lastUpdateAt: DateTime.now(),
                assignedCustomerId: p.assignedCustomerId,
                assignedContractorId: p.assignedContractorId,
              );
              if (repo != null) {
                await repo.updateProject(updated);
              }
              // ignore: use_build_context_synchronously
              context.read<AppState>().updateProject(updated);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'Active', child: Text('Mark Active')),
              PopupMenuItem(value: 'Planning', child: Text('Mark Planning')),
              PopupMenuItem(value: 'Completed', child: Text('Mark Completed')),
              PopupMenuItem(value: 'Requested', child: Text('Mark Requested')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final controller = TextEditingController();
          final text = await showDialog<String>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Add update'),
              content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'What changed?')),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Add')),
              ],
            ),
          );
          if ((text ?? '').isEmpty) return;
          final update = app_updates.Update(
            id: 'u${DateTime.now().millisecondsSinceEpoch}',
            projectId: p.id,
            message: text!,
            timestamp: DateTime.now(),
            photos: const [],
          );
          if (repo != null) {
            await repo.addUpdate(update);
            final updatedProject = app_models.Project(
              id: p.id,
              title: p.title,
              address: p.address,
              status: p.status,
              lastUpdateAt: DateTime.now(),
              assignedCustomerId: p.assignedCustomerId,
              assignedContractorId: p.assignedContractorId,
            );
            await repo.updateProject(updatedProject);
            // Also refresh local state so other parts of app using AppState see latest time.
            // ignore: use_build_context_synchronously
            context.read<AppState>().updateProject(updatedProject);
          } else {
            final list = [update, ...appState.updates];
            // ignore: use_build_context_synchronously
            context.read<AppState>().setUpdates(list);
            final updatedProject = app_models.Project(
              id: p.id,
              title: p.title,
              address: p.address,
              status: p.status,
              lastUpdateAt: DateTime.now(),
              assignedCustomerId: p.assignedCustomerId,
              assignedContractorId: p.assignedContractorId,
            );
            // ignore: use_build_context_synchronously
            context.read<AppState>().updateProject(updatedProject);
          }
        },
        icon: const Icon(Icons.add_comment),
        label: const Text('Add update'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.place),
              title: Text(p.address),
              subtitle: const Text('Address'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.label),
              title: Text(p.status),
              subtitle: Text('Updated ${_ago(p.lastUpdateAt)}'),
            ),
          ),
          if (repo != null)
            StreamBuilder(
              stream: repo.watchProjectSnapshot(p.id),
              builder: (context, AsyncSnapshot snap) {
                if (!snap.hasData) return const SizedBox.shrink();
                final data = (snap.data?.data() as Map<String, dynamic>?) ?? const <String, dynamic>{};
                final description = (data['description'] as String?)?.trim();
                final budget = data['budget'];
                final startDateStr = data['startDate'] as String?;
                final startDate = startDateStr != null && startDateStr.isNotEmpty ? DateTime.tryParse(startDateStr) : null;
                final details = <Widget>[];
                if (description != null && description.isNotEmpty) {
                  details.add(Card(
                    child: ListTile(
                      leading: const Icon(Icons.notes),
                      title: const Text('Description'),
                      subtitle: Text(description),
                    ),
                  ));
                }
                if (budget != null && budget.toString().isNotEmpty) {
                  final budgetText = budget is num ? '\$${budget.toStringAsFixed(2)}' : budget.toString();
                  details.add(Card(
                    child: ListTile(
                      leading: const Icon(Icons.attach_money),
                      title: const Text('Budget'),
                      subtitle: Text(budgetText),
                    ),
                  ));
                }
                if (startDate != null) {
                  details.add(Card(
                    child: ListTile(
                      leading: const Icon(Icons.event),
                      title: const Text('Start date'),
                      subtitle: Text('${startDate.toLocal().toString().split(' ')[0]}'),
                    ),
                  ));
                }
                return Column(children: details);
              },
            ),
          const SizedBox(height: 8),
          Text('Updates', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (repo != null)
            StreamBuilder<List<app_updates.Update>>(
              stream: repo.watchUpdates(p.id),
              builder: (context, updatesSnap) {
                final updates = updatesSnap.data ?? const <app_updates.Update>[];
                if (updates.isEmpty) return const Text('No updates yet.');
                return Column(
                  children: updates
                      .map((u) => Card(
                            child: ListTile(
                              leading: const Icon(Icons.update),
                              title: Text(u.message),
                              subtitle: Text(_ago(u.timestamp)),
                            ),
                          ))
                      .toList(),
                );
              },
            )
          else
            Builder(builder: (_) {
              final local = appState.updates.where((u) => u.projectId == p.id).toList();
              if (local.isEmpty) return const Text('No updates yet.');
              return Column(
                children: local
                    .map((u) => Card(
                          child: ListTile(
                            leading: const Icon(Icons.update),
                            title: Text(u.message),
                            subtitle: Text(_ago(u.timestamp)),
                          ),
                        ))
                    .toList(),
              );
            }),
        ],
      ),
        );
      },
    );
  }

  String _ago(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }
}

app_models.Project? _findLocalProject(AppState appState, String id) {
  try {
    return appState.activeProjects.firstWhere((p) => p.id == id);
  } catch (_) {
    return null;
  }
}
