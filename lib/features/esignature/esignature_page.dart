import 'package:flutter/material.dart';

class ESignaturePage extends StatefulWidget {
  const ESignaturePage({Key? key}) : super(key: key);

  @override
  State<ESignaturePage> createState() => _ESignaturePageState();
}

class _ESignaturePageState extends State<ESignaturePage> {
  final List<_SignatureRequest> _requests = [];

  void _addOrEditRequest([_SignatureRequest? req, int? index]) async {
    final result = await showDialog<_SignatureRequest>(
      context: context,
      builder: (context) => _SignatureDialog(request: req),
    );
    if (result != null) {
      setState(() {
        if (index != null) {
          _requests[index] = result;
        } else {
          _requests.add(result);
        }
      });
    }
  }

  void _deleteRequest(int index) {
    setState(() {
      _requests.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('E-signature & Approvals')),
      body: ListView.builder(
        itemCount: _requests.length,
        itemBuilder: (context, i) {
          final r = _requests[i];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.edit_document),
              title: Text(r.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(r.description),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.green),
                    onPressed: () => _addOrEditRequest(r, i),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteRequest(i),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditRequest(),
        child: const Icon(Icons.edit_document),
        tooltip: 'Request Signature',
      ),
    );
  }
}

class _SignatureRequest {
  String title;
  String description;
  _SignatureRequest({required this.title, required this.description});
}

class _SignatureDialog extends StatefulWidget {
  final _SignatureRequest? request;
  const _SignatureDialog({this.request});

  @override
  State<_SignatureDialog> createState() => _SignatureDialogState();
}

class _SignatureDialogState extends State<_SignatureDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.request?.title ?? '');
    _descController = TextEditingController(text: widget.request?.description ?? '');
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
      title: Text(widget.request == null ? 'Request Signature' : 'Edit Request'),
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
            Navigator.pop(context, _SignatureRequest(
              title: _titleController.text.trim(),
              description: _descController.text.trim(),
            ));
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
