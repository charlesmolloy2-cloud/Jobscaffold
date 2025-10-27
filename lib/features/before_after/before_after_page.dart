import 'package:flutter/material.dart';
import '../../models/before_after_set.dart';
import '../../services/before_after_service.dart';
import 'before_after_slider.dart';
import 'package:file_picker/file_picker.dart';

class BeforeAfterPage extends StatefulWidget {
  final String projectId;
  const BeforeAfterPage({super.key, required this.projectId});

  @override
  State<BeforeAfterPage> createState() => _BeforeAfterPageState();
}

class _BeforeAfterPageState extends State<BeforeAfterPage> {
  final _service = BeforeAfterService();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Before/After Comparisons'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'List'),
              Tab(text: 'Timeline'),
              Tab(text: 'Portfolio'),
            ],
          ),
        ),
        body: StreamBuilder<List<BeforeAfterSet>>(
          stream: _service.watchSets(widget.projectId),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final sets = snap.data!;
            return TabBarView(
              children: [
                _buildListView(context, sets),
                _buildTimelineView(context, sets),
                _buildPortfolioView(context, sets),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddSetDialog(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _emptyPlaceholder(String text) => Center(
        child: Text(text, style: TextStyle(color: Colors.grey[600])),
      );

  Widget _buildListView(BuildContext context, List<BeforeAfterSet> sets) {
    if (sets.isEmpty) return _emptyPlaceholder('No before/after sets yet');
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sets.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, i) => Card(
        child: ListTile(
          title: Text(sets[i].title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(sets[i].description),
          onTap: () => _openSlider(context, sets[i]),
          trailing: IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete set',
            onPressed: () => _confirmDelete(context, sets[i].id),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineView(BuildContext context, List<BeforeAfterSet> sets) {
    if (sets.isEmpty) return _emptyPlaceholder('No timeline entries yet');
    final sorted = [...sets]
      ..sort((a, b) => (a.afterDate ?? a.createdAt).compareTo(b.afterDate ?? b.createdAt));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      itemBuilder: (context, i) {
        final s = sorted[i];
        final date = s.afterDate ?? s.createdAt;
        final d = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        return Card(
          child: ListTile(
            leading: SizedBox(
              width: 56,
              child: Row(
                children: [
                  Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: Image.network(s.beforeUrl, fit: BoxFit.cover))),
                  const SizedBox(width: 2),
                  Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: Image.network(s.afterUrl, fit: BoxFit.cover))),
                ],
              ),
            ),
            title: Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(d),
            onTap: () => _openSlider(context, s),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _confirmDelete(context, s.id),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPortfolioView(BuildContext context, List<BeforeAfterSet> sets) {
    if (sets.isEmpty) return _emptyPlaceholder('No portfolio items yet');
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: sets.length,
      itemBuilder: (context, i) {
        final s = sets[i];
        return GestureDetector(
          onTap: () => _openSlider(context, s),
          child: Card(
            clipBehavior: Clip.hardEdge,
            child: Stack(
              children: [
                Positioned.fill(child: Image.network(s.beforeUrl, fit: BoxFit.cover)),
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.5,
                    child: Image.network(s.afterUrl, fit: BoxFit.cover),
                  ),
                ),
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                    child: Text(s.title, style: const TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, String setId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Set'),
        content: const Text('Are you sure you want to delete this before/after set?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true) {
      await _service.deleteSet(setId);
      if (mounted) setState(() {});
    }
  }

  void _openSlider(BuildContext context, BeforeAfterSet s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => BeforeAfterSlider(
        beforeUrl: s.beforeUrl,
        afterUrl: s.afterUrl,
        title: s.title,
      ),
    );
  }

  Future<void> _showAddSetDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
  PlatformFile? beforeFile;
  PlatformFile? afterFile;
  DateTime? afterDate;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Before/After Set'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                TextFormField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Before Photo:'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(beforeFile?.name ?? 'Not selected'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.photo_camera),
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles(type: FileType.image);
                        if (result != null && result.files.isNotEmpty) {
                          beforeFile = result.files.first;
                          (context as Element).markNeedsBuild();
                        }
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text('After Photo:'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(afterFile?.name ?? 'Not selected'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.photo_camera),
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles(type: FileType.image);
                        if (result != null && result.files.isNotEmpty) {
                          afterFile = result.files.first;
                          (context as Element).markNeedsBuild();
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('After Date:'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(afterDate != null
                          ? '${afterDate!.year}-${afterDate!.month.toString().padLeft(2, '0')}-${afterDate!.day.toString().padLeft(2, '0')}'
                          : 'Not set'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: afterDate ?? now,
                          firstDate: DateTime(now.year - 5),
                          lastDate: DateTime(now.year + 5),
                        );
                        if (picked != null) {
                          afterDate = picked;
                          (context as Element).markNeedsBuild();
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate() && beforeFile != null && afterFile != null) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (confirmed == true && beforeFile != null && afterFile != null) {
      await _service.addSet(
        projectId: widget.projectId,
        title: titleCtrl.text.trim(),
        description: descCtrl.text.trim(),
        beforeFile: beforeFile!,
        afterFile: afterFile!,
        afterDate: afterDate,
      );
      setState(() {});
    }
  }
}
