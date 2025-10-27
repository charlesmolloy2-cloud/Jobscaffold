import 'package:flutter/material.dart';
import '../../services/budget_service.dart';
import '../../models/budget.dart';


// Top-level helper for add/edit item dialog
Future<void> _showAddEditItem(BuildContext context, BudgetService service, String budgetId, {BudgetItem? existing}) async {
  // TODO: Move the actual dialog code here from the previous _BudgetContent implementation
  // For now, show a placeholder dialog
  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(existing == null ? 'Add Item' : 'Edit Item'),
      content: const Text('Add/Edit item dialog goes here.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    ),
  );
}

// Top-level helper for receipts bottom sheet
Future<void> _showReceiptsSheet(BuildContext context, BudgetService service, String budgetId, String projectId, BudgetItem item) async {
  // TODO: Move the actual bottom sheet code here from the previous _BudgetContent implementation
  // For now, show a placeholder bottom sheet
  await showModalBottomSheet(
    context: context,
    builder: (context) => Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Receipts for ${item.description.isEmpty ? item.category : item.description}', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text('Receipts bottom sheet goes here.'),
          const SizedBox(height: 12),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    ),
  );
}

class BudgetPage extends StatefulWidget {
  final String projectId;
  final String? projectName;
  const BudgetPage({super.key, required this.projectId, this.projectName});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  final _service = BudgetService();
  String? _budgetId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final id = await _service.createOrGetBudget(widget.projectId);
    if (mounted) setState(() => _budgetId = id);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.projectName != null
        ? 'Budget — ${widget.projectName}'
        : 'Budget';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _budgetId == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder(
              stream: _service.watchBudgetByProject(widget.projectId),
              builder: (context, AsyncSnapshot<Budget?> snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final budget = snap.data!;
                return _BudgetContent(
                  budget: budget,
                  budgetId: _budgetId!,
                  service: _service,
                  projectId: widget.projectId,
                );
              },
            ),
    );
  }
}

class _BudgetContent extends StatelessWidget {
  final Budget budget;
  final String budgetId;
  final BudgetService service;
  final String projectId;

  const _BudgetContent({
    required this.budget,
    required this.budgetId,
    required this.service,
    required this.projectId,
  });

  String _currency(num v) => '4${v.toStringAsFixed(2)}'.replaceAll('\u0002', '\\');

  @override
  Widget build(BuildContext context) {
    final overrun = budget.variance > 0;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _KpiCard(label: 'Estimate', value: _currency(budget.totalEstimate), color: Colors.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _KpiCard(label: 'Actual', value: _currency(budget.totalActual), color: overrun ? Colors.red : Colors.green),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Progress'),
                  const SizedBox(width: 8),
                  Text('${(budget.progress * 100).toStringAsFixed(0)}%'),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: budget.progress.clamp(0, 1),
                backgroundColor: Colors.grey[300],
                color: overrun ? Colors.red : Colors.blue,
                minHeight: 10,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: StreamBuilder<List<BudgetItem>>(
            stream: service.watchItems(budgetId),
            builder: (context, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              final items = snap.data!;
              if (items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 56, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text('No budget items yet', style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 6),
                      Text('Tap + to add your first item', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    ],
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) => _ItemTile(
                  item: items[i],
                  onEdit: () => _showAddEditItem(context, service, budgetId, existing: items[i]),
                  onDelete: () => service.deleteItem(budgetId, items[i].id),
                  onReceipts: () => _showReceiptsSheet(context, service, budgetId, projectId, items[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _KpiCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final BudgetItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onReceipts;
  const _ItemTile({required this.item, required this.onEdit, required this.onDelete, required this.onReceipts});

  @override
  Widget build(BuildContext context) {
    final over = item.actual > item.estimate;
    return Card(
      child: ListTile(
        title: Row(
          children: [
            Expanded(
              child: Text(item.description.isEmpty ? item.category : item.description, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            if (item.receiptUrls.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue[200]!)),
                child: Row(children: [const Icon(Icons.receipt_long, size: 16, color: Colors.blue), const SizedBox(width: 4), Text('${item.receiptUrls.length}', style: const TextStyle(fontSize: 12, color: Colors.blue))]),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.category, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 4),
            Row(children: [Text('Est: ${_currency(item.estimate)}', style: TextStyle(color: Colors.blue[700])), const SizedBox(width: 12), Text('Act: ${_currency(item.actual)}', style: TextStyle(color: over ? Colors.red : Colors.green))]),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') onEdit();
            if (value == 'receipts') onReceipts();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'receipts', child: Text('Receipts')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}

// Top-level helper for currency formatting
String _currency(num v) {
  return '\$${v.toStringAsFixed(2)}';
}

