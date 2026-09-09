import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  AppTextStyles._();

  // Headlines
  static TextStyle h1 = GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
  );

  static TextStyle h2 = GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );

  static TextStyle h3 = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  // Body
  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  // Score Numbers & Badges (Monospaced & Punchy)
  static TextStyle scoreDisplay = GoogleFonts.jetBrainsMono(
    fontSize: 48,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.0,
  );

  static TextStyle scoreMedium = GoogleFonts.jetBrainsMono(
    fontSize: 26,
    fontWeight: FontWeight.w700,
  );

  static TextStyle scoreSmall = GoogleFonts.jetBrainsMono(
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );

  static TextStyle badgeText = GoogleFonts.jetBrainsMono(
    fontSize: 13,
    fontWeight: FontWeight.w800,
  );

  // Labels & Buttons
  static TextStyle button = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  static TextStyle label = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );
}
