import 'package:flutter/material.dart';

/// Apple Design System — 基于 DESIGN.md 规范
/// 颜色、字体、间距、圆角统一管理
class AppTheme {
  AppTheme._();

  // ============ Colors ============
  static const Color primary = Color(0xFF0066cc); // Action Blue
  static const Color primaryFocus = Color(0xFF0071e3); // Focus Blue
  static const Color primaryOnDark = Color(0xFF2997ff); // Sky Link Blue

  static const Color ink = Color(0xFF1d1d1f); // Near-Black Ink
  static const Color textColor = Color(
    0xFF1d1d1f,
  ); // 正文色（避免与 TextStyle body 冲突）
  static const Color bodyOnDark = Color(0xFFFFFFFF);
  static const Color bodyMuted = Color(0xFFcccccc);
  static const Color inkMuted80 = Color(0xFF333333);
  static const Color inkMuted48 = Color(0xFF7a7a7a);

  static const Color dividerSoft = Color(0xFFf0f0f0);
  static const Color hairline = Color(0xFFe0e0e0);

  static const Color canvas = Color(0xFFFFFFFF);
  static const Color canvasParchment = Color(0xFFf5f5f7);
  static const Color surfacePearl = Color(0xFFfafafc);

  static const Color surfaceTile1 = Color(0xFF272729);
  static const Color surfaceTile2 = Color(0xFF2a2a2c);
  static const Color surfaceTile3 = Color(0xFF252527);
  static const Color surfaceBlack = Color(0xFF000000);
  static const Color surfaceChipTranslucent = Color(0xFFd2d2d7);

  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onDark = Color(0xFFFFFFFF);

  // ============ Typography ============
  static const String fontFamilyDisplay =
      'SF Pro Display, system-ui, -apple-system, sans-serif';
  static const String fontFamilyBody =
      'SF Pro Text, system-ui, -apple-system, sans-serif';

  // Display sizes (SF Pro Display)
  static const TextStyle heroDisplay = TextStyle(
    fontFamily: fontFamilyDisplay,
    fontSize: 56,
    fontWeight: FontWeight.w600,
    height: 1.07,
    letterSpacing: -0.28,
    color: ink,
  );

  static const TextStyle displayLg = TextStyle(
    fontFamily: fontFamilyDisplay,
    fontSize: 40,
    fontWeight: FontWeight.w600,
    height: 1.10,
    letterSpacing: 0,
    color: ink,
  );

  static const TextStyle displayMd = TextStyle(
    fontFamily: fontFamilyBody,
    fontSize: 34,
    fontWeight: FontWeight.w600,
    height: 1.47,
    letterSpacing: -0.374,
    color: ink,
  );

  static const TextStyle lead = TextStyle(
    fontFamily: fontFamilyDisplay,
    fontSize: 28,
    fontWeight: FontWeight.w400,
    height: 1.14,
    letterSpacing: 0.196,
    color: ink,
  );

  static const TextStyle tagline = TextStyle(
    fontFamily: fontFamilyDisplay,
    fontSize: 21,
    fontWeight: FontWeight.w600,
    height: 1.19,
    letterSpacing: 0.231,
    color: ink,
  );

  // Body sizes (SF Pro Text)
  static const TextStyle bodyStrong = TextStyle(
    fontFamily: fontFamilyBody,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.24,
    letterSpacing: -0.374,
    color: ink,
  );

  static const TextStyle body = TextStyle(
    fontFamily: fontFamilyBody,
    fontSize: 17,
    fontWeight: FontWeight.w400,
    height: 1.47,
    letterSpacing: -0.374,
    color: ink,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamilyBody,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.43,
    letterSpacing: -0.224,
    color: inkMuted48,
  );

  static const TextStyle captionStrong = TextStyle(
    fontFamily: fontFamilyBody,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.29,
    letterSpacing: -0.224,
    color: ink,
  );

  static const TextStyle buttonLarge = TextStyle(
    fontFamily: fontFamilyBody,
    fontSize: 18,
    fontWeight: FontWeight.w300,
    height: 1.0,
    color: onPrimary,
  );

