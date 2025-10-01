
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({Key? key}) : super(key: key);

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final List<_FeedbackItem> _feedbacks = [];

  void _addOrEditFeedback([_FeedbackItem? feedback, int? index]) async {
    final result = await showDialog<_FeedbackItem>(
      context: context,
      builder: (context) => _FeedbackDialog(feedback: feedback),
    );
    if (result != null) {
      setState(() {
        if (index != null) {
          _feedbacks[index] = result;
        } else {
          _feedbacks.add(result);
        }
      });
    }
  }

  void _deleteFeedback(int index) {
    setState(() {
      _feedbacks.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feedback & Ratings')),
      body: ListView.builder(
        itemCount: _feedbacks.length,
        itemBuilder: (context, i) {
          final f = _feedbacks[i];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.feedback),
              title: Text(f.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Rating: ${f.rating}\n${f.comment}'),
              isThreeLine: true,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.green),
                    onPressed: () => _addOrEditFeedback(f, i),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteFeedback(i),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditFeedback(),
        child: const Icon(Icons.rate_review),
        tooltip: 'Leave Feedback',
      ),
    );
  }
}

class _FeedbackItem {
  String name;
  String comment;
  int rating;
  _FeedbackItem({required this.name, required this.comment, required this.rating});
}

class _FeedbackDialog extends StatefulWidget {
  final _FeedbackItem? feedback;
  const _FeedbackDialog({this.feedback});

  @override
  State<_FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<_FeedbackDialog> {
  late TextEditingController _nameController;
  late TextEditingController _commentController;
  int _rating = 5;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.feedback?.name ?? '');
    _commentController = TextEditingController(text: widget.feedback?.comment ?? '');
    _rating = widget.feedback?.rating ?? 5;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.feedback == null ? 'Leave Feedback' : 'Edit Feedback'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          TextField(
            controller: _commentController,
            decoration: const InputDecoration(labelText: 'Comment'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Rating:'),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _rating,
                items: List.generate(5, (i) => i + 1)
                    .map((r) => DropdownMenuItem(value: r, child: Text('$r')))
                    .toList(),
                onChanged: (v) => setState(() => _rating = v ?? 5),
              ),
            ],
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
            if (_nameController.text.trim().isEmpty) return;
            Navigator.pop(context, _FeedbackItem(
              name: _nameController.text.trim(),
              comment: _commentController.text.trim(),
              rating: _rating,
            ));
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
