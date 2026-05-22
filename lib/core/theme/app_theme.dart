import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Orderlli Design System — "The Culinary Architect"
/// Based on Stitch orderlli_crimson design tokens.
class AppTheme {
  // ── Primary Palette ───────────────────────────────────────────────────────
  static const Color primary = Color(0xFF9D0518);
  static const Color primaryContainer = Color(0xFFC0272D);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryFixed = Color(0xFFFFDAD7);
  static const Color primaryFixedDim = Color(0xFFFFB3AE);
  static const Color onPrimaryFixed = Color(0xFF410004);
  static const Color onPrimaryFixedVariant = Color(0xFF930015);

  // ── Secondary ─────────────────────────────────────────────────────────────
  static const Color secondary = Color(0xFF515F74);
  static const Color secondaryContainer = Color(0xFFD5E3FC);
  static const Color onSecondaryContainer = Color(0xFF57657A);

  // ── Tertiary ──────────────────────────────────────────────────────────────
  static const Color tertiary = Color(0xFF00536E);
  static const Color tertiaryContainer = Color(0xFF006D8F);

  // ── Surface Hierarchy ─────────────────────────────────────────────────────
  static const Color background = Color(0xFFF8FAFB);
  static const Color surface = Color(0xFFF8FAFB);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF2F4F5);
  static const Color surfaceContainer = Color(0xFFECEEEF);
  static const Color surfaceContainerHigh = Color(0xFFE6E8E9);
  static const Color surfaceContainerHighest = Color(0xFFE1E3E4);
  static const Color surfaceBright = Color(0xFFF8FAFB);
  static const Color surfaceDim = Color(0xFFD8DADB);

  // ── On-Surface ────────────────────────────────────────────────────────────
  static const Color onSurface = Color(0xFF191C1D);
  static const Color onSurfaceVariant = Color(0xFF5A403E);
  static const Color onBackground = Color(0xFF191C1D);

  // ── Error ─────────────────────────────────────────────────────────────────
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);

  // ── Outline ───────────────────────────────────────────────────────────────
  static const Color outline = Color(0xFF8F706D);
  static const Color outlineVariant = Color(0xFFE3BEBB);

  // ── Misc ──────────────────────────────────────────────────────────────────
  static const Color inverseSurface = Color(0xFF2E3132);
  static const Color inverseOnSurface = Color(0xFFEFF1F2);
  static const Color inversePrimary = Color(0xFFFFB3AE);
  static const Color surfaceTint = Color(0xFFB72028);

  // ── Shadow ────────────────────────────────────────────────────────────────
  /// Crimson-tinted shadow used for floating elements
  static const List<BoxShadow> crimsonShadow = [
    BoxShadow(
      color: Color(0x149D0518), // rgba(157,5,24,0.08)
      blurRadius: 32,
      spreadRadius: -8,
      offset: Offset(0, 12),
    ),
  ];

  static const List<BoxShadow> crimsonShadowLight = [
    BoxShadow(
      color: Color(0x0D9D0518), // rgba(157,5,24,0.05)
      blurRadius: 32,
      spreadRadius: -8,
      offset: Offset(0, 12),
    ),
  ];

  // ── Text Styles ───────────────────────────────────────────────────────────
  static TextStyle get displayLg => GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: onSurface,
    letterSpacing: -0.5,
  );

  static TextStyle get headlineMd => GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: onSurface,
    letterSpacing: -0.5,
  );

  static TextStyle get titleLg => GoogleFonts.inter(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: onSurface,
    letterSpacing: -0.3,
  );

  static TextStyle get titleMd => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: onSurface,
  );

  static TextStyle get titleSm => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: onSurface,
  );

  static TextStyle get bodyMd => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: onSurface,
    height: 1.6,
  );

  static TextStyle get bodySm => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: secondary,
    height: 1.5,
  );

  static TextStyle get labelMd => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: secondary,
  );

  static TextStyle get labelSm => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: secondary,
    letterSpacing: 0.8,
  );

  /// JetBrains Mono for technical data (IDs, prices, table numbers)
  static TextStyle get monoMd => GoogleFonts.jetBrainsMono(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.6,
  );

  static TextStyle get monoLg => GoogleFonts.jetBrainsMono(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  // ── Radius ────────────────────────────────────────────────────────────────
  static const BorderRadius radiusSm = BorderRadius.all(Radius.circular(8));
  static const BorderRadius radiusMd = BorderRadius.all(Radius.circular(12));
  static const BorderRadius radiusLg = BorderRadius.all(Radius.circular(16));
  static const BorderRadius radiusXl = BorderRadius.all(Radius.circular(20));
  static const BorderRadius radiusFull = BorderRadius.all(
    Radius.circular(9999),
  );

  // ── Theme ─────────────────────────────────────────────────────────────────
  static ThemeData get light {
    final base = GoogleFonts.interTextTheme();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primary,
        primaryContainer: primaryContainer,
        onPrimary: onPrimary,
        secondary: secondary,
        secondaryContainer: secondaryContainer,
        surface: surface,
        onSurface: onSurface,
        error: error,
        errorContainer: errorContainer,
        onError: onError,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceContainerLowest,
        foregroundColor: onSurface,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
        iconTheme: const IconThemeData(color: secondary),
      ),
      textTheme: base.copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          color: onSurface,
          letterSpacing: -1.0,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: onSurface,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: onSurface,
          letterSpacing: -0.5,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: onSurface,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: onSurface,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: onSurface,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: secondary,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: secondary,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: secondary,
          letterSpacing: 0.5,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: const TextStyle(color: secondary),
        labelStyle: const TextStyle(
          color: secondary,
          fontWeight: FontWeight.w500,
        ),
        prefixIconColor: secondary,
        suffixIconColor: secondary,
        // Bottom-border-only style (financial dashboard aesthetic)
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: surfaceContainerHigh, width: 2),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: surfaceContainerHigh, width: 2),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: primaryContainer, width: 2),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: error, width: 2),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryContainer,
          foregroundColor: onPrimary,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryContainer,
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: primaryContainer, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryContainer,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceContainerLowest,
        selectedItemColor: primaryContainer,
        unselectedItemColor: secondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerColor: surfaceContainerHighest,
      dividerTheme: const DividerThemeData(
        color: surfaceContainerHighest,
        thickness: 1,
        space: 0,
      ),
    );
  }
}
