// ignore_for_file: overridden_fields, annotate_overrides

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/core/theme/oneway_theme.dart';

const kThemeModeKey = '__theme_mode__';

SharedPreferences? _prefs;

abstract class FlutterFlowTheme {
  static Future initialize() async =>
      _prefs = await SharedPreferences.getInstance();

  static ThemeMode get themeMode {
    final darkMode = _prefs?.getBool(kThemeModeKey);
    return darkMode == null
        ? ThemeMode.system
        : darkMode
            ? ThemeMode.dark
            : ThemeMode.light;
  }

  static void saveThemeMode(ThemeMode mode) => mode == ThemeMode.system
      ? _prefs?.remove(kThemeModeKey)
      : _prefs?.setBool(kThemeModeKey, mode == ThemeMode.dark);

  static FlutterFlowTheme of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? DarkModeTheme()
        : LightModeTheme();
  }

  @Deprecated('Use primary instead')
  Color get primaryColor => primary;
  @Deprecated('Use secondary instead')
  Color get secondaryColor => secondary;
  @Deprecated('Use tertiary instead')
  Color get tertiaryColor => tertiary;

  // Brightness (for backward compatibility)
  @Deprecated('Use Theme.of(context).brightness instead')
  Brightness get brightness => themeMode == ThemeMode.dark
      ? Brightness.dark
      : Brightness.light;

  // Core Brand Colors
  late Color primary;
  late Color primaryLight;
  late Color primaryDark;
  late Color secondary;
  late Color secondaryLight;
  late Color secondaryDark;
  late Color tertiary;
  late Color tertiaryLight;
  late Color tertiaryDark;

  // ONEWAY redesign - deep navy dusk palette
  late Color navy;
  late Color navyLight;
  late Color navyDark;
  late Color gold;

  // Surface Colors
  late Color surface;
  late Color surfaceVariant;
  late Color surfaceContainer;
  late Color surfaceContainerHigh;
  late Color surfaceContainerHighest;
  late Color background;
  late Color onBackground;

  // Text Colors
  late Color onPrimary;
  late Color onPrimaryContainer;
  late Color onSecondary;
  late Color onSecondaryContainer;
  late Color onSurface;
  late Color onSurfaceVariant;
  late Color primaryText;
  late Color secondaryText;
  late Color tertiaryText;
  late Color hintText;

  // State Colors
  late Color success;
  late Color successContainer;
  late Color onSuccess;
  late Color onSuccessContainer;
  late Color warning;
  late Color warningContainer;
  late Color onWarning;
  late Color onWarningContainer;
  late Color error;
  late Color errorContainer;
  late Color onError;
  late Color onErrorContainer;
  late Color info;
  late Color infoContainer;
  late Color onInfo;
  late Color onInfoContainer;

  // Outline & Divider
  late Color outline;
  late Color outlineVariant;
  late Color divider;

  // Utility
  late Color transparent;
  late Color shadow;
  late Color scrim;

  // Opacity variants
  late Color primary8;
  late Color primary12;
  late Color primary16;
  late Color primary24;
  late Color secondary8;
  late Color secondary12;
  late Color secondary16;
  late Color onSurface8;
  late Color onSurface12;
  late Color onSurface16;
  late Color onSurface24;

  FFDesignTokens get designToken => FFDesignTokens(this);

  // Typography
  @Deprecated('Use displaySmallFamily instead')
  String get title1Family => displaySmallFamily;
  @Deprecated('Use displaySmall instead')
  TextStyle get title1 => typography.displaySmall;
  @Deprecated('Use headlineMediumFamily instead')
  String get title2Family => typography.headlineMediumFamily;
  @Deprecated('Use headlineMedium instead')
  TextStyle get title2 => typography.headlineMedium;
  @Deprecated('Use headlineSmallFamily instead')
  String get title3Family => typography.headlineSmallFamily;
  @Deprecated('Use headlineSmall instead')
  TextStyle get title3 => typography.headlineSmall;
  @Deprecated('Use titleMediumFamily instead')
  String get subtitle1Family => typography.titleMediumFamily;
  @Deprecated('Use titleMedium instead')
  TextStyle get subtitle1 => typography.titleMedium;
  @Deprecated('Use titleSmallFamily instead')
  String get subtitle2Family => typography.titleSmallFamily;
  @Deprecated('Use titleSmall instead')
  TextStyle get subtitle2 => typography.titleSmall;
  @Deprecated('Use bodyMediumFamily instead')
  String get bodyText1Family => typography.bodyMediumFamily;
  @Deprecated('Use bodyMedium instead')
  TextStyle get bodyText1 => typography.bodyMedium;
  @Deprecated('Use bodySmallFamily instead')
  String get bodyText2Family => typography.bodySmallFamily;
  @Deprecated('Use bodySmall instead')
  TextStyle get bodyText2 => typography.bodySmall;

  String get displayLargeFamily => typography.displayLargeFamily;
  bool get displayLargeIsCustom => typography.displayLargeIsCustom;
  TextStyle get displayLarge => typography.displayLarge;
  String get displayMediumFamily => typography.displayMediumFamily;
  bool get displayMediumIsCustom => typography.displayMediumIsCustom;
  TextStyle get displayMedium => typography.displayMedium;
  String get displaySmallFamily => typography.displaySmallFamily;
  bool get displaySmallIsCustom => typography.displaySmallIsCustom;
  TextStyle get displaySmall => typography.displaySmall;
  String get headlineLargeFamily => typography.headlineLargeFamily;
  bool get headlineLargeIsCustom => typography.headlineLargeIsCustom;
  TextStyle get headlineLarge => typography.headlineLarge;
  String get headlineMediumFamily => typography.headlineMediumFamily;
  bool get headlineMediumIsCustom => typography.headlineMediumIsCustom;
  TextStyle get headlineMedium => typography.headlineMedium;
  String get headlineSmallFamily => typography.headlineSmallFamily;
  bool get headlineSmallIsCustom => typography.headlineSmallIsCustom;
  TextStyle get headlineSmall => typography.headlineSmall;
  String get titleLargeFamily => typography.titleLargeFamily;
  bool get titleLargeIsCustom => typography.titleLargeIsCustom;
  TextStyle get titleLarge => typography.titleLarge;
  String get titleMediumFamily => typography.titleMediumFamily;
  bool get titleMediumIsCustom => typography.titleMediumIsCustom;
  TextStyle get titleMedium => typography.titleMedium;
  String get titleSmallFamily => typography.titleSmallFamily;
  bool get titleSmallIsCustom => typography.titleSmallIsCustom;
  TextStyle get titleSmall => typography.titleSmall;
  String get labelLargeFamily => typography.labelLargeFamily;
  bool get labelLargeIsCustom => typography.labelLargeIsCustom;
  TextStyle get labelLarge => typography.labelLarge;
  String get labelMediumFamily => typography.labelMediumFamily;
  bool get labelMediumIsCustom => typography.labelMediumIsCustom;
  TextStyle get labelMedium => typography.labelMedium;
  String get labelSmallFamily => typography.labelSmallFamily;
  bool get labelSmallIsCustom => typography.labelSmallIsCustom;
  TextStyle get labelSmall => typography.labelSmall;
  String get bodyLargeFamily => typography.bodyLargeFamily;
  bool get bodyLargeIsCustom => typography.bodyLargeIsCustom;
  TextStyle get bodyLarge => typography.bodyLarge;
  String get bodyMediumFamily => typography.bodyMediumFamily;
  bool get bodyMediumIsCustom => typography.bodyMediumIsCustom;
  TextStyle get bodyMedium => typography.bodyMedium;
  String get bodySmallFamily => typography.bodySmallFamily;
  bool get bodySmallIsCustom => typography.bodySmallIsCustom;
  TextStyle get bodySmall => typography.bodySmall;

  Typography get typography => ThemeTypography(this);
}

