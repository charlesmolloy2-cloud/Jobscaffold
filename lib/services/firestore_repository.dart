import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/project.dart' as app_models;
import '../models/update.dart' as app_updates;

class FirestoreRepository {
  FirestoreRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  // Collections
  CollectionReference<Map<String, dynamic>> get _projects => _db.collection('projects');
  CollectionReference<Map<String, dynamic>> get _updates => _db.collection('updates');

  // Mapping
  static app_models.Project _projectFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return app_models.Project(
      id: doc.id,
      title: d['title'] as String? ?? 'Untitled',
      address: d['address'] as String? ?? 'TBD',
      status: d['status'] as String? ?? 'new',
      lastUpdateAt: (d['lastUpdateAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      assignedCustomerId: d['assignedCustomerId'] as String? ?? '',
      assignedContractorId: d['assignedContractorId'] as String? ?? '',
    );
  }

  static Map<String, dynamic> _projectToMap(app_models.Project p) => {
        'title': p.title,
        'address': p.address,
        'status': p.status,
        'lastUpdateAt': Timestamp.fromDate(p.lastUpdateAt),
        'assignedCustomerId': p.assignedCustomerId,
        'assignedContractorId': p.assignedContractorId,
      };

  static app_updates.Update _updateFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final List<dynamic>? photos = d['photos'] as List<dynamic>?;
    return app_updates.Update(
      id: doc.id,
      projectId: d['projectId'] as String? ?? '',
      message: d['message'] as String? ?? '',
      timestamp: (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      photos: photos?.map((e) => e.toString()).toList(),
    );
  }

  static Map<String, dynamic> _updateToMap(app_updates.Update u) => {
        'projectId': u.projectId,
        'message': u.message,
        'timestamp': Timestamp.fromDate(u.timestamp),
        if (u.photos != null) 'photos': u.photos,
      };

  // Project streams
  Stream<List<app_models.Project>> watchProjectsForCustomer(String customerId) => _projects
      .where('assignedCustomerId', isEqualTo: customerId)
      .orderBy('lastUpdateAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(_projectFromDoc).toList());

  Stream<List<app_models.Project>> watchProjectsForContractor(String contractorId) => _projects
      .where('assignedContractorId', isEqualTo: contractorId)
      .orderBy('lastUpdateAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(_projectFromDoc).toList());

  Future<void> createProject(app_models.Project p) async {
    await _projects.add(_projectToMap(p));
  }

  Future<void> createProjectWithId(String id, app_models.Project p) async {
    await _projects.doc(id).set(_projectToMap(p));
  }

  Future<void> createProjectWithExtras(String id, app_models.Project p, Map<String, dynamic> extras) async {
    final data = {
      ..._projectToMap(p),
      ...extras,
    };
    await _projects.doc(id).set(data);
  }

  Future<void> updateProject(app_models.Project p) async {
    await _projects.doc(p.id).set(_projectToMap(p), SetOptions(merge: true));
  }

  Future<void> deleteProject(String id) async {
    await _projects.doc(id).delete();
  }

  Stream<app_models.Project?> watchProject(String id) => _projects.doc(id).snapshots().map(
        (doc) => doc.exists ? _projectFromDoc(doc) : null,
      );

  // Raw snapshot stream (includes extra fields like description/budget/startDate)
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchProjectSnapshot(String id) => _projects.doc(id).snapshots();

  Future<Map<String, dynamic>?> getProjectData(String id) async {
    final snap = await _projects.doc(id).get();
    return snap.data();
  }

  Future<void> updateProjectExtras(String id, Map<String, dynamic> data) async {
    if (data.isEmpty) return;
    await _projects.doc(id).set(data, SetOptions(merge: true));
  }

  // Updates
  Stream<List<app_updates.Update>> watchUpdates(String projectId) => _updates
      .where('projectId', isEqualTo: projectId)
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((s) => s.docs.map(_updateFromDoc).toList());

  Future<void> addUpdate(app_updates.Update u) async {
    await _updates.add(_updateToMap(u));
  }
}
