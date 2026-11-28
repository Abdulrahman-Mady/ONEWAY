import 'package:flutter/material.dart';

/// Lightweight bilingual helper (Arabic / English) for ONEWAY.
/// Reads the active locale from `Localizations.localeOf(context)` so every
/// widget automatically rebuilds when the user switches languages in Settings.
class S {
  S._();

  static bool isEn(BuildContext context) {
    final locale = Localizations.maybeLocaleOf(context);
    return locale?.languageCode == 'en';
  }

  static String t(BuildContext context, String ar, String en) =>
      isEn(context) ? en : ar;
}
