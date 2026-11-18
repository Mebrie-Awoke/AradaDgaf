# AradaDgaf Mobile

Flutter client for the AradaDgaf IT support system. It shares the Django backend and MongoDB records used by the administrator portal.

## Requirements

- Flutter SDK compatible with the Dart SDK constraint in `pubspec.yaml`
- Android Studio / Android SDK
- A reachable AradaDgaf backend and an account provisioned by an administrator

## Install dependencies

Run from this directory:

```powershell
flutter pub get
```

## Configure the API URL

The app reads `API_BASE_URL` at compile time. Include the `/api` prefix, but do not include `/mobile`.

Android Emulator default:

```text
http://10.0.2.2:8000/api
```

For a physical Android device, pass the development computer's LAN IP and ensure both devices can reach each other. For deployment, use the HTTPS Render service URL.

## Run locally

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

## Build a release APK

Replace the example host with the actual Render service hostname:

```powershell
flutter build apk --release --dart-define=API_BASE_URL=https://YOUR-RENDER-SERVICE.onrender.com/api
```

The APK is normally generated at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## Backend integration

The app uses `ApiTicketRepository` and the `/api/mobile/` endpoints for authentication, ticket listing/submission/details, technician work actions, service ratings, and notifications.

Bearer tokens are stored using `flutter_secure_storage`. The role selector maps employee accounts to `employee` and backend support/admin accounts to `technician`.

Demo credentials and the in-memory mock repository have been removed. Accounts must be provisioned in the backend by an administrator.

## Verify before release

```powershell
flutter analyze
flutter test
flutter build apk --release --dart-define=API_BASE_URL=https://YOUR-RENDER-SERVICE.onrender.com/api
```

Install the APK on a physical Android device and test both employee and technician accounts against the deployed backend. Verify ticket creation, technician start-work, work recording, ratings, notifications, logout, and expired-token behavior. Source integration alone does not prove live deployment readiness.
