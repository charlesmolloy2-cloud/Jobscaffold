import 'package:flutter/material.dart';
import '../../models/material_order.dart';
import '../../services/material_order_service.dart';
import 'material_order_detail_sheet.dart';

class MaterialOrdersPage extends StatefulWidget {
  final String projectId;
  const MaterialOrdersPage({super.key, required this.projectId});

  @override
  State<MaterialOrdersPage> createState() => _MaterialOrdersPageState();
}

class _MaterialOrdersPageState extends State<MaterialOrdersPage> {
  final _service = MaterialOrderService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Material Orders')),
      body: StreamBuilder<List<MaterialOrder>>(
        stream: _service.watchOrders(widget.projectId),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final orders = snap.data!;
          if (orders.isEmpty) {
            return Center(
              child: Text('No material orders yet', style: TextStyle(color: Colors.grey[600])),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) => Card(
              child: ListTile(
                title: Text(orders[i].title, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(orders[i].vendor),
                trailing: Text(orders[i].status.name),
                onTap: () async {
                  await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    builder: (context) => MaterialOrderDetailSheet(
                      order: orders[i],
                      projectId: widget.projectId,
                      service: _service,
                      onChanged: () => setState(() {}),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOrderDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddOrderDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final vendorCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    MaterialOrderStatus status = MaterialOrderStatus.pending;
    DateTime? expectedDelivery;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Material Order'),
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
                TextFormField(
                  controller: vendorCtrl,
                  decoration: const InputDecoration(labelText: 'Vendor'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                TextFormField(
                  controller: costCtrl,
                  decoration: const InputDecoration(labelText: 'Total Cost'),
                  keyboardType: TextInputType.number,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                DropdownButtonFormField<MaterialOrderStatus>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: MaterialOrderStatus.values.map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s.name),
                  )).toList(),
                  onChanged: (s) => status = s!,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Expected Delivery:'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(expectedDelivery != null
                          ? '${expectedDelivery!.year}-${expectedDelivery!.month.toString().padLeft(2, '0')}-${expectedDelivery!.day.toString().padLeft(2, '0')}'
                          : 'Not set'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: expectedDelivery ?? now,
                          firstDate: now,
                          lastDate: DateTime(now.year + 5),
                        );
                        if (picked != null) {
                          expectedDelivery = picked;
                          // ignore: use_build_context_synchronously
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
              if (formKey.currentState!.validate()) Navigator.pop(context, true);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _service.addOrder(
        projectId: widget.projectId,
        title: titleCtrl.text.trim(),
        description: descCtrl.text.trim(),
        vendor: vendorCtrl.text.trim(),
        totalCost: double.tryParse(costCtrl.text) ?? 0.0,
        status: status,
        expectedDelivery: expectedDelivery,
      );
    }
  }
}
