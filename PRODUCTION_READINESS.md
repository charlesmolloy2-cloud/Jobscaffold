# JobScaffold - Production Readiness Checklist

Complete guide to prepare JobScaffold for production deployment across Web, Android, and iOS.

---

## ✅ Completed

### Core Platform Setup
- [x] **Firebase Integration**
  - Project: `project-bridge-cm`
  - Auth, Firestore, Storage, Messaging, Functions, Analytics, Crashlytics configured
  - Web app deployed to Hosting
  
- [x] **Branding & UI**
  - Renamed to JobScaffold across all files
  - Steel blue/charcoal theme with blueprint grid background
  - Landing page with demo login
  - Calendar redesigned (month grid, 2000-2100 range)
  - Privacy Policy & Terms of Service (production copy)
  
- [x] **Web Deployment**
  - Live: https://project-bridge-cm.web.app
  - SPA routing configured
  - Native splash screen generated
  - Firebase Hosting workflow ready (`.github/workflows/deploy-hosting.yml`)
  
- [x] **Authentication**
  - Demo login (Admin1234/1234) with role selection
  - Real Firebase Auth wired for email/password
  - Google & Microsoft OAuth ready (needs Firebase Console enable)
  - Auth bypass for demo mode
  
- [x] **Android Config**
  - Package: `com.jobscaffold.app`
  - App label: JobScaffold
  - Release signing scaffold in place
  - Crashlytics & Analytics initialized
  
- [x] **iOS Config**
  - Bundle ID: `com.example.jobscaffold`
  - Display name: JobScaffold
  - Info.plist corrected
  - Docs for APNs/FCM and GoogleService-Info.plist

---

## 🔧 Ready to Complete (Requires Your Input)

### 1. Enable Firebase Auth Providers
**Why:** Allow real user sign-in (email/password, Google, Microsoft)

