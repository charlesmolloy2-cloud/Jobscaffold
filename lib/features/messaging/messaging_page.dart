import 'package:flutter/material.dart';

class MessagingPage extends StatefulWidget {
  const MessagingPage({Key? key}) : super(key: key);

  @override
  State<MessagingPage> createState() => _MessagingPageState();
}

class _MessagingPageState extends State<MessagingPage> {
  final List<_Message> _messages = [];

  void _addOrEditMessage([_Message? message, int? index]) async {
    final result = await showDialog<_Message>(
      context: context,
      builder: (context) => _MessageDialog(message: message),
    );
    if (result != null) {
      setState(() {
        if (index != null) {
          _messages[index] = result;
        } else {
          _messages.add(result);
        }
      });
    }
  }

  void _deleteMessage(int index) {
    setState(() {
      _messages.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messaging')),
      body: ListView.builder(
        itemCount: _messages.length,
        itemBuilder: (context, i) {
          final m = _messages[i];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(m.sender, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(m.text),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.green),
                    onPressed: () => _addOrEditMessage(m, i),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteMessage(i),
                  ),
                ],
              ),
            ),
          );
        },
      ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'fab-messaging',
        onPressed: () => _addOrEditMessage(),
        child: const Icon(Icons.add_comment),
        tooltip: 'Start New Chat',
      ),
    );
  }
}

class _Message {
  String sender;
  String text;
  _Message({required this.sender, required this.text});
}

class _MessageDialog extends StatefulWidget {
  final _Message? message;
  const _MessageDialog({this.message});

  @override
  State<_MessageDialog> createState() => _MessageDialogState();
}

class _MessageDialogState extends State<_MessageDialog> {
  late TextEditingController _senderController;
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _senderController = TextEditingController(text: widget.message?.sender ?? '');
    _textController = TextEditingController(text: widget.message?.text ?? '');
  }

  @override
  void dispose() {
    _senderController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.message == null ? 'New Message' : 'Edit Message'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _senderController,
            decoration: const InputDecoration(labelText: 'Sender'),
          ),
          TextField(
            controller: _textController,
            decoration: const InputDecoration(labelText: 'Message'),
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
            if (_senderController.text.trim().isEmpty || _textController.text.trim().isEmpty) return;
            Navigator.pop(context, _Message(
              sender: _senderController.text.trim(),
              text: _textController.text.trim(),
            ));
          },
          child: const Text('Send'),
        ),
      ],
    );
  }
}
