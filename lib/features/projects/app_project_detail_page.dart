import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../services/firestore_repository.dart';
import '../../models/project.dart' as app_models;
import '../../models/update.dart' as app_updates;
import 'package:intl/intl.dart';
import '../../widgets/error_banner.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppProjectDetailPage extends StatelessWidget {
  const AppProjectDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context);
    final args = route?.settings.arguments;
    String? projectId = (args is Map && args['projectId'] is String) ? args['projectId'] as String : null;
    // Support deep links like /project/<id>
    if (projectId == null) {
      final name = route?.settings.name ?? '';
      if (name.startsWith('/project/')) {
        projectId = name.substring('/project/'.length);
      }
    }
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
        if (snap.hasError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final msg = 'Failed to load project. Using local data.';
            ScaffoldMessenger.of(context).showMaterialBanner(
              appErrorBanner(context, message: msg, onRetry: () {}),
            );
          });
        }
  final project = snap.data ?? _findLocalProject(appState, projectId!);
        if (project == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Project')),
            body: const Center(child: Text('Project not found.')),
          );
        }
  final p = project;
  final repo = context.read<FirestoreRepository?>();
  final currency = NumberFormat.simpleCurrency();

        return Scaffold(
      appBar: AppBar(
  title: Text(p.title),
        actions: [
          IconButton(
            tooltip: 'Share link',
            icon: const Icon(Icons.share),
            onPressed: () async {
              final base = Uri.base; // current URL
              final shareUrl = Uri(
                scheme: base.scheme,
                host: base.host,
                port: base.hasPort ? base.port : null,
                path: '/project/${p.id}',
              ).toString();
              try {
                await Clipboard.setData(ClipboardData(text: shareUrl));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copied to clipboard')));
                }
              } catch (_) {}
              // Fire analytics event
              try { await FirebaseAnalytics.instance.logShare(contentType: 'project', itemId: p.id, method: 'clipboard'); } catch (_) {}
            },
          ),
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
              try {
                if (repo != null) {
                  await repo.updateProject(updated);
                }
              } catch (e) {
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showMaterialBanner(
                  appErrorBanner(context, message: 'Failed to update status', onRetry: () {}),
                );
                return;
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
            try {
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
            } catch (e) {
              // ignore: use_build_context_synchronously
              ScaffoldMessenger.of(context).showMaterialBanner(
                appErrorBanner(context, message: 'Failed to add update', onRetry: () {}),
              );
            }
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
          _ConsentBanner(),
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
                if (snap.hasError) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ScaffoldMessenger.of(context).showMaterialBanner(appErrorBanner(context, message: 'Failed to load extra details', onRetry: () {}));
                  });
                }
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
                  final budgetText = budget is num ? currency.format(budget) : budget.toString();
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
                      subtitle: Text(DateFormat.yMMMd().format(startDate.toLocal())),
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
                if (updatesSnap.hasError) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ScaffoldMessenger.of(context).showMaterialBanner(appErrorBanner(context, message: 'Failed to load updates', onRetry: () {}));
                  });
                }
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

class _ConsentBanner extends StatefulWidget {
  @override
  State<_ConsentBanner> createState() => _ConsentBannerState();
}

class _ConsentBannerState extends State<_ConsentBanner> {
  bool _decided = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final decided = prefs.getBool('analytics_consent_decided') ?? false;
      setState(() => _decided = decided);
    } catch (_) {}
  }

  Future<void> _setConsent(bool allowed) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('analytics_consent_decided', true);
      await prefs.setBool('analytics_consent_allowed', allowed);
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(allowed);
      setState(() => _decided = true);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_decided) return const SizedBox.shrink();
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Analytics consent', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('We use anonymous analytics to improve the app. You can opt out any time in settings.'),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton(onPressed: () => _setConsent(false), child: const Text('Decline')),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: () => _setConsent(true), child: const Text('Allow')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
