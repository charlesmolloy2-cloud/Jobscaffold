import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key});

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  bool _loading = false;
  String? _currentRole;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (doc.exists) {
      setState(() {
        _userData = doc.data();
        _currentRole = _userData?['role'];
      });
    }
  }

  Future<void> _switchRole(String newRole) async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _loading = true);

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'role': newRole,
      });

      setState(() {
        _currentRole = newRole;
        if (_userData != null) {
          _userData!['role'] = newRole;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Switched to ${newRole.toUpperCase()} role')),
        );

        // Navigate to the appropriate home page
        if (newRole == 'contractor') {
          Navigator.of(context).pushReplacementNamed('/contractor/home');
        } else {
          Navigator.of(context).pushReplacementNamed('/customer/home');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error switching role: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/');
              }
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : user == null
              ? const Center(child: Text('Not signed in'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Admin Account',
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 16),
                              _buildInfoRow('Email', user.email ?? 'N/A'),
                              _buildInfoRow('UID', user.uid),
                              _buildInfoRow('Current Role', _currentRole ?? 'Not set'),
                              if (_userData?['name'] != null)
                                _buildInfoRow('Name', _userData!['name']),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Switch Role',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.build, size: 40),
                              title: const Text('Contractor'),
                              subtitle: const Text('Access contractor dashboard, projects, and tasks'),
                              trailing: _currentRole == 'contractor'
                                  ? const Chip(
                                      label: Text('Active'),
                                      backgroundColor: Colors.green,
                                    )
                                  : ElevatedButton(
                                      onPressed: () => _switchRole('contractor'),
                                      child: const Text('Switch'),
                                    ),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.person, size: 40),
                              title: const Text('Customer'),
                              subtitle: const Text('Access customer dashboard and view project updates'),
                              trailing: _currentRole == 'customer'
                                  ? const Chip(
                                      label: Text('Active'),
                                      backgroundColor: Colors.green,
                                    )
                                  : ElevatedButton(
                                      onPressed: () => _switchRole('customer'),
                                      child: const Text('Switch'),
                                    ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_currentRole != null)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.dashboard),
                            label: Text('Go to ${_currentRole!.toUpperCase()} Dashboard'),
                            onPressed: () {
                              if (_currentRole == 'contractor') {
                                Navigator.of(context).pushReplacementNamed('/contractor/home');
                              } else {
                                Navigator.of(context).pushReplacementNamed('/customer/home');
                              }
                            },
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: SelectableText(value),
          ),
        ],
      ),
    );
  }
}
