import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/time_tracking_service.dart';
import '../../state/app_state.dart';
import 'package:intl/intl.dart';

class TimeTrackingPage extends StatefulWidget {
  final String projectId;

  const TimeTrackingPage({super.key, required this.projectId});

  @override
  State<TimeTrackingPage> createState() => _TimeTrackingPageState();
}

class _TimeTrackingPageState extends State<TimeTrackingPage> {
  final TimeTrackingService _timeService = TimeTrackingService();
  TimeEntry? _activeEntry;
  TimeSummary? _summary;

  @override
  void initState() {
    super.initState();
    _loadActiveEntry();
    _loadSummary();
  }

  Future<void> _loadActiveEntry() async {
    final appState = context.read<AppState>();
    final userId = appState.currentUser?.id ?? '';
    
    final entry = await _timeService.getActiveEntry(userId);
    setState(() => _activeEntry = entry);
  }

  Future<void> _loadSummary() async {
    final summary = await _timeService.getProjectTimeSummary(widget.projectId);
    setState(() => _summary = summary);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final userId = appState.currentUser?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Time Tracking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _showWeeklyTimesheet(userId),
          ),
          IconButton(
            icon: const Icon(Icons.receipt),
            onPressed: () => _generateInvoice(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Clock in/out section
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Column(
              children: [
                if (_activeEntry != null) ...[
                  Text(
                    'Currently Clocked In',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  _ActiveTimer(entry: _activeEntry!),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _clockOut(_activeEntry!.id),
                    icon: const Icon(Icons.stop),
                    label: const Text('Clock Out'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ] else ...[
                  const Icon(Icons.access_time, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Not Clocked In',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _clockIn(userId),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Clock In'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Summary section
          if (_summary != null)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _SummaryCard(
                    title: 'Total Hours',
                    value: _summary!.totalHours.toStringAsFixed(1),
                    icon: Icons.schedule,
                  ),
                  _SummaryCard(
                    title: 'Entries',
                    value: _summary!.entryCount.toString(),
                    icon: Icons.list,
                  ),
                ],
              ),
            ),

          const Divider(),

          // Time entries list
          Expanded(
            child: StreamBuilder<List<TimeEntry>>(
              stream: _timeService.getProjectEntries(widget.projectId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.timer_off, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No time entries',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                final entries = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return _TimeEntryCard(
                      entry: entry,
                      onEdit: () => _editEntry(entry),
                      onDelete: () => _deleteEntry(entry.id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _clockIn(String userId) async {
    final notes = await showDialog<String>(
      context: context,
      builder: (context) {
        String notesText = '';
        return AlertDialog(
          title: const Text('Clock In'),
          content: TextField(
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              hintText: 'What are you working on?',
            ),
            maxLines: 3,
            onChanged: (value) => notesText = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, notesText),
              child: const Text('Clock In'),
            ),
          ],
        );
      },
    );

    if (notes == null) return;

    try {
      await _timeService.clockIn(
        projectId: widget.projectId,
        notes: notes.isEmpty ? null : notes,
      );
      
      await _loadActiveEntry();
      await _loadSummary();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clocked in successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _clockOut(String entryId) async {
    final notes = await showDialog<String>(
      context: context,
      builder: (context) {
        String notesText = '';
        return AlertDialog(
          title: const Text('Clock Out'),
          content: TextField(
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              hintText: 'What did you accomplish?',
            ),
            maxLines: 3,
            onChanged: (value) => notesText = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, notesText),
              child: const Text('Clock Out'),
            ),
          ],
        );
      },
    );

    if (notes == null) return;

    try {
      await _timeService.clockOut(
        entryId: entryId,
        notes: notes.isEmpty ? null : notes,
      );
      
      await _loadActiveEntry();
      await _loadSummary();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clocked out successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _editEntry(TimeEntry entry) {
    // Show edit dialog
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TimeEntryEditPage(entry: entry),
      ),
    );
  }

  Future<void> _deleteEntry(String entryId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Time Entry'),
        content: const Text('Are you sure you want to delete this time entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _timeService.deleteEntry(entryId);
      _loadSummary();
    }
  }

  void _showWeeklyTimesheet(String userId) async {
    // Default to current week
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    
    final timesheet = await _timeService.getWeeklyTimesheet(userId, weekStart);
    
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WeeklyTimesheetPage(timesheet: timesheet),
        ),
      );
    }
  }

  void _generateInvoice() async {
    // Show date range picker
    final dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (dateRange == null) return;

    // Show hourly rate input
    final rateText = await showDialog<String>(
      context: context,
      builder: (context) {
        String rate = '50.00';
        return AlertDialog(
          title: const Text('Hourly Rate'),
          content: TextField(
            decoration: const InputDecoration(
              labelText: 'Rate (\$/hour)',
              prefixText: '\$',
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) => rate = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, rate),
              child: const Text('Generate'),
            ),
          ],
        );
      },
    );

    if (rateText == null) return;

    final hourlyRate = double.tryParse(rateText) ?? 50.0;

    final invoiceData = await _timeService.generateInvoiceData(
      projectId: widget.projectId,
      startDate: dateRange.start,
      endDate: dateRange.end,
      hourlyRate: hourlyRate,
    );

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InvoicePreviewPage(invoiceData: invoiceData),
        ),
      );
    }
  }
}

