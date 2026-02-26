import 'package:flutter/material.dart';

/// Predefined animation curves and durations for consistent motion design.
/// CARE-AI uses calm, smooth animations to avoid overwhelming users.
class AppAnimations {
  AppAnimations._();

  // ─── Durations ───────────────────────────────────────────────
  /// Ultra-fast micro-interactions (button press, toggle)
  static const Duration fast = Duration(milliseconds: 150);

  /// Standard transitions (page fade, card expand)
  static const Duration normal = Duration(milliseconds: 300);

  /// Smooth transitions (modal, drawer)
  static const Duration slow = Duration(milliseconds: 500);

  /// Elaborate transitions (onboarding, hero)
  static const Duration xSlow = Duration(milliseconds: 800);

  /// Very long (splash, initial loading)
  static const Duration splash = Duration(milliseconds: 1200);

  // ─── Curves ──────────────────────────────────────────────────
  /// Default smooth ease-in-out
  static const Curve defaultCurve = Curves.easeInOutCubic;

  /// Entering elements (slide in, fade in)
  static const Curve enter = Curves.easeOutCubic;

  /// Exiting elements (slide out, fade out)
  static const Curve exit = Curves.easeInCubic;

  /// Bouncy / playful (game elements, celebrations)
  static const Curve bounce = Curves.elasticOut;

  /// Spring-like overshoot (buttons, toggles)
  static const Curve spring = Curves.easeOutBack;

  /// Smooth decelerate (page transitions)
  static const Curve decelerate = Curves.decelerate;

  // ─── Common Delays ───────────────────────────────────────────
  /// Stagger delay between list items
  static const Duration stagger = Duration(milliseconds: 50);

  /// Delay before starting an animation sequence
  static const Duration startDelay = Duration(milliseconds: 200);
}
