
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({Key? key}) : super(key: key);

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  final List<_Invoice> _invoices = [];

  void _addOrEditInvoice([_Invoice? invoice, int? index]) async {
    final result = await showDialog<_Invoice>(
      context: context,
      builder: (context) => _InvoiceDialog(invoice: invoice),
    );
    if (result != null) {
      setState(() {
        if (index != null) {
          _invoices[index] = result;
        } else {
          _invoices.add(result);
        }
      });
    }
  }

  void _deleteInvoice(int index) {
    setState(() {
      _invoices.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payments & Invoicing')),
      body: ListView.builder(
        itemCount: _invoices.length,
        itemBuilder: (context, i) {
          final inv = _invoices[i];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.receipt_long),
              title: Text(inv.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Amount: ${inv.amount}\n${inv.description}'),
              isThreeLine: true,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.green),
                    onPressed: () => _addOrEditInvoice(inv, i),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteInvoice(i),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditInvoice(),
        child: const Icon(Icons.receipt_long),
        tooltip: 'Create Invoice',
      ),
    );
  }
}

class _Invoice {
  String title;
  String description;
  double amount;
  _Invoice({required this.title, required this.description, required this.amount});
}

class _InvoiceDialog extends StatefulWidget {
  final _Invoice? invoice;
  const _InvoiceDialog({this.invoice});

  @override
  State<_InvoiceDialog> createState() => _InvoiceDialogState();
}

class _InvoiceDialogState extends State<_InvoiceDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.invoice?.title ?? '');
    _descController = TextEditingController(text: widget.invoice?.description ?? '');
    _amountController = TextEditingController(text: widget.invoice?.amount.toString() ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.invoice == null ? 'Create Invoice' : 'Edit Invoice'),
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
            controller: _amountController,
            decoration: const InputDecoration(labelText: 'Amount'),
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
            if (_titleController.text.trim().isEmpty || double.tryParse(_amountController.text.trim()) == null) return;
            Navigator.pop(context, _Invoice(
              title: _titleController.text.trim(),
              description: _descController.text.trim(),
              amount: double.parse(_amountController.text.trim()),
            ));
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
