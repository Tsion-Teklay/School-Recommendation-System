/// Centralizes the API base URL so swapping environments is a one-line change.
///
/// Web/Android dev (this VM):  flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:5050
/// Android emulator:           --dart-define=API_BASE_URL=http://10.0.2.2:5050
/// Production:                 --dart-define=API_BASE_URL=https://api.example.com
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5050',
  );
}
