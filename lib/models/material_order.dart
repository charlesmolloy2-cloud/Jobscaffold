import 'package:cloud_firestore/cloud_firestore.dart';

enum MaterialOrderStatus { pending, ordered, shipped, delivered, cancelled }

class MaterialOrder {
  final String id;
  final String projectId;
  final String title;
  final String description;
  final String vendor;
  final double totalCost;
  final MaterialOrderStatus status;
  final List<String> receiptUrls;
  final DateTime createdAt;
  final DateTime? expectedDelivery;
  final DateTime? updatedAt;

  const MaterialOrder({
    required this.id,
    required this.projectId,
    required this.title,
    required this.description,
    required this.vendor,
    required this.totalCost,
    required this.status,
    required this.receiptUrls,
    required this.createdAt,
    this.expectedDelivery,
    this.updatedAt,
  });

  factory MaterialOrder.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MaterialOrder(
      id: doc.id,
      projectId: data['projectId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      vendor: data['vendor'] ?? '',
      totalCost: (data['totalCost'] ?? 0).toDouble(),
      status: _parseStatus(data['status']),
      receiptUrls: List<String>.from(data['receiptUrls'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expectedDelivery: (data['expectedDelivery'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'projectId': projectId,
      'title': title,
      'description': description,
      'vendor': vendor,
      'totalCost': totalCost,
      'status': status.toString(),
      'receiptUrls': receiptUrls,
      'createdAt': Timestamp.fromDate(createdAt),
      'expectedDelivery': expectedDelivery != null ? Timestamp.fromDate(expectedDelivery!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  static MaterialOrderStatus _parseStatus(dynamic value) {
    if (value is String) {
      return MaterialOrderStatus.values.firstWhere(
        (e) => e.toString() == value,
        orElse: () => MaterialOrderStatus.pending,
      );
    }
    return MaterialOrderStatus.pending;
  }
}
