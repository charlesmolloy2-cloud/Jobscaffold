# JobScaffold iOS App Icon & Launch Screen Setup

## 1) App Icon
- Prepare a 1024x1024 PNG logo (JobScaffold branding).
- Use [appicon.co](https://appicon.co/) or Flutter’s `flutter_launcher_icons` to generate all required sizes.
- Replace all files in `ios/Runner/Assets.xcassets/AppIcon.appiconset/` with the generated icons.
- In Xcode, confirm the AppIcon is set in Runner target > General > App Icons.

## 2) Launch Screen
- Edit `ios/Runner/Base.lproj/LaunchScreen.storyboard` in Xcode.
- Add your logo and a dark background (#1C1C1E) for JobScaffold.
- Optionally, add a tagline: “Let’s Get to Work.”
- For a quick text-only launch, you can use the default storyboard and set background color and label.

## 3) Automate with flutter_launcher_icons (optional)
- Add to `pubspec.yaml`:
  ```yaml
  dev_dependencies:
    flutter_launcher_icons: ^0.13.1
  flutter_icons:
    android: false
    ios: true
  image_path: "assets/icon/jobscaffold_icon.png"
  ```
- Run:
  ```bash
  flutter pub get
  flutter pub run flutter_launcher_icons:main
  ```
- This will update all icon assets for iOS automatically.
