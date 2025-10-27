# Jobscaffold.com Domain Integration Guide

## Overview
This guide will help you connect your Squarespace-purchased domain (jobscaffold.com) to your Firebase-hosted Flutter web app.

## Prerequisites
- Firebase project: `project-bridge-cm`
- Domain purchased: jobscaffold.com (via Squarespace)
- Firebase Hosting already configured

---

## Step-by-Step Integration

### 1. Add Custom Domain in Firebase Console

1. **Navigate to Firebase Console:**
   - Go to: https://console.firebase.google.com
   - Select project: **project-bridge-cm**

2. **Access Hosting Settings:**
   - Click **Hosting** in left sidebar
   - Click **Add custom domain** button

3. **Enter Your Domain:**
   - Primary domain: `jobscaffold.com`
   - Click **Continue**

4. **Note DNS Records:**
   Firebase will display DNS records you need to add. They'll look like:
   ```
   Type: A
   Name: @
   Value: 151.101.1.195, 151.101.65.195
   
   Type: TXT
   Name: @
   Value: [verification code from Firebase]
   ```

---

### 2. Configure DNS in Squarespace

1. **Log into Squarespace:**
   - Go to: https://account.squarespace.com
   - Navigate to **Settings → Domains**

2. **Select jobscaffold.com:**
   - Click on your domain
   - Click **DNS Settings**

3. **Remove Conflicting Records:**
   - Delete any existing A records pointing to Squarespace servers
   - Keep MX records if you use email

4. **Add Firebase DNS Records:**
   
   **A Records (IPv4):**
   ```
   Host: @
   Type: A
   Data: 151.101.1.195
   
   Host: @
   Type: A
   Data: 151.101.65.195
   ```

   **TXT Record (for verification):**
   ```
   Host: @
   Type: TXT
   Data: [paste the verification code from Firebase]
   ```

5. **Add www Subdomain (Recommended):**
   ```
   Host: www
   Type: CNAME
   Data: jobscaffold.com
   ```

6. **Save Changes**

---

### 3. Add www Subdomain in Firebase

1. **Back in Firebase Console:**
   - Click **Add custom domain** again
   - Enter: `www.jobscaffold.com`
   - Follow the same DNS setup process

---

### 4. Wait for DNS Propagation

- **Time Required:** 24-48 hours (usually faster)
- **Check Status:** Firebase Console will show verification status
- **SSL Certificate:** Firebase automatically provisions SSL after verification

**Check DNS Propagation:**
- Use: https://dnschecker.org
- Search for: `jobscaffold.com`

---

### 5. Update Firebase Authentication (Important!)

Once your domain is live, add it to authorized domains:

1. **Firebase Console → Authentication**
2. Click **Settings** tab
3. Scroll to **Authorized domains**
4. Click **Add domain**
5. Add:
   - `jobscaffold.com`
   - `www.jobscaffold.com`

---

### 6. Deploy Your App

After DNS is configured, deploy your latest build:

**Option A: Using Firebase CLI (if PowerShell execution policy allows):**
```powershell
cd "c:\flutterapps\Project Bridge"
flutter build web --release
firebase deploy --only hosting
```

**Option B: Manual Build & Deploy:**
1. Build: `flutter build web --release`
2. Use Firebase Console → Hosting → Deploy
3. Upload the `build/web` folder

---

## Verification Checklist

After setup, verify:

- [ ] https://jobscaffold.com loads your app
- [ ] https://www.jobscaffold.com redirects to main domain
- [ ] SSL certificate is valid (green padlock in browser)
- [ ] Firebase Auth works on custom domain
- [ ] Open Graph meta tags show correct domain

---

## Troubleshooting

### DNS Not Propagating
- Clear your DNS cache: `ipconfig /flushdns` (Windows)
- Try different DNS checker tools
- Wait 24-48 hours before contacting support

### SSL Certificate Not Provisioning
- Ensure all DNS records are correct
- Wait for full DNS propagation
- Check Firebase Console for error messages

### Authentication Fails
- Verify domain is in Firebase Auth → Authorized domains
- Check browser console for CORS errors
- Ensure OAuth redirect URIs are updated

### Squarespace Still Showing
- Confirm A records point to Firebase, not Squarespace
- Clear browser cache
- Try incognito/private browsing

---

## Alternative: Use Cloudflare (Advanced)

For better performance and DDoS protection:

1. **Transfer DNS to Cloudflare:**
   - Keep domain registered with Squarespace
   - Change nameservers to Cloudflare
   - Manage DNS through Cloudflare

2. **Benefits:**
   - Free CDN
   - DDoS protection
   - Analytics
   - Better cache control

3. **Setup:**
   - Sign up: https://cloudflare.com
   - Add site: jobscaffold.com
   - Update nameservers in Squarespace to Cloudflare's
   - Add Firebase DNS records in Cloudflare

---

## Post-Deployment Tasks

After your domain is live:

1. **Update Marketing Materials:**
   - Update links to use jobscaffold.com
   - Update social media profiles
   - Update business cards, etc.

2. **Set up Google Analytics:**
   - Update property URL to jobscaffold.com
   - Verify tracking is working

3. **Submit to Search Engines:**
   - Google Search Console: Add jobscaffold.com
   - Submit sitemap
   - Request indexing

4. **Monitor Performance:**
   - Check Firebase Hosting analytics
   - Monitor uptime
   - Check SSL certificate expiry (auto-renews)

---

## Support Resources

- **Firebase Hosting Docs:** https://firebase.google.com/docs/hosting
- **Squarespace DNS Help:** https://support.squarespace.com/hc/en-us/articles/205812378
- **Firebase Support:** https://firebase.google.com/support

---

## Notes

- **Current Firebase Project:** project-bridge-cm
- **Current Hosting:** build/web directory
- **SSL:** Automatically managed by Firebase
- **Cost:** Firebase hosting free tier: 10GB storage, 360MB/day bandwidth

---

## Quick Reference: DNS Records

Once you receive them from Firebase, your DNS records will be:

```
# Replace with actual values from Firebase Console

# A Records (IPv4)
@ → 151.101.1.195
@ → 151.101.65.195

# TXT Record (Verification)
@ → [Firebase verification code]

# CNAME (www subdomain)
www → jobscaffold.com
```

---

**Last Updated:** October 26, 2025
