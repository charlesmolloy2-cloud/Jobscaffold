# Web Launch Checklist (Project Bridge)

## Configure payments (Stripe + Firebase Functions)
1. In the `functions` folder, run `npm install`.
2. Set config:
   - `firebase functions:config:set stripe.secret="sk_test_..."`
   - Optional webhook: `firebase functions:config:set stripe.webhook="whsec_..."`
3. Deploy:
   - `npm run deploy` from `functions/` or `firebase deploy --only functions` from repo root.

IMPORTANT: Deploying Cloud Functions requires the Firebase Blaze (pay‑as‑you‑go) plan. Upgrade the project in Firebase Console → Usage and billing before deploying. Hosting on web.app does not require Blaze, only Functions do.

## Build and deploy web
1. `flutter build web --release`
2. `firebase deploy --only hosting`

## DNS (custom domain)
1. In Firebase Hosting, add your domain and follow DNS steps.
2. Update `web/sitemap.xml` URLs to your domain.

## Optional hardening
- Implement full webhook signature verification (already supported if you set `stripe.webhook`).
- Add Terms/Privacy pages and link from the app (e.g., More tab).
- Run Lighthouse and fix any quick wins.
