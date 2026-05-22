import 'package:flutter/material.dart';
import 'package:ctg_app/core/theme/app_colors.dart';

abstract final class AppTextStyles {
  // Space Grotesk — headlines
  static const displayLg = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    height: 1.2,
  );

  static const displayMd = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    height: 1.25,
  );

  static const headingLg = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
    height: 1.3,
  );

  static const headingMd = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
    height: 1.35,
  );

  static const headingSm = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
    height: 1.4,
  );

  // Inter — body
  static const bodyLg = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.ink,
    height: 1.5,
  );

  static const bodyMd = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.ink,
    height: 1.5,
  );

  static const bodySm = TextStyle(
    fontFamily: 'Inter',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.ink2,
    height: 1.45,
  );

  static const labelMd = TextStyle(
    fontFamily: 'Inter',
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.ink,
    height: 1.4,
  );

  static const labelSm = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.muted,
    height: 1.4,
  );

  static const caption = TextStyle(
    fontFamily: 'Inter',
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.muted,
    height: 1.4,
  );

  // JetBrains Mono — technical labels
  static const monoMd = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.muted,
    height: 1.4,
  );

  static const monoSm = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.muted,
    letterSpacing: 0.5,
  );

  static const monoLg = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.ink,
    height: 1.3,
  );
}
