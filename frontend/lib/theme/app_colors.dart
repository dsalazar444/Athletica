import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ─── Colores Principales ───────────────────────────────────────────────────
  static const Color primary = Color(0xFFFF6B35);
  static const Color primaryLight = Color(0xFFFF8E64);
  static const Color primaryDark = Color(0xFFD94E28);

  // ─── Gradientes ───────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [primaryDark, primary],
  );

  static const LinearGradient imageOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Color(0xCC000000)],
  );

  // ─── Neutros y Superficies ─────────────────────────────────────────────────
  static const Color background = Color(0xFFF0F2F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F3F5);
  static const Color white = Color(0xFFFFFFFF);
  static const Color whiteGlass = Color(0x99FFFFFF); // Glassmorphism
  static const Color blackGlass = Color(0x33000000);

  // ─── Texto ─────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF141718);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color textHint = Color(0xFFADB5BD);

  // ─── Bordes y Estados ──────────────────────────────────────────────────────
  static const Color border = Color(0xFFE9ECEF);
  static const Color borderSelected = Color(0xFFFF6B35);
  static const Color cardSelectedBg = Color(0xFFFFF4F0);
  static const Color buttonDisabled = Color(0xFFDEE2E6);
  static const Color buttonDisabledText = Color(0xFF868E96);

  // ─── Feedback ──────────────────────────────────────────────────────────────
  static const Color tagBackground = Color(0xFFFFF0EB);
  static const Color tagText = Color(0xFFFF6B35);
  static const Color error = Color(0xFFFA5252);
  static const Color deleteRed = Color(0xFFFA5252);
  static const Color success = Color(0xFF40C057);
  static const Color intensityNeon = Color(0xFFFFA500); // Electric fitness accent

  // ─── Sombras (Shadows) ─────────────────────────────────────────────────────
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get mediumShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  // Sombras por capas para profundidad extrema (Premium)
  static List<BoxShadow> get deepShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 32,
          offset: const Offset(0, 16),
        ),
      ];
}

