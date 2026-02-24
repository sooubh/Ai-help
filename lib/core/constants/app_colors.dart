import 'package:flutter/material.dart';

/// Calm, accessible color palette from the CARE-AI PRD.
/// Designed to be soothing for stressed parents.
class AppColors {
  AppColors._();

  // Primary — Soft Blue (trust, calm)
  static const Color primary = Color(0xFF4A90E2);
  static const Color primaryLight = Color(0xFF7EB3F1);
  static const Color primaryDark = Color(0xFF2D6FC0);

  // Secondary — Soft Green (growth, hope)
  static const Color secondary = Color(0xFF7ED321);
  static const Color secondaryLight = Color(0xFFA8E065);
  static const Color secondaryDark = Color(0xFF5CA010);

  // Background — Light Neutral
  static const Color background = Color(0xFFF7F9FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Alert — Soft Orange
  static const Color alert = Color(0xFFF5A623);

  // Text Colors
  static const Color textPrimary = Color(0xFF2C3E50);
  static const Color textSecondary = Color(0xFF7F8C8D);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status
  static const Color error = Color(0xFFE74C3C);
  static const Color success = Color(0xFF27AE60);

  // Chat Bubbles
  static const Color userBubble = Color(0xFF4A90E2);
  static const Color aiBubble = Color(0xFFE8F0FE);

  // Divider / Border
  static const Color divider = Color(0xFFECF0F1);
  static const Color border = Color(0xFFDDE3EA);
}
