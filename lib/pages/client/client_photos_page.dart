import 'package:flutter/material.dart';
import '../../services/storage_service.dart';

class ClientPhotosPage extends StatefulWidget {
  const ClientPhotosPage({super.key});

  @override
  State<ClientPhotosPage> createState() => _ClientPhotosPageState();
}

class _ClientPhotosPageState extends State<ClientPhotosPage> {
  final StorageService _storageService = StorageService();
  String? _selectedProjectId; // In real app, get from dropdown/context
  bool _showGridView = true;

  @override
  Widget build(BuildContext context) {
    // In a real app, fetch files for client's projects
    // For now, showing all files (demo)
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Photos & Files'),
        actions: [
          IconButton(
            icon: Icon(_showGridView ? Icons.list : Icons.grid_view),
            onPressed: () => setState(() => _showGridView = !_showGridView),
            tooltip: _showGridView ? 'List View' : 'Grid View',
          ),
        ],
      ),
      body: StreamBuilder<List<FileMetadata>>(
        // In production, filter by client's projects
        // For demo, showing all files
        stream: _selectedProjectId != null
            ? _storageService.getProjectFiles(_selectedProjectId!)
            : Stream.value([]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final files = snapshot.data ?? [];

          if (files.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'No photos or files yet.\nYour contractor will upload project updates here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            );
          }

          // Separate images and other files
          final images = files.where((f) => f.isImage).toList();
          final otherFiles = files.where((f) => !f.isImage).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (images.isNotEmpty) ...[
                const Text(
                  'Photos',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _showGridView
                    ? _buildPhotoGrid(images)
                    : _buildFileList(images),
                const SizedBox(height: 24),
              ],
              if (otherFiles.isNotEmpty) ...[
                const Text(
                  'Documents',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildFileList(otherFiles),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildPhotoGrid(List<FileMetadata> images) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final image = images[index];
        return GestureDetector(
          onTap: () => _viewFullscreen(image),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              image.downloadUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image, size: 40),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFileList(List<FileMetadata> files) {
    return Column(
      children: files.map((file) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
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
                : Icon(
                    _getFileIcon(file.contentType),
                    size: 40,
                    color: Colors.blue,
                  ),
            title: Text(file.fileName),
            subtitle: Text('${file.sizeFormatted} • ${_formatDate(file.uploadedAt)}'),
            trailing: IconButton(
              icon: const Icon(Icons.download),
              onPressed: () => _downloadFile(file),
            ),
            onTap: file.isImage ? () => _viewFullscreen(file) : null,
          ),
        );
      }).toList(),
    );
  }

  IconData _getFileIcon(String contentType) {
    if (contentType.contains('pdf')) return Icons.picture_as_pdf;
    if (contentType.contains('word') || contentType.contains('document')) {
      return Icons.description;
    }
    if (contentType.contains('excel') || contentType.contains('spreadsheet')) {
      return Icons.table_chart;
    }
    return Icons.insert_drive_file;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.month}/${date.day}/${date.year}';
  }

  Future<void> _viewFullscreen(FileMetadata file) async {
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(file.fileName),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () => _downloadFile(file),
                ),
              ],
            ),
            Expanded(
              child: InteractiveViewer(
                child: Image.network(
                  file.downloadUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      const Center(child: Icon(Icons.broken_image, size: 80)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadFile(FileMetadata file) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening ${file.fileName}...')),
    );
    // In production, use url_launcher to open/download the file
    // await launchUrl(Uri.parse(file.downloadUrl));
  }
}
