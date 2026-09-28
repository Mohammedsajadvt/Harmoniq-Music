import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const Color background = Color(0xFF090B10);
  static const Color surface = Color(0xFF121624);
  static const Color surfaceElevated = Color(0xFF1C2236);
  static const Color surfaceGlass = Color(0x331E293B);

  // Accents & Neons
  static const Color primary = Color(0xFF8B5CF6); // Vibrant Electric Purple
  static const Color primaryLight = Color(0xFFA78BFA);
  static const Color secondary = Color(0xFF06B6D4); // Neon Cyan
  static const Color secondaryLight = Color(0xFF22D3EE);
  static const Color accent = Color(0xFFFF3366); // Neon Pink / Coral
  static const Color accentYellow = Color(0xFFFBBF24);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient neonGradient = LinearGradient(
    colors: [Color(0xFFFF3366), Color(0xFF8B5CF6), Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF1E2438), Color(0xFF131726)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient glassOverlayGradient = LinearGradient(
    colors: [Colors.white10, Colors.white24],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Border & Divider
  static const Color border = Color(0xFF2E3856);
  static const Color borderGlow = Color(0x668B5CF6);
}
