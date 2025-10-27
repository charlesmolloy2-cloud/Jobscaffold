import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

/// GPS check-in service with geofencing
class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Request location permissions
  Future<LocationPermission> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission;
  }

  /// Get current position
  Future<Position> getCurrentPosition() async {
    final permission = await requestPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions denied');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Check in at a project location
  Future<String> checkIn({
    required String projectId,
    required Position position,
    String? notes,
    List<String>? photoUrls,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    // Get project location for verification
    final projectDoc = await _firestore.collection('projects').doc(projectId).get();
    final projectData = projectDoc.data();

    bool isWithinGeofence = false;
    double? distanceInMeters;

    if (projectData != null && projectData['location'] != null) {
      final projectLocation = projectData['location'] as GeoPoint;
      
      distanceInMeters = Geolocator.distanceBetween(
        projectLocation.latitude,
        projectLocation.longitude,
        position.latitude,
        position.longitude,
      );

      // Default geofence radius: 100 meters
      final geofenceRadius = projectData['geofenceRadius'] ?? 100.0;
      isWithinGeofence = distanceInMeters <= geofenceRadius;
    }

    final checkInRef = _firestore.collection('check_ins').doc();

    final checkIn = CheckIn(
      id: checkInRef.id,
      userId: currentUser.uid,
      projectId: projectId,
      timestamp: DateTime.now(),
      location: GeoPoint(position.latitude, position.longitude),
      accuracy: position.accuracy,
      isWithinGeofence: isWithinGeofence,
      distanceFromProject: distanceInMeters,
      notes: notes,
      photoUrls: photoUrls ?? [],
      checkInType: CheckInType.arrival,
    );

    await checkInRef.set(checkIn.toMap());

    // Create notification for project manager
    if (isWithinGeofence) {
      await _createCheckInNotification(projectId, currentUser.uid, 'arrived');
    }

    return checkInRef.id;
  }

  /// Check out from a project location
  Future<void> checkOut({
    required String projectId,
    required Position position,
    String? notes,
    List<String>? photoUrls,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    final checkInRef = _firestore.collection('check_ins').doc();

    final checkIn = CheckIn(
      id: checkInRef.id,
      userId: currentUser.uid,
      projectId: projectId,
      timestamp: DateTime.now(),
      location: GeoPoint(position.latitude, position.longitude),
      accuracy: position.accuracy,
      notes: notes,
      photoUrls: photoUrls ?? [],
      checkInType: CheckInType.departure,
    );

    await checkInRef.set(checkIn.toMap());

    // Create notification
    await _createCheckInNotification(projectId, currentUser.uid, 'departed');
  }

  /// Get check-ins for a project
  Stream<List<CheckIn>> getProjectCheckIns(String projectId) {
    return _firestore
        .collection('check_ins')
        .where('projectId', isEqualTo: projectId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => CheckIn.fromFirestore(doc)).toList();
    });
  }

  /// Get user's check-ins
  Stream<List<CheckIn>> getUserCheckIns(String userId) {
    return _firestore
        .collection('check_ins')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => CheckIn.fromFirestore(doc)).toList();
    });
  }

  /// Get today's check-ins for a user
  Future<List<CheckIn>> getTodayCheckIns(String userId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    final snapshot = await _firestore
        .collection('check_ins')
        .where('userId', isEqualTo: userId)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs.map((doc) => CheckIn.fromFirestore(doc)).toList();
  }

  /// Set project geofence location
  Future<void> setProjectLocation({
    required String projectId,
    required double latitude,
    required double longitude,
    double radiusMeters = 100.0,
  }) async {
    await _firestore.collection('projects').doc(projectId).update({
      'location': GeoPoint(latitude, longitude),
      'geofenceRadius': radiusMeters,
    });
  }

  /// Calculate distance between two points
  double calculateDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Monitor location changes (for background tracking)
  Stream<Position> watchPosition() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    );
  }

  /// Get attendance summary for a date range
  Future<AttendanceSummary> getAttendanceSummary({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final snapshot = await _firestore
        .collection('check_ins')
        .where('userId', isEqualTo: userId)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    final checkIns = snapshot.docs.map((doc) => CheckIn.fromFirestore(doc)).toList();

    final arrivals = checkIns.where((c) => c.checkInType == CheckInType.arrival).length;
    final departures = checkIns.where((c) => c.checkInType == CheckInType.departure).length;
    final withinGeofence = checkIns.where((c) => c.isWithinGeofence == true).length;
    final totalCheckIns = checkIns.length;

    // Group by project
    final Map<String, int> projectCounts = {};
    for (final checkIn in checkIns) {
      projectCounts.update(
        checkIn.projectId,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    return AttendanceSummary(
      totalCheckIns: totalCheckIns,
      arrivals: arrivals,
      departures: departures,
      withinGeofence: withinGeofence,
      projectCounts: projectCounts,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<void> _createCheckInNotification(
    String projectId,
    String userId,
    String action,
  ) async {
    // Get project details
    final projectDoc = await _firestore.collection('projects').doc(projectId).get();
    final projectName = projectDoc.data()?['title'] ?? 'Project';

    // Get contractor/manager to notify
    final contractorId = projectDoc.data()?['contractorId'];
    if (contractorId != null && contractorId != userId) {
      await _firestore.collection('notifications').add({
        'userId': contractorId,
        'title': 'Team Member $action',
        'body': 'A team member has $action at $projectName',
        'type': 'check_in',
        'data': {
          'projectId': projectId,
          'userId': userId,
          'action': action,
        },
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}

/// Check-in record
class CheckIn {
  final String id;
  final String userId;
  final String projectId;
  final DateTime timestamp;
  final GeoPoint location;
  final double accuracy;
  final bool? isWithinGeofence;
  final double? distanceFromProject;
  final String? notes;
  final List<String> photoUrls;
  final CheckInType checkInType;

  CheckIn({
    required this.id,
    required this.userId,
    required this.projectId,
    required this.timestamp,
    required this.location,
    required this.accuracy,
    this.isWithinGeofence,
    this.distanceFromProject,
    this.notes,
    required this.photoUrls,
    required this.checkInType,
  });

  factory CheckIn.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CheckIn(
      id: doc.id,
      userId: data['userId'] ?? '',
      projectId: data['projectId'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      location: data['location'] as GeoPoint,
      accuracy: (data['accuracy'] as num?)?.toDouble() ?? 0.0,
      isWithinGeofence: data['isWithinGeofence'] as bool?,
      distanceFromProject: (data['distanceFromProject'] as num?)?.toDouble(),
      notes: data['notes'] as String?,
      photoUrls: List<String>.from(data['photoUrls'] ?? []),
      checkInType: CheckInType.values.firstWhere(
        (e) => e.toString() == data['checkInType'],
        orElse: () => CheckInType.arrival,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'projectId': projectId,
      'timestamp': Timestamp.fromDate(timestamp),
      'location': location,
      'accuracy': accuracy,
      'isWithinGeofence': isWithinGeofence,
      'distanceFromProject': distanceFromProject,
      'notes': notes,
      'photoUrls': photoUrls,
      'checkInType': checkInType.toString(),
    };
  }

  String get distanceText {
    if (distanceFromProject == null) return 'Unknown';
    if (distanceFromProject! < 1000) {
      return '${distanceFromProject!.round()}m away';
    }
    return '${(distanceFromProject! / 1000).toStringAsFixed(1)}km away';
  }
}

enum CheckInType {
  arrival,
  departure,
  break_start,
  break_end,
}

/// Attendance summary
class AttendanceSummary {
  final int totalCheckIns;
  final int arrivals;
  final int departures;
  final int withinGeofence;
  final Map<String, int> projectCounts;
  final DateTime startDate;
  final DateTime endDate;

  AttendanceSummary({
    required this.totalCheckIns,
    required this.arrivals,
    required this.departures,
    required this.withinGeofence,
    required this.projectCounts,
    required this.startDate,
    required this.endDate,
  });

  double get geofenceCompliance {
    if (totalCheckIns == 0) return 0;
    return (withinGeofence / totalCheckIns) * 100;
  }
}
