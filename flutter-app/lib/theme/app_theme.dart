import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/club.dart';
import '../models/event.dart';

/// Energetic Palestinian sunbird palette — male iridescent teal/blue,
/// female olive/gold/orange — bright and campus-forward, not sleepy dawn.
class AppPalette {
  // Male sunbird: metallic teal sky.
  static const Color nightTop = Color(0xFF0A4F5C);
  static const Color nightMid = Color(0xFF073842);
  static const Color nightDeep = Color(0xFF042028);

  // Daylight: bright sky + golden chest.
  static const Color dawnTop = Color(0xFFE8F8FC);
  static const Color dawnMid = Color(0xFF5EC4D4);
  static const Color dawnLow = Color(0xFF0E7C8C);

  // Shared tones.
  static const Color ink = Color(0xFF0A2E36);
  static const Color cream = Color(0xFFFFF4E6);
  static const Color sunbirdGold = Color(0xFFE8920F);
  static const Color sunbirdOlive = Color(0xFF6B8E23);
}

class AppColors {
  // Sunbird brand — teal primary, gold accent, olive serve tone.
  static const Color primary = Color(0xFF0E9CAD);
  static const Color primaryDark = Color(0xFF067888);
  static const Color accent = Color(0xFFE8920F);
  static const Color magenta = Color(0xFF2BB8C8);
  static const Color success = Color(0xFF5BA316);
  static const Color warning = Color(0xFFF5A623);
  static const Color danger = Color(0xFFE04545);

  // Neutral tokens — reassigned by applyMode()
  static Color background = _darkBackground;
  static Color surface = _darkSurface;
  static Color surfaceMuted = _darkSurfaceMuted;
  static Color accentLight = _darkAccentLight;
  static Color textPrimary = _darkTextPrimary;
  static Color textSecondary = _darkTextSecondary;
  static Color textMuted = _darkTextMuted;
  static Color divider = _darkDivider;

  // Light mode — bright sunbird sky with gold highlights.
  static const Color _lightBackground = Color(0xFFF0FAFC);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightSurfaceMuted = Color(0xFFD8F2F6);
  static const Color _lightAccentLight = Color(0xFFB8EAF0);
  static const Color _lightTextPrimary = Color(0xFF0A2E36);
  static const Color _lightTextSecondary = Color(0xFF2E5A62);
  static const Color _lightTextMuted = Color(0xFF6A9098);
  static const Color _lightDivider = Color(0xFFB8DDE4);

  // Dark mode — deep teal night (male sunbird back).
  static const Color _darkBackground = Color(0xFF042028);
  static const Color _darkSurface = Color(0xFF073842);
  static const Color _darkSurfaceMuted = Color(0xFF0A4F5C);
  static const Color _darkAccentLight = Color(0xFF0E7C8C);
  static const Color _darkTextPrimary = Color(0xFFE8F8FC);
  static const Color _darkTextSecondary = Color(0xFF9AD4DE);
  static const Color _darkTextMuted = Color(0xFF6A9098);
  static const Color _darkDivider = Color(0xFF0E5A66);

  static void applyMode(bool dark) {
    if (dark) {
      background = _darkBackground;
      surface = _darkSurface;
      surfaceMuted = _darkSurfaceMuted;
      accentLight = _darkAccentLight;
      textPrimary = _darkTextPrimary;
      textSecondary = _darkTextSecondary;
      textMuted = _darkTextMuted;
      divider = _darkDivider;
    } else {
      background = _lightBackground;
      surface = _lightSurface;
      surfaceMuted = _lightSurfaceMuted;
      accentLight = _lightAccentLight;
      textPrimary = _lightTextPrimary;
      textSecondary = _lightTextSecondary;
      textMuted = _lightTextMuted;
      divider = _lightDivider;
    }
  }
}

class AppAccents {
  static const List<Color> palette = [
    Color(0xFF0E9CAD),
    Color(0xFF2BB8C8),
    Color(0xFFE8920F),
    Color(0xFF6B8E23),
    AppColors.warning,
  ];

