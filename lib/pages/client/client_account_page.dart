import '../../state/dummy_data.dart';
import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/project.dart';
import '../../services/firestore_repository.dart';
import '../../models/update.dart' as app_updates;

class ClientAccountPage extends StatelessWidget {
	const ClientAccountPage({super.key});

	@override
	Widget build(BuildContext context) {
		final appState = context.watch<AppState>();
		final user = appState.currentUser ?? clientChris;
		final customerId = user.id;
		final projects = appState.activeProjects
				.where((p) => p.assignedCustomerId == customerId)
				.toList();
		final projectsSorted = [...projects]..sort((a, b) => b.lastUpdateAt.compareTo(a.lastUpdateAt));
		final primary = projectsSorted.isNotEmpty ? projectsSorted.first : null;

		return SingleChildScrollView(
			padding: const EdgeInsets.all(24),
			child: Center(
				child: ConstrainedBox(
					constraints: const BoxConstraints(maxWidth: 900),
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.stretch,
						children: [
							// Signed-in banner via dev bypass is elsewhere; keep this page client-facing.
							// Header: Client profile
							Row(
								crossAxisAlignment: CrossAxisAlignment.center,
								children: [
									CircleAvatar(
										radius: 36,
										backgroundColor: Colors.green.shade100,
										child: const Icon(Icons.person, size: 40, color: Colors.green),
									),
									const SizedBox(width: 16),
									Expanded(
										child: Column(
											crossAxisAlignment: CrossAxisAlignment.start,
											children: [
												Text(user.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
												const SizedBox(height: 4),
												Text('client', style: TextStyle(color: Colors.grey[600])),
											],
										),
									),
									FilledButton.icon(
										onPressed: () async {
											try {
												await FirebaseAuth.instance.signOut();
											} catch (_) {}
											if (context.mounted) {
												Navigator.pushNamedAndRemoveUntil(
													context,
													'/client_signin',
													(route) => false,
													arguments: const {'signedOut': true},
												);
											}
										},
										icon: const Icon(Icons.logout),
										label: const Text('Sign out'),
									),
								],
							),
							const SizedBox(height: 24),

							// Quick actions
							Wrap(
								spacing: 12,
								runSpacing: 12,
								children: [
									_QuickAction(icon: Icons.work_outline, label: 'Request a job', onTap: () => Navigator.pushNamed(context, '/client')),
									_QuickAction(icon: Icons.list_alt, label: 'View all projects', onTap: () => Navigator.pushNamed(context, '/projects')),
									if (primary != null)
										_QuickAction(icon: Icons.folder_open, label: 'Open latest project', onTap: () => Navigator.pushNamed(context, '/project', arguments: {'projectId': primary.id})),
								],
							),
							const SizedBox(height: 16),

							// Contact info (placeholder for now)
							Card(
								child: Padding(
									padding: const EdgeInsets.all(16),
									child: Column(
										crossAxisAlignment: CrossAxisAlignment.start,
										children: const [
											Text('Contact info', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
											SizedBox(height: 8),
											Text('Email: client@example.com'),
											SizedBox(height: 4),
											Text('Phone: (555) 010-0101'),
											SizedBox(height: 4),
											Text('Address: 123 Main St, Springfield'),
										],
									),
								),
							),
							const SizedBox(height: 16),

							// Project overview
							Card(
								child: Padding(
									padding: const EdgeInsets.all(16),
									child: Column(
										crossAxisAlignment: CrossAxisAlignment.start,
										children: [
											const Text('Project overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
											const SizedBox(height: 12),
											if (projects.isEmpty)
												const Text('No active projects yet.'),
											if (projects.isNotEmpty)
												Wrap(
													spacing: 12,
													runSpacing: 12,
													children: [
														_StatChip(label: 'Active', value: _countByStatus(projects, 'active').toString(), color: Colors.green),
														_StatChip(label: 'Planning', value: _countByStatus(projects, 'planning').toString(), color: Colors.blue),
														_StatChip(label: 'Completed', value: _countByStatus(projects, 'completed').toString(), color: Colors.grey),
														_StatChip(label: 'Requested', value: _countByStatus(projects, 'requested').toString(), color: Colors.orange),
													],
												),
										],
									),
								),
							),
							const SizedBox(height: 16),

							// Recent projects list (compact)
							if (projects.isNotEmpty)
								Card(
									child: Padding(
										padding: const EdgeInsets.all(16),
										child: Column(
											crossAxisAlignment: CrossAxisAlignment.start,
											children: [
												const Text('Your projects', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
												const SizedBox(height: 8),
												...projectsSorted.take(5).map((p) => _ProjectMiniTile(project: p)),
												if (projects.length > 5)
													Text('… and ${projects.length - 5} more', style: TextStyle(color: Colors.grey[600])),
											],
										),
									),
								),

														// Next step + Recent updates for the most recent project
														if (primary != null) ...[
															const SizedBox(height: 16),
															Card(
																child: Padding(
																	padding: const EdgeInsets.all(16),
																	child: _NextSteps(project: primary),
																),
															),
															const SizedBox(height: 16),
															Card(
																child: Padding(
																	padding: const EdgeInsets.all(16),
																	child: Column(
																		crossAxisAlignment: CrossAxisAlignment.start,
																		children: const [
																			Text('Recent updates', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
																			SizedBox(height: 8),
																		],
																	),
																),
															),
															// Stream/fallback below the header
															_RecentUpdates(projectId: primary.id),
														],
						],
					),
				),
			),
		);
	}
}

class _StatChip extends StatelessWidget {
	final String label;
	final String value;
	final Color color;
	const _StatChip({required this.label, required this.value, required this.color});
	@override
	Widget build(BuildContext context) {
		return Chip(
			avatar: CircleAvatar(backgroundColor: color, radius: 8),
			label: Text('$label: $value'),
		);
	}
}

int _countByStatus(List<Project> projects, String status) =>
		projects.where((p) => p.status.toLowerCase() == status.toLowerCase()).length;

class _ProjectMiniTile extends StatelessWidget {
	final Project project;
	const _ProjectMiniTile({required this.project});
	@override
	Widget build(BuildContext context) {
		return ListTile(
			contentPadding: EdgeInsets.zero,
			title: Text(project.title, style: const TextStyle(fontWeight: FontWeight.w500)),
			subtitle: Text('${project.address} • ${project.status}'),
			trailing: const Icon(Icons.chevron_right),
			onTap: () => Navigator.pushNamed(context, '/project', arguments: {'projectId': project.id}),
		);
	}
}

class _QuickAction extends StatelessWidget {
	final IconData icon;
	final String label;
	final VoidCallback onTap;
	const _QuickAction({required this.icon, required this.label, required this.onTap});
	@override
	Widget build(BuildContext context) {
		return InkWell(
			onTap: onTap,
			borderRadius: BorderRadius.circular(8),
			child: Container(
				padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
				decoration: BoxDecoration(
					border: Border.all(color: Theme.of(context).dividerColor),
					borderRadius: BorderRadius.circular(8),
				),
				child: Row(
					mainAxisSize: MainAxisSize.min,
					children: [Icon(icon, size: 18), const SizedBox(width: 8), Text(label)],
				),
			),
		);
	}
}

class _NextSteps extends StatelessWidget {
	final Project project;
	const _NextSteps({required this.project});
	@override
	Widget build(BuildContext context) {
		String headline;
		String detail;
		IconData icon;
		Color color;
		switch (project.status.toLowerCase()) {
			case 'requested':
				headline = 'We received your request';
				detail = 'A contractor will contact you to schedule a visit.';
				icon = Icons.schedule;
				color = Colors.orange;
				break;
			case 'planning':
				headline = 'Your project is in planning';
				detail = 'Review the proposal and approve to start.';
				icon = Icons.description_outlined;
				color = Colors.blue;
				break;
			case 'active':
				headline = 'Work in progress';
				detail = 'We’ll post updates as milestones are completed.';
				icon = Icons.build_circle_outlined;
				color = Colors.green;
				break;
			case 'completed':
				headline = 'Project completed';
				detail = 'Thank you! You can download documents and share feedback.';
				icon = Icons.check_circle_outline;
				color = Colors.grey;
				break;
			default:
				headline = 'Status: ${project.status}';
				detail = 'We’ll keep you posted here.';
				icon = Icons.info_outline;
				color = Colors.teal;
		}

		return Row(
			crossAxisAlignment: CrossAxisAlignment.start,
			children: [
				Icon(icon, color: color),
				const SizedBox(width: 12),
				Expanded(
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							Text(headline, style: const TextStyle(fontWeight: FontWeight.w600)),
							const SizedBox(height: 4),
							Text(detail),
							const SizedBox(height: 8),
							Wrap(
								spacing: 8,
								children: [
									TextButton(
										onPressed: () => Navigator.pushNamed(context, '/project', arguments: {'projectId': project.id}),
										child: const Text('Open project'),
									),
									TextButton(
										onPressed: () => Navigator.pushNamed(context, '/projects'),
										child: const Text('All projects'),
									),
								],
							),
						],
					),
				),
			],
		);
	}
}

String _ago(DateTime dt) {
	final diff = DateTime.now().difference(dt);
	if (diff.inDays > 0) return '${diff.inDays}d ago';
	if (diff.inHours > 0) return '${diff.inHours}h ago';
	if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
	return 'just now';
}

class _RecentUpdates extends StatelessWidget {
		final String projectId;
		const _RecentUpdates({required this.projectId});
		@override
		Widget build(BuildContext context) {
				final repo = context.read<FirestoreRepository?>();
				final appState = context.watch<AppState>();
				if (repo != null) {
						return StreamBuilder<List<app_updates.Update>>(
								stream: repo.watchUpdates(projectId),
								builder: (context, snap) {
										final updates = snap.data ?? const <app_updates.Update>[];
										if (updates.isEmpty) return const Text('No updates yet.');
										return Column(
											children: updates.take(5).map((u) => ListTile(
												leading: const Icon(Icons.update),
												title: Text(u.message),
												subtitle: Text(_ago(u.timestamp)),
											)).toList(),
										);
								},
						);
				}
				final local = appState.updates.where((u) => u.projectId == projectId).toList();
				if (local.isEmpty) return const Text('No updates yet.');
				return Column(children: local.take(5).map((u) => ListTile(
					leading: const Icon(Icons.update),
					title: Text(u.message),
					subtitle: Text(_ago(u.timestamp)),
				)).toList());
		}
}
