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
    // Use a finite minimum-width here. `Size.fromHeight(48)` resolves to
    // `Size(double.infinity, 48)`, which forces every FilledButton in the
    // app to a min-width of infinity. That works in `Column(crossAxisAlignment:
    // stretch)` (where the parent imposes a tight bounded width regardless),
    // but blows up in unbounded-width contexts — `Row + Spacer`, `Wrap`,
    // narrow viewports — with "Cannot hit test a render box that has never
    // been laid out" / "BoxConstraints forces an infinite width" assertions.
    // `Size(0, 48)` keeps the 48dp tap-target height and lets the button
    // size to its content elsewhere.
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 48),
      ),
    ),
  );
}