  static Color at(int i) => palette[i % palette.length];
}

class AppRadii {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double pill = 999;
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

ThemeData buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final base = isDark
      ? ThemeData.dark(useMaterial3: true)
      : ThemeData.light(useMaterial3: true);

  final textPrimary =
      isDark ? AppColors._darkTextPrimary : AppColors._lightTextPrimary;
  final textSecondary =
      isDark ? AppColors._darkTextSecondary : AppColors._lightTextSecondary;
  final textMuted =
      isDark ? AppColors._darkTextMuted : AppColors._lightTextMuted;
  final background =
      isDark ? AppColors._darkBackground : AppColors._lightBackground;
  final surface = isDark ? AppColors._darkSurface : AppColors._lightSurface;
  final surfaceMuted =
      isDark ? AppColors._darkSurfaceMuted : AppColors._lightSurfaceMuted;
  final divider = isDark ? AppColors._darkDivider : AppColors._lightDivider;

  final interText = GoogleFonts.interTextTheme(base.textTheme).apply(
    bodyColor: textPrimary,
    displayColor: textPrimary,
  );

  TextStyle? fraunces(TextStyle? base, double size, FontWeight weight) =>
      GoogleFonts.fraunces(
        textStyle: base,
        fontSize: size,
        fontWeight: weight,
        color: textPrimary,
      );

  final textTheme = interText.copyWith(
    displayLarge: fraunces(interText.displayLarge, 40, FontWeight.w700),
    displayMedium: fraunces(interText.displayMedium, 32, FontWeight.w700),
    displaySmall: fraunces(interText.displaySmall, 28, FontWeight.w600),
    headlineLarge: fraunces(interText.headlineLarge, 30, FontWeight.w700),
    headlineMedium: fraunces(interText.headlineMedium, 26, FontWeight.w600),
    headlineSmall: fraunces(interText.headlineSmall, 22, FontWeight.w600),
    titleLarge: fraunces(interText.titleLarge, 22, FontWeight.w700),
    titleMedium: fraunces(interText.titleMedium, 18, FontWeight.w600),
  );

  final colorScheme = isDark
      ? ColorScheme.dark(
          primary: AppColors.primary,
          onPrimary: Colors.white,
          secondary: AppColors.accent,
          onSecondary: Colors.white,
          surface: surface,
          onSurface: textPrimary,
          error: AppColors.danger,
          onError: Colors.white,
        )
      : ColorScheme.light(
          primary: AppColors.primary,
          onPrimary: Colors.white,
          secondary: AppColors.accent,
          onSecondary: Colors.white,
          surface: surface,
          onSurface: textPrimary,
          error: AppColors.danger,
          onError: Colors.white,
        );

  return base.copyWith(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: background,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      iconTheme: IconThemeData(color: textPrimary),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 17),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        textStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
          letterSpacing: 1.2,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 1.4),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 17),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        textStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
          letterSpacing: 1.2,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.primary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: BorderSide(color: divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: BorderSide(color: divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      ),
      hintStyle: textTheme.bodyMedium?.copyWith(color: textMuted),
      labelStyle: textTheme.bodyMedium?.copyWith(color: textSecondary),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surfaceMuted,
      selectedColor: AppColors.primary,
      labelStyle: textTheme.bodyMedium!,
      secondaryLabelStyle: textTheme.bodyMedium!.copyWith(color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      side: BorderSide.none,
    ),
    dividerTheme: DividerThemeData(
      color: divider,
      thickness: 1,
      space: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.primary,
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: textMuted,
      selectedLabelStyle: textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: textTheme.labelSmall,
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
      elevation: 8,
    ),
  );
}

ThemeData buildAppTheme() => buildTheme(Brightness.light);

