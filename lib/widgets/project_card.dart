import 'package:flutter/material.dart';
import '../models/project.dart';

class ProjectCard extends StatelessWidget {
	final Project project;
	final VoidCallback? onTap;

	const ProjectCard({super.key, required this.project, this.onTap});

	@override
	Widget build(BuildContext context) {
			return LayoutBuilder(
				builder: (context, constraints) {
					final wide = constraints.maxWidth > 900;
					final card = Card(
						margin: EdgeInsets.symmetric(
							vertical: 8,
							horizontal: wide ? (constraints.maxWidth - 900) / 2 : 16,
						),
						child: ListTile(
							onTap: onTap,
							minVerticalPadding: 16,
							contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
							title: Text(project.title, style: const TextStyle(fontWeight: FontWeight.bold)),
							subtitle: Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									Text(project.address),
									const SizedBox(height: 4),
									Row(
										children: [
											Semantics(
												label: 'Project status: ${project.status}',
												child: Chip(label: Text(project.status)),
											),
											const SizedBox(width: 8),
											Text('updated ${_ago(project.lastUpdateAt)}'),
										],
									),
								],
							),
						),
					);
					return card;
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
