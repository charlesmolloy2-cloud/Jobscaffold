import '../../widgets/empty_state.dart';
import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../widgets/update_timeline_item.dart';
import 'package:provider/provider.dart';

class ClientUpdatesPage extends StatelessWidget {
	const ClientUpdatesPage({super.key});

	@override
	Widget build(BuildContext context) {
		final appState = Provider.of<AppState>(context);
		final user = appState.currentUser;
		final projects = appState.activeProjects.where((p) => p.assignedCustomerId == user?.id).toList();
		final projectIds = projects.map((p) => p.id).toSet();
		final updates = appState.updates.where((u) => projectIds.contains(u.projectId)).toList()
			..sort((a, b) => b.timestamp.compareTo(a.timestamp));
			if (updates.isEmpty) {
				return EmptyState(
					icon: Icons.timeline,
					title: 'No updates yet',
					subtitle: 'Project updates will show here',
				);
			}
		return ListView.separated(
			itemCount: updates.length,
			separatorBuilder: (_, __) => const Divider(),
			itemBuilder: (context, i) => UpdateTimelineItem(
				update: updates[i],
				isFirst: i == 0,
				isLast: i == updates.length - 1,
			),
		);
	}
}