class LightModeTheme extends FlutterFlowTheme {
  @Deprecated('Use primary instead')
  Color get primaryColor => primary;
  @Deprecated('Use secondary instead')
  Color get secondaryColor => secondary;
  @Deprecated('Use tertiary instead')
  Color get tertiaryColor => tertiary;

  // Core Brand Colors - WCAG 2.1 AA compliant Teal/Blue palette (>= 5.0:1 on white)
  late Color primary = OnewayPalette.primaryLightMode;       // #0E7C77 (5.04:1 on white)
  late Color primaryLight = OnewayPalette.primaryAccentOnDark; // #16A6A0 (for dark surfaces)
  late Color primaryDark = OnewayPalette.primaryDarker;      // #0A5C58
  late Color secondary = OnewayPalette.secondaryLightMode;   // Soft mint
  late Color secondaryLight = const Color(0xFFEDF6F9);       // Very light mint
  late Color secondaryDark = const Color(0xFF52A39B);        // Medium teal
  late Color tertiary = OnewayPalette.tertiaryAmber;         // Warm amber
  late Color tertiaryLight = const Color(0xFFFFD98A);        // Light amber
  late Color tertiaryDark = const Color(0xFFE67E22);         // Dark amber

  // ONEWAY design-system spec palette
  late Color navy = OnewayPalette.navy;                      // Spec primary navy
  late Color navyLight = OnewayPalette.navyLight;            // Lighter navy (cards on navy)
  late Color navyDark = OnewayPalette.navyDark;              // Darkest navy (vignettes)
  late Color gold = OnewayPalette.gold;                      // Sun gold accent