class _ActiveTimer extends StatefulWidget {
  final TimeEntry entry;

  const _ActiveTimer({required this.entry});

  @override
  State<_ActiveTimer> createState() => _ActiveTimerState();
}

class _ActiveTimerState extends State<_ActiveTimer> {
  late Stream<int> _timerStream;

  @override
  void initState() {
    super.initState();
    _timerStream = Stream.periodic(const Duration(seconds: 1), (_) {
      return DateTime.now().difference(widget.entry.clockIn).inSeconds;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _timerStream,
      initialData: DateTime.now().difference(widget.entry.clockIn).inSeconds,
      builder: (context, snapshot) {
        final seconds = snapshot.data ?? 0;
        final hours = seconds ~/ 3600;
        final minutes = (seconds % 3600) ~/ 60;
        final secs = seconds % 60;

        return Text(
          '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeEntryCard extends StatelessWidget {
  final TimeEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TimeEntryCard({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, y');
    final timeFormat = DateFormat('h:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: entry.status == TimeEntryStatus.active
                ? Colors.green.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            entry.status == TimeEntryStatus.active ? Icons.play_arrow : Icons.check,
            color: entry.status == TimeEntryStatus.active ? Colors.green : Colors.grey,
          ),
        ),
        title: Text(
          dateFormat.format(entry.clockIn),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${timeFormat.format(entry.clockIn)} - ${entry.clockOut != null ? timeFormat.format(entry.clockOut!) : 'In Progress'}'),
            if (entry.notes != null) ...[
              const SizedBox(height: 4),
              Text(
                entry.notes!,
                style: TextStyle(color: Colors.grey[600]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              entry.formattedDuration,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (entry.status != TimeEntryStatus.active) ...[
              const SizedBox(width: 8),
              PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Placeholder pages (would need full implementation)
class TimeEntryEditPage extends StatelessWidget {
  final TimeEntry entry;

  const TimeEntryEditPage({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Time Entry')),
      body: const Center(child: Text('Edit functionality coming soon')),
    );
  }
}

class WeeklyTimesheetPage extends StatelessWidget {
  final WeeklyTimesheet timesheet;

  const WeeklyTimesheetPage({super.key, required this.timesheet});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Timesheet')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Week of ${DateFormat('MMM d, y').format(timesheet.weekStart)}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Total Hours: ${timesheet.totalHours.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  Text('Total Entries: ${timesheet.entries.length}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...timesheet.entriesByDay.entries.map((dayEntry) {
            final day = dayEntry.key;
            final entries = dayEntry.value;
            final dayTotal = entries.fold<int>(
              0,
              (sum, entry) => sum + (entry.duration ?? 0),
            );
            return Card(
              child: ExpansionTile(
                title: Text(DateFormat('EEEE, MMM d').format(day)),
                subtitle: Text('${(dayTotal / 60).toStringAsFixed(2)} hours'),
                children: entries.map((entry) {
                  return ListTile(
                    title: Text(entry.formattedDuration),
                    subtitle: Text(entry.notes ?? 'No notes'),
                  );
                }).toList(),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class InvoicePreviewPage extends StatelessWidget {
  final InvoiceData invoiceData;

  const InvoicePreviewPage({super.key, required this.invoiceData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Preview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              // TODO: Generate PDF
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PDF generation coming soon')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'INVOICE',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Text('Period: ${DateFormat('MMM d, y').format(invoiceData.startDate)} - ${DateFormat('MMM d, y').format(invoiceData.endDate)}'),
            const SizedBox(height: 24),
            const Text(
              'Time Entries',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ...invoiceData.entries.map((entry) {
              final hours = (entry.duration ?? 0) / 60;
              final amount = hours * invoiceData.hourlyRate;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(DateFormat('MMM d, y').format(entry.clockIn)),
                    ),
                    Text('${hours.toStringAsFixed(2)} hrs'),
                    const SizedBox(width: 16),
                    Text('\$${amount.toStringAsFixed(2)}'),
                  ],
                ),
              );
            }),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Hours:', style: TextStyle(fontSize: 16)),
                Text('${invoiceData.totalHours.toStringAsFixed(2)} hrs',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Hourly Rate:', style: TextStyle(fontSize: 16)),
                Text('\$${invoiceData.hourlyRate.toStringAsFixed(2)}/hr',
                    style: const TextStyle(fontSize: 16)),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TOTAL:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text('\$${invoiceData.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
