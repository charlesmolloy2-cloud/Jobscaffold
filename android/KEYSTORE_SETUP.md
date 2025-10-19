# Android Keystore Setup for JobScaffold

## Generate Keystore

Run this command in the `android/app` directory:

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

You'll be prompted for:
- Keystore password (remember this!)
- Key password (can be same as keystore password)
- Your name/organization details

## Configure Signing

1. Copy the generated `upload-keystore.jks` to `android/app/`
2. Copy `android/key.properties.example` to `android/key.properties`
3. Edit `android/key.properties` with your passwords:

```
KEYSTORE_FILE=upload-keystore.jks
KEYSTORE_PASSWORD=your_actual_password
KEY_ALIAS=upload
KEY_PASSWORD=your_actual_password
```

4. Add to `.gitignore`:
```
android/key.properties
android/app/upload-keystore.jks
```

## Build Release APK/Bundle

```bash
flutter build appbundle --release
```

The signed bundle will be at: `build/app/outputs/bundle/release/app-release.aab`

## Important Notes

- **NEVER** commit `key.properties` or `upload-keystore.jks` to git
- Store backups of your keystore in a secure location
- If you lose the keystore, you cannot update your app on Play Store
- Keep your passwords in a password manager
