import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../widgets/fade_in.dart';
import '../../widgets/app_nav_scaffold.dart';
import '../../widgets/notifications_badge.dart';
import '../../widgets/notification_bell.dart';
import 'client_jobs_page.dart';
import '../../features/calendar/calendar_page.dart';
import 'client_updates_page.dart';
import 'client_account_page.dart';
import 'client_photos_page.dart';

class ClientHomePage extends StatelessWidget {
  const ClientHomePage({super.key});

  @override
  Widget build(BuildContext context) {
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
    final user = FirebaseAuth.instance.currentUser;
    final appState = context.read<AppState>();
    // Determine initial tab from the route name if deep-linked (e.g., /client/calendar)
    final routeName = ModalRoute.of(context)?.settings.name ?? '';
    int initialTab = 0;
    if (routeName.startsWith('/client/')) {
      final seg = routeName.substring('/client/'.length);
      switch (seg) {
        case 'jobs':
          initialTab = 0; break;
        case 'calendar':
          initialTab = 1; break;
        case 'updates':
          initialTab = 2; break;
        case 'photos':
          initialTab = 3; break;
        case 'account':
          initialTab = 4; break;
      }
    }
    if (user == null && appState.devBypassRole != 'client') {
      Future.microtask(() => Navigator.pushReplacementNamed(context, '/client_signin'));
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return AppNavScaffold(
      includeMoreTab: true,
      moreTabIndex: 5 - 1, // place More just left of Account
      bottomNavIconSize: 22,
      tabs: [
        ClientJobsPage(),
        CalendarPage(),
        ClientUpdatesPage(),
        ClientPhotosPage(),
        ClientAccountPage(),
      ],
      items: [
        const BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Jobs'),
        const BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Calendar'),
  BottomNavigationBarItem(icon: NotificationsBadge(child: const Icon(Icons.timeline)), label: 'Updates'),
        const BottomNavigationBarItem(icon: Icon(Icons.photo_library), label: 'Photos'),
        const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
      ],
      initialIndex: initialTab,
      appBarTitles: const [
        'Jobs',
        'Calendar',
        'Updates',
        'Photos',
        'Account',
      ],
      onTabChanged: (i) {
        String path = '/client';
        switch (i) {
          case 0: path = '/client/jobs'; break;
          case 1: path = '/client/calendar'; break;
          case 2: path = '/client/updates'; break;
          case 3: path = '/client/photos'; break;
          case 4: path = '/client/account'; break;
        }
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
            try {
              // ignore: use_build_context_synchronously
              context.read<AppState>().disableDevBypass();
            } catch (_) {}
            await FirebaseAuth.instance.signOut();
            if (context.mounted) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/client_signin',
                (route) => false,
                arguments: const {'signedOut': true},
              );
            }
          },
        ),
      ],
      topBanners: [
        // Jobs tab: show prominent Request Job banner like contractor
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
                      'Customer: ${user?.displayName ?? user?.email ?? user?.uid ?? 'Developer Bypass'}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    onPressed: () => showCreateClientJobDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('REQUEST JOB'),
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
      ],
    );
  }
}
