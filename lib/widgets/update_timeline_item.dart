import 'package:flutter/material.dart';
import '../models/update.dart';

class UpdateTimelineItem extends StatelessWidget {
	final Update update;
	final bool isFirst;
	final bool isLast;

	const UpdateTimelineItem({super.key, required this.update, this.isFirst = false, this.isLast = false});

	@override
	Widget build(BuildContext context) {
		return Row(
			crossAxisAlignment: CrossAxisAlignment.start,
			children: [
				Column(
					children: [
						if (!isFirst) Container(width: 2, height: 12, color: Colors.grey[300]),
						Container(
							width: 12, height: 12,
							decoration: BoxDecoration(
								color: Colors.green,
								shape: BoxShape.circle,
							),
						),
						if (!isLast) Container(width: 2, height: 32, color: Colors.grey[300]),
					],
				),
				const SizedBox(width: 12),
				Expanded(
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							Row(
								children: [
									Text(_ago(update.timestamp), style: const TextStyle(fontSize: 12, color: Colors.grey)),
									if (update.photos != null && update.photos!.isNotEmpty)
										Container(
											margin: const EdgeInsets.only(left: 8),
											padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
											decoration: BoxDecoration(
												color: Colors.blue[50],
												borderRadius: BorderRadius.circular(8),
											),
											child: Row(
												children: [
													const Icon(Icons.photo, size: 14, color: Colors.blue),
													Text(' ${update.photos!.length}', style: const TextStyle(fontSize: 12)),
												],
											),
										),
								],
							),
							const SizedBox(height: 2),
							Text(update.message, maxLines: 2, overflow: TextOverflow.ellipsis),
						],
					),
				),
			],
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
