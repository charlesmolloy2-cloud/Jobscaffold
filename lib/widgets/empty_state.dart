import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
	final IconData icon;
	final String title;
	final String subtitle;
	final VoidCallback? onAction;
	final String? actionLabel;

	const EmptyState({
		super.key,
		required this.icon,
		required this.title,
		required this.subtitle,
		this.onAction,
		this.actionLabel,
	});

		@override
		Widget build(BuildContext context) {
			return LayoutBuilder(
				builder: (context, constraints) {
					final wide = constraints.maxWidth > 900;
					return Center(
						child: ConstrainedBox(
							constraints: BoxConstraints(maxWidth: wide ? 500 : double.infinity),
							child: Column(
								mainAxisAlignment: MainAxisAlignment.center,
								children: [
									Semantics(
										label: title,
										child: Icon(icon, size: 64, color: Colors.grey[400]),
									),
									const SizedBox(height: 16),
									Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
									const SizedBox(height: 8),
									Text(subtitle, style: const TextStyle(fontSize: 16, color: Colors.grey)),
									if (onAction != null && actionLabel != null) ...[
										const SizedBox(height: 20),
										ElevatedButton(
											onPressed: onAction,
											child: Text(actionLabel!),
											style: ElevatedButton.styleFrom(
												minimumSize: const Size(44, 44),
											),
										),
									],
								],
							),
						),
					);
				},
			);
		}
}
