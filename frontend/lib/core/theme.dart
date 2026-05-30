import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData appTheme() {
  // Use ColorScheme.fromSeed to automatically generate all Material 3 colors
  // while keeping your custom blue as the primary brand color
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF2563EB),
    brightness: Brightness.light,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,

    scaffoldBackgroundColor: const Color(0xFFF8FAFC),

    textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
      headlineLarge: GoogleFonts.plusJakartaSans(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF1A1D23),
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF1A1D23),
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1A1D23),
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        height: 1.5,
        color: const Color(0xFF374151),
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        height: 1.5,
        color: const Color(0xFF6B7280),
      ),
    ),

    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: Colors.black.withValues(alpha: 0.06),
        ),
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,

      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),

      hintStyle: TextStyle(
        color: Colors.grey.shade600,
      ),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.grey.withValues(alpha: 0.3),
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: scheme.primary,
          width: 2,
        ),
      ),
    ),

    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Color(0xFF1A1D23),
      iconTheme: IconThemeData(
        color: Color(0xFF1A1D23),
      ),
    ),

    iconTheme: const IconThemeData(
      color: Color(0xFF374151),
    ),
  );
}