import 'package:flutter/material.dart';

/// Predefined shadow presets for consistent elevation and depth.
class AppShadows {
  AppShadows._();

  // ─── Subtle (cards, chips) ───────────────────────────────────
  static List<BoxShadow> subtle = [
    BoxShadow(
      color: const Color(0xFF1A1D3E).withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  // ─── Soft (elevated cards) ───────────────────────────────────
  static List<BoxShadow> soft = [
    BoxShadow(
      color: const Color(0xFF1A1D3E).withValues(alpha: 0.06),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: const Color(0xFF1A1D3E).withValues(alpha: 0.02),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  // ─── Medium (floating elements) ──────────────────────────────
  static List<BoxShadow> medium = [
    BoxShadow(
      color: const Color(0xFF1A1D3E).withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: const Color(0xFF1A1D3E).withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  // ─── Strong (modals, dialogs) ────────────────────────────────
  static List<BoxShadow> strong = [
    BoxShadow(
      color: const Color(0xFF1A1D3E).withValues(alpha: 0.12),
      blurRadius: 32,
      offset: const Offset(0, 12),
    ),
    BoxShadow(
      color: const Color(0xFF1A1D3E).withValues(alpha: 0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // ─── Colored glow (primary buttons, hero elements) ───────────
  static List<BoxShadow> primaryGlow = [
    BoxShadow(
      color: const Color(0xFF5B6EF5).withValues(alpha: 0.30),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> accentGlow = [
    BoxShadow(
      color: const Color(0xFF2DD4A8).withValues(alpha: 0.30),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> secondaryGlow = [
    BoxShadow(
      color: const Color(0xFFFF7B6B).withValues(alpha: 0.30),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> emergencyGlow = [
    BoxShadow(
      color: const Color(0xFFDC2626).withValues(alpha: 0.35),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
}
