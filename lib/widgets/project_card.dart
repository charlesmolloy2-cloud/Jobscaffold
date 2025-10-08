import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/project.dart';
import '../services/firestore_repository.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class ProjectCard extends StatelessWidget {
	final Project project;
	final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

	const ProjectCard({super.key, required this.project, this.onTap, this.onEdit, this.onDelete});

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
																		const SizedBox(height: 6),
																																																																																																																		// Extra details from Firestore when available
																		Builder(
																			builder: (context) {
																				final repo = context.read<FirestoreRepository?>();
																				if (repo == null) return const SizedBox.shrink();
																				return StreamBuilder(
																					stream: repo.watchProjectSnapshot(project.id),
																					builder: (context, AsyncSnapshot snap) {
																						if (!snap.hasData) return const SizedBox.shrink();
																						final data = (snap.data?.data() as Map<String, dynamic>?) ?? const <String, dynamic>{};
																						final description = (data['description'] as String?)?.trim();
																						final budget = data['budget'];
																						final startDateStr = data['startDate'] as String?;
																						final startDate = startDateStr != null && startDateStr.isNotEmpty ? DateTime.tryParse(startDateStr) : null;

																																																				final currency = NumberFormat.simpleCurrency();

																						final lines = <Widget>[];
																						if (description != null && description.isNotEmpty) {
																							lines.add(Text(
																								description,
																								maxLines: 2,
																								overflow: TextOverflow.ellipsis,
																								style: TextStyle(color: Colors.grey[700]),
																							));
																						}
																																																																				if (budget != null || startDate != null) {
																							String parts = '';
																																																					if (budget != null) {
																																																								final bText = budget is num ? currency.format(budget) : budget.toString();
																																																								parts = bText;
																							}
																							if (startDate != null) {
																								final sText = startDate.toLocal().toString().split(' ')[0];
																								parts = parts.isEmpty ? 'Starts: $sText' : '$parts  •  Starts: $sText';
																							}
																							lines.add(Text(parts, style: TextStyle(color: Colors.grey[600])));
																						}
																						if (lines.isEmpty) return const SizedBox.shrink();
																						return Padding(
																							padding: const EdgeInsets.only(top: 4),
																							child: Column(
																								crossAxisAlignment: CrossAxisAlignment.start,
																								children: lines,
																							),
																						);
																					},
																				);
																			},
																		),
								],
							),
							trailing: (onEdit != null || onDelete != null)
									? PopupMenuButton<String>(
																onSelected: (value) async {
																		if (value == 'edit' && onEdit != null) onEdit!();
																		if (value == 'edit_details') _editDetails(context);
																		if (value == 'delete' && onDelete != null) onDelete!();
																		if (value == 'copy_link') {
																			final base = Uri.base;
																			final url = Uri(
																				scheme: base.scheme,
																				host: base.host,
																				port: base.hasPort ? base.port : null,
																				path: '/project/${project.id}',
																			).toString();
																			try {
																				// ignore: deprecated_member_use
																				await Clipboard.setData(ClipboardData(text: url));
																				// ignore: use_build_context_synchronously
																				ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copied to clipboard')));
																			} catch (_) {}
																		}
																},
									itemBuilder: (_) => [
										if (onEdit != null) const PopupMenuItem(value: 'edit', child: Text('Edit')),
										const PopupMenuItem(value: 'edit_details', child: Text('Edit details')),
																		const PopupMenuItem(value: 'copy_link', child: Text('Copy link')),
										if (onDelete != null) const PopupMenuItem(value: 'delete', child: Text('Delete')),
									],
								)
								: null,
						),
					);
					return card;
				},
			);
	}

	Future<void> _editDetails(BuildContext context) async {
		final repo = context.read<FirestoreRepository?>();
		if (repo == null) {
			await showDialog(
				context: context,
				builder: (_) => AlertDialog(
					title: const Text('Edit details'),
					content: const Text('Firestore is not available. Connect Firebase to edit details.'),
					actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
				),
			);
			return;
		}
		final data = await repo.getProjectData(project.id) ?? {};
		final descCtrl = TextEditingController(text: (data['description'] as String?) ?? '');
		final budgetCtrl = TextEditingController(text: data['budget']?.toString() ?? '');
		DateTime? startDate;
		final startDateStr = data['startDate'] as String?;
		if (startDateStr != null && startDateStr.isNotEmpty) startDate = DateTime.tryParse(startDateStr);

		final result = await showDialog<Map<String, String>>(
			context: context,
			builder: (context) => StatefulBuilder(
				builder: (context, setState) => AlertDialog(
					title: const Text('Edit details'),
					content: SingleChildScrollView(
						child: Column(
							mainAxisSize: MainAxisSize.min,
							children: [
								TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
								TextField(controller: budgetCtrl, decoration: const InputDecoration(labelText: 'Budget (USD)'), keyboardType: TextInputType.number),
								const SizedBox(height: 8),
								Row(children: [
									Expanded(child: Text(startDate == null ? 'Start date: Not set' : 'Start date: ${startDate!.toLocal().toString().split(' ')[0]}')),
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
										child: const Text('Pick date'),
									),
								]),
							],
						),
					),
					actions: [
						TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
						ElevatedButton(
							onPressed: () => Navigator.pop(context, {
								'description': descCtrl.text.trim(),
								'budget': budgetCtrl.text.trim(),
								'startDate': startDate?.toIso8601String() ?? '',
							}),
							child: const Text('Save'),
						),
					],
				),
			),
		);
		if (result == null) return;
		final extras = <String, dynamic>{};
		if ((result['description'] ?? '').isNotEmpty) extras['description'] = result['description']; else extras['description'] = null;
		if ((result['budget'] ?? '').isNotEmpty) extras['budget'] = double.tryParse(result['budget']!) ?? result['budget']; else extras['budget'] = null;
		if ((result['startDate'] ?? '').isNotEmpty) extras['startDate'] = result['startDate']; else extras['startDate'] = null;

		// Cleanup nulls to remove keys when empty
		extras.removeWhere((key, value) => value == null);
		await repo.updateProjectExtras(project.id, extras);
	}

	String _ago(DateTime dt) {
		final diff = DateTime.now().difference(dt);
		if (diff.inDays > 0) return '${diff.inDays}d ago';
		if (diff.inHours > 0) return '${diff.inHours}h ago';
		if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
		return 'just now';
	}
}