  // Surface Colors
  late Color surface = OnewayPalette.surfaceLight;
  late Color surfaceVariant = const Color(0xFFF0F4F5);
  late Color surfaceContainer = const Color(0xFFE8EDEE);
  late Color surfaceContainerHigh = const Color(0xFFDEE3E4);
  late Color surfaceContainerHighest = const Color(0xFFD4D9DA);
  late Color background = OnewayPalette.backgroundLight;
  late Color onBackground = OnewayPalette.primaryTextLight;

  // Text Colors
  late Color onPrimary = const Color(0xFFFFFFFF);
  late Color onPrimaryContainer = const Color(0xFF002023);
  late Color onSecondary = const Color(0xFF002023);
  late Color onSecondaryContainer = const Color(0xFF002023);
  late Color onSurface = const Color(0xFF1A1C1E);
  late Color onSurfaceVariant = const Color(0xFF424748);
  late Color primaryText = OnewayPalette.primaryTextLight;
  late Color secondaryText = OnewayPalette.secondaryTextLight; // #556575 (>= 5.6:1 on light bg)
  late Color tertiaryText = const Color(0xFF5A5E60);
  late Color hintText = const Color(0xFF6B7073);

  // State Colors
  late Color success = OnewayPalette.accessFull;
  late Color successContainer = const Color(0xFFD1E7DD);
  late Color onSuccess = const Color(0xFFFFFFFF);
  late Color onSuccessContainer = const Color(0xFF00230B);
  late Color warning = OnewayPalette.accessPartial;
  late Color warningContainer = const Color(0xFFFFF3D1);
  late Color onWarning = const Color(0xFFFFFFFF);
  late Color onWarningContainer = const Color(0xFF331D00);
  late Color error = const Color(0xFFC81E1E);
  late Color errorContainer = const Color(0xFFFFDAD6);
  late Color onError = const Color(0xFFFFFFFF);
  late Color onErrorContainer = const Color(0xFF410002);
  late Color info = OnewayPalette.primaryLightMode;
  late Color infoContainer = const Color(0xFFD1E9EB);
  late Color onInfo = const Color(0xFFFFFFFF);
  late Color onInfoContainer = const Color(0xFF002023);

  // Outline & Divider
  late Color outline = const Color(0xFF737779);
  late Color outlineVariant = const Color(0xFFC3C7C9);
  late Color divider = const Color(0xFFE0E4E5);

  // Utility
  late Color transparent = const Color(0x00000000);
  late Color shadow = const Color(0xFF000000);
  late Color scrim = const Color(0xFF000000);

  // Opacity variants
  late Color primary8 = const Color(0x14006D77);
  late Color primary12 = const Color(0x1F006D77);
  late Color primary16 = const Color(0x29006D77);
  late Color primary24 = const Color(0x3D006D77);
  late Color secondary8 = const Color(0x1483C5BE);
  late Color secondary12 = const Color(0x1F83C5BE);
  late Color secondary16 = const Color(0x2983C5BE);
  late Color onSurface8 = const Color(0x141A1C1E);
  late Color onSurface12 = const Color(0x1F1A1C1E);
  late Color onSurface16 = const Color(0x291A1C1E);
  late Color onSurface24 = const Color(0x3D1A1C1E);

