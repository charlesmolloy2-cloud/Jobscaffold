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
  String _search = '';
  String _sourceFilter = 'All';
  _DateRange _dateRange = _DateRange.all;
  final TextEditingController _searchController = TextEditingController();

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
          'utm_source': data['utm_source'] ?? '',
          'utm_medium': data['utm_medium'] ?? '',
          'utm_campaign': data['utm_campaign'] ?? '',
          'utm_term': data['utm_term'] ?? '',
          'utm_content': data['utm_content'] ?? '',
          'landing_path': data['landing_path'] ?? '',
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
    csvRows.add([
      'Email',
      'Source',
      'UTM Source',
      'UTM Medium',
      'UTM Campaign',
      'UTM Term',
      'UTM Content',
      'Landing Path',
      'Timestamp',
    ].join(','));

    final exportList = _filteredLeads;
    // Data rows
    for (final lead in exportList) {
      final timestamp = lead['timestamp'] as Timestamp?;
      final dateStr = timestamp != null
          ? timestamp.toDate().toIso8601String()
          : '';
      // Escape commas by wrapping fields containing commas in quotes
      String esc(String v) => v.contains(',') ? '"$v"' : v;
      csvRows.add([
        esc('${lead['email'] ?? ''}'),
        esc('${lead['source'] ?? ''}'),
        esc('${lead['utm_source'] ?? ''}'),
        esc('${lead['utm_medium'] ?? ''}'),
        esc('${lead['utm_campaign'] ?? ''}'),
        esc('${lead['utm_term'] ?? ''}'),
        esc('${lead['utm_content'] ?? ''}'),
        esc('${lead['landing_path'] ?? ''}'),
        dateStr,
      ].join(','));
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
        SnackBar(content: Text('Exported ${exportList.length} leads to CSV')),
      );
    }
  }

  List<Map<String, dynamic>> get _filteredLeads {
    final now = DateTime.now();
    DateTime? cutoff;
    switch (_dateRange) {
      case _DateRange.seven:
        cutoff = now.subtract(const Duration(days: 7));
        break;
      case _DateRange.thirty:
        cutoff = now.subtract(const Duration(days: 30));
        break;
      case _DateRange.ninety:
        cutoff = now.subtract(const Duration(days: 90));
        break;
      case _DateRange.year:
        cutoff = now.subtract(const Duration(days: 365));
        break;
      case _DateRange.all:
        cutoff = null;
        break;
    }

    return _leads.where((lead) {
      final ts = lead['timestamp'] as Timestamp?;
      final dateOk = cutoff == null || (ts != null && ts.toDate().isAfter(cutoff));
      final sourceOk = _sourceFilter == 'All' || (lead['source'] ?? '') == _sourceFilter || (lead['utm_source'] ?? '') == _sourceFilter;
      final term = _search.trim().toLowerCase();
      final searchOk = term.isEmpty ||
          ('${lead['email'] ?? ''}'.toLowerCase().contains(term)) ||
          ('${lead['utm_campaign'] ?? ''}'.toLowerCase().contains(term)) ||
          ('${lead['landing_path'] ?? ''}'.toLowerCase().contains(term));
      return dateOk && sourceOk && searchOk;
    }).toList();
  }

  List<String> get _availableSources {
    final set = <String>{};
    for (final l in _leads) {
      final s1 = (l['source'] ?? '').toString();
      final s2 = (l['utm_source'] ?? '').toString();
      if (s1.isNotEmpty) set.add(s1);
      if (s2.isNotEmpty) set.add(s2);
    }
    final list = ['All', ...set.toList()..sort()];
    return list;
  }

  Widget _buildSummaryChips() {
    final counts = <String, int>{};
    for (final l in _filteredLeads) {
      final key = ((l['utm_source'] ?? '') as String).isNotEmpty
          ? (l['utm_source'] as String)
          : ((l['source'] ?? '') as String);
      final label = key.isEmpty ? 'unknown' : key;
      counts[label] = (counts[label] ?? 0) + 1;
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: entries.map((e) => Chip(label: Text('${e.key}: ${e.value}'))).toList(),
    );
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
                          constraints: const BoxConstraints(maxWidth: 1200),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: TextField(
                                      controller: _searchController,
                                      decoration: InputDecoration(
                                        prefixIcon: const Icon(Icons.search),
                                        hintText: 'Search email, campaign, or path',
                                        suffixIcon: _search.isNotEmpty
                                            ? IconButton(
                                                icon: const Icon(Icons.clear),
                                                onPressed: () {
                                                  _searchController.clear();
                                                  setState(() => _search = '');
                                                },
                                              )
                                            : null,
                                      ),
                                      onChanged: (v) => setState(() => _search = v),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  DropdownButton<_DateRange>(
                                    value: _dateRange,
                                    onChanged: (v) => setState(() => _dateRange = v ?? _DateRange.all),
                                    items: const [
                                      DropdownMenuItem(value: _DateRange.seven, child: Text('Last 7d')),
                                      DropdownMenuItem(value: _DateRange.thirty, child: Text('Last 30d')),
                                      DropdownMenuItem(value: _DateRange.ninety, child: Text('Last 90d')),
                                      DropdownMenuItem(value: _DateRange.year, child: Text('Last 1y')),
                                      DropdownMenuItem(value: _DateRange.all, child: Text('All time')),
                                    ],
                                  ),
                                  const SizedBox(width: 12),
                                  DropdownButton<String>(
                                    value: _availableSources.contains(_sourceFilter) ? _sourceFilter : 'All',
                                    onChanged: (v) => setState(() => _sourceFilter = v ?? 'All'),
                                    items: _availableSources
                                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                        .toList(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Showing ${_filteredLeads.length} of ${_leads.length} leads',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              _buildSummaryChips(),
                              const SizedBox(height: 16),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columns: const [
                                    DataColumn(label: Text('Email')),
                                    DataColumn(label: Text('Source')),
                                    DataColumn(label: Text('UTM Source')),
                                    DataColumn(label: Text('UTM Medium')),
                                    DataColumn(label: Text('Campaign')),
                                    DataColumn(label: Text('Term')),
                                    DataColumn(label: Text('Content')),
                                    DataColumn(label: Text('Landing Path')),
                                    DataColumn(label: Text('Timestamp')),
                                  ],
                                  rows: _filteredLeads.map((lead) {
                                    final ts = lead['timestamp'] as Timestamp?;
                                    final dateStr = ts != null
                                        ? '${ts.toDate().toLocal()}'.split('.').first
                                        : '';
                                    return DataRow(cells: [
                                      DataCell(Text('${lead['email'] ?? ''}')),
                                      DataCell(Text('${lead['source'] ?? ''}')),
                                      DataCell(Text('${lead['utm_source'] ?? ''}')),
                                      DataCell(Text('${lead['utm_medium'] ?? ''}')),
                                      DataCell(Text('${lead['utm_campaign'] ?? ''}')),
                                      DataCell(Text('${lead['utm_term'] ?? ''}')),
                                      DataCell(Text('${lead['utm_content'] ?? ''}')),
                                      DataCell(Text('${lead['landing_path'] ?? ''}')),
                                      DataCell(Text(dateStr)),
                                    ]);
                                  }).toList(),
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

enum _DateRange { seven, thirty, ninety, year, all }