class AppGradients {
  static const LinearGradient campusPage = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppPalette.dawnTop, AppColors._lightBackground],
  );

  static const BoxDecoration pageBackground =
      BoxDecoration(gradient: campusPage);

  static const LinearGradient header = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2BB8C8), Color(0xFF067888)],
  );

  static LinearGradient get soft => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.surfaceMuted, AppColors.background],
      );

  static LinearGradient category(EventCategory c) {
    final pair = AppCategoryStyle.gradientColors(c);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: pair,
    );
  }

  static LinearGradient clubCategory(ClubCategory c) {
    final pair = ClubCategoryStyle.gradientColors(c);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: pair,
    );
  }
}

class AppCategoryStyle {
  static Color accent(EventCategory c) {
    switch (c) {
      case EventCategory.learn:
        return const Color(0xFF0E9CAD);
      case EventCategory.serve:
        return const Color(0xFF6B8E23);
      case EventCategory.connect:
        return const Color(0xFFE8920F);
      case EventCategory.explore:
        return const Color(0xFF2BB8C8);
    }
  }

  static List<Color> gradientColors(EventCategory c) {
    switch (c) {
      case EventCategory.learn:
        return const [Color(0xFF5EC4D4), Color(0xFF067888)];
      case EventCategory.serve:
        return const [Color(0xFF9BCB4A), Color(0xFF6B8E23)];
      case EventCategory.connect:
        return const [Color(0xFFF5C04A), Color(0xFFE8920F)];
      case EventCategory.explore:
        return const [Color(0xFF7AD8E8), Color(0xFF0E9CAD)];
    }
  }

  static Color softTint(EventCategory c) =>
      Color.lerp(accent(c), Colors.white, 0.78)!;
}

class ClubCategoryStyle {
  static Color accent(ClubCategory c) {
    switch (c) {
      case ClubCategory.academic:
        return const Color(0xFF2BB8C8);
      case ClubCategory.cultural:
        return const Color(0xFFE8920F);
      case ClubCategory.wellness:
        return const Color(0xFF0E9CAD);
      case ClubCategory.arts:
        return const Color(0xFFE8920F);
      case ClubCategory.tech:
        return const Color(0xFF067888);
    }
  }

  static List<Color> gradientColors(ClubCategory c) {
    switch (c) {
      case ClubCategory.academic:
        return const [Color(0xFF7AD8E8), Color(0xFF2BB8C8)];
      case ClubCategory.cultural:
        return const [Color(0xFFF5C04A), Color(0xFFE8920F)];
      case ClubCategory.wellness:
        return const [Color(0xFF5EC4D4), Color(0xFF0E9CAD)];
      case ClubCategory.arts:
        return const [Color(0xFFF5C04A), Color(0xFFE8920F)];
      case ClubCategory.tech:
        return const [Color(0xFF5EC4D4), Color(0xFF067888)];
    }
  }

  static Color softTint(ClubCategory c) =>
      Color.lerp(accent(c), Colors.white, 0.78)!;
}

List<BoxShadow> glow(
  Color color, {
  double alpha = 0.45,
  double blurRadius = 24,
  double spreadRadius = 0,
  Offset offset = const Offset(0, 8),
}) {
  return [
    BoxShadow(
      color: color.withValues(alpha: alpha),
      blurRadius: blurRadius,
      spreadRadius: spreadRadius,
      offset: offset,
    ),
  ];
}

TextStyle playfulDisplay({
  double size = 34,
  FontWeight weight = FontWeight.w800,
  Color? color,
  double? letterSpacing,
  double? height,
}) {
  return GoogleFonts.baloo2(
    fontSize: size,
    fontWeight: weight,
    color: color ?? AppColors.textPrimary,
    letterSpacing: letterSpacing,
    height: height,
  );
}

BoxDecoration cardDecoration({Color? color, double radius = AppRadii.lg}) {
  return BoxDecoration(
    color: color ?? AppColors.surface,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: [
      BoxShadow(
        color: AppColors.primary.withValues(alpha: 0.08),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ],
  );
}
