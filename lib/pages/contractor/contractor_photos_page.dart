import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class ContractorPhotosPage extends StatefulWidget {
  const ContractorPhotosPage({super.key});

  @override
  State<ContractorPhotosPage> createState() => _ContractorPhotosPageState();
}

class _ContractorPhotosPageState extends State<ContractorPhotosPage> {
  final List<PlatformFile> _files = [];

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    final picked = result?.files.whereType<PlatformFile>().toList();
    if (picked != null && picked.isNotEmpty) {
      setState(() {
        _files.addAll(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ElevatedButton.icon(
            onPressed: _pickFiles,
            icon: const Icon(Icons.upload_file),
            label: const Text('Upload Photos/Files'),
          ),
          const SizedBox(height: 16),
          if (_files.isEmpty)
            const Text('No files uploaded yet.'),
          ..._files.map((file) => ListTile(
                leading: const Icon(Icons.insert_drive_file),
                title: Text(file.name),
                subtitle: Text('${file.size} bytes'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    setState(() => _files.remove(file));
                  },
                ),
              )),
        ],
      ),
    );
  }
}