  static const TextStyle buttonUtility = TextStyle(
    fontFamily: fontFamilyBody,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.29,
    letterSpacing: -0.224,
    color: primary,
  );

  static const TextStyle finePrint = TextStyle(
    fontFamily: fontFamilyBody,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.0,
    letterSpacing: -0.12,
    color: inkMuted48,
  );

  static const TextStyle navLink = TextStyle(
    fontFamily: fontFamilyBody,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.0,
    letterSpacing: -0.12,
    color: onDark,
  );

  // ============ Rounded Corners ============
  static const double radiusNone = 0;
  static const double radiusXs = 5;
  static const double radiusSm = 8;
  static const double radiusMd = 11;
  static const double radiusLg = 18;
  static const double radiusPill = 9999;

  // ============ Spacing ============
  static const double spaceXxs = 4;
  static const double spaceXs = 8;
  static const double spaceSm = 12;
  static const double spaceMd = 17;
  static const double spaceLg = 24;
  static const double spaceXl = 32;
  static const double spaceXxl = 48;

  // ============ Build ThemeData ============
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primary,
        primaryContainer: Color(0xFFe8f2ff),
        secondary: primary,
        surface: canvasParchment,
        onPrimary: onPrimary,
        onSurface: ink,
        error: Color(0xFFff3b30),
      ),
      scaffoldBackgroundColor: canvasParchment,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: canvas,
        foregroundColor: ink,
        titleTextStyle: TextStyle(
          fontFamily: fontFamilyBody,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.374,
          color: ink,
        ),
        iconTheme: IconThemeData(color: ink),
      ),
      textTheme: TextTheme(
        displayLarge: heroDisplay,
        displayMedium: displayLg,
        displaySmall: displayMd,
        headlineLarge: lead,
        headlineMedium: tagline,
        titleLarge: bodyStrong,
        titleMedium: body,
        bodyLarge: body,
        bodyMedium: body,
        labelLarge: buttonLarge,
        labelSmall: buttonUtility,
        bodySmall: caption,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: canvas,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusPill),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusPill),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusPill),
          borderSide: const BorderSide(color: primary, width: 0.5),
        ),
        hintStyle: caption.copyWith(color: inkMuted48),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusPill),
          ),
          textStyle: buttonLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide.none,
          backgroundColor: surfacePearl,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusPill),
          ),
          textStyle: body,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: body,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: canvas,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: hairline),
        ),
      ),
      dividerColor: dividerSoft,
      dividerTheme: DividerThemeData(color: dividerSoft, thickness: 0.5),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primary,
        unselectedItemColor: inkMuted48,
        elevation: 0,
        selectedLabelStyle: captionStrong,
        unselectedLabelStyle: caption,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 2,
        shape: const CircleBorder(),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        backgroundColor: surfaceTile1,
        contentTextStyle: const TextStyle(
          fontFamily: fontFamilyBody,
          fontSize: 14,
          color: onDark,
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        backgroundColor: canvas,
        titleTextStyle: displayMd.copyWith(fontSize: 20),
        contentTextStyle: body,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: canvasParchment,
      ),
    );
  }

  /// 深色模式（用于深色 tile 区域）
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryOnDark,
        surface: surfaceTile1,
        onSurface: onDark,
        onPrimary: onPrimary,
      ),
      scaffoldBackgroundColor: surfaceTile1,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: surfaceBlack,
        foregroundColor: onDark,
      ),
      textTheme: _darkTextTheme,
    );
  }

  static TextTheme get _darkTextTheme => TextTheme(
    displayLarge: heroDisplay.copyWith(color: onDark),
    displayMedium: displayLg.copyWith(color: onDark),
    displaySmall: displayMd.copyWith(color: onDark),
    headlineLarge: lead.copyWith(color: onDark),
    headlineMedium: tagline.copyWith(color: onDark),
    titleLarge: bodyStrong.copyWith(color: onDark),
    titleMedium: body.copyWith(color: onDark),
    bodyLarge: body.copyWith(color: bodyMuted),
    bodySmall: caption.copyWith(color: bodyMuted),
  );
}
