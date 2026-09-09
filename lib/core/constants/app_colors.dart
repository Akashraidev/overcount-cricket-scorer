import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Cricket & Sports Identity - Modern Red, White & Black
  static const Color primary = Color(0xFFDC2626); // Vibrant Racing Crimson Red
  static const Color primaryDark = Color(0xFF991B1B); // Deep Velvet Crimson
  static const Color primaryLight = Color(0xFFEF4444); // Bright Electric Red
  static const Color accent = Color(0xFFDC2626); // High-contrast Red accent
  static const Color accentLight = Color(0xFFFCA5A5);

  // Status & Event Badges - Vibrant & Distinct
  static const Color boundary4 = Color(0xFF2563EB); // Royal Ocean Blue for 4s
  static const Color boundary6 = Color(0xFF7C3AED); // Electric Purple / Violet for 6s
  static const Color wicket = Color(0xFFDC2626); // Wicket Crimson
  static const Color extraWide = Color(0xFFD97706); // Amber
  static const Color extraNoBall = Color(0xFFEA580C); // Warm Orange
  static const Color dotBall = Color(0xFF71717A); // Slate Zinc Grey
  static const Color single = Color(0xFF16A34A); // Emerald Green

  // Chart & Graph Colors (Distinct Innings Comparison)
  static const Color chartInnings1 = Color(0xFF2563EB); // Royal Blue for 1st Innings
  static const Color chartInnings2 = Color(0xFFDC2626); // Vivid Crimson Red for 2nd Innings

  // Dark Theme Palette - Obsidian Pitch Black & Crimson
  static const Color darkBackground = Color(0xFF0A0A0A); // Pure Deep Pitch Black
  static const Color darkSurface = Color(0xFF141414); // Sleek Obsidian Surface
  static const Color darkSurfaceElevated = Color(0xFF1F1F1F); // Elevated Charcoal Card
  static const Color darkBorder = Color(0xFF2E2E2E); // Subtle Charcoal Border
  static const Color darkTextPrimary = Color(0xFFFFFFFF); // Pure White
  static const Color darkTextSecondary = Color(0xFFA3A3A3); // Cool Neutral Gray
  static const Color darkTextMuted = Color(0xFF737373); // Muted Gray

  // Light Theme Palette - Ultra Clean White & Jet Black
  static const Color lightBackground = Color(0xFFF5F5F7); // Clean Off-White
  static const Color lightSurface = Color(0xFFFFFFFF); // Pure White Surface
  static const Color lightSurfaceElevated = Color(0xFFF0F0F2); // Soft Light Gray
  static const Color lightBorder = Color(0xFFE4E4E7); // Subtle Border
  static const Color lightTextPrimary = Color(0xFF0A0A0A); // Jet Black
  static const Color lightTextSecondary = Color(0xFF52525B); // Graphite Gray
  static const Color lightTextMuted = Color(0xFF71717A); // Slate Gray

  // Live Indicator & Alerts
  static const Color liveRed = Color(0xFFDC2626);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color error = Color(0xFFDC2626);
  static const Color danger = Color(0xFFDC2626);
  static const Color info = Color(0xFF2563EB);

  // Gradient accents
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFDC2626), Color(0xFF991B1B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient liveHeaderGradient = LinearGradient(
    colors: [Color(0xFF171717), Color(0xFF0A0A0A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient heroCardGradient = LinearGradient(
    colors: [Color(0xFF1E1E1E), Color(0xFF0A0A0A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
