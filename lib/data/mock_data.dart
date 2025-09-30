import 'dart:math';
import '../models/models.dart';

class MockDB {
  static final List<Project> projects = [
    Project(
      id: 'p1',
      title: 'Kitchen Remodel — 19 Pine St.',
      client: 'Acme Contracting',
      status: ProjectStatus.inProgress,
      dueDate: DateTime.now().add(const Duration(days: 14)),
      photoUrls: [],
      updates: [
        ProjectUpdate(id: 'u1', text: 'Demolition complete.', createdAt: DateTime.now().subtract(const Duration(days: 2))),
        ProjectUpdate(id: 'u2', text: 'Installed cabinets and rough plumbing.', createdAt: DateTime.now().subtract(const Duration(days: 1))),
      ],
      invoices: [
        Invoice(id: 'INV-1048', projectId: 'p1', amount: 2450, status: InvoiceStatus.sent, dueDate: DateTime.now().add(const Duration(days: 7))),
      ],
    ),
    Project(
      id: 'p2',
      title: 'Porch Repair — 42 Maple Ave.',
      client: 'Homeowner: J. Donovan',
      status: ProjectStatus.blocked,
      dueDate: DateTime.now().add(const Duration(days: 28)),
      updates: [
        ProjectUpdate(id: 'u3', text: 'Waiting on town permit.', createdAt: DateTime.now().subtract(const Duration(days: 3))),
      ],
      invoices: [
        Invoice(id: 'INV-1047', projectId: 'p2', amount: 980, status: InvoiceStatus.paid),
      ],
    ),
    Project(
      id: 'p3',
      title: 'Roof Inspection — 9 Harbor Rd.',
      client: 'Harbor Condo Assoc.',
      status: ProjectStatus.completed,
      dueDate: DateTime.now().subtract(const Duration(days: 3)),
      updates: [
        ProjectUpdate(id: 'u4', text: 'Inspection complete. No major issues.', createdAt: DateTime.now().subtract(const Duration(days: 5))),
      ],
      invoices: [
        Invoice(id: 'INV-1046', projectId: 'p3', amount: 1300, status: InvoiceStatus.overdue, dueDate: DateTime.now().subtract(const Duration(days: 3))),
      ],
    ),
  ];

  static final List<ScheduleItem> schedule = [
    ScheduleItem(
      id: 's1',
      title: 'Site Visit — 19 Pine St.',
      where: '19 Pine St.',
      start: DateTime.now().add(const Duration(days: 1, hours: 9)),
      end: DateTime.now().add(const Duration(days: 1, hours: 10)),
    ),
    ScheduleItem(
      id: 's2',
      title: 'Invoice Review — Harbor Rd.',
      where: 'Office',
      start: DateTime.now().add(const Duration(days: 2, hours: 14, minutes: 30)),
      end: DateTime.now().add(const Duration(days: 2, hours: 15)),
    ),
  ];

  static String newId(String prefix) => '$prefix-${Random().nextInt(999999)}';
}
