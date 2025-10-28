import 'package:flutter/material.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({Key? key}) : super(key: key);

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

enum _QuickRange { last30, last90, ytd, custom }

class _AnalyticsPageState extends State<AnalyticsPage> {
  final List<_Stat> _stats = [];
  _QuickRange _range = _QuickRange.last30;
  DateTimeRange? _customRange;

  DateTimeRange get _activeRange {
    final now = DateTime.now();
    switch (_range) {
      case _QuickRange.last30:
        return DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now);
      case _QuickRange.last90:
        return DateTimeRange(start: now.subtract(const Duration(days: 90)), end: now);
      case _QuickRange.ytd:
        return DateTimeRange(start: DateTime(now.year, 1, 1), end: now);
      case _QuickRange.custom:
        return _customRange ?? DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now);
    }
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2022, 1, 1),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _activeRange,
    );
    if (picked != null) {
      setState(() {
        _range = _QuickRange.custom;
        _customRange = picked;
      });
    }
  }

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

  Widget _kpiCard(String title, String value, IconData icon, {Color? color}) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color ?? Colors.blueGrey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _barChart(String title, List<double> values, {Color? color}) {
    final maxVal = values.fold<double>(0, (p, v) => v > p ? v : p);
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            SizedBox(
              height: 160,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final v in values)
                    Expanded(
                      child: Container(
                        height: maxVal == 0 ? 0 : (v / maxVal) * 130 + 10,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: (color ?? Colors.blueGrey).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _donut(String title, Map<String, double> parts, {List<Color>? colors}) {
    final total = parts.values.fold<double>(0, (p, v) => p + v);
    final cols = colors ?? [
      Colors.teal, Colors.indigo, Colors.orange, Colors.purple, Colors.blueGrey,
    ];
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Simple ring using many arcs as solid segments (approximation)
                      for (int i = 0; i < parts.length; i++)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _ArcPainter(
                              startPercent: parts.values.toList().take(i).fold<double>(0, (p, v) => p + v) / (total == 0 ? 1 : total),
                              sweepPercent: parts.values.elementAt(i) / (total == 0 ? 1 : total),
                              color: cols[i % cols.length],
                            ),
                          ),
                        ),
                      Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(72),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      for (int i = 0; i < parts.length; i++)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 10, height: 10, color: cols[i % cols.length]),
                            const SizedBox(width: 6),
                            Text('${parts.keys.elementAt(i)}'),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    final r = _activeRange;
    final titleSuffix = '(${r.start.month}/${r.start.day} - ${r.end.month}/${r.end.day})';

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics & Reporting')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filters
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Last 30 days'),
                  selected: _range == _QuickRange.last30,
                  onSelected: (_) => setState(() => _range = _QuickRange.last30),
                ),
                ChoiceChip(
                  label: const Text('Last 90 days'),
                  selected: _range == _QuickRange.last90,
                  onSelected: (_) => setState(() => _range = _QuickRange.last90),
                ),
                ChoiceChip(
                  label: const Text('Year to date'),
                  selected: _range == _QuickRange.ytd,
                  onSelected: (_) => setState(() => _range = _QuickRange.ytd),
                ),
                ActionChip(
                  label: Text(_range == _QuickRange.custom && _customRange != null ? 'Custom $titleSuffix' : 'Custom range'),
                  onPressed: _pickCustomRange,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // KPIs
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isWide ? 3 : 1,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: isWide ? 3.2 : 3.6,
              ),
              children: [
                _kpiCard('Open Jobs', '12', Icons.work_outline, color: Colors.teal),
                _kpiCard('Revenue $titleSuffix', '\$124,800', Icons.payments_outlined, color: Colors.indigo),
                _kpiCard('Avg Payment Days', '7.8', Icons.schedule_outlined, color: Colors.deepPurple),
              ],
            ),
            const SizedBox(height: 12),

            // Charts
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isWide ? 2 : 1,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.4,
              ),
              children: [
                _barChart('Revenue by Month $titleSuffix', [24, 56, 40, 72, 68, 90, 62, 96, 84, 110, 120, 140], color: Colors.indigo),
                _donut('Job Status Distribution', {
                  'Leads': 8,
                  'Active': 12,
                  'On hold': 2,
                  'Completed': 20,
                }),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text('Custom stats', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (_stats.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('Add your own custom stats to track what matters for your workflow.'),
              ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _stats.length,
              itemBuilder: (context, i) {
                final s = _stats[i];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
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
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-analytics',
        onPressed: () => _addOrEditStat(),
        child: const Icon(Icons.add),
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

class _ArcPainter extends CustomPainter {
  final double startPercent; // 0..1
  final double sweepPercent; // 0..1
  final Color color;
  _ArcPainter({required this.startPercent, required this.sweepPercent, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.butt;
    final startAngle = (startPercent * 360 - 90) * 3.1415926535 / 180;
    final sweepAngle = (sweepPercent * 360) * 3.1415926535 / 180;
    canvas.drawArc(rect.deflate(18), startAngle, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) {
    return oldDelegate.startPercent != startPercent || oldDelegate.sweepPercent != sweepPercent || oldDelegate.color != color;
  }
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
