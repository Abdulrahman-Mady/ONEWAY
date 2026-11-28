import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_way_egypt/core/theme/oneway_theme.dart';
import 'package:one_way_egypt/core/utils/a11y_utils.dart';
import 'package:one_way_egypt/core/utils/arabic_normalizer.dart';
import 'package:one_way_egypt/flutter_flow/flutter_flow_theme.dart';

void main() {
  group('WCAG 2.1 AA Color Contrast Compliance', () {
    test('LightModeTheme primary teal on white passes >= 4.5:1 AA contrast',
        () {
      final light = LightModeTheme();
      final ratio = A11yUtils.contrastRatio(light.primary, Colors.white);
      expect(ratio, greaterThanOrEqualTo(4.5),
          reason: 'Primary teal on white must pass WCAG AA (got $ratio)');
      expect(A11yUtils.meetsWcagAA(light.onPrimary, light.primary), isTrue);
    });

    test('LightModeTheme secondaryText on background passes >= 4.5:1 AA', () {
      final light = LightModeTheme();
      final ratio =
          A11yUtils.contrastRatio(light.secondaryText, light.background);
      expect(ratio, greaterThanOrEqualTo(4.5),
          reason: 'Secondary text on background contrast was $ratio');
    });

    test('DarkModeTheme primary on dark surface passes >= 4.5:1 AA', () {
      final dark = DarkModeTheme();
      expect(A11yUtils.meetsWcagAA(dark.primary, dark.surface), isTrue);
      expect(A11yUtils.meetsWcagAA(dark.onPrimary, dark.primary), isTrue);
    });

    test('Traffic-light accessibility colors pass AA contrast with white text',
        () {
      expect(A11yUtils.meetsWcagAA(Colors.white, OnewayPalette.accessFull),
          isTrue);
      expect(A11yUtils.meetsWcagAA(Colors.white, OnewayPalette.accessPartial),
          isTrue);
      expect(A11yUtils.meetsWcagAA(Colors.white, OnewayPalette.accessLimited),
          isTrue);
    });
  });

  group('Reduced Motion & Arabic Normalizer', () {
    testWidgets('effectiveDuration returns Duration.zero when disableAnimations is true',
        (tester) async {
      Duration? capturedNormal;
      Duration? capturedReduced;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              capturedNormal = A11yUtils.effectiveDuration(
                context,
                const Duration(milliseconds: 300),
              );
              return MediaQuery(
                data: const MediaQueryData(disableAnimations: true),
                child: Builder(
                  builder: (innerCtx) {
                    capturedReduced = A11yUtils.effectiveDuration(
                      innerCtx,
                      const Duration(milliseconds: 300),
                    );
                    return const SizedBox.shrink();
                  },
                ),
              );
            },
          ),
        ),
      );

      expect(capturedNormal, const Duration(milliseconds: 300));
      expect(capturedReduced, Duration.zero);
    });

    test('ArabicNormalizer folds hamzas, taa marbouta, alef maqsura & tashkeel',
        () {
      expect(ArabicNormalizer.normalize('مُسْتَشْفَى القَاهِرَة'),
          'مستشفي القاهره');
      expect(ArabicNormalizer.containsNormalized('أهلاً بِكُم', 'اهلا'), isTrue);
    });
  });
}