  // Backward compatibility - deprecated old property names
  @Deprecated('Use surface instead')
  Color get primaryBackground => background;
  @Deprecated('Use surface instead')
  Color get secondaryBackground => surface;
  @Deprecated('Use outlineVariant instead')
  Color get alternate => outlineVariant;
  @Deprecated('Use primaryText instead')
  Color get onPrimary80 => onPrimary.withValues(alpha: 0.8);
  @Deprecated('Use primaryText instead')
  Color get onPrimary10 => onPrimary.withValues(alpha: 0.1);
  @Deprecated('Use primary instead')
  Color get secondary10 => primary.withValues(alpha: 0.1);
  @Deprecated('Use primary instead')
  Color get secondary15 => primary.withValues(alpha: 0.15);
  @Deprecated('Use primaryText instead')
  Color get onPrimary90 => onPrimary.withValues(alpha: 0.9);
  @Deprecated('Use onSurface instead')
  Color get fullContrast60 => onSurface.withValues(alpha: 0.6);
  @Deprecated('Use primaryText instead')
  Color get onPrimary20 => onPrimary.withValues(alpha: 0.2);
  @Deprecated('Use successContainer instead')
  Color get success10 => successContainer;
  @Deprecated('Use successContainer instead')
  Color get success30 => successContainer;
  @Deprecated('Use primary instead')
  Color get secondary30 => primary.withValues(alpha: 0.3);
  @Deprecated('Use primary instead')
  Color get primary95 => primary.withValues(alpha: 0.95);
  @Deprecated('Use warningContainer instead')
  Color get warning10 => warningContainer;
  @Deprecated('Use primary instead')
  Color get primary80 => primary.withValues(alpha: 0.8);
  @Deprecated('Use error instead')
  Color get onErrorCompat => error;
  @Deprecated('Use onSurface instead')
  Color get onSurfaceCompat => onSurface;

  // Additional backward compatibility for old property names
  @Deprecated('Use primary instead')
  Color get accent1 => primary.withValues(alpha: 0.3);
  @Deprecated('Use secondary instead')
  Color get accent2 => secondary;
  @Deprecated('Use onSurfaceVariant instead')
  Color get accent3 => onSurfaceVariant;
  @Deprecated('Use surface instead')
  Color get accent4 => surface;
  @Deprecated('Use warningContainer instead')
  Color get warning10Compat => warningContainer;
}

abstract class Typography {
  String get displayLargeFamily;
  bool get displayLargeIsCustom;
  TextStyle get displayLarge;
  String get displayMediumFamily;
  bool get displayMediumIsCustom;
  TextStyle get displayMedium;
  String get displaySmallFamily;
  bool get displaySmallIsCustom;
  TextStyle get displaySmall;
  String get headlineLargeFamily;
  bool get headlineLargeIsCustom;
  TextStyle get headlineLarge;
  String get headlineMediumFamily;
  bool get headlineMediumIsCustom;
  TextStyle get headlineMedium;
  String get headlineSmallFamily;
  bool get headlineSmallIsCustom;
  TextStyle get headlineSmall;
  String get titleLargeFamily;
  bool get titleLargeIsCustom;
  TextStyle get titleLarge;
  String get titleMediumFamily;
  bool get titleMediumIsCustom;
  TextStyle get titleMedium;
  String get titleSmallFamily;
  bool get titleSmallIsCustom;
  TextStyle get titleSmall;
  String get labelLargeFamily;
  bool get labelLargeIsCustom;
  TextStyle get labelLarge;
  String get labelMediumFamily;
  bool get labelMediumIsCustom;
  TextStyle get labelMedium;
  String get labelSmallFamily;
  bool get labelSmallIsCustom;
  TextStyle get labelSmall;
  String get bodyLargeFamily;
  bool get bodyLargeIsCustom;
  TextStyle get bodyLarge;
  String get bodyMediumFamily;
  bool get bodyMediumIsCustom;
  TextStyle get bodyMedium;
  String get bodySmallFamily;
  bool get bodySmallIsCustom;
  TextStyle get bodySmall;
}

class ThemeTypography extends Typography {
  ThemeTypography(this.theme);

  final FlutterFlowTheme theme;

