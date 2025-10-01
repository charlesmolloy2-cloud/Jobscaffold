import 'package:flutter/material.dart';
import '../account/account_page.dart';
import '../../data/mock_data.dart';

class ClientHome extends StatefulWidget {
  const ClientHome({super.key});

  @override
  State<ClientHome> createState() => _ClientHomeState();
}

class _ClientHomeState extends State<ClientHome> {
  int _index = 0;

  final _titles = const ['My Jobs', 'Updates', 'Account'];

  late final List<Widget> _pages = [
    const _ClientJobsPage(),
    const _ClientUpdatesPage(),
    const AccountPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      body: _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.work_outline), label: 'Jobs'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Updates'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Account'),
        ],
      ),
    );
  }
}

// ---------------- Client Jobs ----------------
class _ClientJobsPage extends StatelessWidget {
  const _ClientJobsPage();

  @override
  Widget build(BuildContext context) {
    final jobs = MockDB.projects;
    return ListView.builder(
      itemCount: jobs.length,
      itemBuilder: (_, i) {
        final p = jobs[i];
        return Card(
          child: ListTile(
            title: Text(p.title),
            subtitle: Text('${p.client} • ${p.status.name}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text('Open project detail')));
            },
          ),
        );
      },
    );
  }
}

// ---------------- Client Updates ----------------
class _ClientUpdatesPage extends StatelessWidget {
  const _ClientUpdatesPage();

  @override
  Widget build(BuildContext context) {
    final updates = MockDB.projects.expand((p) => p.updates).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return ListView.builder(
      itemCount: updates.length,
      itemBuilder: (_, i) {
        final u = updates[i];
        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.note)),
          title: Text(u.text),
          subtitle: Text('${u.createdAt.month}/${u.createdAt.day} ${u.createdAt.hour}:${u.createdAt.minute}'),
        );
      },
    );
  }
}
