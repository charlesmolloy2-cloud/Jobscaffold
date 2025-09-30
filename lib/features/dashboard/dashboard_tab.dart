import 'package:flutter/material.dart';
import '../../widgets/feature_card.dart';

class DashboardTab extends StatelessWidget {
  final void Function(int index)? onQuickNav;
  const DashboardTab({super.key, this.onQuickNav});

  @override
  Widget build(BuildContext context) {
    final grid = [
      FeatureCard(
        icon: Icons.work,
        title: 'Projects',
        subtitle: 'View & manage projects',
        onTap: () => onQuickNav?.call(1),
      ),
      FeatureCard(
        icon: Icons.event,
        title: 'Schedule',
        subtitle: 'Upcoming tasks & visits',
        onTap: () => onQuickNav?.call(2),
      ),
      FeatureCard(
        icon: Icons.receipt_long,
        title: 'Invoices',
        subtitle: 'Create & track invoices',
        onTap: () => onQuickNav?.call(3),
      ),
      FeatureCard(
        icon: Icons.notifications_active,
        title: 'Updates',
        subtitle: 'Recent activity & notes',
        onTap: () => onQuickNav?.call(4),
      ),
      FeatureCard(
        icon: Icons.person,
        title: 'Account',
        subtitle: 'Profile & settings',
        onTap: () => onQuickNav?.call(5),
      ),
      FeatureCard(
        icon: Icons.add_circle,
        title: 'New Project',
        subtitle: 'Start a new job quickly',
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('New Project flow coming soon')),
          );
        },
      ),
    ];

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
            child: Text('Dashboard',
                style: Theme.of(context).textTheme.headlineMedium),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
          sliver: SliverGrid.extent(
            maxCrossAxisExtent: 240,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.15,
            children: grid,
          ),
        ),
      ],
    );
  }
}
