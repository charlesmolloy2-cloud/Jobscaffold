import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      // Persist new invoices to Firestore and retain docId for payments/webhook reconciliation
      if (index == null) {
        final created = await _createInvoiceInFirestore(result);
        setState(() => _invoices.add(created));
      } else {
        // For edits, update Firestore if a doc exists
        final updated = await _updateInvoiceInFirestore(result);
        setState(() => _invoices[index] = updated);
      }
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
              subtitle: Text('Amount: ${inv.amount}\n${inv.description}${inv.statusLabel}'),
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
                  IconButton(
                    tooltip: 'Collect Payment',
                    icon: const Icon(Icons.payment, color: Colors.blue),
                    onPressed: () => _collectPayment(inv),
                  ),
                ],
              ),
            ),
          );
        },
      ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'fab-payments',
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
  String? docId; // Firestore document id
  String status; // pending | paid
  _Invoice({required this.title, required this.description, required this.amount, this.docId, this.status = 'pending'});

  Map<String, dynamic> toMap(String userId) => {
        'title': title,
        'description': description,
        'amount': amount,
        'amountCents': (amount * 100).round(),
        'currency': 'usd',
        'status': status,
        'userId': userId,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      };
}

extension _InvoiceUi on _Invoice {
  String get statusLabel => status == 'paid' ? '\nStatus: PAID' : '';
}

class _InvoiceDialog extends StatefulWidget {
  final _Invoice? invoice;
  const _InvoiceDialog({this.invoice});

  @override
  State<_InvoiceDialog> createState() => _InvoiceDialogState();
}

extension on _PaymentsPageState {
  Future<_Invoice> _createInvoiceInFirestore(_Invoice inv) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return inv; // not signed in; skip persistence
    final col = FirebaseFirestore.instance.collection('invoices');
    final doc = await col.add(inv.toMap(uid));
    return _Invoice(
      title: inv.title,
      description: inv.description,
      amount: inv.amount,
      docId: doc.id,
      status: inv.status,
    );
  }

  Future<_Invoice> _updateInvoiceInFirestore(_Invoice inv) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || inv.docId == null) return inv;
    await FirebaseFirestore.instance.collection('invoices').doc(inv.docId).set({
      'title': inv.title,
      'description': inv.description,
      'amount': inv.amount,
      'amountCents': (inv.amount * 100).round(),
      'currency': 'usd',
      'status': inv.status,
      'userId': uid,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return inv;
  }

  Future<void> _collectPayment(_Invoice inv) async {
    try {
      // Create a Stripe Checkout session via Firebase Functions
      final cf = FirebaseFunctions.instance;
      final callable = cf.httpsCallable('createCheckoutSession');
      final origin = Uri.base.origin; // current host for redirects
      // Ensure invoice exists in Firestore to reconcile with webhook
      if (inv.docId == null) {
        final persisted = await _createInvoiceInFirestore(inv);
        inv.docId = persisted.docId;
      }
      final result = await callable.call({
        'title': inv.title,
        'description': inv.description,
        'amount': (inv.amount * 100).round(), // cents
        'currency': 'usd',
        'successUrl': '$origin/payments/success',
        'cancelUrl': '$origin/payments/cancel',
        'invoiceId': inv.docId,
      });
      final data = result.data as Map;
      final url = data['url']?.toString();
      if (url == null) throw Exception('No checkout URL returned');
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch checkout');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: $e')),
        );
      }
    }
  }
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
              docId: widget.invoice?.docId,
              status: widget.invoice?.status ?? 'pending',
            ));
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
