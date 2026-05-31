# Fidel Guide — Flutter Frontend

Single Flutter codebase that builds for **web, Android, and iOS**, talking to the Express + Prisma backend in `../backend/`.

## Tech Stack

| Concern | Package |
|---|---|
| State management | `flutter_riverpod` |
| Navigation / deep linking | `go_router` |
| HTTP + JWT plumbing | `dio` |
| Token storage (per-platform) | `flutter_secure_storage` |
| Form helpers | `email_validator` |
| Theme | Material 3 with custom design system |
| Animations | Custom transitions and effects |

## Features

### Implemented Features
- **Authentication**: Registration, login, email verification, password reset, profile management
- **School Discovery**: Browse, search, and filter schools with detailed information
- **School Details**: View comprehensive school profiles with ratings, reviews, and verification status
- **Recommendations**: AI-powered personalized school recommendations
- **School Comparison**: Side-by-side comparison of multiple schools
- **Reviews & Ratings**: Write and moderate reviews with category-based tags
- **Announcements**: School and Ministry announcements with targeted delivery
- **Follow System**: Subscribe to schools for updates
- **Forum**: Community Q&A for parent discussions
- **Analytics**: School and Ministry-level dashboards
- **School Management**: Admin interface for school profile management
- **Verification Workflow**: Document submission and MoE approval process

### Design System
- Custom color palette with navy blue primary theme
- Comprehensive typography system
- Spacing and sizing utilities
- Custom navigation components (AppNavigationBar, AppNavigationRail, AppBottomNavigation)
- Unique page transitions (navySweep, bounceSlide, rotateIn, expandFromCenter)
- Responsive layouts for all screen sizes

## Project Layout

```
lib/
├── core/                            # Cross-feature plumbing
│   ├── config.dart                  # API base URL (--dart-define=API_BASE_URL=…)
│   ├── api_client.dart              # Single Dio instance + JWT interceptor
│   ├── auth_storage.dart            # flutter_secure_storage wrapper
│   ├── router.dart                  # go_router with auth-state redirect + custom transitions
│   ├── theme.dart                   # Material 3 theme (light + dark)
│   ├── design_system.dart           # Custom design system (colors, spacing, typography)
│   └── typography.dart              # Typography definitions
├── features/
│   ├── auth/                        # Authentication (register, login, verify, reset, profile)
│   │   ├── data/                    # DTOs + repository (Dio calls)
│   │   ├── state/                   # Riverpod ChangeNotifier (auth state)
│   │   └── presentation/            # Screens (login, register, profile, etc.)
│   ├── landing/                     # Landing page with feature illustrations
│   │   └── presentation/            # Landing screen
│   ├── schools/                     # School discovery and details
│   │   ├── data/                    # School DTOs and repositories
│   │   ├── state/                   # School state management
│   │   └── presentation/            # School list, detail, map screens
│   ├── recommendations/             # AI-powered recommendations
│   │   ├── data/                    # Recommendation DTOs
│   │   ├── state/                   # Recommendation state
│   │   └── presentation/            # Recommendation screens
│   ├── comparisons/                 # School comparison
│   │   ├── data/                    # Comparison DTOs
│   │   ├── state/                   # Comparison state
│   │   └── presentation/            # Comparison screens
│   ├── announcements/               # Announcements feed and details
│   │   ├── data/                    # Announcement DTOs
│   │   ├── state/                   # Announcement state
│   │   └── presentation/            # Announcement screens
│   ├── forum/                       # Community Q&A
│   │   ├── data/                    # Forum DTOs
│   │   ├── state/                   # Forum state
│   │   └── presentation/            # Forum screens
│   ├── admin/                       # Admin dashboard
│   │   ├── data/                    # Admin DTOs
│   │   ├── state/                   # Admin state
│   │   └── presentation/            # Admin screens (home, announcements, school management)
│   ├── analytics/                   # Analytics dashboards
│   │   ├── data/                    # Analytics DTOs
│   │   ├── state/                   # Analytics state
│   │   └── presentation/            # Analytics screens
│   └── achievements/                # MoE achievement reviews
│       ├── data/                    # Achievement DTOs
│       ├── state/                   # Achievement state
│       └── presentation/            # Achievement review screens
└── shared/
    ├── widgets/                     # Shared UI components
    │   ├── responsive_shell.dart    # Responsive app shell with navigation
    │   ├── custom_navigation.dart   # Custom navigation components
    │   ├── loading_button.dart      # Loading button widget
    │   └── ...                      # Other shared widgets
    └── utils/                       # Shared utilities
        ├── animations.dart          # Custom animation definitions
        └── ...                      # Other utilities
```

Feature-first folder layout: each feature gets its own `features/<name>/{data,state,presentation}` triplet for clean separation of concerns.

## Local Development

### Prerequisites
- Flutter SDK ≥ 3.24 (`flutter --version`)
- Backend running on port `5050` (`PORT=5050 npm run dev` from `../backend/`)
- For Android: Android Studio + SDK + an emulator
- For iOS: Xcode + iOS SDK (macOS only)

### First Run
```bash
cd frontend
flutter pub get

# Web (Chrome) — backend on the same machine
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:5050

# Android emulator — localhost from emulator points to 10.0.2.2
flutter run -d <android-emu-id> --dart-define=API_BASE_URL=http://10.0.2.2:5050

# iOS simulator (macOS only)
flutter run -d <ios-simulator-id> --dart-define=API_BASE_URL=http://localhost:5050
```

### Development Commands
```bash
flutter analyze    # Static analysis (lint + type errors)
flutter test       # Unit + widget tests
flutter build web  # Build web version
flutter build apk  # Build Android APK
flutter build ios  # Build iOS app
```

### Environment Configuration

The API base URL can be configured using dart-define:

```bash
# Local development (default)
flutter run --dart-define=API_BASE_URL=http://localhost:5050

# Production
flutter run --dart-define=API_BASE_URL=https://api.fidelguide.com
```

For more configuration options, see [`.env.example`](.env.example).

## Auth Flow Quick Test (Web)

1. Start backend on port 5050 with `NODE_ENV=development` (Ethereal mailer enabled)
2. Run `flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:5050`
3. Register a parent account
4. Check backend logs for the verification link from Ethereal
5. Open the verification link → app navigates to `/verify-email?token=…` → "Email verified"
6. Navigate to `/login` → enter credentials → land on home page
7. Visit `/profile` to edit name, change password, or deactivate account

## Design System

The app uses a custom design system defined in `lib/core/design_system.dart`:

- **Colors**: Navy blue primary theme with semantic color tokens
- **Typography**: Custom font scales and weights
- **Spacing**: Consistent spacing scale for layouts
- **Components**: Reusable UI components following design principles
- **Animations**: Unique transitions and micro-interactions

## Environment Variables

| Define | Default | Purpose |
|---|---|---|
| `API_BASE_URL` | `http://localhost:5050` | Backend API root URL |

## Deployment

### Web
```bash
flutter build web --release
```
Deploy the `build/web` directory to Firebase Hosting, Netlify, or any static hosting service.

### Android
```bash
flutter build apk --release
```
The APK will be in `build/app/outputs/flutter-apk/app-release.apk`.

### iOS
```bash
flutter build ios --release
```
Requires Xcode and macOS. For production, you'll need an Apple Developer account.

## Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/widget_test.dart
```