import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_way_egypt/features/onboarding/home_spotlight_tour.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    HomeTourController.instance.resetForTesting();
  });

  group('HomeTourController persistence & replay', () {
    test('tracks seen state per user UID and supports replay requests',
        () async {
      final ctrl = HomeTourController.instance;
      expect(await ctrl.hasSeenTour('user_1'), isFalse);
      expect(await ctrl.hasSeenTour('user_2'), isFalse);

      await ctrl.markTourSeen('user_1');
      expect(await ctrl.hasSeenTour('user_1'), isTrue);
      expect(await ctrl.hasSeenTour('user_2'), isFalse);

      expect(ctrl.consumePendingReplay(), isFalse);
      ctrl.requestReplay();
      expect(ctrl.consumePendingReplay(), isTrue);
      expect(ctrl.consumePendingReplay(), isFalse);
    });
  });

  group('HomeSpotlightTourOverlay', () {
    testWidgets(
      'walks through steps with next, back, voice toggle, and finishes cleanly',
      (tester) async {
        final key1 = GlobalKey();
        final key2 = GlobalKey();
        var finished = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: Stack(
                children: [
                  Scaffold(
                    body: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          key: key1,
                          height: 56,
                          width: 240,
                          color: Colors.teal,
                        ),
                        Container(
                          key: key2,
                          height: 56,
                          width: 240,
                          color: Colors.amber,
                        ),
                      ],
                    ),
                  ),
                  Positioned.fill(
                    child: HomeSpotlightTourOverlay(
                      enableTts: false,
                      steps: [
                        SpotlightTourStep(
                          id: 'step_1',
                          targetKey: key1,
                          titleAr: 'البحث والمساعد الصوتي',
                          titleEn: 'Search & Voice',
                          descriptionAr: 'شرح الخطوة الأولى',
                          descriptionEn: 'First step description',
                          icon: Icons.mic_rounded,
                        ),
                        SpotlightTourStep(
                          id: 'step_2',
                          targetKey: key2,
                          titleAr: 'الخريطة التفاعلية',
                          titleEn: 'Interactive Map',
                          descriptionAr: 'شرح الخطوة الثانية',
                          descriptionEn: 'Second step description',
                          icon: Icons.map_rounded,
                        ),
                      ],
                      onFinished: () => finished = true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        expect(find.text('خطوة 1 من 2'), findsOneWidget);
        expect(find.text('البحث والمساعد الصوتي'), findsOneWidget);

        // Toggle voice button on/off
        await tester.tap(find.byKey(const Key('spotlight_voice_toggle_btn')));
        await tester.pump();
        expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);

        // Go to Step 2
        await tester.tap(find.byKey(const Key('spotlight_next_btn')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        expect(find.text('خطوة 2 من 2'), findsOneWidget);
        expect(find.text('الخريطة التفاعلية'), findsOneWidget);

        // Go back to Step 1
        await tester.tap(find.byKey(const Key('spotlight_prev_btn')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        expect(find.text('خطوة 1 من 2'), findsOneWidget);

        // Advance to Step 2 and finish
        await tester.tap(find.byKey(const Key('spotlight_next_btn')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        await tester.tap(find.byKey(const Key('spotlight_next_btn')));
        await tester.pump();

        expect(finished, isTrue);
      },
    );
  });
}
