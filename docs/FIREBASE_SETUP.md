# Firebase setup (public clone)

This app does **not** commit Firebase client configuration files. After cloning, generate them with the [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/) using **your own** Firebase project.

## Prerequisites

- A [Firebase](https://console.firebase.google.com/) project
- **Authentication** → enable **Email/Password**
- **Firestore** → create database (start in test mode only for local dev, then use production rules)

## One-time setup on your machine

From the project root:

```bash
flutter pub get

# Install FlutterFire CLI (once per machine)
dart pub global activate flutterfire_cli

# Log in to Firebase (browser)
firebase login

# Generate lib/firebase_options.dart and platform config files
flutterfire configure
```

Follow the prompts: select your Firebase project and the platforms you use (Android, iOS, macOS, web as needed).

This creates (among other things):

- `lib/firebase_options.dart`
- `android/app/google-services.json` (Android)
- `ios/Runner/GoogleService-Info.plist` (iOS)
- `macos/Runner/GoogleService-Info.plist` (macOS, if selected)

These paths are listed in `.gitignore` so they are **not** pushed to GitHub.

## Firestore security rules

Use rules so users can only access their own data, for example:

```text
match /users/{userId}/{document=**} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}
```

Adjust to match your data model.

## Troubleshooting

- **`Target of URI doesn't exist: 'package:.../firebase_options.dart'`** — Run `flutterfire configure` from the project root.
- **Build fails on Android/iOS** — Ensure the platform apps are registered in the Firebase console for the same package name / bundle ID as in this project.
