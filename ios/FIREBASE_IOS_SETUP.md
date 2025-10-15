# iOS Firebase Setup (SiteBench)

This project uses the Firebase project `project-bridge-cm`.

## 1) Add GoogleService-Info.plist
- Download from Firebase Console → Project Settings → iOS app.
- Place the file at: `ios/Runner/GoogleService-Info.plist`.
- Ensure the bundle ID matches `PRODUCT_BUNDLE_IDENTIFIER` in Xcode (currently `com.example.sitebench`). Update both if you change it.

## 2) URL Schemes (Optional if using Auth/Links)
- Open `ios/Runner/Info.plist` in Xcode.
- Add URL Types → URL Schemes from `REVERSED_CLIENT_ID` in the plist.

## 3) CocoaPods
From macOS with Xcode:
- In the `ios` folder, run:
  - `pod repo update`
  - `pod install`

Flutter will also run CocoaPods during `flutter build ios`.

## 4) Build and Run
- `flutter clean`
- `flutter pub get`
- `flutter run -d ios`

## 5) Push Notifications (if needed)
- Enable Push + Background Modes in Xcode → Signing & Capabilities.
- Add Notification permissions handling in Dart as needed.
