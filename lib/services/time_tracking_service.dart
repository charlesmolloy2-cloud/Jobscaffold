import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TimeTrackingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Clock in
  Future<String> clockIn({
    required String projectId,
    String? notes,
    GeoPoint? location,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    // Check if already clocked in
    final activeEntry = await getActiveEntry(currentUser.uid);
    if (activeEntry != null) {
      throw Exception('Already clocked in. Please clock out first.');
    }

    final entryRef = _firestore.collection('time_entries').doc();

    final entry = TimeEntry(
      id: entryRef.id,
      userId: currentUser.uid,
      projectId: projectId,
      clockIn: DateTime.now(),
      notes: notes,
      locationIn: location,
      status: TimeEntryStatus.active,
    );

    await entryRef.set(entry.toMap());
    return entryRef.id;
  }

  // Clock out
  Future<void> clockOut({
    required String entryId,
    String? notes,
    GeoPoint? location,
  }) async {
    final entry = await _firestore.collection('time_entries').doc(entryId).get();
    if (!entry.exists) throw Exception('Time entry not found');

    final data = entry.data()!;
    final clockIn = (data['clockIn'] as Timestamp).toDate();
    final clockOut = DateTime.now();
    final duration = clockOut.difference(clockIn);

    await _firestore.collection('time_entries').doc(entryId).update({
      'clockOut': Timestamp.fromDate(clockOut),
      'duration': duration.inMinutes,
      'status': TimeEntryStatus.completed.toString(),
      'notesOut': notes,
      'locationOut': location,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Get active time entry for user
  Future<TimeEntry?> getActiveEntry(String userId) async {
    final snapshot = await _firestore
        .collection('time_entries')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: TimeEntryStatus.active.toString())
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return TimeEntry.fromFirestore(snapshot.docs.first);
  }

  // Get time entries for a project
  Stream<List<TimeEntry>> getProjectEntries(String projectId) {
    return _firestore
        .collection('time_entries')
        .where('projectId', isEqualTo: projectId)
        .orderBy('clockIn', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => TimeEntry.fromFirestore(doc)).toList();
    });
  }

  // Get user's time entries
  Stream<List<TimeEntry>> getUserEntries(String userId, {DateTime? startDate, DateTime? endDate}) {
    Query query = _firestore
        .collection('time_entries')
        .where('userId', isEqualTo: userId);

    if (startDate != null) {
      query = query.where('clockIn', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    if (endDate != null) {
      query = query.where('clockIn', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    return query.orderBy('clockIn', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => TimeEntry.fromFirestore(doc)).toList();
    });
  }

  // Get weekly timesheet
  Future<WeeklyTimesheet> getWeeklyTimesheet(String userId, DateTime weekStart) async {
    final weekEnd = weekStart.add(const Duration(days: 7));

    final snapshot = await _firestore
        .collection('time_entries')
        .where('userId', isEqualTo: userId)
        .where('clockIn', isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
        .where('clockIn', isLessThan: Timestamp.fromDate(weekEnd))
        .where('status', isEqualTo: TimeEntryStatus.completed.toString())
        .get();

    final entries = snapshot.docs.map((doc) => TimeEntry.fromFirestore(doc)).toList();

    // Group by day
    final entriesByDay = <DateTime, List<TimeEntry>>{};
    for (final entry in entries) {
      final day = DateTime(entry.clockIn.year, entry.clockIn.month, entry.clockIn.day);
      entriesByDay.putIfAbsent(day, () => []).add(entry);
    }

    // Calculate totals
    final totalMinutes = entries.fold<int>(0, (sum, entry) => sum + (entry.duration ?? 0));
    final totalHours = totalMinutes / 60;

    return WeeklyTimesheet(
      userId: userId,
      weekStart: weekStart,
      weekEnd: weekEnd,
      entries: entries,
      entriesByDay: entriesByDay,
      totalMinutes: totalMinutes,
      totalHours: totalHours,
    );
  }

  // Get time summary for a project
  Future<TimeSummary> getProjectTimeSummary(String projectId) async {
    final snapshot = await _firestore
        .collection('time_entries')
        .where('projectId', isEqualTo: projectId)
        .where('status', isEqualTo: TimeEntryStatus.completed.toString())
        .get();

    final entries = snapshot.docs.map((doc) => TimeEntry.fromFirestore(doc)).toList();

    final totalMinutes = entries.fold<int>(0, (sum, entry) => sum + (entry.duration ?? 0));
    final totalHours = totalMinutes / 60;

    // Group by user
    final hoursByUser = <String, double>{};
    for (final entry in entries) {
      final hours = (entry.duration ?? 0) / 60;
      hoursByUser.update(entry.userId, (value) => value + hours, ifAbsent: () => hours);
    }

    return TimeSummary(
      projectId: projectId,
      totalMinutes: totalMinutes,
      totalHours: totalHours,
      entryCount: entries.length,
      hoursByUser: hoursByUser,
    );
  }

  // Update time entry
  Future<void> updateEntry({
    required String entryId,
    DateTime? clockIn,
    DateTime? clockOut,
    String? notes,
    String? notesOut,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (clockIn != null) updates['clockIn'] = Timestamp.fromDate(clockIn);
    if (clockOut != null) {
      updates['clockOut'] = Timestamp.fromDate(clockOut);
      
      // Recalculate duration
      final entry = await _firestore.collection('time_entries').doc(entryId).get();
      final existingClockIn = clockIn ?? (entry.data()!['clockIn'] as Timestamp).toDate();
      final duration = clockOut.difference(existingClockIn);
      updates['duration'] = duration.inMinutes;
    }
    if (notes != null) updates['notes'] = notes;
    if (notesOut != null) updates['notesOut'] = notesOut;

    await _firestore.collection('time_entries').doc(entryId).update(updates);
  }

  // Delete time entry
  Future<void> deleteEntry(String entryId) async {
    await _firestore.collection('time_entries').doc(entryId).delete();
  }

  // Generate invoice data from time entries
  Future<InvoiceData> generateInvoiceData({
    required String projectId,
    required DateTime startDate,
    required DateTime endDate,
    required double hourlyRate,
  }) async {
    final snapshot = await _firestore
        .collection('time_entries')
        .where('projectId', isEqualTo: projectId)
        .where('clockIn', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('clockIn', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .where('status', isEqualTo: TimeEntryStatus.completed.toString())
        .get();

    final entries = snapshot.docs.map((doc) => TimeEntry.fromFirestore(doc)).toList();

    final totalMinutes = entries.fold<int>(0, (sum, entry) => sum + (entry.duration ?? 0));
    final totalHours = totalMinutes / 60;
    final totalAmount = totalHours * hourlyRate;

    return InvoiceData(
      projectId: projectId,
      startDate: startDate,
      endDate: endDate,
      entries: entries,
      totalHours: totalHours,
      hourlyRate: hourlyRate,
      totalAmount: totalAmount,
    );
  }
}

// Time Entry Model
class TimeEntry {
  final String id;
  final String userId;
  final String projectId;
  final DateTime clockIn;
  final DateTime? clockOut;
  final int? duration; // in minutes
  final String? notes;
  final String? notesOut;
  final GeoPoint? locationIn;
  final GeoPoint? locationOut;
  final TimeEntryStatus status;
  final DateTime? updatedAt;

  TimeEntry({
    required this.id,
    required this.userId,
    required this.projectId,
    required this.clockIn,
    this.clockOut,
    this.duration,
    this.notes,
    this.notesOut,
    this.locationIn,
    this.locationOut,
    required this.status,
    this.updatedAt,
  });

  String get formattedDuration {
    if (duration == null) {
      // Calculate current duration if still active
      if (status == TimeEntryStatus.active) {
        final current = DateTime.now().difference(clockIn).inMinutes;
        final hours = current ~/ 60;
        final minutes = current % 60;
        return '${hours}h ${minutes}m';
      }
      return '0h 0m';
    }
    
    final hours = duration! ~/ 60;
    final minutes = duration! % 60;
    return '${hours}h ${minutes}m';
  }

  factory TimeEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TimeEntry(
      id: doc.id,
      userId: data['userId'] ?? '',
      projectId: data['projectId'] ?? '',
      clockIn: (data['clockIn'] as Timestamp).toDate(),
      clockOut: data['clockOut'] != null
          ? (data['clockOut'] as Timestamp).toDate()
          : null,
      duration: data['duration'],
      notes: data['notes'],
      notesOut: data['notesOut'],
      locationIn: data['locationIn'],
      locationOut: data['locationOut'],
      status: TimeEntryStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
        orElse: () => TimeEntryStatus.completed,
      ),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'projectId': projectId,
      'clockIn': Timestamp.fromDate(clockIn),
      'clockOut': clockOut != null ? Timestamp.fromDate(clockOut!) : null,
      'duration': duration,
      'notes': notes,
      'notesOut': notesOut,
      'locationIn': locationIn,
      'locationOut': locationOut,
      'status': status.toString(),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}

enum TimeEntryStatus {
  active,
  completed,
  edited,
}

class WeeklyTimesheet {
  final String userId;
  final DateTime weekStart;
  final DateTime weekEnd;
  final List<TimeEntry> entries;
  final Map<DateTime, List<TimeEntry>> entriesByDay;
  final int totalMinutes;
  final double totalHours;

  WeeklyTimesheet({
    required this.userId,
    required this.weekStart,
    required this.weekEnd,
    required this.entries,
    required this.entriesByDay,
    required this.totalMinutes,
    required this.totalHours,
  });
}

class TimeSummary {
  final String projectId;
  final int totalMinutes;
  final double totalHours;
  final int entryCount;
  final Map<String, double> hoursByUser;

  TimeSummary({
    required this.projectId,
    required this.totalMinutes,
    required this.totalHours,
    required this.entryCount,
    required this.hoursByUser,
  });
}

class InvoiceData {
  final String projectId;
  final DateTime startDate;
  final DateTime endDate;
  final List<TimeEntry> entries;
  final double totalHours;
  final double hourlyRate;
  final double totalAmount;

  InvoiceData({
    required this.projectId,
    required this.startDate,
    required this.endDate,
    required this.entries,
    required this.totalHours,
    required this.hourlyRate,
    required this.totalAmount,
  });
}
