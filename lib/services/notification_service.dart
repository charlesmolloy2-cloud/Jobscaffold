import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Service for handling push notifications via Firebase Cloud Messaging
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Read VAPID key from --dart-define FCM_VAPID_KEY (for web)
  static const String vapidKey = String.fromEnvironment('FCM_VAPID_KEY');

  /// Initialize notification service and request permissions
  Future<void> initialize() async {
    // Request permission (iOS/Web)
    await requestPermission();

    // Get FCM token
    final token = await getToken();
    if (token != null) {
      await saveTokenToFirestore(token);
    }

    // Listen for token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen(saveTokenToFirestore);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages (requires top-level function)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  /// Request notification permissions
  Future<NotificationSettings> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');
    return settings;
  }

  /// Get FCM token for this device
  Future<String?> getToken() async {
    try {
      // For web, use vapidKey (get from Firebase Console → Project Settings → Cloud Messaging)
      final token = kIsWeb
          ? await _messaging.getToken(
              vapidKey: (vapidKey.isEmpty ? null : vapidKey),
            )
          : await _messaging.getToken();

      print('FCM Token: $token');
      return token;
    } catch (e) {
      print('Failed to get FCM token: $e');
      return null;
    }
  }

  /// Save FCM token to Firestore for this user
  Future<void> saveTokenToFirestore(String token) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Back-compat: keep last token on user doc
      await _firestore.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Preferred: store tokens in a subcollection to support multi-device
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('tokens')
          .doc(token)
          .set({
        'token': token,
        'platform': kIsWeb ? 'web' : 'app',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('FCM token saved to Firestore');
    } catch (e) {
      print('Failed to save FCM token: $e');
    }
  }

  /// Handle foreground messages (when app is open)
  void _handleForegroundMessage(RemoteMessage message) {
    print('Foreground message received: ${message.notification?.title}');
    // Minimal UX: try to show a SnackBar if we can find a context
    final ctx = _ForegroundMessenger.navigatorKey.currentContext;
    if (ctx != null && message.notification != null) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text(message.notification!.title ?? message.notification!.body ?? 'New notification')),
      );
    }
    // You can show a local notification or update UI here
    if (message.notification != null) {
      print('Notification Title: ${message.notification!.title}');
      print('Notification Body: ${message.notification!.body}');
    }

    // Handle data payload
    if (message.data.isNotEmpty) {
      print('Message data: ${message.data}');
    }
  }

  /// Subscribe to a topic (e.g., 'project_updates', 'invoices')
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    print('Subscribed to topic: $topic');
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    print('Unsubscribed from topic: $topic');
  }

  /// Send a notification to a specific user (requires Cloud Function)
  /// This is called from Cloud Functions, not from the app directly
  /// 
  /// Example Cloud Function:
  /// ```
  /// exports.sendNotification = functions.firestore
  ///   .document('updates/{updateId}')
  ///   .onCreate(async (snap, context) => {
  ///     const update = snap.data();
  ///     const userDoc = await admin.firestore()
  ///       .collection('users').doc(update.userId).get();
  ///     const token = userDoc.data()?.fcmToken;
  ///     
  ///     if (token) {
  ///       await admin.messaging().send({
  ///         token: token,
  ///         notification: {
  ///           title: 'New Project Update',
  ///           body: update.message,
  ///         },
  ///         data: {
  ///           projectId: update.projectId,
  ///           type: 'project_update',
  ///         },
  ///       });
  ///     }
  ///   });
  /// ```
  
  /// Get user's notification preferences
  Future<NotificationPreferences> getPreferences(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    final data = doc.data();
    
    return NotificationPreferences(
      projectUpdates: data?['notif_projectUpdates'] ?? true,
      messages: data?['notif_messages'] ?? true,
      invoices: data?['notif_invoices'] ?? true,
      reminders: data?['notif_reminders'] ?? true,
    );
  }

  /// Update notification preferences
  Future<void> updatePreferences(String userId, NotificationPreferences prefs) async {
    await _firestore.collection('users').doc(userId).update({
      'notif_projectUpdates': prefs.projectUpdates,
      'notif_messages': prefs.messages,
      'notif_invoices': prefs.invoices,
      'notif_reminders': prefs.reminders,
    });
  }
}

/// Top-level function to handle background messages
/// Must be top-level or static
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message received: ${message.notification?.title}');
}

/// Helper to ensure a ScaffoldMessenger is available app-wide for SnackBars
class _ForegroundMessenger extends StatelessWidget {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final Widget child;
  const _ForegroundMessenger({required this.child});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (settings) => MaterialPageRoute(builder: (_) => child),
    );
  }
}

/// Notification preferences model
class NotificationPreferences {
  final bool projectUpdates;
  final bool messages;
  final bool invoices;
  final bool reminders;

  NotificationPreferences({
    required this.projectUpdates,
    required this.messages,
    required this.invoices,
    required this.reminders,
  });
}
