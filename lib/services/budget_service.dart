import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import '../models/budget.dart';
import 'storage_service.dart';

class BudgetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final StorageService _storage = StorageService();

  CollectionReference<Map<String, dynamic>> get _budgets => _firestore.collection('budgets');

  Future<String> createOrGetBudget(String projectId) async {
    // Try to find existing budget for project
    final existing = await _budgets.where('projectId', isEqualTo: projectId).limit(1).get();
    if (existing.docs.isNotEmpty) return existing.docs.first.id;

    final userId = _auth.currentUser?.uid ?? 'system';
    final doc = await _budgets.add({
      'projectId': projectId,
      'totalEstimate': 0.0,
      'totalActual': 0.0,
      'createdBy': userId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Stream<Budget?> watchBudgetByProject(String projectId) {
    return _budgets.where('projectId', isEqualTo: projectId).limit(1).snapshots().map((snap) {
      if (snap.docs.isEmpty) return null;
      return Budget.fromFirestore(snap.docs.first);
    });
  }

  Stream<List<BudgetItem>> watchItems(String budgetId) {
    return _budgets.doc(budgetId).collection('items')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => BudgetItem.fromFirestore(d)).toList());
  }

  Future<void> addItem({
    required String budgetId,
    required String category,
    required String description,
    required double estimate,
    double actual = 0,
    BudgetItemStatus status = BudgetItemStatus.planned,
    String? vendor,
  }) async {
    await _budgets.doc(budgetId).collection('items').add({
      'budgetId': budgetId,
      'category': category,
      'description': description,
      'estimate': estimate,
      'actual': actual,
      'status': status.toString(),
      'vendor': vendor,
      'receiptUrls': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
    });
    await recalcTotals(budgetId);
  }

  Future<void> updateItem(String budgetId, String itemId, Map<String, dynamic> data) async {
    await _budgets.doc(budgetId).collection('items').doc(itemId).update(data);
    await recalcTotals(budgetId);
  }

  Future<void> deleteItem(String budgetId, String itemId) async {
    await _budgets.doc(budgetId).collection('items').doc(itemId).delete();
    await recalcTotals(budgetId);
  }

  /// Upload a receipt to Storage and attach its download URL to the budget item
  Future<void> addReceipt({
    required String budgetId,
    required String itemId,
    required PlatformFile file,
    required String projectId,
  }) async {
    final userId = _auth.currentUser?.uid ?? 'system';
    // Upload file and fetch its metadata to get the downloadUrl
    final fileDocId = await _storage.uploadFile(
      file: file,
      userId: userId,
      projectId: projectId,
      description: 'Budget receipt for $itemId',
    );
    final metaDoc = await _firestore.collection('files').doc(fileDocId).get();
    final downloadUrl = (metaDoc.data() ?? const {})['downloadUrl'] as String?;
    if (downloadUrl == null || downloadUrl.isEmpty) return;

    await _budgets.doc(budgetId).collection('items').doc(itemId).update({
      'receiptUrls': FieldValue.arrayUnion([downloadUrl]),
    });
  }

  Future<void> removeReceipt({
    required String budgetId,
    required String itemId,
    required String receiptUrl,
  }) async {
    await _budgets.doc(budgetId).collection('items').doc(itemId).update({
      'receiptUrls': FieldValue.arrayRemove([receiptUrl]),
    });
  }

  Future<void> recalcTotals(String budgetId) async {
    final itemsSnap = await _budgets.doc(budgetId).collection('items').get();
    double totalEst = 0;
    double totalAct = 0;
    for (final d in itemsSnap.docs) {
      final data = d.data();
      totalEst += (data['estimate'] ?? 0).toDouble();
      totalAct += (data['actual'] ?? 0).toDouble();
    }
    await _budgets.doc(budgetId).update({
      'totalEstimate': totalEst,
      'totalActual': totalAct,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
