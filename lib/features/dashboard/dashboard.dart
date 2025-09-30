import 'package:flutter/material.dart';
import 'jobs_tab.dart';
import 'updates_tab.dart';
import 'account_tab.dart';
import 'previous_projects_tab.dart';

// Entry point for the Dashboard feature
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _tabs = [
    JobsTab(),
    UpdatesTab(),
    AccountTab(),
    PreviousProjectsTab(),
  ];

  static const List<BottomNavigationBarItem> _items = [
    BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Jobs'),
    BottomNavigationBarItem(icon: Icon(Icons.update), label: 'Updates'),
    BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Account'),
    BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Previous'),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: _items,
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        selectedItemColor: Colors.green[700],
        unselectedItemColor: Colors.grey[600],
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
