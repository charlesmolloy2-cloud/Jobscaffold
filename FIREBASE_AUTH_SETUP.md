# Firebase Auth Setup

JobScaffold uses Firebase Authentication for secure user sign-in.

## Enable Email/Password Sign-In

1. Go to [Firebase Console](https://console.firebase.google.com/) → Your Project → Authentication → Sign-in method
2. Click **Email/Password** → Enable → Save
3. Optionally enable **Email link (passwordless sign-in)** for magic links

## Enable Google Sign-In (Web)

1. In Firebase Console → Authentication → Sign-in method → Google → Enable
2. Add your Hosting domain (e.g., `project-bridge-cm.web.app`) to Authorized domains
3. No extra config needed for web; Google provider works out of the box

## Enable Microsoft Sign-In (Web)

1. In Firebase Console → Authentication → Sign-in method → Microsoft → Enable
2. Register your app in [Azure AD](https://portal.azure.com/) → App registrations
3. Add Redirect URI: `https://<your-project-id>.firebaseapp.com/__/auth/handler`
4. Copy Application (client) ID and Directory (tenant) ID to Firebase Console
5. Add your Hosting domain to Authorized domains

## Create Test Users

Run this in Firebase Console → Authentication → Users:
- Click **Add User** and create:
  - Contractor: `contractor@jobscaffold.com` / password
  - Customer: `customer@jobscaffold.com` / password

Or use the demo login (Admin1234 / 1234) which bypasses Firebase Auth for quick testing.

## Mobile (Android/iOS)

- Android: `google-services.json` is already configured
- iOS: Add `GoogleService-Info.plist` to `ios/Runner/` (see `ios/GOOGLESERVICE_INFO_SETUP.md`)
- For Google/Microsoft sign-in on mobile, install additional packages:
  - `google_sign_in` for Google
  - `flutter_microsoft_authentication` or `aad_oauth` for Microsoft

## Production Checklist

- [ ] Enable only the sign-in methods you need
- [ ] Restrict authorized domains to your production domain
- [ ] Set up email templates (password reset, verification) in Firebase Console
- [ ] Enable multi-factor authentication (MFA) if required
- [ ] Review Firebase Auth usage quotas and pricing
