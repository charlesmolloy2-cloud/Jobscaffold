import 'package:flutter/material.dart';
import '../../widgets/app_nav_scaffold.dart';
import 'contractor_jobs_page.dart';
import 'contractor_projects_page.dart';
import 'contractor_updates_page.dart';
import 'contractor_account_page.dart';
import 'contractor_photos_page.dart';
import '../../features/calendar/calendar_page.dart';

class ContractorHomePage extends StatelessWidget {
  const ContractorHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppNavScaffold(
      tabs: [
        ContractorJobsPage(),
        ContractorProjectsPage(),
        CalendarPage(),
        ContractorUpdatesPage(),
        ContractorPhotosPage(),
        ContractorAccountPage(),
      ],
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Jobs'),
        BottomNavigationBarItem(icon: Icon(Icons.layers), label: 'Projects'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Calendar'),
        BottomNavigationBarItem(icon: Icon(Icons.timeline), label: 'Updates'),
        BottomNavigationBarItem(icon: Icon(Icons.photo_library), label: 'Photos'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
      ],
      appBarTitles: const [
        'Jobs',
        'Projects',
        'Calendar',
        'Updates',
        'Photos',
        'Account',
      ],
      floatingActionButtons: const [
        FloatingActionButton(onPressed: null, child: Icon(Icons.add)),
        FloatingActionButton(onPressed: null, child: Icon(Icons.add)),
        FloatingActionButton(onPressed: null, child: Icon(Icons.event)),
        null,
        null,
        null,
      ],
    );
  }
}
