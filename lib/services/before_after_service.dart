import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/before_after_set.dart';
import 'storage_service.dart';
import 'package:file_picker/file_picker.dart';

class BeforeAfterService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storage = StorageService();

  CollectionReference<Map<String, dynamic>> get _sets => _firestore.collection('beforeAfterSets');

  Stream<List<BeforeAfterSet>> watchSets(String projectId) {
    return _sets.where('projectId', isEqualTo: projectId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => BeforeAfterSet.fromFirestore(d)).toList());
  }

  Future<void> addSet({
    required String projectId,
    required String title,
    required String description,
    required PlatformFile beforeFile,
    required PlatformFile afterFile,
    DateTime? afterDate,
  }) async {
    final beforeDocId = await _storage.uploadFile(
      file: beforeFile,
      userId: 'system', // Replace with actual user if needed
      projectId: projectId,
      description: 'Before photo',
    );
    final afterDocId = await _storage.uploadFile(
      file: afterFile,
      userId: 'system',
      projectId: projectId,
      description: 'After photo',
    );
    final beforeMeta = await _firestore.collection('files').doc(beforeDocId).get();
    final afterMeta = await _firestore.collection('files').doc(afterDocId).get();
    final beforeUrl = (beforeMeta.data() ?? const {})['downloadUrl'] as String?;
    final afterUrl = (afterMeta.data() ?? const {})['downloadUrl'] as String?;
    if (beforeUrl == null || afterUrl == null) return;
    await _sets.add({
      'projectId': projectId,
      'title': title,
      'description': description,
      'beforeUrl': beforeUrl,
      'afterUrl': afterUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'afterDate': afterDate != null ? Timestamp.fromDate(afterDate) : null,
    });
  }

  Future<void> deleteSet(String setId) async {
    await _sets.doc(setId).delete();
  }
}
