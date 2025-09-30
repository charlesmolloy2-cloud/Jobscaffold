import 'package:flutter/material.dart';
import '../../../models/models.dart' as models;
import '../../../widgets/status_badge.dart';

class ProjectRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final DateTime? date;
  final models.ProjectStatus status;
  final VoidCallback? onTap;

  const ProjectRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.status,
    this.date,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateText = date != null
        ? '${date!.month}/${date!.day}/${date!.year}'
        : null;

    return ListTile(
      onTap: onTap,
      leading: const CircleAvatar(child: Icon(Icons.work_outline)),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle),
          const SizedBox(height: 6),
          Row(
            children: [
              StatusBadge(status: status),
              if (dateText != null) ...[
                const SizedBox(width: 10),
                Text('Due $dateText',
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: Colors.black54)),
              ]
            ],
          ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}
