import 'package:flutter/material.dart';

class FilesPage extends StatefulWidget {
  const FilesPage({super.key});

  @override
  State<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage> {
  final List<_FileItem> _files = [];

  void _addOrEditFile([_FileItem? file, int? index]) async {
    final result = await showDialog<_FileItem>(
      context: context,
      builder: (context) => _FileDialog(file: file),
    );
    if (result != null) {
      setState(() {
        if (index != null) {
          _files[index] = result;
        } else {
          _files.add(result);
        }
      });
    }
  }

  void _deleteFile(int index) {
    setState(() {
      _files.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('File Sharing')),
      body: ListView.builder(
        itemCount: _files.length,
        itemBuilder: (context, i) {
          final f = _files[i];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: Text(f.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(f.description),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.green),
                    onPressed: () => _addOrEditFile(f, i),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteFile(i),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditFile(),
        child: const Icon(Icons.upload_file),
        tooltip: 'Upload File',
      ),
    );
  }
}

class _FileItem {
  String name;
  String description;
  _FileItem({required this.name, required this.description});
}

class _FileDialog extends StatefulWidget {
  final _FileItem? file;
  const _FileDialog({this.file});

  @override
  State<_FileDialog> createState() => _FileDialogState();
}

class _FileDialogState extends State<_FileDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.file?.name ?? '');
    _descController = TextEditingController(text: widget.file?.description ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.file == null ? 'Upload File' : 'Edit File'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'File Name'),
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
            if (_nameController.text.trim().isEmpty) return;
            Navigator.pop(context, _FileItem(
              name: _nameController.text.trim(),
              description: _descController.text.trim(),
            ));
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
