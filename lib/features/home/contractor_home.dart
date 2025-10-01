import 'package:flutter/material.dart';
import '../dashboard/dashboard_tab.dart';
import '../projects/projects_page.dart';
import '../schedule/schedule_page.dart';
import '../invoices/invoices_page.dart';
import '../account/account_page.dart';
import '../../theme/app_theme.dart';

class ContractorHome extends StatefulWidget {
  const ContractorHome({super.key});

  @override
  State<ContractorHome> createState() => _ContractorHomeState();
}

class _ContractorHomeState extends State<ContractorHome> {
  int _index = 0;

  final _titles = const [
    'Dashboard',
    'Projects',
    'Schedule',
    'Invoices',
    'Account',
  ];

  late final List<Widget> _pages = [
    DashboardTab(onQuickNav: (i) => setState(() => _index = i.clamp(0, 4))),
    const ProjectsPage(),
    const SchedulePage(),
    const InvoicesPage(),
    const AccountPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      body: _pages[_index],
      floatingActionButton: _index == 0
          ? FloatingActionButton.extended(
              onPressed: () => _toast('Create new project'),
              icon: const Icon(Icons.add_circle),
              label: const Text('New Project'),
              backgroundColor: kGreen,
              foregroundColor: kBlack,
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Projects'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Schedule'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Invoices'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Account'),
        ],
      ),
    );
  }

  void _toast(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}
