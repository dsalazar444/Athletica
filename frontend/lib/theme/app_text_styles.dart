import 'package:flutter/material.dart';
import './app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // ─── Screen & Section Titles ───────────────────────────────────────────────

  static const TextStyle screenTitle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle sectionSubtitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle bodyText1 = TextStyle(
    fontSize: 15,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  // ─── Header (naranja) ──────────────────────────────────────────────────────

  static const TextStyle appTitle = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w800,
    color: AppColors.white,
    letterSpacing: -1.0,
  );

  static const TextStyle headerSubtitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: Colors.white70,
  );

  static const TextStyle stepCounter = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
    letterSpacing: 1.0,
  );

  // ─── Labels ────────────────────────────────────────────────────────────────

  static const TextStyle label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.2,
  );

  static const TextStyle labelRequired = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );

  static const TextStyle inputLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // ─── Inputs ────────────────────────────────────────────────────────────────

  static const TextStyle inputText = TextStyle(
    fontSize: 15,
    color: AppColors.textPrimary,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle hintText = TextStyle(
    fontSize: 15,
    color: AppColors.textHint,
    fontWeight: FontWeight.w400,
  );

  // ─── Cards ─────────────────────────────────────────────────────────────────

  static const TextStyle cardTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  // ─── Exercises ─────────────────────────────────────────────────────────────

  static const TextStyle exerciseName = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle exerciseSubtitle = TextStyle(
    fontSize: 13,
    color: AppColors.textSecondary,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle addExerciseLink = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );

  // ─── Tags & Chips ──────────────────────────────────────────────────────────

  static const TextStyle tagLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.tagText,
    letterSpacing: 0.5,
  );

  static const TextStyle chipLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  // ─── Goals ─────────────────────────────────────────────────────────────────

  static const TextStyle goalEmoji = TextStyle(fontSize: 40);

  static const TextStyle goalLabel = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // ─── Buttons ───────────────────────────────────────────────────────────────

  static const TextStyle buttonPrimary = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: AppColors.surface,
    letterSpacing: 0.5,
  );

  static const TextStyle buttonSecondary = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
    letterSpacing: 0.5,
  );

  static const TextStyle buttonTextDisabled = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.buttonDisabledText,
    letterSpacing: 0.5,
  );

  // ─── Stats & Bento Grid ────────────────────────────────────────────────────

  static const TextStyle bentoValue = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w900,
    color: AppColors.textPrimary,
    letterSpacing: -1.0,
  );

  static const TextStyle bentoTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );

  static const TextStyle bentoUnit = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );

  // ─── Fitness Vibes ──────────────────────────────────────────────────────────

  static const TextStyle fitnessHero = TextStyle(
    fontSize: 42,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -1.5,
  );

  static const TextStyle fitnessDisplay = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle fitnessBold = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle fitnessCaption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w800,
    color: AppColors.textSecondary,
    letterSpacing: 2.0,
  );
}

// ─── Spacing ───────────────────────────────────────────────────────────────────

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
}
