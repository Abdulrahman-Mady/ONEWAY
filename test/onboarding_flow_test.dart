import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:one_way_egypt/core/analytics/analytics_service.dart';
import 'package:one_way_egypt/core/constants/app_constants.dart';
import 'package:one_way_egypt/features/onboarding/onboarding_flow.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'analytics_service_test.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget wrap(Widget child, {Locale locale = const Locale('ar')}) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('ar'), Locale('en')],
      home: Directionality(
        textDirection:
            locale.languageCode == 'en' ? TextDirection.ltr : TextDirection.rtl,
        child: child,
      ),
    );
  }

  testWidgets(
      'completes permissions + 3-step needs-based personalization without raw % labels',
      (tester) async {
    final sink = InMemoryAnalyticsSink();
    final analytics = AnalyticsService.forTesting(sink);
    String? completedMobility;
    final requestedPermissions = <OnboardingPermissionKind>[];

    await tester.pumpWidget(
      wrap(
        OnewayOnboardingFlow(
          analytics: analytics,
          permissionRequester: (kind) async {
            requestedPermissions.add(kind);
            return OnboardingPermissionState.granted;
          },
          onFinished: (mobility) async {
            completedMobility = mobility;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Screen 0: Native-style Permissions
    expect(find.byKey(const Key('onboarding_step_permissions')), findsOneWidget);
    expect(sink.events.first.name, AnalyticsEvents.onboardingStarted);

    // Tapping Next directly when all permissions are untouched prompts all 3 native OS permissions!
    await tester.tap(find.byKey(const Key('onboarding_next_btn')));
    await tester.pumpAndSettle();
    expect(
      requestedPermissions,
      containsAll(OnboardingPermissionKind.values),
    );

    // Personalization Step 1 of 3: Mobility Way (Single choice, no raw 25%/30% text)
    expect(find.byKey(const Key('onboarding_step_mobility')), findsOneWidget);
    expect(find.textContaining('25%'), findsNothing);
    expect(find.textContaining('30%'), findsNothing);

    await tester.tap(find.byKey(const Key('mobility_option_assisted_walking')));
    await tester.pumpAndSettle();

    // Advance to Personalization Step 2 of 3: Concrete Access Needs (Multi-select)
    await tester.tap(find.byKey(const Key('onboarding_next_btn')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('onboarding_step_access_needs')), findsOneWidget);

    final widePassagesFinder = find.byKey(const Key('need_option_wide_passages'));
    await tester.ensureVisible(widePassagesFinder);
    await tester.pumpAndSettle();
    await tester.tap(widePassagesFinder);
    await tester.pumpAndSettle();

    // Advance to Personalization Step 3 of 3: Summary & Live Preview
    await tester.tap(find.byKey(const Key('onboarding_next_btn')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('onboarding_step_guide')), findsOneWidget);

    // Toggle Ramp off in live interactive playground and verify UI responds
    final guideRampFinder = find.byKey(const Key('guide_toggle_ramp'));
    await tester.ensureVisible(guideRampFinder);
    await tester.pumpAndSettle();
    await tester.tap(guideRampFinder);
    await tester.pumpAndSettle();

    // Complete onboarding
    await tester.tap(find.byKey(const Key('onboarding_next_btn')));
    await tester.pumpAndSettle();

    expect(completedMobility, 'المشي بمساعدة (عكاز أو مشاية)');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(AppConstants.kOnboardingSeenKey), isTrue);
    expect(
      prefs.getString(AppConstants.kPendingMobilityTypeKey),
      'المشي بمساعدة (عكاز أو مشاية)',
    );
    expect(
      prefs.getStringList(AppConstants.kPendingAccessNeedsKey),
      contains('wide_passages'),
    );
    expect(
      sink.events.any((e) =>
          e.name == AnalyticsEvents.onboardingCompleted &&
          e.params?['mobility_type'] == 'assisted_walking'),
      isTrue,
    );
  });

  testWidgets('skipping onboarding logs onboarding_skipped with current step',
      (tester) async {
    final sink = InMemoryAnalyticsSink();
    final analytics = AnalyticsService.forTesting(sink);
    var finished = false;

    await tester.pumpWidget(
      wrap(
        OnewayOnboardingFlow(
          analytics: analytics,
          onFinished: (_) async {
            finished = true;
          },
        ),
        locale: const Locale('en'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('onboarding_skip_btn')));
    await tester.pumpAndSettle();

    expect(finished, isTrue);
    expect(
      sink.events.any((e) =>
          e.name == AnalyticsEvents.onboardingSkipped &&
          e.params?['step'] == 1),
      isTrue,
    );
  });
}
