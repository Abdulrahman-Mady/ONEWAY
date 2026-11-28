import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:integration_test/integration_test.dart';
import 'package:one_way_egypt/backend/schema/structs/accessibility_features_struct.dart';
import 'package:one_way_egypt/core/theme/oneway_theme.dart';
import 'package:one_way_egypt/features/business/b2b_portal_models.dart';
import 'package:one_way_egypt/features/business/b2b_verification_dashboard.dart';
import 'package:one_way_egypt/features/guide/egypt_guide_page.dart';
import 'package:one_way_egypt/features/onboarding/onboarding_flow.dart';
import 'package:one_way_egypt/flutter_flow/flutter_flow_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// End-to-end integration test covering ONEWAY's primary user journeys:
/// 1. 3-step interactive onboarding (Permissions -> Mobility Profile -> Quick Guide)
/// 2. Egypt Rights & Accessibility Guide (offline AR/EN)
/// 3. B2B Business Verification Portal & self-assessment flow
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('E2E: Onboarding -> Egypt Guide -> B2B Portal', (tester) async {
    String? savedMobility;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('ar'), Locale('en')],
        theme: buildOnewayTheme(LightModeTheme(), Brightness.light),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: OnewayOnboardingFlow(
            permissionRequester: (_) async => OnboardingPermissionState.granted,
            onFinished: (mobility) async {
              savedMobility = mobility;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Step 1 -> Step 2
    await tester.tap(find.byKey(const Key('onboarding_next_btn')));
    await tester.pumpAndSettle();

    // Select Senior profile -> Step 3
    await tester.tap(find.byKey(const Key('mobility_option_senior')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('onboarding_next_btn')));
    await tester.pumpAndSettle();

    // Finish onboarding
    await tester.tap(find.byKey(const Key('onboarding_next_btn')));
    await tester.pumpAndSettle();
    expect(savedMobility, contains('كبار السن'));

    // Verify Egypt Guide loads cleanly
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('ar'), Locale('en')],
        theme: buildOnewayTheme(LightModeTheme(), Brightness.light),
        home: const Directionality(
          textDirection: TextDirection.rtl,
          child: EgyptGuidePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('16736'), findsOneWidget);

    // Verify B2B Portal renders & enforces ethical verification state
    final b2bSnap = B2bPortalSnapshot(
      businessId: 'e2e_biz',
      businessName: 'مركز النيل الطبي',
      category: 'طبي ومستشفيات',
      subscriptionTier: 'pro',
      branches: [
        B2bBranchSummary(
          placeId: 'p1',
          name: 'فرع المهندسين',
          category: 'طبي ومستشفيات',
          address: 'الجيزة',
          features: AccessibilityFeaturesStruct(
            wheelchairEntrance: true,
            ramp: true,
            suitableElevator: true,
          ),
          isGenuinelyVerified: false,
          effectiveVerificationStatus: 'pending',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('ar'), Locale('en')],
        theme: buildOnewayTheme(LightModeTheme(), Brightness.light),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: B2bVerificationDashboardView(
            snapshot: b2bSnap,
            onRegisterBusiness: () {},
            onRequestFieldAudit: (_) async {},
            onContactSales: (_) {},
            onClose: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('b2b_ethical_charter')),
      200,
      scrollable: find.descendant(
        of: find.byKey(const Key('b2b_overview_list')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.byKey(const Key('b2b_ethical_charter')), findsOneWidget);
  });
}
