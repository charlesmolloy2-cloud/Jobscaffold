

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarEvent {
  String title;
  String description;
  DateTime date;
  _CalendarEvent({required this.title, required this.description, required this.date});
}

class _CalendarPageState extends State<CalendarPage> {
  final List<_CalendarEvent> _events = [];
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  void _addEvent([_CalendarEvent? event, int? index, DateTime? date]) async {
    final result = await showDialog<_CalendarEvent>(
      context: context,
      builder: (context) => _EventDialog(event: event, initialDate: date ?? _focusedMonth),
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

  List<_CalendarEvent> _eventsForDay(DateTime day) {
    return _events.where((e) =>
      e.date.year == day.year && e.date.month == day.month && e.date.day == day.day
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final firstWeekday = firstDayOfMonth.weekday;
    final weeks = <List<DateTime?>>[];
    int day = 1;
    for (int w = 0; w < 6; w++) {
      final week = <DateTime?>[];
      for (int d = 1; d <= 7; d++) {
        if (w == 0 && d < firstWeekday) {
          week.add(null);
        } else if (day > daysInMonth) {
          week.add(null);
        } else {
          week.add(DateTime(_focusedMonth.year, _focusedMonth.month, day));
          day++;
        }
      }
      weeks.add(week);
    }

    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      setState(() {
                        final prevMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
                        if (prevMonth.year >= 2000) {
                          _focusedMonth = prevMonth;
                        }
                      });
                    },
                  ),
                  Text(
                    '${monthNames[_focusedMonth.month - 1]} ${_focusedMonth.year}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {
                      setState(() {
                        final nextMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
                        if (nextMonth.year <= 2100) {
                          _focusedMonth = nextMonth;
                        }
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  Text('Mon'), Text('Tue'), Text('Wed'), Text('Thu'), Text('Fri'), Text('Sat'), Text('Sun'),
                ],
              ),
              const SizedBox(height: 4),
              Expanded(
                child: ListView.builder(
                  itemCount: weeks.length,
                  itemBuilder: (context, w) {
                    final week = weeks[w];
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: week.map((date) {
                        if (date == null) {
                          return Expanded(child: Container());
                        }
                        final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
                        final events = _eventsForDay(date);
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              _addEvent(null, null, date);
                            },
                            child: Container(
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: isToday ? kGreen : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              height: 48,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Text(
                                    '${date.day}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isToday ? kWhite : kBlack,
                                    ),
                                  ),
                                  if (events.isNotEmpty)
                                    Positioned(
                                      bottom: 6,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              if (_events.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    itemCount: _events.length,
                    itemBuilder: (context, i) {
                      final e = _events[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${e.date.year}-${e.date.month.toString().padLeft(2, '0')}-${e.date.day.toString().padLeft(2, '0')}\n${e.description}'),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: kGreenDark),
                                onPressed: () => _addEvent(e, i, e.date),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteEvent(i),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventDialog extends StatefulWidget {
  final _CalendarEvent? event;
  final DateTime initialDate;
  const _EventDialog({this.event, required this.initialDate});

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
    _date = widget.event?.date ?? widget.initialDate;
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
