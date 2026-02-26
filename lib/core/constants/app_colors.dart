import 'package:flutter/material.dart';

/// Premium, accessible color palette for CARE-AI.
///
/// Design philosophy:
/// - Calming, reassuring tones for stressed parents
/// - High contrast for accessibility (WCAG AA+)
/// - Child-friendly accent colors for game/activity sections
/// - Professional tones for doctor portal
class AppColors {
  AppColors._();

  // ─── Primary: Deep Indigo-Blue (trust, stability, calm) ──────
  static const Color primary = Color(0xFF5B6EF5);
  static const Color primaryLight = Color(0xFF8B9BFF);
  static const Color primaryDark = Color(0xFF3A4FD9);
  static const Color primarySurface = Color(0xFFEEF0FF);

  // ─── Secondary: Warm Coral-Orange (warmth, energy, hope) ─────
  static const Color secondary = Color(0xFFFF7B6B);
  static const Color secondaryLight = Color(0xFFFFA69E);
  static const Color secondaryDark = Color(0xFFE55A4A);
  static const Color secondarySurface = Color(0xFFFFF0EE);

  // ─── Accent: Vibrant Teal (growth, progress, healing) ────────
  static const Color accent = Color(0xFF2DD4A8);
  static const Color accentLight = Color(0xFF6EE7C6);
  static const Color accentDark = Color(0xFF1AAB87);
  static const Color accentSurface = Color(0xFFE6FBF4);

  // ─── Warm Gold (achievement, encouragement, milestones) ──────
  static const Color gold = Color(0xFFFFB938);
  static const Color goldLight = Color(0xFFFFD180);
  static const Color goldDark = Color(0xFFE59E1B);
  static const Color goldSurface = Color(0xFFFFF8E8);

  // ─── Purple (creativity, games, child activities) ────────────
  static const Color purple = Color(0xFFA855F7);
  static const Color purpleLight = Color(0xFFC084FC);
  static const Color purpleDark = Color(0xFF8B2FE0);
  static const Color purpleSurface = Color(0xFFF5EEFF);

  // ─── Light Theme Backgrounds ─────────────────────────────────
  static const Color background = Color(0xFFF8F9FE);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F3F9);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // ─── Dark Theme Backgrounds ──────────────────────────────────
  static const Color darkBackground = Color(0xFF0F1120);
  static const Color darkSurface = Color(0xFF1A1D35);
  static const Color darkSurfaceVariant = Color(0xFF242742);
  static const Color darkCardBackground = Color(0xFF1E2140);

  // ─── Text Colors (Light) ─────────────────────────────────────
  static const Color textPrimary = Color(0xFF1A1D3E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnDark = Color(0xFFF3F4F6);

  // ─── Text Colors (Dark) ──────────────────────────────────────
  static const Color darkTextPrimary = Color(0xFFF1F3F9);
  static const Color darkTextSecondary = Color(0xFF9CA3C2);
  static const Color darkTextTertiary = Color(0xFF6B7298);

  // ─── Status Colors ───────────────────────────────────────────
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF9C3);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);

  // ─── Emergency / Crisis ──────────────────────────────────────
  static const Color emergency = Color(0xFFDC2626);
  static const Color emergencyLight = Color(0xFFFCA5A5);
  static const Color emergencySurface = Color(0xFFFEF2F2);

  // ─── Chat Bubbles ────────────────────────────────────────────
  static const Color userBubble = Color(0xFF5B6EF5);
  static const Color aiBubble = Color(0xFFF1F3F9);
  static const Color darkUserBubble = Color(0xFF4B5CD4);
  static const Color darkAiBubble = Color(0xFF242742);

  // ─── Divider / Border ────────────────────────────────────────
  static const Color divider = Color(0xFFE5E7EB);
  static const Color border = Color(0xFFD1D5DB);
  static const Color darkDivider = Color(0xFF2D3154);
  static const Color darkBorder = Color(0xFF374063);

  // ─── Glass Effect ────────────────────────────────────────────
  static const Color glassWhite = Color(0x33FFFFFF);
  static const Color glassDark = Color(0x33000000);

  // ─── Shimmer ─────────────────────────────────────────────────
  static const Color shimmerBase = Color(0xFFE5E7EB);
  static const Color shimmerHighlight = Color(0xFFF3F4F6);

  // ─── Doctor Portal Accent ────────────────────────────────────
  static const Color doctorPrimary = Color(0xFF0EA5E9);
  static const Color doctorPrimaryDark = Color(0xFF0284C7);
  static const Color doctorSurface = Color(0xFFE0F7FF);
}
