import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:one_way_egypt/app_state.dart';
import 'package:one_way_egypt/components/bottom_nav/bottom_nav_widget.dart';
import 'package:one_way_egypt/components/bottom_nav_child/bottom_nav_child_widget.dart';
import 'package:one_way_egypt/components/category_chip/category_chip_widget.dart';
import 'package:one_way_egypt/core/constants/app_constants.dart';
import 'package:one_way_egypt/features/discovery/place_explorer_page.dart';
import 'package:one_way_egypt/features/legal/legal_pages.dart';
import 'package:one_way_egypt/help_support_page/help_support_page_widget.dart';
import 'package:one_way_egypt/pages/splash_onboarding/splash_onboarding_widget.dart';
import 'package:one_way_egypt/settings_page/settings_page_widget.dart';
import 'package:provider/provider.dart';

/// Verifies that core screens render cleanly with ZERO RenderFlex overflow
/// errors across small phones (320x568), standard phones (390x844), landscape
/// phones (667x375), tablets (768x1024), and max accessibility font scaling (1.45x).
void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  const viewports = <(String, Size, double)>[
    ('small-phone-320', Size(320, 568), 1.0),
    ('small-phone-max-font', Size(320, 640), AppConstants.maxFontScale),
    ('standard-phone', Size(390, 844), 1.0),
    ('standard-phone-max-font', Size(360, 780), AppConstants.maxFontScale),
    ('landscape-phone', Size(667, 375), 1.0),
    ('tablet-portrait', Size(768, 1024), 1.15),
  ];

  Future<void> pumpAndAssertNoOverflow(
    WidgetTester tester, {
    required Size size,
    required double textScale,
    required Widget child,
    Locale locale = const Locale('ar'),
  }) async {
    final errors = <FlutterErrorDetails>[];
    final previousOnError = FlutterError.onError;

    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    FlutterError.onError = (details) {
      errors.add(details);
    };
    try {
      await tester.pumpWidget(
        ChangeNotifierProvider<FFAppState>.value(
          value: FFAppState(),
          child: MaterialApp(
            locale: locale,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('ar'), Locale('en')],
            home: Directionality(
              textDirection: locale.languageCode == 'en'
                  ? TextDirection.ltr
                  : TextDirection.rtl,
              child: MediaQuery(
                data: MediaQueryData(
                  size: size,
                  textScaler: TextScaler.linear(textScale),
                ),
                child: child,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    } finally {
      FlutterError.onError = previousOnError;
    }

    final overflowErrors = errors
        .where((e) => e.exceptionAsString().contains('overflowed'))
        .toList();
    expect(
      overflowErrors,
      isEmpty,
      reason: 'Overflow detected at $size (scale $textScale): '
          '${overflowErrors.map((e) => e.exceptionAsString()).join('\n')}',
    );
  }

  for (final (label, size, scale) in viewports) {
    testWidgets('SplashOnboarding renders with zero overflow on $label',
        (tester) async {
      await pumpAndAssertNoOverflow(
        tester,
        size: size,
        textScale: scale,
        child: const SplashOnboardingWidget(),
      );
    });

    testWidgets('BottomNav renders with zero overflow on $label',
        (tester) async {
      await pumpAndAssertNoOverflow(
        tester,
        size: size,
        textScale: scale,
        child: Scaffold(
          bottomNavigationBar: BottomNavWidget(
            child: () => BottomNavChildWidget(currentIndex: 2, onTap: (_) {}),
          ),
        ),
      );
    });

    testWidgets('PrivacyPolicy renders with zero overflow on $label',
        (tester) async {
      await pumpAndAssertNoOverflow(
        tester,
        size: size,
        textScale: scale,
        child: const PrivacyPolicyPage(),
      );
    });

    testWidgets('AboutApp renders with zero overflow on $label',
        (tester) async {
      await pumpAndAssertNoOverflow(
        tester,
        size: size,
        textScale: scale,
        child: const AboutAppPage(),
      );
    });

    testWidgets('HelpSupport renders with zero overflow on $label',
        (tester) async {
      await pumpAndAssertNoOverflow(
        tester,
        size: size,
        textScale: scale,
        child: const HelpSupportPageWidget(),
      );
    });
  }

  testWidgets('English LTR SplashOnboarding & BottomNav render with zero overflow on 320px at 1.45x',
      (tester) async {
    await pumpAndAssertNoOverflow(
      tester,
      size: const Size(320, 640),
      textScale: AppConstants.maxFontScale,
      locale: const Locale('en'),
      child: const SplashOnboardingWidget(),
    );
    await pumpAndAssertNoOverflow(
      tester,
      size: const Size(320, 640),
      textScale: AppConstants.maxFontScale,
      locale: const Locale('en'),
      child: Scaffold(
        bottomNavigationBar: BottomNavWidget(
          child: () => BottomNavChildWidget(currentIndex: 2, onTap: (_) {}),
        ),
      ),
    );
  });

  testWidgets('SettingsPage renders with zero overflow at 1.45x max font scale (AR & EN)',
      (tester) async {
    await pumpAndAssertNoOverflow(
      tester,
      size: const Size(320, 640),
      textScale: AppConstants.maxFontScale,
      locale: const Locale('ar'),
      child: const SettingsPageWidget(),
    );
    await pumpAndAssertNoOverflow(
      tester,
      size: const Size(320, 640),
      textScale: AppConstants.maxFontScale,
      locale: const Locale('en'),
      child: const SettingsPageWidget(),
    );
  });

  testWidgets('PlaceExplorerPage & CategoryChip render with zero overflow at 1.45x max font scale',
      (tester) async {
    await pumpAndAssertNoOverflow(
      tester,
      size: const Size(320, 640),
      textScale: AppConstants.maxFontScale,
      locale: const Locale('ar'),
      child: const PlaceExplorerPage(
        initialCategory: 'مستشف',
        placesOverride: [],
      ),
    );
    await pumpAndAssertNoOverflow(
      tester,
      size: const Size(320, 640),
      textScale: AppConstants.maxFontScale,
      locale: const Locale('ar'),
      child: Scaffold(
        body: SizedBox(
          height: 126 * AppConstants.maxFontScale,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const [
              CategoryChipWidget(
                icon: Icon(Icons.local_hospital_rounded),
                label: 'مستشفيات',
              ),
              SizedBox(width: 12),
              CategoryChipWidget(
                icon: Icon(Icons.museum_rounded),
                label: 'سياحة وثقافة',
              ),
            ],
          ),
        ),
      ),
    );
  });
}
