import 'package:flutter/material.dart';
import './app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // ─── Screen & Section Titles ───────────────────────────────────────────────

  static const TextStyle screenTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle sectionSubtitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  // ─── Header (naranja) ──────────────────────────────────────────────────────

  static const TextStyle appTitle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
    letterSpacing: -0.5,
  );

  static const TextStyle headerSubtitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.white,
  );

  static const TextStyle stepCounter = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.white,
  );

  // ─── Labels ────────────────────────────────────────────────────────────────

  static const TextStyle label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelRequired = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.primary,
  );

  static const TextStyle inputLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  // ─── Inputs ────────────────────────────────────────────────────────────────

  static const TextStyle inputText = TextStyle(
    fontSize: 14,
    color: AppColors.textPrimary,
  );

  static const TextStyle hintText = TextStyle(
    fontSize: 14,
    color: AppColors.textHint,
  );

  // ─── Cards ─────────────────────────────────────────────────────────────────

  static const TextStyle cardTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  // ─── Exercises ─────────────────────────────────────────────────────────────

  static const TextStyle exerciseName = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle exerciseSubtitle = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );

  static const TextStyle addExerciseLink = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );

  // ─── Tags & Chips ──────────────────────────────────────────────────────────

  static const TextStyle tagLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.tagText,
  );

  static const TextStyle chipLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );

  // ─── Goals ─────────────────────────────────────────────────────────────────

  static const TextStyle goalEmoji = TextStyle(
    fontSize: 36,
  );

  static const TextStyle goalLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  // ─── Buttons ───────────────────────────────────────────────────────────────

  static const TextStyle buttonPrimary = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.surface,
    letterSpacing: 0.2,
  );

  static const TextStyle buttonSecondary = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.2,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
    letterSpacing: 0.2,
  );

  static const TextStyle buttonTextDisabled = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.buttonDisabledText,
    letterSpacing: 0.2,
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