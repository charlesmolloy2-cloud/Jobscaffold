
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final List<_CalendarEvent> _events = [];

  void _addEvent([_CalendarEvent? event, int? index]) async {
    final result = await showDialog<_CalendarEvent>(
      context: context,
      builder: (context) => _EventDialog(event: event),
    );
    if (result != null) {
      setState(() {
        if (index != null) {
          _events[index] = result;
        } else {
          _events.add(result);
        }
      });
    }
  }

  void _deleteEvent(int index) {
    setState(() {
      _events.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kGreen, kLightGreenBg],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                Icon(Icons.calendar_today, size: 64, color: kGreenDark),
                const SizedBox(height: 16),
                const Text(
                  'Project Calendar',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: kBlack),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text(
                          'View all your project milestones, meetings, and deadlines in one place.',
                          style: TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),
                        if (_events.isEmpty)
                          const Text('No events yet. Add your first event!'),
                        if (_events.isNotEmpty)
                          ..._events.asMap().entries.map((entry) {
                            final i = entry.key;
                            final e = entry.value;
                            return Card(
                              color: Colors.white,
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('${e.date.toLocal()}\n${e.description}'),
                                isThreeLine: true,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: kGreenDark),
                                      onPressed: () => _addEvent(e, i),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _deleteEvent(i),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  icon: const Icon(Icons.event),
                  label: const Text('Add Event'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kGreen,
                    foregroundColor: kWhite,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _addEvent(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CalendarEvent {
  String title;
  String description;
  DateTime date;
  _CalendarEvent({required this.title, required this.description, required this.date});
}

class _EventDialog extends StatefulWidget {
  final _CalendarEvent? event;
  const _EventDialog({this.event});

  @override
  State<_EventDialog> createState() => _EventDialogState();
}

class _EventDialogState extends State<_EventDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event?.title ?? '');
    _descController = TextEditingController(text: widget.event?.description ?? '');
    _date = widget.event?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.event == null ? 'Add Event' : 'Edit Event'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Date:'),
                const SizedBox(width: 8),
                TextButton(
                  child: Text('${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}'),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => _date = picked);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_titleController.text.trim().isEmpty) return;
            Navigator.pop(context, _CalendarEvent(
              title: _titleController.text.trim(),
              description: _descController.text.trim(),
              date: _date,
            ));
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
