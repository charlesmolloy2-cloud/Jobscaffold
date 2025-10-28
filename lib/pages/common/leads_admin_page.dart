import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:html' as html;

class LeadsAdminPage extends StatefulWidget {
  const LeadsAdminPage({Key? key}) : super(key: key);

  @override
  State<LeadsAdminPage> createState() => _LeadsAdminPageState();
}

class _LeadsAdminPageState extends State<LeadsAdminPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _leads = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLeads();
  }

  Future<void> _loadLeads() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('leads')
          .orderBy('timestamp', descending: true)
          .get();
      
      final leads = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'email': data['email'] ?? '',
          'source': data['source'] ?? '',
          'timestamp': data['timestamp'],
        };
      }).toList();
      
      setState(() {
        _leads = leads;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _exportToCsv() {
    final csvRows = <String>[];
    // Header
    csvRows.add('Email,Source,Timestamp');
    
    // Data rows
    for (final lead in _leads) {
      final timestamp = lead['timestamp'] as Timestamp?;
      final dateStr = timestamp != null
          ? timestamp.toDate().toIso8601String()
          : '';
      csvRows.add('${lead['email']},${lead['source']},$dateStr');
    }
    
    final csvContent = csvRows.join('\n');
    final blob = html.Blob([csvContent]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', 'leads_${DateTime.now().millisecondsSinceEpoch}.csv')
      ..click();
    html.Url.revokeObjectUrl(url);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported ${_leads.length} leads to CSV')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check authentication
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Leads Admin')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Sign in required to access leads'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/contractor_signin'),
                child: const Text('Sign In'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leads Admin'),
        actions: [
          if (_leads.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Export to CSV',
              onPressed: _exportToCsv,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLeads,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadLeads,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _leads.isEmpty
                  ? const Center(child: Text('No leads yet'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 900),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total leads: ${_leads.length}',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 16),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _leads.length,
                                itemBuilder: (context, index) {
                                  final lead = _leads[index];
                                  final timestamp = lead['timestamp'] as Timestamp?;
                                  final dateStr = timestamp != null
                                      ? '${timestamp.toDate().toLocal()}'.split('.').first
                                      : 'N/A';
                                  return Card(
                                    child: ListTile(
                                      leading: const Icon(Icons.email),
                                      title: Text(lead['email']),
                                      subtitle: Text('Source: ${lead['source']}\n$dateStr'),
                                      isThreeLine: true,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
    );
  }
}
