import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../widgets/project_card.dart';
import '../../widgets/empty_state.dart';
import 'package:provider/provider.dart';

class ContractorJobsPage extends StatelessWidget {
	const ContractorJobsPage({super.key});

	@override
	Widget build(BuildContext context) {
		final appState = Provider.of<AppState>(context);
		final user = appState.currentUser;
		final jobs = appState.activeProjects.where((p) => p.assignedContractorId == user?.id).toList();
		if (jobs.isEmpty) {
			return const EmptyState(
				icon: Icons.work,
				title: 'No jobs yet',
				subtitle: 'New assignments appear here',
			);
		}
		return ListView.builder(
			itemCount: jobs.length,
			itemBuilder: (context, i) => ProjectCard(project: jobs[i]),
		);
	}
}
