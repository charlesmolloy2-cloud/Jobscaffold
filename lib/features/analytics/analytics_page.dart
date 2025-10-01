
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({Key? key}) : super(key: key);

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final List<_Stat> _stats = [];

  void _addOrEditStat([_Stat? stat, int? index]) async {
    final result = await showDialog<_Stat>(
      context: context,
      builder: (context) => _StatDialog(stat: stat),
    );
    if (result != null) {
      setState(() {
        if (index != null) {
          _stats[index] = result;
        } else {
          _stats.add(result);
        }
      });
    }
  }

  void _deleteStat(int index) {
    setState(() {
      _stats.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics & Reporting')),
      body: ListView.builder(
        itemCount: _stats.length,
        itemBuilder: (context, i) {
          final s = _stats[i];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.bar_chart),
              title: Text(s.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Value: ${s.value}\n${s.description}'),
              isThreeLine: true,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.green),
                    onPressed: () => _addOrEditStat(s, i),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteStat(i),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditStat(),
        child: const Icon(Icons.bar_chart),
        tooltip: 'Add Stat',
      ),
    );
  }
}

class _Stat {
  String title;
  String description;
  double value;
  _Stat({required this.title, required this.description, required this.value});
}

class _StatDialog extends StatefulWidget {
  final _Stat? stat;
  const _StatDialog({this.stat});

  @override
  State<_StatDialog> createState() => _StatDialogState();
}

class _StatDialogState extends State<_StatDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _valueController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.stat?.title ?? '');
    _descController = TextEditingController(text: widget.stat?.description ?? '');
    _valueController = TextEditingController(text: widget.stat?.value.toString() ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.stat == null ? 'Add Stat' : 'Edit Stat'),
      content: Column(
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
          TextField(
            controller: _valueController,
            decoration: const InputDecoration(labelText: 'Value'),
            keyboardType: TextInputType.number,
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
            if (_titleController.text.trim().isEmpty || double.tryParse(_valueController.text.trim()) == null) return;
            Navigator.pop(context, _Stat(
              title: _titleController.text.trim(),
              description: _descController.text.trim(),
              value: double.parse(_valueController.text.trim()),
            ));
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
