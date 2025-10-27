import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/material_order.dart';
import 'package:file_picker/file_picker.dart';
import 'storage_service.dart';

class MaterialOrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storage = StorageService();

  CollectionReference<Map<String, dynamic>> get _orders => _firestore.collection('materialOrders');

  Stream<List<MaterialOrder>> watchOrders(String projectId) {
    return _orders.where('projectId', isEqualTo: projectId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => MaterialOrder.fromFirestore(d)).toList());
  }

  Future<void> addOrder({
    required String projectId,
    required String title,
    required String description,
    required String vendor,
    required double totalCost,
    MaterialOrderStatus status = MaterialOrderStatus.pending,
    DateTime? expectedDelivery,
  }) async {
    await _orders.add({
      'projectId': projectId,
      'title': title,
      'description': description,
      'vendor': vendor,
      'totalCost': totalCost,
      'status': status.toString(),
      'receiptUrls': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
      'expectedDelivery': expectedDelivery != null ? Timestamp.fromDate(expectedDelivery) : null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateOrder(String orderId, Map<String, dynamic> data) async {
    await _orders.doc(orderId).update(data);
  }

  Future<void> deleteOrder(String orderId) async {
    await _orders.doc(orderId).delete();
  }

  Future<void> addReceipt({
    required String orderId,
    required PlatformFile file,
    required String projectId,
  }) async {
    // Upload file and fetch its metadata to get the downloadUrl
    final fileDocId = await _storage.uploadFile(
      file: file,
      userId: 'system', // Replace with actual user if needed
      projectId: projectId,
      description: 'Material order receipt for $orderId',
    );
    final metaDoc = await _firestore.collection('files').doc(fileDocId).get();
    final downloadUrl = (metaDoc.data() ?? const {})['downloadUrl'] as String?;
    if (downloadUrl == null || downloadUrl.isEmpty) return;
    await _orders.doc(orderId).update({
      'receiptUrls': FieldValue.arrayUnion([downloadUrl]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeReceipt({
    required String orderId,
    required String receiptUrl,
  }) async {
    await _orders.doc(orderId).update({
      'receiptUrls': FieldValue.arrayRemove([receiptUrl]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
