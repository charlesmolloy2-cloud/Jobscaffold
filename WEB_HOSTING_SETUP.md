# Web Hosting Setup (Firebase Hosting)

## Build Web (Release)

```bash
flutter build web --release
```

Output: `build/web/`

## Deploy with Firebase Hosting

1. Install Firebase CLI and login
2. Ensure `firebase.json` points to `build/web`
3. Deploy:

```bash
firebase deploy --only hosting
```

SPA routing is already configured via `rewrites` in `firebase.json`.

## Custom Domain

1. In Firebase Console > Hosting > Connect custom domain
2. Add: `jobscaffold.com` (and `www.jobscaffold.com`)
3. Add the DNS records shown (A/AAAA or CNAME)
4. Wait for verification and SSL provisioning
