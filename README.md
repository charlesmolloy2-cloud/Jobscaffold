# JobScaffold

JobScaffold is a builder-friendly project management app for construction teams.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:



## GitHub Actions: Firebase Hosting Deploy

To enable deployment to Firebase Hosting via GitHub Actions, you must add the `FIREBASE_SERVICE_ACCOUNT` secret to your repository:

1. Go to your repository on GitHub.
2. Click on **Settings** > **Secrets and variables** > **Actions**.
3. Click **New repository secret**.
4. Name it `FIREBASE_SERVICE_ACCOUNT` and paste your Firebase service account JSON as the value.
5. Save the secret.

This secret is required for the workflow in `.github/workflows/deploy-hosting.yml` to deploy successfully.

For help getting started with Flutter development, view the
 [online documentation](https://docs.flutter.dev/), which offers tutorials,
 samples, guidance on mobile development, and a full API reference.
