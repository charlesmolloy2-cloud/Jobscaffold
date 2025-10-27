import 'package:cloud_firestore/cloud_firestore.dart';

class BeforeAfterSet {
  final String id;
  final String projectId;
  final String title;
  final String description;
  final String beforeUrl;
  final String afterUrl;
  final DateTime createdAt;
  final DateTime? afterDate;

  const BeforeAfterSet({
    required this.id,
    required this.projectId,
    required this.title,
    required this.description,
    required this.beforeUrl,
    required this.afterUrl,
    required this.createdAt,
    this.afterDate,
  });

  factory BeforeAfterSet.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return BeforeAfterSet(
      id: doc.id,
      projectId: data['projectId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      beforeUrl: data['beforeUrl'] ?? '',
      afterUrl: data['afterUrl'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      afterDate: (data['afterDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'projectId': projectId,
      'title': title,
      'description': description,
      'beforeUrl': beforeUrl,
      'afterUrl': afterUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'afterDate': afterDate != null ? Timestamp.fromDate(afterDate!) : null,
    };
  }
}
