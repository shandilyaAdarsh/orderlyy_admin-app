// lib/core/theme/app_text_styles.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  static TextStyle get h1 => GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      );

  static TextStyle get h2 => GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.2,
      );

  static TextStyle get h3 => GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      );

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.1,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.1,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.2,
      );

  static TextStyle get button => GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
      );
}
