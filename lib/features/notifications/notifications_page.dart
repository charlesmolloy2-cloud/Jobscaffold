import 'package:flutter/material.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final List<_Notification> _notifications = [];

  void _addOrEditNotification([_Notification? notification, int? index]) async {
    final result = await showDialog<_Notification>(
      context: context,
      builder: (context) => _NotificationDialog(notification: notification),
    );
    if (result != null) {
      setState(() {
        if (index != null) {
          _notifications[index] = result;
        } else {
          _notifications.add(result);
        }
      });
    }
  }

  void _deleteNotification(int index) {
    setState(() {
      _notifications.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView.builder(
        itemCount: _notifications.length,
        itemBuilder: (context, i) {
          final n = _notifications[i];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(n.body),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.green),
                    onPressed: () => _addOrEditNotification(n, i),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteNotification(i),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditNotification(),
        child: const Icon(Icons.add_alert),
        tooltip: 'Add Notification',
      ),
    );
  }
}

class _Notification {
  String title;
  String body;
  _Notification({required this.title, required this.body});
}

class _NotificationDialog extends StatefulWidget {
  final _Notification? notification;
  const _NotificationDialog({this.notification});

  @override
  State<_NotificationDialog> createState() => _NotificationDialogState();
}

class _NotificationDialogState extends State<_NotificationDialog> {
  late TextEditingController _titleController;
  late TextEditingController _bodyController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.notification?.title ?? '');
    _bodyController = TextEditingController(text: widget.notification?.body ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.notification == null ? 'Add Notification' : 'Edit Notification'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          TextField(
            controller: _bodyController,
            decoration: const InputDecoration(labelText: 'Body'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_titleController.text.trim().isEmpty) return;
            Navigator.pop(context, _Notification(
              title: _titleController.text.trim(),
              body: _bodyController.text.trim(),
            ));
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
