import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';

class StatusBadge extends StatelessWidget {
  final ProjectStatus status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    String label;
    Color bg;
    switch (status) {
      case ProjectStatus.completed:
        label = 'Completed';
        bg = AppColors.green.withOpacity(.2);
        break;
      case ProjectStatus.blocked:
        label = 'Blocked';
        bg = const Color(0xFFFFE5E5);
        break;
      case ProjectStatus.inProgress:
        label = 'In Progress';
        bg = const Color(0xFFE5F0FF);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}
