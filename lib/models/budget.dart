import 'package:cloud_firestore/cloud_firestore.dart';

enum BudgetItemStatus { planned, ordered, received, invoiced, paid }

class Budget {
  final String id;
  final String projectId;
  final double totalEstimate;
  final double totalActual;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Budget({
    required this.id,
    required this.projectId,
    required this.totalEstimate,
    required this.totalActual,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
  });

  double get variance => totalActual - totalEstimate;
  double get progress => totalEstimate <= 0 ? 0 : (totalActual / totalEstimate).clamp(0, 2);

  factory Budget.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Budget(
      id: doc.id,
      projectId: data['projectId'] ?? '',
      totalEstimate: (data['totalEstimate'] ?? 0).toDouble(),
      totalActual: (data['totalActual'] ?? 0).toDouble(),
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'projectId': projectId,
      'totalEstimate': totalEstimate,
      'totalActual': totalActual,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}

class BudgetItem {
  final String id;
  final String budgetId;
  final String category;
  final String description;
  final double estimate;
  final double actual;
  final BudgetItemStatus status;
  final String? vendor;
  final List<String> receiptUrls;
  final DateTime createdAt;

  const BudgetItem({
    required this.id,
    required this.budgetId,
    required this.category,
    required this.description,
    required this.estimate,
    required this.actual,
    required this.status,
    this.vendor,
    required this.receiptUrls,
    required this.createdAt,
  });

  factory BudgetItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return BudgetItem(
      id: doc.id,
      budgetId: data['budgetId'] ?? '',
      category: data['category'] ?? 'General',
      description: data['description'] ?? '',
      estimate: (data['estimate'] ?? 0).toDouble(),
      actual: (data['actual'] ?? 0).toDouble(),
      status: _statusFromString(data['status'] as String?),
      vendor: data['vendor'] as String?,
      receiptUrls: List<String>.from(data['receiptUrls'] ?? const []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'budgetId': budgetId,
      'category': category,
      'description': description,
      'estimate': estimate,
      'actual': actual,
      'status': status.toString(),
      'vendor': vendor,
      'receiptUrls': receiptUrls,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static BudgetItemStatus _statusFromString(String? v) {
    return BudgetItemStatus.values.firstWhere(
      (e) => e.toString() == v,
      orElse: () => BudgetItemStatus.planned,
    );
  }
}
