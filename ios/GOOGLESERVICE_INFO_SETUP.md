# iOS Firebase Setup - GoogleService-Info.plist

You need to download the `GoogleService-Info.plist` file from Firebase Console and add it to the iOS project.

## Steps:

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: **project-bridge-cm**
3. Go to Project Settings (gear icon)
4. Under "Your apps", find the iOS app or add a new iOS app
5. Set iOS bundle ID to: **com.example.jobscaffold**
6. Download `GoogleService-Info.plist`
7. Copy the file to: `ios/Runner/GoogleService-Info.plist`
8. Open `ios/Runner.xcworkspace` in Xcode
9. Right-click on "Runner" folder and select "Add Files to Runner"
10. Select `GoogleService-Info.plist` and ensure "Copy items if needed" is checked
11. Verify the file appears in Xcode project navigator

## Alternative: Use firebase_options.dart

The app is already configured to use `firebase_options.dart` for iOS, so it will work without GoogleService-Info.plist. However, for production and advanced Firebase features, the plist file is recommended.

## Current Status

- ✅ iOS bundle identifier updated: `com.example.jobscaffold`
- ✅ Firebase initialized in main.dart for iOS
- ⚠️ GoogleService-Info.plist needs to be added manually from Firebase Console
