import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Predefined gradient presets used throughout CARE-AI.
/// Consistent, premium gradients for cards, headers, and backgrounds.
class AppGradients {
  AppGradients._();

  // ─── Primary Gradients ───────────────────────────────────────
  static const LinearGradient primary = LinearGradient(
    colors: [AppColors.primary, AppColors.primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryVertical = LinearGradient(
    colors: [AppColors.primary, AppColors.primaryDark],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ─── Accent Gradients ────────────────────────────────────────
  static const LinearGradient accent = LinearGradient(
    colors: [AppColors.accent, AppColors.accentLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warm = LinearGradient(
    colors: [AppColors.secondary, AppColors.gold],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Hero / Dashboard Gradients ──────────────────────────────
  static const LinearGradient hero = LinearGradient(
    colors: [Color(0xFF5B6EF5), Color(0xFF8B5CF6), Color(0xFFA855F7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroSubtle = LinearGradient(
    colors: [Color(0xFFEEF0FF), Color(0xFFF5EEFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Card Gradients ──────────────────────────────────────────
  static const LinearGradient cardGlow = LinearGradient(
    colors: [Color(0xFF5B6EF5), Color(0xFF2DD4A8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardWarm = LinearGradient(
    colors: [Color(0xFFFF7B6B), Color(0xFFFFB938)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardCool = LinearGradient(
    colors: [Color(0xFF2DD4A8), Color(0xFF5B6EF5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardPurple = LinearGradient(
    colors: [Color(0xFFA855F7), Color(0xFF5B6EF5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Emergency Gradient ──────────────────────────────────────
  static const LinearGradient emergency = LinearGradient(
    colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Dark Theme Gradients ────────────────────────────────────
  static const LinearGradient darkHero = LinearGradient(
    colors: [Color(0xFF1A1D35), Color(0xFF242742)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient darkCard = LinearGradient(
    colors: [Color(0xFF1E2140), Color(0xFF2D3154)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Doctor Portal ───────────────────────────────────────────
  static const LinearGradient doctor = LinearGradient(
    colors: [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Glass / Overlay ─────────────────────────────────────────
  static const LinearGradient glassOverlay = LinearGradient(
    colors: [Color(0x20FFFFFF), Color(0x05FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Background Mesh ─────────────────────────────────────────
  static const RadialGradient backgroundGlow = RadialGradient(
    colors: [Color(0x155B6EF5), Color(0x00FFFFFF)],
    radius: 1.5,
    center: Alignment.topRight,
  );
}
