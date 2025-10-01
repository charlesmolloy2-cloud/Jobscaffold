
enum ProjectStatus { inProgress, completed, blocked }

class Project {
  final String id;
  String title;
  String client;
  ProjectStatus status;
  DateTime? dueDate;
  List<String> photoUrls;
  List<ProjectUpdate> updates;
  List<Invoice> invoices;

  Project({
    required this.id,
    required this.title,
    required this.client,
    required this.status,
    this.dueDate,
    List<String>? photoUrls,
    List<ProjectUpdate>? updates,
    List<Invoice>? invoices,
  })  : photoUrls = photoUrls ?? [],
        updates = updates ?? [],
        invoices = invoices ?? [];
}

class ProjectUpdate {
  final String id;
  final String text;
  final DateTime createdAt;
  ProjectUpdate({
    required this.id,
    required this.text,
    required this.createdAt,
  });
}

enum InvoiceStatus { draft, sent, paid, overdue }

class Invoice {
  final String id;
  final String projectId;
  double amount;
  InvoiceStatus status;
  DateTime? dueDate;

  Invoice({
    required this.id,
    required this.projectId,
    required this.amount,
    required this.status,
    this.dueDate,
  });
}

class ScheduleItem {
  final String id;
  final String title;
  final String where;
  final DateTime start;
  final DateTime end;

  ScheduleItem({
    required this.id,
    required this.title,
    required this.where,
    required this.start,
    required this.end,
  });
}
