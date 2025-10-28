# JobScaffold

**Contractors and clients, connected.**

A comprehensive Flutter project management platform for construction contractors and their clients.

## 🌐 Live Site

**https://project-bridge-cm.web.app**

### Quick Access
- **Landing Page:** https://project-bridge-cm.web.app/landing
- **Demo Login:** https://project-bridge-cm.web.app/demo_login
- **GitHub Repo:** https://github.com/charlesmolloy2-cloud/Jobscaffold

### Demo Access
- Username: `Admin1234`
- Password: `1234`
- Choose role: Contractor or Customer

### Test Accounts (Firebase Auth)
- Contractor: `contractor@jobscaffold.com` / `Contractor123!`
- Customer: `customer@jobscaffold.com` / `Customer123!`

## 🚀 Features

- **Multi-role Authentication**: Contractor, Customer, and Admin roles with demo bypass
- **Project Management**: Track projects, tasks, milestones, and timelines
- **Calendar & Scheduling**: Month-grid calendar (2000-2100) with event management
- **Messaging**: Real-time communication between contractors and clients
- **Invoicing & Payments**: Stripe integration for secure checkout
- **File Management**: Upload and share project documents and photos
- **E-Signature**: Digital signature capture for contracts
- **Notifications**: Push (FCM) and optional email (SendGrid)
- **Analytics**: Firebase Analytics and Crashlytics integration
- **Cross-Platform**: Web (live), Android (ready), and iOS (ready)

## 🛠️ Tech Stack

- **Flutter** 3.35.5 / **Dart** 3.6.0
- **Firebase Suite**: 
  - Auth 6.1.0 (email/password, Google, Microsoft)
  - Firestore 6.0.2 (real-time database)
  - Storage 13.0.2 (file uploads)
  - Functions 6.0.2 (Stripe backend)
  - Analytics 12.0.2 & Crashlytics 5.0.2
  - Messaging 16.0.2 (push notifications)
- **State Management**: Provider pattern
- **Hosting**: Firebase Hosting with GitHub Actions CI/CD
- **Payments**: Stripe Checkout integration
- **Design**: Material 3 with custom blueprint grid theme

## 📦 Getting Started

### Prerequisites
- Flutter SDK 3.35.5 or later
- Dart 3.6.0 or later
- Firebase CLI (for deployment)
- Node.js 18+ (for Cloud Functions)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/charlesmolloy2-cloud/Jobscaffold.git
   cd Jobscaffold
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   cd functions && npm install && cd ..
   ```

3. **Run on web (Chrome):**
   ```bash
   flutter run -d chrome
   ```

      For web push notifications, add your VAPID key:
      ```powershell
      flutter run -d chrome --dart-define FCM_VAPID_KEY=YOUR_PUBLIC_VAPID_KEY
      ```

4. **Build for production:**
   ```bash
   flutter build web --release
   firebase deploy --only hosting
   ```

### Platform Setup

- **Web:** Ready to deploy (see `WEB_HOSTING_SETUP.md`)
- **Android:** Follow `android/KEYSTORE_SETUP.md` for release builds
- **iOS:** Follow `ios/GOOGLESERVICE_INFO_SETUP.md` for Firebase setup

## 🔐 Firebase Configuration

This project uses Firebase project: `project-bridge-cm`

To enable authentication:
1. See `FIREBASE_AUTH_SETUP.md` for provider setup
2. Enable Email/Password in Firebase Console
3. Optional: Enable Google & Microsoft OAuth

To enable push notifications:
1. Ensure Cloud Messaging is enabled in Firebase Console.
2. For web, set a VAPID key in Project Settings → Cloud Messaging and pass it via `--dart-define FCM_VAPID_KEY=...`.
3. The service worker `web/firebase-messaging-sw.js` is included and references your messagingSenderId.

To enable email notifications (optional):
1. Create a SendGrid account and API key.
2. Set environment for Functions: `SENDGRID_API_KEY` and `SENDGRID_FROM` or use `functions:config:set sendgrid.key=... sendgrid.from=...`.

## 🚀 Deployment

### Manual Deploy (Firebase Hosting)
```bash
flutter build web --release
firebase deploy --only hosting
```

To deploy Cloud Functions (notifications fanout and Stripe):
```powershell
cd functions; npm install; npm run build; firebase deploy --only functions
```

### GitHub Actions (Automated)

The project includes CI/CD via GitHub Actions (`.github/workflows/deploy-hosting.yml`).

**Setup:**
1. Firebase Console → Project Settings → Service accounts
2. Generate new private key (JSON)
3. GitHub repo → Settings → Secrets → Actions
4. Add secret: `FIREBASE_SERVICE_ACCOUNT` (paste JSON content)
5. Push to `master` branch to auto-deploy

## 📱 Production Readiness

See `PRODUCTION_READINESS.md` for complete checklist including:
- ✅ Firebase Auth setup
- ✅ GitHub deployment
- ⏳ App icon generation (needs 1024x1024 PNG)
- ⏳ Android release signing
- ⏳ iOS App Store setup
- ⏳ Custom domain configuration

## 📄 Documentation

- `FIREBASE_AUTH_SETUP.md` - Enable authentication providers
- `WEB_HOSTING_SETUP.md` - Deploy to Firebase Hosting
- `android/KEYSTORE_SETUP.md` - Android release builds
- `ios/GOOGLESERVICE_INFO_SETUP.md` - iOS Firebase config
- `PRODUCTION_READINESS.md` - Complete launch checklist

## 🤝 Contributing

This is a production project. For feature requests or bug reports, contact the development team.

## 📞 Support

- **Privacy:** privacy@jobscaffold.com
- **Support:** support@jobscaffold.com
- **Legal:** legal@jobscaffold.com

## 📄 License

Proprietary - All rights reserved

---

**Built with ❤️ using Flutter and Firebase**
