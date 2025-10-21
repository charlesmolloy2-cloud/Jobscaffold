import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/storage_service.dart';

class ContractorPhotosPage extends StatefulWidget {
  const ContractorPhotosPage({super.key});

  @override
  State<ContractorPhotosPage> createState() => _ContractorPhotosPageState();
}

class _ContractorPhotosPageState extends State<ContractorPhotosPage> {
  final StorageService _storageService = StorageService();
  final List<FileMetadata> _uploadedFiles = [];
  bool _uploading = false;
  String? _selectedProjectId; // In real app, get from dropdown or context

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _storageService.getUserFiles(user.uid).listen((files) {
      if (mounted) {
        setState(() {
          _uploadedFiles.clear();
          _uploadedFiles.addAll(files);
        });
      }
    });
  }

  Future<void> _pickAndUploadFiles() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to upload files')),
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
    );

    if (result == null || result.files.isEmpty) return;

    setState(() => _uploading = true);

    try {
      for (final file in result.files) {
        await _storageService.uploadFile(
          file: file,
          userId: user.uid,
          projectId: _selectedProjectId,
          description: 'Uploaded from contractor dashboard',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Uploaded ${result.files.length} file(s) successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ElevatedButton.icon(
            onPressed: _uploading ? null : _pickAndUploadFiles,
            icon: _uploading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file),
            label: Text(_uploading ? 'Uploading...' : 'Upload Photos/Files'),
          ),
          const SizedBox(height: 16),
          if (_uploadedFiles.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'No files uploaded yet.\nTap the button above to upload photos or documents.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            ),
          ..._uploadedFiles.map((file) => Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: file.isImage
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            file.downloadUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.broken_image),
                          ),
                        )
                      : const Icon(Icons.insert_drive_file, size: 40),
                  title: Text(file.fileName),
                  subtitle: Text('${file.sizeFormatted} • ${_formatDate(file.uploadedAt)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.download),
                        onPressed: () => _downloadFile(file),
                        tooltip: 'Download',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(file),
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.month}/${date.day}/${date.year}';
  }

  Future<void> _downloadFile(FileMetadata file) async {
    // For web, open in new tab
    // For mobile, would implement actual download
    // ignore: deprecated_member_use
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening ${file.fileName}...')),
    );
    // In production, use url_launcher to open the download URL
    // await launchUrl(Uri.parse(file.downloadUrl));
  }

  Future<void> _confirmDelete(FileMetadata file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Are you sure you want to delete "${file.fileName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _storageService.deleteFile(file.id, file.storagePath);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete file: $e')),
          );
        }
      }
    }
  }
}
