import 'package:flutter/material.dart';

/// Material 3 theme seeded off a single brand color. Both light and dark
/// schemes are derived automatically; if we ever swap the brand seed it
/// propagates everywhere.
ThemeData appTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF1565C0),
    brightness: brightness,
  );
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      filled: false,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
      ),
    ),
  );
}
