import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../widgets/project_card.dart';
import '../../widgets/empty_state.dart';
import '../../models/project.dart';
import '../../state/dummy_data.dart';
import '../../services/firestore_repository.dart';
import 'package:provider/provider.dart';
import '../../widgets/error_banner.dart';

class ClientJobsPage extends StatelessWidget {
	const ClientJobsPage({super.key});

	@override
	Widget build(BuildContext context) {
		final appState = Provider.of<AppState>(context);
		final user = appState.currentUser;
		final customerId = user?.id ?? clientChris.id;
		final localJobs = appState.activeProjects.where((p) => p.assignedCustomerId == customerId).toList();
		final repo = context.read<FirestoreRepository?>();

		Future<void> createJobRequest() async {
			final result = await showDialog<Map<String, String>>(
				context: context,
				builder: (context) {
					final titleCtrl = TextEditingController(text: 'New Job');
					final addressCtrl = TextEditingController(text: 'TBD');
					return AlertDialog(
						title: const Text('Request a job'),
						content: Column(
							mainAxisSize: MainAxisSize.min,
							children: [
								TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
								TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address')),
							],
						),
						actions: [
							TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
							ElevatedButton(
								onPressed: () => Navigator.pop(context, {
									'title': titleCtrl.text.trim(),
									'address': addressCtrl.text.trim(),
								}),
								child: const Text('Create'),
							),
						],
					);
				},
			);
			if (result == null) return;
			final id = 'p${DateTime.now().millisecondsSinceEpoch}';
			final project = Project(
				id: id,
				title: result['title']?.isNotEmpty == true ? result['title']! : 'Untitled Job',
				address: result['address']?.isNotEmpty == true ? result['address']! : 'TBD',
				status: 'requested',
				lastUpdateAt: DateTime.now(),
				assignedCustomerId: customerId,
				assignedContractorId: contractorCasey.id,
			);
			final repo = context.read<FirestoreRepository?>();
			if (repo != null) {
				try {
					await repo.createProjectWithId(id, project);
				} catch (e) {
					// ignore: use_build_context_synchronously
					ScaffoldMessenger.of(context).showMaterialBanner(appErrorBanner(context, message: 'Failed to create job', onRetry: () {}));
				}
			}
			appState.addProject(project);
		}
		Widget buildJobs(List<Project> jobs) {
			if (jobs.isEmpty) {
				return EmptyState(
					icon: Icons.work,
					title: 'No jobs yet',
					subtitle: 'Your jobs will show here',
					onAction: createJobRequest,
					actionLabel: 'Request a job',
				);
			}
			return Stack(
			children: [
				ListView.builder(
					itemCount: jobs.length,
					itemBuilder: (context, i) {
						final p = jobs[i];
						return ProjectCard(
							project: p,
							onTap: () => Navigator.pushNamed(context, '/project', arguments: {'projectId': p.id}),
							onEdit: () async {
								final titleCtrl = TextEditingController(text: p.title);
								final addressCtrl = TextEditingController(text: p.address);
								final result = await showDialog<Map<String, String>>(
									context: context,
									builder: (_) => AlertDialog(
										title: const Text('Edit job'),
										content: Column(
											mainAxisSize: MainAxisSize.min,
											children: [
												TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
												TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address')),
											],
										),
										actions: [
											TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
											ElevatedButton(
												onPressed: () => Navigator.pop(context, {
													'title': titleCtrl.text.trim(),
													'address': addressCtrl.text.trim(),
												}),
												child: const Text('Save'),
											),
										],
									),
								);
								if (result == null) return;
								final updated = Project(
									id: p.id,
									title: result['title']?.isNotEmpty == true ? result['title']! : p.title,
									address: result['address']?.isNotEmpty == true ? result['address']! : p.address,
									status: p.status,
									lastUpdateAt: DateTime.now(),
									assignedCustomerId: p.assignedCustomerId,
									assignedContractorId: p.assignedContractorId,
								);
																					final repo = context.read<FirestoreRepository?>();
																					if (repo != null) {
																						try {
																							await repo.updateProject(updated);
																						} catch (e) {
																							ScaffoldMessenger.of(context).showMaterialBanner(appErrorBanner(context, message: 'Failed to save changes', onRetry: () {}));
																						}
																					}
								appState.updateProject(updated);
						},
						onDelete: () async {
							final confirm = await showDialog<bool>(
								context: context,
								builder: (_) => AlertDialog(
									title: const Text('Delete job'),
									content: Text('Delete "${p.title}"? This cannot be undone.'),
									actions: [
										TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
										ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
									],
								),
							);
																	if (confirm == true) {
																		final repo = context.read<FirestoreRepository?>();
																		if (repo != null) {
																			try {
																				await repo.deleteProject(p.id);
																			} catch (e) {
																				ScaffoldMessenger.of(context).showMaterialBanner(appErrorBanner(context, message: 'Failed to delete job', onRetry: () {}));
																				return;
																			}
																		}
																		appState.removeProject(p.id);
																	}
						},
						);
					},
				),
				Positioned(
					right: 16,
					bottom: 16,
					child: FloatingActionButton(
						heroTag: 'client-jobs-fab',
						onPressed: createJobRequest,
						tooltip: 'Request a job',
						child: const Icon(Icons.add),
					),
				),
			],
			);
		}

		if (repo != null) {
			return StreamBuilder<List<Project>>(
				stream: repo.watchProjectsForCustomer(customerId),
				builder: (context, snap) {
					if (snap.hasError) {
						WidgetsBinding.instance.addPostFrameCallback((_) {
							ScaffoldMessenger.of(context).showMaterialBanner(appErrorBanner(context, message: 'Failed to load jobs', onRetry: () {}));
						});
					}
					return buildJobs(snap.data ?? localJobs);
				},
			);
		}
		return buildJobs(localJobs);
	}
}