  // Using Cairo for Arabic, with proper weights
  String get displayLargeFamily => 'Cairo';
  bool get displayLargeIsCustom => false;
  TextStyle get displayLarge => GoogleFonts.cairo(
        color: theme.primaryText,
        fontWeight: FontWeight.w800,
        fontSize: 57,
        height: 1.12,
        letterSpacing: -0.25,
      );

  String get displayMediumFamily => 'Cairo';
  bool get displayMediumIsCustom => false;
  TextStyle get displayMedium => GoogleFonts.cairo(
        color: theme.primaryText,
        fontWeight: FontWeight.w800,
        fontSize: 45,
        height: 1.16,
        letterSpacing: 0,
      );

  String get displaySmallFamily => 'Cairo';
  bool get displaySmallIsCustom => false;
  TextStyle get displaySmall => GoogleFonts.cairo(
        color: theme.primaryText,
        fontWeight: FontWeight.w700,
        fontSize: 36,
        height: 1.22,
        letterSpacing: 0,
      );

  String get headlineLargeFamily => 'Cairo';
  bool get headlineLargeIsCustom => false;
  TextStyle get headlineLarge => GoogleFonts.cairo(
        color: theme.primaryText,
        fontWeight: FontWeight.w700,
        fontSize: 32,
        height: 1.25,
        letterSpacing: 0,
      );

  String get headlineMediumFamily => 'Cairo';
  bool get headlineMediumIsCustom => false;
  TextStyle get headlineMedium => GoogleFonts.cairo(
        color: theme.primaryText,
        fontWeight: FontWeight.w700,
        fontSize: 28,
        height: 1.29,
        letterSpacing: 0,
      );

  String get headlineSmallFamily => 'Cairo';
  bool get headlineSmallIsCustom => false;
  TextStyle get headlineSmall => GoogleFonts.cairo(
        color: theme.primaryText,
        fontWeight: FontWeight.w600,
        fontSize: 24,
        height: 1.33,
        letterSpacing: 0,
      );

  String get titleLargeFamily => 'Cairo';
  bool get titleLargeIsCustom => false;
  TextStyle get titleLarge => GoogleFonts.cairo(
        color: theme.primaryText,
        fontWeight: FontWeight.w600,
        fontSize: 22,
        height: 1.27,
        letterSpacing: 0,
      );

  String get titleMediumFamily => 'Cairo';
  bool get titleMediumIsCustom => false;
  TextStyle get titleMedium => GoogleFonts.cairo(
        color: theme.primaryText,
        fontWeight: FontWeight.w600,
        fontSize: 16,
        height: 1.5,
        letterSpacing: 0.15,
      );

  String get titleSmallFamily => 'Cairo';
  bool get titleSmallIsCustom => false;
  TextStyle get titleSmall => GoogleFonts.cairo(
        color: theme.primaryText,
        fontWeight: FontWeight.w600,
        fontSize: 14,
        height: 1.43,
        letterSpacing: 0.1,
      );

  String get labelLargeFamily => 'Cairo';
  bool get labelLargeIsCustom => false;
  TextStyle get labelLarge => GoogleFonts.cairo(
        color: theme.primaryText,
        fontWeight: FontWeight.w600,
        fontSize: 14,
        height: 1.43,
        letterSpacing: 0.1,
      );

  String get labelMediumFamily => 'Cairo';
  bool get labelMediumIsCustom => false;
  TextStyle get labelMedium => GoogleFonts.cairo(
        color: theme.secondaryText,
        fontWeight: FontWeight.w500,
        fontSize: 12,
        height: 1.33,
        letterSpacing: 0.5,
      );

  String get labelSmallFamily => 'Cairo';
  bool get labelSmallIsCustom => false;
  TextStyle get labelSmall => GoogleFonts.cairo(
        color: theme.tertiaryText,
        fontWeight: FontWeight.w500,
        fontSize: 11,
        height: 1.45,
        letterSpacing: 0.5,
      );

  String get bodyLargeFamily => 'Cairo';
  bool get bodyLargeIsCustom => false;
  TextStyle get bodyLarge => GoogleFonts.cairo(
        color: theme.primaryText,
        fontWeight: FontWeight.w400,
        fontSize: 16,
        height: 1.5,
        letterSpacing: 0.15,
      );