**Steps:**
1. Go to [Firebase Console → Authentication → Sign-in method](https://console.firebase.google.com/project/project-bridge-cm/authentication/providers)
2. Enable **Email/Password** → Save
3. Optional: Enable **Google** and **Microsoft** (see `FIREBASE_AUTH_SETUP.md`)
4. Create test users in [Users tab](https://console.firebase.google.com/project/project-bridge-cm/authentication/users):
   - `contractor@jobscaffold.com` / `Contractor123!`
   - `customer@jobscaffold.com` / `Customer123!`

**Status:** Firebase Console action required

---

### 2. Push Code to GitHub
**Why:** Enable CI/CD deploys via GitHub Actions

**Steps:**
1. Create a new GitHub repo: `JobScaffold` (or use existing)
2. Get your GitHub username/org
3. Run in terminal:
   ```powershell
   git remote add origin https://github.com/YOUR_USERNAME/JobScaffold.git
   git branch -M master
   git push -u origin master
   ```
4. Add `FIREBASE_SERVICE_ACCOUNT` secret:
   - Firebase Console → Project Settings → Service accounts → Generate new private key
   - GitHub repo → Settings → Secrets and variables → Actions → New repository secret
   - Name: `FIREBASE_SERVICE_ACCOUNT`
   - Value: Paste the entire JSON file content
5. Trigger workflow: GitHub Actions → Deploy Firebase Hosting (manual) → Run workflow

**Status:** Needs GitHub repo URL

---

### 3. App Icon Generation
**Why:** Professional icons for Android, iOS, and Web

**Steps:**
1. Design a 1024x1024 PNG icon for JobScaffold
2. Save it to: `assets/icon/jobscaffold_icon.png`
3. Run:
   ```powershell
   flutter pub run flutter_launcher_icons
   ```
4. Commit the generated icons:
   ```powershell
   git add android/app/src/main ios/Runner web/icons
   git commit -m "Assets: add JobScaffold app icons"
   git push
   ```

**Status:** Awaiting icon asset (1024x1024 PNG)

---

### 4. Android Release Build (Play Console)
**Why:** Signed AAB for Google Play Store

**Steps:**
1. Generate keystore (see `android/KEYSTORE_SETUP.md`):
   ```powershell
   keytool -genkey -v -keystore c:\keys\jobscaffold-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias jobscaffold
   ```
2. Create `android/key.properties`:
   ```
   storePassword=YOUR_STORE_PASSWORD
   keyPassword=YOUR_KEY_PASSWORD
   keyAlias=jobscaffold
   storeFile=c:\\keys\\jobscaffold-release.jks
   ```
3. Build release AAB:
   ```powershell
   flutter build appbundle --release
   ```
4. Upload `build/app/outputs/bundle/release/app-release.aab` to Play Console

**Status:** Needs keystore creation

---

### 5. iOS Release Build (App Store Connect)
**Why:** Prepare for App Store submission

**Steps:**
1. Add `ios/Runner/GoogleService-Info.plist` (see `ios/GOOGLESERVICE_INFO_SETUP.md`)
2. Open Xcode: `open ios/Runner.xcworkspace`
3. Update signing in Xcode:
   - Select Runner target → Signing & Capabilities
   - Team: Your Apple Developer account
   - Bundle Identifier: `com.example.jobscaffold` (or your custom ID)
4. Archive for App Store:
   ```bash
   flutter build ios --release
   # Then archive in Xcode: Product → Archive → Distribute App
   ```

**Status:** Needs GoogleService-Info.plist & Apple Developer account

---

### 6. Custom Domain (Optional but Recommended)
**Why:** Brand consistency (e.g., `jobscaffold.com`)

**Steps:**
1. Buy domain (GoDaddy, Namecheap, Google Domains, etc.)
2. Firebase Hosting → Add custom domain → Follow DNS verification steps
3. Update `web/index.html`:
   ```html
   <link rel="canonical" href="https://jobscaffold.com/" />
   ```
4. Rebuild and deploy:
   ```powershell
   flutter build web --release
   firebase deploy --only hosting
   ```

**Status:** Needs domain purchase and DNS setup

---

### 7. Stripe Payments (If Needed)
**Why:** Accept invoice payments via Stripe Checkout

**Steps:**
1. Get Stripe API keys (test & live) from [Stripe Dashboard](https://dashboard.stripe.com/)
2. Set Firebase Functions config:
   ```powershell
   firebase functions:config:set stripe.secret="sk_live_..." stripe.webhook="whsec_..."
   ```
3. Deploy functions:
   ```powershell
   cd functions
   npm install
   npm run deploy
   ```
4. Add Stripe webhook endpoint in Stripe Dashboard:
   - URL: `https://us-central1-project-bridge-cm.cloudfunctions.net/stripeWebhook`
   - Events: `checkout.session.completed`

**Status:** Optional; needs Stripe account

---

## 📋 Store Submission Checklists

### Google Play Console
- [ ] App name: JobScaffold
- [ ] Short description (80 chars)
- [ ] Full description (4000 chars)
- [ ] Category: Business / Productivity
- [ ] Screenshots (phone, tablet, optional)
- [ ] Feature graphic (1024x500)
- [ ] Privacy Policy URL: `https://project-bridge-cm.web.app/privacy`
- [ ] Target age: 13+
- [ ] Content rating questionnaire
- [ ] Upload signed AAB

### Apple App Store Connect
- [ ] App name: JobScaffold
- [ ] Subtitle (30 chars)
- [ ] Description (4000 chars)
- [ ] Keywords (100 chars, comma-separated)
- [ ] Category: Business / Productivity
- [ ] Screenshots (required sizes per device)
- [ ] Privacy Policy URL: `https://project-bridge-cm.web.app/privacy`
- [ ] Age rating: 4+
- [ ] Upload IPA via Xcode/Transporter

---

## 🧪 Testing Checklist

### Web
- [ ] Test on Chrome, Firefox, Safari, Edge
- [ ] Mobile browser (iOS Safari, Android Chrome)
- [ ] Demo login (Admin1234/1234) works
- [ ] Real Firebase Auth sign-in works
- [ ] Calendar navigation (2000-2100 clamp)
- [ ] Analytics events fire (check Firebase Console)

### Android
- [ ] Test on emulator and physical device
- [ ] Firebase Crashlytics reports errors
- [ ] Push notifications (FCM) work
- [ ] Release build installs and runs
- [ ] App label shows "JobScaffold"

### iOS
- [ ] Test on simulator and physical device
- [ ] Firebase Crashlytics reports errors
- [ ] Push notifications (APNs + FCM) work
- [ ] App display name shows "JobScaffold"
- [ ] Archive builds successfully

---

## 🚀 Quick Deploy Commands

### Web (Local)
```powershell
flutter build web --release
firebase deploy --only hosting
```

### Web (GitHub Actions)
Push to `master` branch or run "Deploy Firebase Hosting (manual)" workflow.

### Android
```powershell
flutter build appbundle --release
# Upload build/app/outputs/bundle/release/app-release.aab to Play Console
```

### iOS
```bash
flutter build ios --release
# Archive in Xcode and upload to App Store Connect
```

---

## 📞 Support & Next Steps

- **Live Site:** https://project-bridge-cm.web.app
- **GitHub Repo:** https://github.com/charlesmolloy2-cloud/Jobscaffold
- **Demo Login:** Admin1234 / 1234 (choose Contractor or Customer)
- **Firebase Project:** project-bridge-cm
- **Test Users:** contractor@jobscaffold.com, customer@jobscaffold.com

**Ready to launch?**
1. Complete Firebase Auth setup (5 min)
2. Push to GitHub (2 min)
3. Generate app icon (when ready)
4. Create Android keystore (10 min)
5. Add iOS GoogleService-Info.plist (5 min)
6. Test on all platforms
7. Submit to stores!

For questions or help, refer to the guide files:
- `FIREBASE_AUTH_SETUP.md`
- `WEB_HOSTING_SETUP.md`
- `android/KEYSTORE_SETUP.md`
- `ios/GOOGLESERVICE_INFO_SETUP.md`
