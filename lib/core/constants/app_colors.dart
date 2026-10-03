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

  // Dark Theme Palette - Deep Obsidian Slate & Racing Crimson
  static const Color darkBackground = Color(0xFF0C0F17); // Deep Pitch Slate
  static const Color darkSurface = Color(0xFF141924); // Sleek Obsidian Surface
  static const Color darkSurfaceElevated = Color(0xFF1D2333); // Elevated Card Surface
  static const Color darkBorder = Color(0xFF273145); // Refined Subtle Border
  static const Color darkTextPrimary = Color(0xFFF8FAFC); // Crisp High-Contrast White
  static const Color darkTextSecondary = Color(0xFF94A3B8); // Cool Slate Neutral Gray
  static const Color darkTextMuted = Color(0xFF64748B); // Muted Gray

  // Light Theme Palette - Ultra Clean Athletic White & Slate
  static const Color lightBackground = Color(0xFFF6F8FA); // Crisp Sport Off-White
  static const Color lightSurface = Color(0xFFFFFFFF); // Pure White Surface
  static const Color lightSurfaceElevated = Color(0xFFEDF2F7); // Soft Elevated Surface
  static const Color lightBorder = Color(0xFFE2E8F0); // Crisp Neutral Border
  static const Color lightTextPrimary = Color(0xFF0F172A); // Deep Slate
  static const Color lightTextSecondary = Color(0xFF475569); // Slate Gray
  static const Color lightTextMuted = Color(0xFF64748B); // Muted Slate Gray

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
    colors: [Color(0xFF1A1F2D), Color(0xFF111522)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroCardGradient = LinearGradient(
    colors: [Color(0xFF1E2434), Color(0xFF131724)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkScreenGradient = LinearGradient(
    colors: [Color(0xFF0F131E), Color(0xFF0A0D15)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient lightScreenGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF4F6F9)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