  String get bodyMediumFamily => 'Cairo';
  bool get bodyMediumIsCustom => false;
  TextStyle get bodyMedium => GoogleFonts.cairo(
        color: theme.primaryText,
        fontWeight: FontWeight.w400,
        fontSize: 14,
        height: 1.43,
        letterSpacing: 0.25,
      );

  String get bodySmallFamily => 'Cairo';
  bool get bodySmallIsCustom => false;
  TextStyle get bodySmall => GoogleFonts.cairo(
        color: theme.secondaryText,
        fontWeight: FontWeight.w400,
        fontSize: 12,
        height: 1.33,
        letterSpacing: 0.4,
      );
}

class DarkModeTheme extends FlutterFlowTheme {
  @Deprecated('Use primary instead')
  Color get primaryColor => primary;
  @Deprecated('Use secondary instead')
  Color get secondaryColor => secondary;
  @Deprecated('Use tertiary instead')
  Color get tertiaryColor => tertiary;

  // Core Brand Colors - Adjusted for dark mode
  late Color primary = const Color(0xFF4FD1C5);       // Light teal
  late Color primaryLight = const Color(0xFF81E6D9);  // Brighter teal
  late Color primaryDark = const Color(0xFF38B2AC);   // Medium teal
  late Color secondary = const Color(0xFF83C5BE);     // Soft mint
  late Color secondaryLight = const Color(0xFF1A2E2E); // Dark mint surface
  late Color secondaryDark = const Color(0xFF52A39B); // Medium teal
  late Color tertiary = const Color(0xFFFFB84D);      // Warm amber
  late Color tertiaryLight = const Color(0xFFFFD98A); // Light amber
  late Color tertiaryDark = const Color(0xFFFF9F1A);  // Brighter amber

  // ONEWAY redesign - deep navy dusk palette
  late Color navy = const Color(0xFF0B2447);
  late Color navyLight = const Color(0xFF143C6B);
  late Color navyDark = const Color(0xFF071A33);
  late Color gold = const Color(0xFFFFC24D);

  // Surface Colors - Dark surfaces
  late Color surface = const Color(0xFF1A1C1E);
  late Color surfaceVariant = const Color(0xFF2A2D2F);
  late Color surfaceContainer = const Color(0xFF242628);
  late Color surfaceContainerHigh = const Color(0xFF2E3032);
  late Color surfaceContainerHighest = const Color(0xFF383A3C);
  late Color background = const Color(0xFF121314);
  late Color onBackground = const Color(0xFFE6E8E9);

  // Text Colors - Light text on dark
  late Color onPrimary = const Color(0xFF002023);
  late Color onPrimaryContainer = const Color(0xFFA7F3F0);
  late Color onSecondary = const Color(0xFF002023);
  late Color onSecondaryContainer = const Color(0xFF002023);
  late Color onSurface = const Color(0xFFE6E8E9);
  late Color onSurfaceVariant = const Color(0xFFC3C7C9);
  late Color primaryText = const Color(0xFFE6E8E9);
  late Color secondaryText = const Color(0xFFB0B3B5);
  late Color tertiaryText = const Color(0xFF8C8F91);
  late Color hintText = const Color(0xFF6B6F71);

  // State Colors - Adjusted for dark mode
  late Color success = const Color(0xFF69DB7C);
  late Color successContainer = const Color(0xFF003D1A);
  late Color onSuccess = const Color(0xFF00230B);
  late Color onSuccessContainer = const Color(0xFFD1E7DD);
  late Color warning = const Color(0xFFFFD56B);
  late Color warningContainer = const Color(0xFF3D2C00);
  late Color onWarning = const Color(0xFF331D00);
  late Color onWarningContainer = const Color(0xFFFFF3D1);
  late Color error = const Color(0xFFFFB4AB);
  late Color errorContainer = const Color(0xFF5A0E0E);
  late Color onError = const Color(0xFF410002);
  late Color onErrorContainer = const Color(0xFFFFDAD6);
  late Color info = const Color(0xFF4FD1C5);
  late Color infoContainer = const Color(0xFF003A3C);
  late Color onInfo = const Color(0xFF002023);
  late Color onInfoContainer = const Color(0xFFA7F3F0);

  // Outline & Divider
  late Color outline = const Color(0xFF8C8F91);
  late Color outlineVariant = const Color(0xFF424748);
  late Color divider = const Color(0xFF2E3032);

