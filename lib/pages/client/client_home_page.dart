import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../widgets/fade_in.dart';
import '../../widgets/app_nav_scaffold.dart';
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
          SnackBar(content: Text('Welcome back${name != null ? ', $name' : '!'}')),
        );
      });
    }
    final user = FirebaseAuth.instance.currentUser;
    final appState = context.read<AppState>();
    if (user == null && appState.devBypassRole != 'client') {
      Future.microtask(() => Navigator.pushReplacementNamed(context, '/client_signin'));
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return AppNavScaffold(
      tabs: [
        ClientJobsPage(),
        CalendarPage(),
        ClientUpdatesPage(),
        ClientPhotosPage(),
        ClientAccountPage(),
      ],
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Jobs'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Calendar'),
        BottomNavigationBarItem(icon: Icon(Icons.timeline), label: 'Updates'),
        BottomNavigationBarItem(icon: Icon(Icons.photo_library), label: 'Photos'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
      ],
      appBarTitles: const [
        'Jobs',
        'Calendar',
        'Updates',
        'Photos',
        'Account',
      ],
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
      topBanner: FadeIn(
        child: Material(
          color: Colors.blue.withOpacity(0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.verified_user, size: 18, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Signed in as ${user?.displayName ?? user?.email ?? user?.uid ?? 'Developer Bypass'}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
