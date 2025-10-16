# iOS Push Notification Setup (JobScaffold)

## 1) Enable Capabilities in Xcode
- Open `ios/Runner.xcworkspace` in Xcode.
- Select the Runner target.
- Go to Signing & Capabilities tab.
- Add:
  - Push Notifications
  - Background Modes: check "Remote notifications" and "Background fetch"

## 2) Firebase Cloud Messaging (FCM)
- Ensure `firebase_messaging` is in your `pubspec.yaml`.
- In Dart, initialize messaging:
  ```dart
  import 'package:firebase_messaging/firebase_messaging.dart';
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission();
  ```
- Handle foreground/background messages as needed.

## 3) APNs Certificates
- In Apple Developer portal, create an APNs key and upload to Firebase Console (Project Settings > Cloud Messaging).
- No need for device tokens; FCM handles mapping.

## 4) Testing
- Run on a real device (simulator does not support push).
- Send a test notification from Firebase Console.

## 5) Troubleshooting
- Make sure your bundle ID matches in Xcode and Firebase.
- Check entitlements and provisioning profile includes push.