  // Utility
  late Color transparent = const Color(0x00000000);
  late Color shadow = const Color(0xFF000000);
  late Color scrim = const Color(0xFF000000);

  // Opacity variants
  late Color primary8 = const Color(0x144FD1C5);
  late Color primary12 = const Color(0x1F4FD1C5);
  late Color primary16 = const Color(0x294FD1C5);
  late Color primary24 = const Color(0x3D4FD1C5);
  late Color secondary8 = const Color(0x1483C5BE);
  late Color secondary12 = const Color(0x1F83C5BE);
  late Color secondary16 = const Color(0x2983C5BE);
  late Color onSurface8 = const Color(0x14E6E8E9);
  late Color onSurface12 = const Color(0x1FE6E8E9);
  late Color onSurface16 = const Color(0x29E6E8E9);
  late Color onSurface24 = const Color(0x3DE6E8E9);

  // Backward compatibility - deprecated old property names
  @Deprecated('Use surface instead')
  Color get primaryBackground => background;
  @Deprecated('Use surface instead')
  Color get secondaryBackground => surface;
  @Deprecated('Use outlineVariant instead')
  Color get alternate => outlineVariant;
  @Deprecated('Use primaryText instead')
  Color get onPrimary80 => onPrimary.withValues(alpha: 0.8);
  @Deprecated('Use primaryText instead')
  Color get onPrimary10 => onPrimary.withValues(alpha: 0.1);
  @Deprecated('Use primary instead')
  Color get secondary10 => primary.withValues(alpha: 0.1);
  @Deprecated('Use primary instead')
  Color get secondary15 => primary.withValues(alpha: 0.15);
  @Deprecated('Use primaryText instead')
  Color get onPrimary90 => onPrimary.withValues(alpha: 0.9);
  @Deprecated('Use onSurface instead')
  Color get fullContrast60 => onSurface.withValues(alpha: 0.6);
  @Deprecated('Use primaryText instead')
  Color get onPrimary20 => onPrimary.withValues(alpha: 0.2);
  @Deprecated('Use successContainer instead')
  Color get success10 => successContainer;
  @Deprecated('Use successContainer instead')
  Color get success30 => successContainer;
  @Deprecated('Use primary instead')
  Color get secondary30 => primary.withValues(alpha: 0.3);
  @Deprecated('Use primary instead')
  Color get primary95 => primary.withValues(alpha: 0.95);
  @Deprecated('Use warningContainer instead')
  Color get warning10 => warningContainer;
  @Deprecated('Use primary instead')
  Color get primary80 => primary.withValues(alpha: 0.8);
  @Deprecated('Use error instead')
  Color get onErrorCompat => error;
  @Deprecated('Use onSurface instead')
  Color get onSurfaceCompat => onSurface;

  // Additional backward compatibility for old property names
  @Deprecated('Use primary instead')
  Color get accent1 => primary.withValues(alpha: 0.3);
  @Deprecated('Use secondary instead')
  Color get accent2 => secondary;
  @Deprecated('Use onSurfaceVariant instead')
  Color get accent3 => onSurfaceVariant;
  @Deprecated('Use surface instead')
  Color get accent4 => surface;
  @Deprecated('Use warningContainer instead')
  Color get warning10Compat => warningContainer;
}

class FFDesignTokens {
  const FFDesignTokens(this.theme);
  final FlutterFlowTheme theme;
  FFSpacing get spacing => const FFSpacing();
  FFRadius get radius => const FFRadius();
  FFShadows get shadow => FFShadows(theme);
  FFAnimation get animation => const FFAnimation();
}

class FFSpacing {
  const FFSpacing();
  double get none => 0;
  double get xs => 4;
  double get sm => 8;
  double get md => 16;
  double get lg => 24;
  double get xl => 32;
  double get xxl => 48;
  double get xxxl => 64;
  double get insetSm => 12;
  double get insetMd => 16;
  double get insetLg => 24;
  double get insetXl => 32;
}

class FFRadius {
  const FFRadius();
  double get none => 0;
  double get xs => 4;
  double get sm => 8;
  double get md => 12;
  double get lg => 16;
  double get xl => 20;
  double get xxl => 28;
  double get full => 9999;
}

