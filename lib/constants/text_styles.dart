import 'package:flutter/material.dart';
import 'colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static const String _font = 'Satoshi';

  static const TextStyle timerHuge = TextStyle(
    fontFamily: _font,
    fontSize: 80,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryText,
    letterSpacing: -2,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle timerMedium = TextStyle(
    fontFamily: _font,
    fontSize: 56,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryText,
    letterSpacing: -1.5,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle heading = TextStyle(
    fontFamily: _font,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryText,
    letterSpacing: -0.5,
  );

  static const TextStyle subheading = TextStyle(
    fontFamily: _font,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.secondaryText,
    height: 1.6,
    letterSpacing: 0.1,
  );

  static const TextStyle body = TextStyle(
    fontFamily: _font,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.secondaryText,
    letterSpacing: 0.2,
  );

  static const TextStyle label = TextStyle(
    fontFamily: _font,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.secondaryText,
    letterSpacing: 1.2,
  );

  static const TextStyle microcopy = TextStyle(
    fontFamily: _font,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.secondaryText,
    letterSpacing: 0.3,
  );

  static const TextStyle buttonPrimary = TextStyle(
    fontFamily: _font,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryText,
    letterSpacing: 0.3,
  );

  static const TextStyle crossedIt = TextStyle(
    fontFamily: _font,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.secondaryText,
    letterSpacing: 0.3,
  );

  static const TextStyle statValue = TextStyle(
    fontFamily: _font,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryText,
    letterSpacing: -0.5,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle statLabel = TextStyle(
    fontFamily: _font,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.secondaryText,
    letterSpacing: 1.4,
  );
}
