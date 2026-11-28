import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/flutter_flow/flutter_flow_theme.dart';

/// WCAG 2.1 AA compliant brand color tokens for ONEWAY — Egypt Without Barriers.
///
/// Primary teal on light surfaces is darkened to [primaryLightMode] (`#0E7C77`),
/// delivering ~5.04:1 contrast against white (`#FFFFFF`) and white text on primary,
/// while preserving [primaryAccentOnDark] (`#16A6A0`) for dark navy headers.
class OnewayPalette {
  OnewayPalette._();

  // Light-mode brand tokens (WCAG 2.1 AA verified >= 4.5:1 on white)
  static const Color primaryLightMode = Color(0xFF0E7C77);
  static const Color primaryAccentOnDark = Color(0xFF16A6A0);
  static const Color primaryDarker = Color(0xFF0A5C58);
  static const Color secondaryLightMode = Color(0xFF83C5BE);
  static const Color tertiaryAmber = Color(0xFFFFA62B);

  // Dark-mode brand tokens
  static const Color primaryDarkMode = Color(0xFF4FD1C5);
  static const Color onPrimaryDarkMode = Color(0xFF002023);

  // Deep Navy Dusk structural palette
  static const Color navy = Color(0xFF142B45);
  static const Color navyLight = Color(0xFF1E3A5C);
  static const Color navyDark = Color(0xFF0C1B2E);
  static const Color gold = Color(0xFFFFC24D);

  // Semantic text & surface tokens (Light)
  static const Color primaryTextLight = Color(0xFF172B3A);
  static const Color secondaryTextLight = Color(0xFF556575);
  static const Color backgroundLight = Color(0xFFF6F8FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);

  // Wheelmap-inspired traffic-light accessibility indicators
  static const Color accessFull = Color(0xFF15803D); // >= 4.5:1 with white
  static const Color accessPartial = Color(0xFFB45309); // >= 4.5:1 with white
  static const Color accessLimited = Color(0xFFB91C1C); // >= 4.5:1 with white
}

/// Design spacing & radius tokens independent of FlutterFlow.
class OnewaySpacing {
  OnewaySpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class OnewayRadius {
  OnewayRadius._();
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 28;
  static const double pill = 999;
}

/// Builds the unified Material 3 [ThemeData] for ONEWAY with:
/// - Cairo typography for crisp Arabic & English rendering
/// - WCAG 2.1 AA contrast tokens & optional High Contrast borders/surfaces
/// - Minimum 48x48dp interactive touch targets
/// - Visible keyboard/web focus rings (`focusColor`, `FocusState` outlines)
/// - Reduced-motion page transitions when [disableAnimations] is true
ThemeData buildOnewayTheme(
  FlutterFlowTheme brand,
  Brightness brightness, {
  bool highContrast = false,
  bool disableAnimations = false,
}) {
  final base = ThemeData(brightness: brightness, useMaterial3: true);
  final cairoText = GoogleFonts.cairoTextTheme(base.textTheme);
  final isDark = brightness == Brightness.dark;
  final borderColor = highContrast
      ? (isDark ? Colors.white : Colors.black)
      : brand.outline;
  final borderWidth = highContrast ? 2.0 : 1.0;
  final focusOutlineColor =
      highContrast ? (isDark ? OnewayPalette.gold : Colors.black) : brand.primary;

  WidgetStateProperty<BorderSide?> focusableBorder(BorderSide normal) {
    return WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.focused)) {
        return BorderSide(color: focusOutlineColor, width: 2.5);
      }
      return normal;
    });
  }

  return ThemeData(
    brightness: brightness,
    useMaterial3: true,
    primaryColor: brand.primary,
    focusColor: focusOutlineColor.withValues(alpha: 0.16),
    scaffoldBackgroundColor: highContrast
        ? (isDark ? Colors.black : Colors.white)
        : brand.background,
    fontFamily: GoogleFonts.cairo().fontFamily,
    textTheme: cairoText,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    visualDensity: VisualDensity.standard,
    pageTransitionsTheme: disableAnimations
        ? const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: _NoAnimationPageTransitionsBuilder(),
              TargetPlatform.iOS: _NoAnimationPageTransitionsBuilder(),
              TargetPlatform.windows: _NoAnimationPageTransitionsBuilder(),
              TargetPlatform.macOS: _NoAnimationPageTransitionsBuilder(),
              TargetPlatform.linux: _NoAnimationPageTransitionsBuilder(),
            },
          )
        : const PageTransitionsTheme(),
    colorScheme: ColorScheme.fromSeed(
      seedColor: brand.primary,
      brightness: brightness,
      primary: brand.primary,
      onPrimary: brand.onPrimary,
      secondary: brand.secondary,
      tertiary: brand.tertiary,
      error: brand.error,
      surface: brand.surface,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: brand.primary,
      foregroundColor: brand.onPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.cairo(
        color: brand.onPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: brand.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor, width: borderWidth),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: brand.primary,
        foregroundColor: brand.onPrimary,
        minimumSize: const Size(48, 52),
        elevation: 0,
        textStyle: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ).copyWith(
        side: focusableBorder(
          highContrast
              ? BorderSide(color: isDark ? Colors.white : Colors.black, width: 1.5)
              : BorderSide.none,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: brand.primary,
        foregroundColor: brand.onPrimary,
        minimumSize: const Size(48, 48),
        textStyle: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ).copyWith(
        side: focusableBorder(BorderSide.none),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: brand.primary,
        minimumSize: const Size(48, 52),
        side: BorderSide(color: brand.primary, width: 1.5),
        textStyle: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ).copyWith(
        side: focusableBorder(BorderSide(color: brand.primary, width: 1.5)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: brand.primary,
        minimumSize: const Size(48, 48),
        textStyle: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
      ),
    ),
    chipTheme: ChipThemeData(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      labelStyle: GoogleFonts.cairo(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: brand.primaryText,
      ),
      side: BorderSide(color: borderColor, width: borderWidth),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: brand.surfaceVariant,
      hintStyle: GoogleFonts.cairo(color: brand.hintText, fontSize: 14),
      labelStyle: GoogleFonts.cairo(color: brand.secondaryText, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor, width: borderWidth),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: focusOutlineColor, width: 2.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: brand.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: brand.error, width: 2),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: brand.onBackground,
      contentTextStyle: GoogleFonts.cairo(color: brand.background, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: brand.surface,
      titleTextStyle: GoogleFonts.cairo(
        color: brand.primaryText,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: brand.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: brand.primary,
      unselectedLabelColor: brand.secondaryText,
      indicatorColor: brand.primary,
      labelStyle: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w700),
      unselectedLabelStyle:
          GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600),
    ),
    dividerTheme: DividerThemeData(color: brand.divider, thickness: 1),
    iconTheme: IconThemeData(color: brand.onSurfaceVariant),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: brand.primary,
      foregroundColor: brand.onPrimary,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: brand.primary,
    ),
  );
}

class _NoAnimationPageTransitionsBuilder extends PageTransitionsBuilder {
  const _NoAnimationPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