class FFShadows {
  const FFShadows(this.theme);
  final FlutterFlowTheme theme;

  BoxShadow get none => const BoxShadow(
      blurRadius: 0,
      color: Colors.transparent,
      offset: Offset(0, 0),
      spreadRadius: 0);

  // Elevation 1 - Subtle
  BoxShadow get xs => BoxShadow(
      blurRadius: 4,
      color: theme.shadow.withValues(alpha: 0.04),
      offset: const Offset(0, 1),
      spreadRadius: 0);

  // Elevation 2 - Card resting
  BoxShadow get sm => BoxShadow(
      blurRadius: 8,
      color: theme.shadow.withValues(alpha: 0.06),
      offset: const Offset(0, 2),
      spreadRadius: 0);

  // Elevation 3 - Card hover
  BoxShadow get md => BoxShadow(
      blurRadius: 12,
      color: theme.shadow.withValues(alpha: 0.08),
      offset: const Offset(0, 4),
      spreadRadius: 0);

  // Elevation 4 - Floating
  BoxShadow get lg => BoxShadow(
      blurRadius: 16,
      color: theme.shadow.withValues(alpha: 0.1),
      offset: const Offset(0, 8),
      spreadRadius: 0);

  // Elevation 5 - Modal
  BoxShadow get xl => BoxShadow(
      blurRadius: 24,
      color: theme.shadow.withValues(alpha: 0.12),
      offset: const Offset(0, 12),
      spreadRadius: 0);

  // Elevation 6 - Toast/Overlay
  BoxShadow get xxl => BoxShadow(
      blurRadius: 32,
      color: theme.shadow.withValues(alpha: 0.15),
      offset: const Offset(0, 16),
      spreadRadius: 0);

  // Colored shadows for brand elements
  BoxShadow get primarySm => BoxShadow(
      blurRadius: 8,
      color: theme.primary.withValues(alpha: 0.2),
      offset: const Offset(0, 2),
      spreadRadius: 0);

  BoxShadow get primaryMd => BoxShadow(
      blurRadius: 16,
      color: theme.primary.withValues(alpha: 0.25),
      offset: const Offset(0, 4),
      spreadRadius: 0);

  BoxShadow get primaryLg => BoxShadow(
      blurRadius: 24,
      color: theme.primary.withValues(alpha: 0.3),
      offset: const Offset(0, 8),
      spreadRadius: 0);
}

class FFAnimation {
  const FFAnimation();
  Duration get instant => const Duration(milliseconds: 0);
  Duration get fast => const Duration(milliseconds: 150);
  Duration get normal => const Duration(milliseconds: 250);
  Duration get slow => const Duration(milliseconds: 350);
  Duration get slower => const Duration(milliseconds: 500);

  Curve get standard => Curves.easeInOutCubic;
  Curve get emphasized => Curves.easeOutCubic;
  Curve get decelerate => Curves.decelerate;
  Curve get accelerate => Curves.easeIn;
  Curve get bounce => Curves.elasticOut;
}

extension TextStyleHelper on TextStyle {
  TextStyle override({
    TextStyle? font,
    String? fontFamily,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
    FontStyle? fontStyle,
    bool useGoogleFonts = false,
    TextDecoration? decoration,
    double? lineHeight,
    List<Shadow>? shadows,
    String? package,
  }) {
    if (useGoogleFonts && fontFamily != null && fontFamily.isNotEmpty) {
      font = GoogleFonts.getFont(fontFamily,
          fontWeight: fontWeight ?? this.fontWeight,
          fontStyle: fontStyle ?? this.fontStyle);
    }

    return font != null
        ? font.copyWith(
            color: color ?? this.color,
            fontSize: fontSize ?? this.fontSize,
            letterSpacing: letterSpacing ?? this.letterSpacing,
            fontWeight: fontWeight ?? this.fontWeight,
            fontStyle: fontStyle ?? this.fontStyle,
            decoration: decoration,
            height: lineHeight,
            shadows: shadows,
          )
        : copyWith(
            fontFamily: fontFamily,
            package: package,
            color: color,
            fontSize: fontSize,
            letterSpacing: letterSpacing,
            fontWeight: fontWeight,
            fontStyle: fontStyle,
            decoration: decoration,
            height: lineHeight,
            shadows: shadows,
          );
  }
}