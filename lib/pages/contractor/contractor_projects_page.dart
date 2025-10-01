import '../../widgets/empty_state.dart';
import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../widgets/project_card.dart';
import 'package:provider/provider.dart';

class ContractorProjectsPage extends StatelessWidget {
	const ContractorProjectsPage({super.key});

	@override
	Widget build(BuildContext context) {
		final appState = Provider.of<AppState>(context);
		final user = appState.currentUser;
		final projects = appState.activeProjects.where((p) => p.assignedContractorId == user?.id).toList();
			if (projects.isEmpty) {
				return EmptyState(
					icon: Icons.layers,
					title: 'No projects yet',
					subtitle: 'Projects you are assigned to will show here',
				);
			}
		return ListView.builder(
			itemCount: projects.length,
			itemBuilder: (context, i) => ProjectCard(project: projects[i]),
		);
	}
}
