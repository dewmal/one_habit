import 'package:flutter/material.dart';

/// Font families: Poppins for Latin text, Noto Sans Sinhala as the fallback.
const sansFamily = 'Poppins';
const sinhalaFamily = 'NotoSansSinhala';
const sinhalaFallback = [sinhalaFamily];

/// Design tokens from the UI guide (pages 1 to 3).
/// No screen hard-codes a colour or size: use these instead.
class AppColors {
  static const bg = Color(0xFF1E2444);
  static const bgDeep = Color(0xFF171B36);
  static const surface = Color(0xFF2A3058);
  static const surfaceRaised = Color(0xFF343B6B);
  static const coral = Color(0xFFF2646C);
  static const coralBright = Color(0xFFFF7A7F);
  static const blush = Color(0xFFFBD9DF);
  static const blushDeep = Color(0xFFF6C3CC);
  static const labelOnBlush = Color(0xFF8A2C45);
  static const sunsetYellow = Color(0xFFFFC56B);
  static const sunsetOrange = Color(0xFFFF9A6B);
  static const sunsetPink = Color(0xFFF0607A);
  static const sunsetPurple = Color(0xFF6B4F9E);
  static const text = Color(0xFFFFFFFF);
  static const textMuted = Color(0xFFB9BEDD);
}

/// Only for the stage card, the step-up card header and the coach avatar.
/// Text on the gradient is navy ([AppColors.bg]).
const sunsetGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    AppColors.sunsetYellow,
    AppColors.sunsetOrange,
    AppColors.sunsetPink,
  ],
  stops: [0.0, 0.45, 1.0],
);

class AppRadii {
  static const smallButton = 12.0;
  static const iconButton = 14.0;
  static const row = 18.0;
  static const mainButton = 18.0;
  static const card = 20.0;
  static const quickReply = 22.0;
  static const stageCard = 24.0;
}

class AppSpacing {
  static const screen = 20.0;

  /// Welcome and Health check use wider padding.
  static const screenWide = 28.0;
  static const gap8 = 8.0;
  static const gap10 = 10.0;
  static const gap12 = 12.0;
  static const gap16 = 16.0;
  static const minTouch = 44.0;
  static const mainButtonHeight = 56.0;
}

class AppText {
  static const welcomeTitle = TextStyle(
    fontFamily: sansFamily,
    fontFamilyFallback: sinhalaFallback,
    fontSize: 34,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
  );
  static const screenTitle = TextStyle(
    fontFamily: sansFamily,
    fontFamilyFallback: sinhalaFallback,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
  );

  /// Settings and My data.
  static const screenTitleSmall = TextStyle(
    fontFamily: sansFamily,
    fontFamilyFallback: sinhalaFallback,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
  );
  static const healthQuestion = TextStyle(
    fontFamily: sansFamily,
    fontFamilyFallback: sinhalaFallback,
    fontSize: 26,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
  );
  static const cardTitle = TextStyle(
    fontFamily: sansFamily,
    fontFamilyFallback: sinhalaFallback,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
  );
  static const body = TextStyle(
    fontFamily: sansFamily,
    fontFamilyFallback: sinhalaFallback,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.text,
  );
  static const bodyMuted = TextStyle(
    fontFamily: sansFamily,
    fontFamilyFallback: sinhalaFallback,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textMuted,
  );
  static const smallLabel = TextStyle(
    fontFamily: sansFamily,
    fontFamilyFallback: sinhalaFallback,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.coralBright,
  );
  static const navLabel = TextStyle(
    fontSize: 11,
    fontFamily: sansFamily,
    fontFamilyFallback: sinhalaFallback,
  );
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    fontFamily: sansFamily,
    fontFamilyFallback: const [sinhalaFamily],
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.coral,
      onPrimary: AppColors.bg,
      secondary: AppColors.coralBright,
      surface: AppColors.surface,
      onSurface: AppColors.text,
    ),
    textTheme: const TextTheme(
      headlineLarge: AppText.welcomeTitle,
      headlineMedium: AppText.screenTitle,
      titleMedium: AppText.cardTitle,
      bodyMedium: AppText.body,
      labelSmall: AppText.smallLabel,
    ).apply(fontFamily: sansFamily, fontFamilyFallback: const [sinhalaFamily]),
  );
}
