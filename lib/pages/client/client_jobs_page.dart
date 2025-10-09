import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../widgets/project_card.dart';
import '../../widgets/empty_state.dart';
import '../../models/project.dart';
import '../../state/dummy_data.dart';
import '../../services/firestore_repository.dart';
import 'package:provider/provider.dart';
import '../../widgets/error_banner.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Exposed helper to create a new client job request via a dialog.
Future<void> showCreateClientJobDialog(BuildContext context) async {
	final appState = context.read<AppState>();
	final firebaseUser = FirebaseAuth.instance.currentUser;
	// Gate: require auth (no dev bypass for job requests)
	if (firebaseUser == null) {
		ScaffoldMessenger.of(context).showSnackBar(
			const SnackBar(content: Text('Please sign in to request a job.')),
		);
		await Future.delayed(const Duration(milliseconds: 300));
		if (context.mounted) {
			Navigator.pushNamed(context, '/client_signin');
		}
		return;
	}

	final user = appState.currentUser;
	final customerId = user?.id ?? clientChris.id;
	final repo = context.read<FirestoreRepository?>();

	final result = await showDialog<Map<String, String>>(
		context: context,
		builder: (context) {
			final formKey = GlobalKey<FormState>();
			final titleCtrl = TextEditingController(text: 'New Job');
			final addressCtrl = TextEditingController(text: 'TBD');
			final descCtrl = TextEditingController();
			final budgetCtrl = TextEditingController();
			DateTime? startDate;
			DateTime? dueDate;

			return StatefulBuilder(
				builder: (context, setState) {
					return Dialog(
						insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
						child: ConstrainedBox(
							constraints: const BoxConstraints(maxWidth: 800),
							child: Padding(
								padding: const EdgeInsets.all(16),
								child: Column(
									mainAxisSize: MainAxisSize.min,
									children: [
										Row(
											children: [
												Expanded(
													child: Text('Request a job', style: Theme.of(context).textTheme.titleLarge),
												),
												IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
											],
										),
										const Divider(),
										Form(
											key: formKey,
											child: SingleChildScrollView(
												child: Column(
													crossAxisAlignment: CrossAxisAlignment.stretch,
													children: [
														TextFormField(
															controller: titleCtrl,
															decoration: const InputDecoration(labelText: 'Title'),
															validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
														),
														TextFormField(
															controller: addressCtrl,
															decoration: const InputDecoration(labelText: 'Address'),
														),
														TextFormField(
															controller: descCtrl,
															decoration: const InputDecoration(labelText: 'Description'),
															maxLines: 4,
														),
														Row(
															children: [
																Expanded(
																	child: TextFormField(
																		controller: budgetCtrl,
																		decoration: const InputDecoration(labelText: 'Budget (USD)'),
																		keyboardType: TextInputType.number,
																		validator: (v) {
																			if (v == null || v.trim().isEmpty) return null;
																			final d = double.tryParse(v.trim());
																			if (d == null || d < 0 || d > 1000000) return '0–1,000,000';
																			return null;
																		},
																	),
																),
																const SizedBox(width: 12),
																Expanded(
																	child: Column(
																		crossAxisAlignment: CrossAxisAlignment.start,
																		children: [
																			Text(startDate == null
																					? 'Start date: Not set'
																					: 'Start date: ${startDate!.toLocal().toString().split(' ')[0]}'),
																			TextButton(
																				onPressed: () async {
																					final now = DateTime.now();
																					final picked = await showDatePicker(
																						context: context,
																						firstDate: DateTime(now.year - 1),
																						lastDate: DateTime(now.year + 2),
																						initialDate: startDate ?? now,
																					);
																					if (picked != null) setState(() => startDate = picked);
																				},
																				child: const Text('Pick start'),
																			),
																		],
																	),
																),
															],
														),
														const SizedBox(height: 8),
														Row(
															children: [
																Expanded(
																	child: Text(dueDate == null
																			? 'Due date: Not set'
																			: 'Due date: ${dueDate!.toLocal().toString().split(' ')[0]}'),
																),
																TextButton(
																	onPressed: () async {
																		final now = DateTime.now();
																		final picked = await showDatePicker(
																			context: context,
																			firstDate: DateTime(now.year - 1),
																			lastDate: DateTime(now.year + 2),
																			initialDate: dueDate ?? now,
																		);
																		if (picked != null) setState(() => dueDate = picked);
																	},
																	child: const Text('Pick due'),
																),
															],
														),
													],
												),
											),
										),
										const SizedBox(height: 12),
										Row(
											mainAxisAlignment: MainAxisAlignment.end,
											children: [
												TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
												const SizedBox(width: 8),
												ElevatedButton(
													onPressed: () {
														if (!(formKey.currentState?.validate() ?? false)) return;
														Navigator.pop(context, {
															'title': titleCtrl.text.trim(),
															'address': addressCtrl.text.trim(),
															'description': descCtrl.text.trim(),
															'budget': budgetCtrl.text.trim(),
															'startDate': startDate?.toIso8601String() ?? '',
															'dueDate': dueDate?.toIso8601String() ?? '',
														});
													},
													child: const Text('Submit request'),
												),
											],
										),
									],
								),
							),
						),
					);
				},
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

	final extras = <String, dynamic>{};
	if ((result['description'] ?? '').isNotEmpty) extras['description'] = result['description'];
	if ((result['budget'] ?? '').isNotEmpty) {
		extras['budget'] = double.tryParse(result['budget']!) ?? result['budget'];
	}
	if ((result['startDate'] ?? '').isNotEmpty) extras['startDate'] = result['startDate'];
	if ((result['dueDate'] ?? '').isNotEmpty) extras['dueDate'] = result['dueDate'];
	extras['createdBy'] = appState.currentUser?.name ?? 'Unknown';
	extras['lastEditedBy'] = appState.currentUser?.name ?? 'Unknown';
	extras['lastEditedAt'] = DateTime.now().toIso8601String();

	if (repo != null) {
		try {
			await repo.createProjectWithExtras(id, project, extras);
		} catch (e) {
			// ignore: use_build_context_synchronously
			ScaffoldMessenger.of(context).showMaterialBanner(
				appErrorBanner(context, message: 'Failed to create job', onRetry: () {}),
			);
		}
	}
	appState.addProject(project);
	// Success toast
	if (context.mounted) {
		ScaffoldMessenger.of(context).showSnackBar(
			const SnackBar(content: Text('Job request submitted')),
		);
	}
}

class ClientJobsPage extends StatelessWidget {
	const ClientJobsPage({super.key});

	@override
	Widget build(BuildContext context) {
		final appState = Provider.of<AppState>(context);
		final user = appState.currentUser;
		final customerId = user?.id ?? clientChris.id;
		final localJobs = appState.activeProjects.where((p) => p.assignedCustomerId == customerId).toList();
		final repo = context.read<FirestoreRepository?>();
		Widget buildJobs(List<Project> jobs) {
			if (jobs.isEmpty) {
						return EmptyState(
					icon: Icons.work,
					title: 'No jobs yet',
					subtitle: 'Your jobs will show here',
							onAction: () => showCreateClientJobDialog(context),
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
