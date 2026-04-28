# School Recommendation System — Flutter frontend

Single Flutter codebase that builds for **web, Android, and iOS**, talking to
the Express + Prisma backend in `../backend/`.

## Stack

| Concern | Package |
|---|---|
| State management | `flutter_riverpod` |
| Navigation / deep linking | `go_router` |
| HTTP + JWT plumbing | `dio` |
| Token storage (per-platform) | `flutter_secure_storage` |
| Form helpers | `email_validator` |
| Theme | Material 3 |

## Project layout

```
lib/
├── core/                            # Cross-feature plumbing (one file = one concern)
│   ├── config.dart                  # API base URL (--dart-define=API_BASE_URL=…)
│   ├── api_client.dart              # Single Dio instance + JWT interceptor
│   ├── auth_storage.dart            # flutter_secure_storage wrapper
│   ├── router.dart                  # go_router with auth-state redirect
│   └── theme.dart                   # Material 3 theme (light + dark)
├── features/
│   ├── auth/                        # Phase 7 — register / login / verify / reset / profile
│   │   ├── data/                    # DTOs + repository (Dio calls)
│   │   ├── state/                   # Riverpod ChangeNotifier (auth state)
│   │   └── presentation/            # Screens
│   └── home/                        # Placeholder; replaced in Phase 8
└── shared/widgets/                  # ResponsiveShell, LoadingButton, …
```

Feature-first folder layout: each Phase 8/9 feature (browse, dashboard, forum,
…) gets its own `features/<name>/{data,state,presentation}` triplet.

## Local development

### Prerequisites
- Flutter SDK ≥ 3.24 (`flutter --version`).
- Backend running on port `5050` (`PORT=5050 npm run dev` from `../backend/`).
- For Android: Android Studio + SDK + an emulator.
- For iOS: deferred to Phase 10 — don't bother locally.

### First run
```bash
cd frontend
flutter pub get

# Web (Chrome) — backend on the same machine
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:5050

# Android emulator — `localhost` from the emulator points to the host's
# loopback alias 10.0.2.2, NOT the host's 127.0.0.1
flutter run -d <android-emu-id> --dart-define=API_BASE_URL=http://10.0.2.2:5050
```

### Tests
```bash
flutter analyze    # Static analysis (lint + type errors)
flutter test       # Unit + widget tests
```

### Auth-flow quick test (web)
1. Backend on 5050 with `NODE_ENV=development` so Ethereal mailer is wired.
2. `flutter run -d chrome …`.
3. Register a parent — note the verification link in the backend logs.
4. Open the link → app navigates to `/verify-email?token=…` → "Email verified".
5. `/login` → land on `/`.
6. `/profile` → edit name, change password, deactivate.

## Environment knobs

| Define | Default | Purpose |
|---|---|---|
| `API_BASE_URL` | `http://localhost:5050` | Backend root |

## Deployment (Phase 10)

- **Web**: `flutter build web --release` → Firebase Hosting (free tier).
- **Android**: `flutter build apk --release` → distribute APK directly.
- **iOS**: Codemagic free tier (500 macOS min/mo) builds the `.ipa`. Sideload
  for the defense; App Store needs a $99/year Apple Developer account.
