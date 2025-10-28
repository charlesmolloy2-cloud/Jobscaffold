import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../widgets/fade_in.dart';
import '../../widgets/app_nav_scaffold.dart';
import 'contractor_jobs_page.dart';
import 'contractor_projects_page.dart';
import 'contractor_updates_page.dart';
import 'contractor_account_page.dart';
import 'contractor_photos_page.dart';
import '../../features/calendar/calendar_page.dart';
import '../../widgets/notifications_badge.dart';
import '../../widgets/notification_bell.dart';
import '../../features/analytics/analytics_page.dart';

class ContractorHomePage extends StatelessWidget {
  const ContractorHomePage({super.key});

  void _maybeShowWelcome(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['signedIn'] == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        final u = FirebaseAuth.instance.currentUser;
        final name = u?.displayName?.trim().isNotEmpty == true
            ? u!.displayName
            : (u?.email?.trim().isNotEmpty == true ? u!.email : u?.uid);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Welcome back to JobScaffold${name != null ? ', $name' : '!'}')),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _maybeShowWelcome(context);
    final user = FirebaseAuth.instance.currentUser;
    final appState = context.read<AppState>();
    // Determine initial tab from the route name if deep-linked (e.g., /admin/projects)
    final routeName = ModalRoute.of(context)?.settings.name ?? '';
    int initialTab = 0;
    if (routeName.startsWith('/admin/')) {
      final seg = routeName.substring('/admin/'.length);
      switch (seg) {
        case 'jobs':
          initialTab = 0; break;
        case 'projects':
          initialTab = 1; break;
        case 'calendar':
          initialTab = 2; break;
        case 'updates':
          initialTab = 3; break;
        case 'analytics':
          initialTab = 4; break;
        case 'photos':
          initialTab = 5; break;
        case 'account':
          initialTab = 6; break;
      }
    }
    if (user == null && appState.devBypassRole != 'contractor') {
      // Redirect to sign in if not authenticated
      // Use Future.microtask to avoid setState during build
      Future.microtask(() => Navigator.pushReplacementNamed(context, '/contractor_signin'));
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return AppNavScaffold(
      includeMoreTab: true,
      moreTabIndex: 7 - 1, // insert More just left of Account (index 6 among 7 tabs)
      bottomNavIconSize: 22,
      tabs: [
        ContractorJobsPage(),
        ContractorProjectsPage(),
        CalendarPage(),
        ContractorUpdatesPage(),
        const AnalyticsPage(),
        ContractorPhotosPage(),
        ContractorAccountPage(),
      ],
      items: [
        const BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Jobs'),
        const BottomNavigationBarItem(icon: Icon(Icons.layers), label: 'Projects'),
        const BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Calendar'),
        BottomNavigationBarItem(icon: NotificationsBadge(child: const Icon(Icons.timeline)), label: 'Updates'),
        const BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Analytics'),
        const BottomNavigationBarItem(icon: Icon(Icons.photo_library), label: 'Photos'),
        const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
      ],
      initialIndex: initialTab,
      appBarTitles: const [
        'Jobs',
        'Projects',
        'Calendar',
        'Updates',
        'Analytics & Reporting',
        'Photos',
        'Account',
      ],
      onTabChanged: (i) {
        String path = '/admin';
        switch (i) {
          case 0: path = '/admin/jobs'; break;
          case 1: path = '/admin/projects'; break;
          case 2: path = '/admin/calendar'; break;
          case 3: path = '/admin/updates'; break;
          case 4: path = '/admin/analytics'; break;
          case 5: path = '/admin/photos'; break;
          case 6: path = '/admin/account'; break;
        }
        // Replace route to avoid piling history when just switching tabs
        if (ModalRoute.of(context)?.settings.name != path) {
          Navigator.of(context).pushReplacementNamed(path);
        }
      },
      appBarActions: [
        Builder(
          builder: (context) {
            final bypass = context.select<AppState, String?>((s) => s.devBypassRole);
            if (bypass != null) {
              return IconButton(
                tooltip: 'Main Menu',
                icon: const Icon(Icons.home),
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
        const NotificationBell(),
        IconButton(
          tooltip: 'Sign out',
          icon: const Icon(Icons.logout),
          onPressed: () async {
            // Clear developer bypass and sign out if signed-in.
            try {
              // ignore: use_build_context_synchronously
              context.read<AppState>().disableDevBypass();
            } catch (_) {}
            await FirebaseAuth.instance.signOut();
            if (context.mounted) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/contractor_signin',
                (route) => false,
                arguments: const {'signedOut': true},
              );
            }
          },
        ),
      ],
      // Show banner only on the Jobs tab (index 0); hide it on other tabs.
      topBanners: [
        FadeIn(
          child: Material(
            color: Colors.green.withOpacity(0.08),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.verified_user, size: 18, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Employee: ${user?.displayName ?? user?.email ?? user?.uid ?? 'Developer Bypass'}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    onPressed: () => showCreateContractorJobDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('ADD NEW PROJECT'),
                  ),
                ],
              ),
            ),
          ),
        ),
        null,
        null,
        null,
        null,
        null,
        null,
      ],
      // No bottom FAB here; the action is moved into the top banner for visibility.
    );
  }
}
