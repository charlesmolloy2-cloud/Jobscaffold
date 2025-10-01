import 'package:flutter/material.dart';
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
    );
  }
}
