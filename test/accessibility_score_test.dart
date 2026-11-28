import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:one_way_egypt/backend/schema/structs/accessibility_features_struct.dart';
import 'package:one_way_egypt/features/accessibility/accessibility_score.dart';
import 'package:one_way_egypt/features/guide/egypt_guide_page.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('AccessibilityScorer', () {
    test('returns 100% and full (green) when all 5 features exist', () {
      final features = AccessibilityFeaturesStruct(
        wheelchairEntrance: true,
        ramp: true,
        suitableElevator: true,
        accessibleRestroom: true,
        accessibleParking: true,
      );
      final result = AccessibilityScorer.evaluateFeatures(
        features,
        mobilityType: 'كرسي متحرك كهربائي',
      );
      expect(result.scorePercent, 100);
      expect(result.level, AccessibilityLevel.full);
      expect(result.isPersonalized, isTrue);
    });

    test('weights ramp higher for electric wheelchair vs elevator for seniors',
        () {
      final rampOnly = AccessibilityFeaturesStruct(
        wheelchairEntrance: false,
        ramp: true,
        suitableElevator: false,
        accessibleRestroom: false,
        accessibleParking: false,
      );
      final electricScore = AccessibilityScorer.evaluateFeatures(
        rampOnly,
        mobilityType: 'كرسي متحرك كهربائي',
      ).scorePercent;
      final seniorScore = AccessibilityScorer.evaluateFeatures(
        rampOnly,
        mobilityType: 'كبار السن',
      ).scorePercent;
      expect(electricScore, greaterThan(seniorScore));
    });

    test('returns limited (red) when no features are confirmed', () {
      final empty = AccessibilityFeaturesStruct();
      final result = AccessibilityScorer.evaluateFeatures(empty);
      expect(result.scorePercent, 0);
      expect(result.level, AccessibilityLevel.limited);
      expect(result.isPersonalized, isFalse);
    });

    test('returns partial (amber) for mid-range accessibility', () {
      final mid = AccessibilityFeaturesStruct(
        wheelchairEntrance: true,
        ramp: true,
      );
      final result = AccessibilityScorer.evaluateFeatures(mid);
      expect(result.scorePercent, 50);
      expect(result.level, AccessibilityLevel.partial);
    });
  });

  testWidgets('EgyptGuidePage renders with zero overflow in AR and EN on 320px',
      (tester) async {
    for (final locale in const [Locale('ar'), Locale('en')]) {
      final errors = <FlutterErrorDetails>[];
      final prev = FlutterError.onError;
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      FlutterError.onError = (d) => errors.add(d);
      try {
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            supportedLocales: const [Locale('ar'), Locale('en')],
            home: Directionality(
              textDirection: locale.languageCode == 'en'
                  ? TextDirection.ltr
                  : TextDirection.rtl,
              child: const MediaQuery(
                data: MediaQueryData(
                  size: Size(320, 568),
                  textScaler: TextScaler.linear(1.25),
                ),
                child: EgyptGuidePage(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      } finally {
        FlutterError.onError = prev;
      }

      final overflows = errors
          .where((e) => e.exceptionAsString().contains('overflowed'))
          .toList();
      expect(overflows, isEmpty, reason: 'Overflow in $locale: $overflows');
    }
  });
}
