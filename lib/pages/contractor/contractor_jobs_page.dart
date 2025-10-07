import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../widgets/project_card.dart';
import '../../widgets/empty_state.dart';
import 'package:provider/provider.dart';
import '../../models/project.dart';
import '../../state/dummy_data.dart';
import '../../services/firestore_repository.dart';

class ContractorJobsPage extends StatelessWidget {
	const ContractorJobsPage({super.key});

	@override
	Widget build(BuildContext context) {
		final appState = Provider.of<AppState>(context);
		final user = appState.currentUser;
		final contractorId = user?.id ?? (appState.devBypassRole == 'contractor' ? contractorCasey.id : null);
		final localJobs = contractorId == null
			? <Project>[]
			: appState.activeProjects.where((p) => p.assignedContractorId == contractorId).toList();
		final repo = context.read<FirestoreRepository?>();

		Future<void> createJob() async {
			final result = await showDialog<Map<String, String>>(
				context: context,
				builder: (context) {
					final titleCtrl = TextEditingController(text: 'New Job');
					final addressCtrl = TextEditingController(text: 'TBD');
					final descCtrl = TextEditingController();
					final budgetCtrl = TextEditingController();
					DateTime? startDate;
					return StatefulBuilder(
						builder: (context, setState) => AlertDialog(
							title: const Text('Create job'),
							content: SingleChildScrollView(
								child: Column(
									mainAxisSize: MainAxisSize.min,
									children: [
										TextField(
											controller: titleCtrl,
											decoration: const InputDecoration(labelText: 'Title', helperText: 'What do you want to call this job?'),
										),
										TextField(
											controller: addressCtrl,
											decoration: const InputDecoration(labelText: 'Address', helperText: 'Where is the job located?'),
										),
										TextField(
											controller: descCtrl,
											decoration: const InputDecoration(labelText: 'Description', helperText: 'Short scope or notes'),
											maxLines: 3,
										),
										Builder(builder: (_) {
											String? error;
											final text = budgetCtrl.text.trim();
											if (text.isNotEmpty) {
												final v = double.tryParse(text);
												if (v == null || v < 0 || v > 1000000) error = 'Enter a number between 0 and 1,000,000';
											}
											return TextField(
												controller: budgetCtrl,
												decoration: InputDecoration(
													labelText: 'Budget (USD)',
													helperText: '0–1,000,000 (optional)',
													errorText: error,
												),
												keyboardType: TextInputType.number,
												onChanged: (_) => setState(() {}),
											);
										}),
										const SizedBox(height: 8),
										Row(
											children: [
												Expanded(child: Text(startDate == null ? 'Start date: Not set' : 'Start date: ${startDate!.toLocal().toString().split(' ')[0]}')),
												TextButton(
													onPressed: () async {
														final now = DateTime.now();
														final picked = await showDatePicker(
															context: context,
															firstDate: DateTime(now.year - 1),
															lastDate: DateTime(now.year + 2),
															initialDate: now,
														);
														if (picked != null) setState(() => startDate = picked);
													},
													child: const Text('Pick date'),
												),
											],
										),
								],
							),
						),
						actions: [
							TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
							Builder(builder: (_) {
								final title = titleCtrl.text.trim();
								final address = addressCtrl.text.trim();
								final budgetText = budgetCtrl.text.trim();
								final budgetVal = budgetText.isEmpty ? null : double.tryParse(budgetText);
								final budgetOk = budgetVal == null || (budgetVal >= 0 && budgetVal <= 1000000);
								final isValid = title.isNotEmpty && address.isNotEmpty && startDate != null && budgetOk;
								return ElevatedButton(
									onPressed: isValid
										? () {
											Navigator.pop(context, {
												'title': title,
												'address': address,
												'description': descCtrl.text.trim(),
												'budget': budgetText,
												'startDate': startDate!.toIso8601String(),
											});
										}
									: null,
									child: const Text('Create'),
								);
							}),
						],
						),
					);
				},
			);
			if (result == null) return;
			final id = 'p${DateTime.now().millisecondsSinceEpoch}';
			final project = Project(
				id: id,
				title: result['title']?.isNotEmpty == true ? result['title']! : 'Untitled Job',
				address: result['address']?.isNotEmpty == true ? result['address']! : 'TBD',
				status: 'new',
				lastUpdateAt: DateTime.now(),
				assignedCustomerId: clientChris.id,
				assignedContractorId: contractorId ?? contractorCasey.id,
			);
			final repo = context.read<FirestoreRepository?>();
			if (repo != null) {
				final extras = <String, dynamic>{};
				if ((result['description'] ?? '').isNotEmpty) extras['description'] = result['description'];
				if ((result['budget'] ?? '').isNotEmpty) extras['budget'] = double.tryParse(result['budget']!) ?? result['budget'];
				if ((result['startDate'] ?? '').isNotEmpty) extras['startDate'] = result['startDate'];
				// Audit metadata
				extras['createdBy'] = appState.currentUser?.name ?? 'Unknown';
				extras['lastEditedBy'] = appState.currentUser?.name ?? 'Unknown';
				extras['lastEditedAt'] = DateTime.now().toIso8601String();
				await repo.createProjectWithExtras(id, project, extras);
			}
			appState.addProject(project);
		}
		Widget buildJobs(List<Project> jobs) {
			if (jobs.isEmpty) {
				return EmptyState(
					icon: Icons.work,
					title: 'No jobs yet',
					subtitle: 'New assignments appear here',
					onAction: createJob,
					actionLabel: 'Create a job',
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
									await repo.updateProject(updated);
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
										await repo.deleteProject(p.id);
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
						onPressed: createJob,
						tooltip: 'Create job',
						child: const Icon(Icons.add),
					),
				),
			],
			);
		}

		if (repo != null && contractorId != null) {
			return StreamBuilder<List<Project>>(
				stream: repo.watchProjectsForContractor(contractorId),
				builder: (context, snap) => buildJobs(snap.data ?? localJobs),
			);
		}
		return buildJobs(localJobs);
	}
}
