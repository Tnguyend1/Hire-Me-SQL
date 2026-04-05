# HireMeSQL

A Flutter app for practicing SQL interview-style questions. Users sign in with Firebase Auth; progress and stats sync to Cloud Firestore. Question content is bundled locally from `assets/questions.json`.

## Features

- **Authentication** — Email/password sign up and sign in (Firebase Auth).
- **Practice** — Browse and solve problems; daily challenge and topic/company filters (as implemented in the app).
- **Progress** — XP, streaks, achievements, topic progress, and recent activity (persisted per user).
- **Wrong attempts** — Review mistakes; data is stored per account (local cache + Firestore where applicable).
- **Profile** — Stats and account actions (e.g. sign out).

## Tech stack

| Layer | Choice |
|--------|--------|
| UI | Flutter (Material) |
| State | `provider` + `ChangeNotifier` |
| Local persistence | `shared_preferences` |
| Backend | Firebase (Auth, Firestore) |
| Local DB (if used) | `sqflite` |

## Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install) (stable), SDK compatible with `pubspec.yaml` (`environment.sdk`).
- Xcode (for iOS) and/or Android Studio / Android SDK (for Android).
- A [Firebase](https://firebase.google.com/) project with **Authentication** (Email/Password) and **Cloud Firestore** enabled.

## Setup

1. **Clone the repository**

   ```bash
   git clone https://github.com/Tnguyend1/Hire-Me-SQL.git
   cd Hire-Me-SQL
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Firebase configuration (required — not committed on purpose)**

   This is a **public** repository: `lib/firebase_options.dart`, `google-services.json`, and `GoogleService-Info.plist` are **gitignored**. You must generate them with **your own** Firebase project:

   - Follow **[docs/FIREBASE_SETUP.md](docs/FIREBASE_SETUP.md)** (FlutterFire CLI: `flutterfire configure`).
   - **Firestore rules** should restrict data so each signed-in user can only read/write their own documents (e.g. under `users/{uid}/...`).

4. **Android signing (release only)**

   Release builds use a keystore configured in `android/` (see `key.properties` — that file should **not** be committed; it is listed in `android/.gitignore`). For local development, debug builds work without it.

## Run the app

```bash
# List devices
flutter devices

# Run (pick a device id if needed)
flutter run
```

## Build for stores (overview)

```bash
# Android App Bundle (Google Play)
flutter build appbundle

# iOS (from macOS, after CocoaPods / signing setup)
flutter build ipa
```

## Project layout (high level)

```
lib/
  app/           # Theme, root app widget
  screens/       # UI screens (login, home, profile, questions, etc.)
  state/         # AppState, shared app logic
  services/      # Auth & Firestore services
  models/        # Data models
  data/          # Question loading / repository
assets/
  questions.json # Bundled question bank
```

## Security note for public repositories

- **Signing:** Do **not** commit Android `key.properties`, `*.jks`, or `*.keystore` (they are ignored under `android/.gitignore`).
- **Firebase:** Client configs are **not** tracked in this repo; use `flutterfire configure` locally (see [docs/FIREBASE_SETUP.md](docs/FIREBASE_SETUP.md)). Real protection comes from **Firestore security rules** and **API key restrictions** in Google Cloud / Firebase console.

## License

This project was created for coursework / portfolio use. Add a license file (e.g. MIT) if you want to clarify reuse terms.
