import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:one_way_egypt/backend/schema/structs/accessibility_features_struct.dart';
import 'package:one_way_egypt/core/analytics/analytics_service.dart';
import 'package:one_way_egypt/features/business/b2b_portal_models.dart';
import 'package:one_way_egypt/features/business/b2b_verification_dashboard.dart';

import 'analytics_service_test.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('B2bPortalModels ethical & scoring invariants', () {
    test('no paid B2B plan ever grants verification badge on payment', () {
      for (final plan in B2bPlanSpec.catalog) {
        expect(plan.grantsBadgeOnPayment, isFalse,
            reason: 'Plan ${plan.id} must never buy a Verified badge');
      }
    });

    test('Pro subscription without field evidence stays unverified', () {
      const snap = B2bPortalSnapshot(
        businessId: 'biz_1',
        businessName: 'فندق النيل',
        category: 'فنادق وسياحة',
        businessStatus: 'active',
        subscriptionTier: 'pro',
        branches: [],
      );
      expect(snap.verificationStage, B2bVerificationStage.registeredPending);
    });

    test('verified stage activates ONLY when a branch is genuinely verified',
        () {
      final branch = B2bBranchSummary(
        placeId: 'p_1',
        name: 'فرع المعادي',
        category: 'طبي ومستشفيات',
        address: 'المعادي، القاهرة',
        features: AccessibilityFeaturesStruct(
          wheelchairEntrance: true,
          ramp: true,
          suitableElevator: true,
          accessibleRestroom: true,
          accessibleParking: true,
        ),
        isGenuinelyVerified: true,
        effectiveVerificationStatus: 'verified',
        verificationEvidence: 'فحص ميداني معتمد بتاريخ 2026-11-15 — ميل المنحدر 1:14',
        rating: 4.8,
        reviewCount: 24,
      );

      final snap = B2bPortalSnapshot(
        businessId: 'biz_1',
        businessName: 'مستشفى السلام',
        category: 'طبي ومستشفيات',
        businessStatus: 'active',
        subscriptionTier: 'free',
        branches: [branch],
      );

      expect(snap.verificationStage, B2bVerificationStage.verifiedWithEvidence);
      expect(snap.averageBranchRating, closeTo(4.8, 0.01));
      expect(snap.averageMobilityScores()?['electric'], 100);
    });

    test('self-assessment readiness reflects facilities + photo evidence', () {
      const partial = B2bSelfAssessment(
        wheelchairEntrance: true,
        ramp: true,
        hasFacilityPhotos: false,
      );
      final withPhotos = partial.copyWith(hasFacilityPhotos: true);
      expect(withPhotos.readinessPercent, partial.readinessPercent + 15);

      const full = B2bSelfAssessment(
        wheelchairEntrance: true,
        ramp: true,
        suitableElevator: true,
        accessibleRestroom: true,
        accessibleParking: true,
        hasFacilityPhotos: true,
      );
      expect(full.readinessPercent, 100);
    });
  });

  testWidgets(
      'B2bVerificationDashboardView navigates all 4 tabs and submits field audit',
      (tester) async {
    final sink = InMemoryAnalyticsSink();
    final analytics = AnalyticsService.forTesting(sink);
    B2bSelfAssessment? submittedAssessment;

    final branch = B2bBranchSummary(
      placeId: 'nmec',
      name: 'المتحف القومي للحضارة',
      category: 'سياحة وثقافة',
      address: 'الفسطاط، القاهرة',
      features: AccessibilityFeaturesStruct(
        wheelchairEntrance: true,
        ramp: true,
        suitableElevator: true,
      ),
      isGenuinelyVerified: true,
      effectiveVerificationStatus: 'verified',
      verificationEvidence: 'قياس ميداني: منحدر 1:12 ومصعد 110 سم',
      rating: 4.9,
      reviewCount: 15,
    );

    final snapshot = B2bPortalSnapshot(
      businessId: 'biz_nmec',
      businessName: 'هيئة المتحف القومي',
      category: 'سياحة وثقافة',
      businessStatus: 'active',
      subscriptionTier: 'pro',
      branches: [branch],
      reportsCount: 2,
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('ar'), Locale('en')],
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: B2bVerificationDashboardView(
            snapshot: snapshot,
            analytics: analytics,
            onRegisterBusiness: () {},
            onRequestFieldAudit: (a) async {
              submittedAssessment = a;
            },
            onContactSales: (_) {},
            onClose: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tab 1: Overview & Ethical Charter
    expect(find.byKey(const Key('b2b_overview_list')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('b2b_ethical_charter')),
      200,
      scrollable: find.descendant(
        of: find.byKey(const Key('b2b_overview_list')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.byKey(const Key('b2b_ethical_charter')), findsOneWidget);

    // Tab 2: Verification & Field Audit request
    await tester.tap(find.byKey(const Key('b2b_tab_verification')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('b2b_verification_list')), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('b2b_request_audit_btn')),
      200,
      scrollable: find.descendant(
        of: find.byKey(const Key('b2b_verification_list')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('b2b_request_audit_btn')));
    await tester.pumpAndSettle();

    expect(submittedAssessment, isNotNull);
    expect(
      sink.events.any((e) => e.name == AnalyticsEvents.fieldAssessmentRequested),
      isTrue,
    );

    // Tab 3: Branches & Evidence
    await tester.tap(find.byKey(const Key('b2b_tab_branches')));
    await tester.pumpAndSettle();
    expect(find.text('المتحف القومي للحضارة'), findsOneWidget);
    expect(find.textContaining('منحدر 1:12'), findsOneWidget);

    // Tab 4: Plans & Subscriptions
    await tester.tap(find.byKey(const Key('b2b_tab_plans')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('b2b_plans_list')), findsOneWidget);
  });
}
