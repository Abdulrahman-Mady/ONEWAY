// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:one_way_egypt/backend/schema/accessibility_reports_record.dart';
import 'package:one_way_egypt/backend/schema/places_record.dart';
import 'package:one_way_egypt/backend/seed_data.dart';
import 'package:one_way_egypt/core/constants/app_constants.dart';
import 'package:one_way_egypt/core/theme/oneway_theme.dart';
import 'package:one_way_egypt/features/account/account_pages.dart';
import 'package:one_way_egypt/features/discovery/place_deduplication_service.dart';
import 'package:one_way_egypt/flutter_flow/flutter_flow_theme.dart';
import 'package:one_way_egypt/pages/submit_accessibility_report/submit_accessibility_report_widget.dart';

class _CapturingReportRef implements DocumentReference<Map<String, dynamic>> {
  _CapturingReportRef(this.id);

  @override
  final String id;

  Map<Object, Object?>? lastUpdateData;

  @override
  String get path => 'accessibilityReports/$id';

  @override
  Future<void> update(Map<Object, Object?> data) async {
    lastUpdateData = Map<Object, Object?>.from(data);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePlaceRef implements DocumentReference<Map<String, dynamic>> {
  _FakePlaceRef(this.id);

  @override
  final String id;

  @override
  String get path => 'places/$id';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Zero Demo Data, 3 Canonical Roles & Traditional Registration Only', () {
    test('OnewayDataSeeder has zero bundled demo/seed places', () {
      expect(OnewayDataSeeder.initialPlaces, isEmpty);
    });

    test('AppConstants enforces strictly 3 canonical user roles', () {
      expect(
        AppConstants.validUserRoles,
        equals(['user', 'businessOwner', 'admin']),
      );
    });

    test('PlacesRecord effectiveVerificationStatus distinguishes field audit vs pending audit',
        () {
      final communityOrOwnerPlace = PlacesRecord.getDocumentFromData(
        {
          'name': 'مستشفى دار الفؤاد',
          'category': 'طبي ومستشفيات',
          'verification_status': 'verified',
          'data_source': 'business_owner',
          'verification_evidence': '',
        },
        _FakePlaceRef('owner_1'),
      );
      expect(
        communityOrOwnerPlace.effectiveVerificationStatus,
        'pendingFieldAudit',
      );

      final auditedPlace = PlacesRecord.getDocumentFromData(
        {
          'name': 'مستشفى مفحوص ميدانياً',
          'category': 'طبي ومستشفيات',
          'verification_status': 'verified',
          'verification_evidence': 'تم الفحص الميداني بواسطة فريق ONEWAY',
        },
        _FakePlaceRef('audited_1'),
      );
      expect(auditedPlace.effectiveVerificationStatus, 'verified');
    });
  });

  group('PlaceDeduplicationService — Duplicate & Ownership Detection', () {
    final existingPlaces = [
      PlacesRecord.getDocumentFromData(
        {
          'name': 'كافيه النيل المجهز',
          'governorate': 'القاهرة',
          'city': 'الزمالك',
          'address': 'شارع 26 يوليو، الزمالك',
          'phone_number': '01012345678',
          'location': const GeoPoint(30.0631, 31.2212),
          'business_id': '',
        },
        _FakePlaceRef('community_cafe_1'),
      ),
      PlacesRecord.getDocumentFromData(
        {
          'name': 'مستشفى الشفاء التخصصي',
          'governorate': 'الجيزة',
          'city': '6 أكتوبر',
          'address': 'المحور المركزي، 6 أكتوبر',
          'phone_number': '+20 111 987 6543',
          'location': const GeoPoint(29.9725, 30.9440),
          'business_id': 'biz_shifa_1',
        },
        _FakePlaceRef('owner_hospital_1'),
      ),
    ];

    test('flags unowned community place as existingUnownedPlace (claimable by owner, blocked for duplicate suggestion)', () {
      final res = PlaceDeduplicationService.findMatchInList(
        existingPlaces: existingPlaces,
        candidateName: 'كافيه النيل المجهز',
        candidateGovernorate: 'القاهرة',
      );

      expect(res, isNotNull);
      expect(res!.kind, DuplicateMatchKind.existingUnownedPlace);
      expect(res.place.reference.id, 'community_cafe_1');
    });

    test('flags owner-registered venue by normalized phone or GPS proximity as alreadyOwnedByBusiness', () {
      final byPhone = PlaceDeduplicationService.findMatchInList(
        existingPlaces: existingPlaces,
        candidateName: 'مستشفى الشفاء',
        candidatePhone: '01119876543',
        candidateGovernorate: 'الجيزة',
      );
      expect(byPhone, isNotNull);
      expect(byPhone!.kind, DuplicateMatchKind.alreadyOwnedByBusiness);
      expect(byPhone.place.businessId, 'biz_shifa_1');

      final byGpsAndSimilarName = PlaceDeduplicationService.findMatchInList(
        existingPlaces: existingPlaces,
        candidateName: 'مستشفي الشفاء التخصصى',
        candidateLocation: const GeoPoint(29.9726, 30.9441),
      );
      expect(byGpsAndSimilarName, isNotNull);
      expect(
        byGpsAndSimilarName!.kind,
        DuplicateMatchKind.alreadyOwnedByBusiness,
      );
    });

    test('allows genuinely new non-duplicate place', () {
      final res = PlaceDeduplicationService.findMatchInList(
        existingPlaces: existingPlaces,
        candidateName: 'مكتبة الإسكندرية الجديدة',
        candidateGovernorate: 'الإسكندرية',
        candidatePhone: '034839999',
        candidateLocation: const GeoPoint(31.2089, 29.9092),
      );
      expect(res, isNull);
    });
  });

  group('SubmitAccessibilityReportWidget — Registered Places Only', () {
    testWidgets(
        'requires selecting an existing registered place and never allows road/free-text barrier reports',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final registeredPlace = PlacesRecord.getDocumentFromData(
        {
          'name': 'مول مصر',
          'category': 'تسوق ومراكز تجارية',
          'city': '6 أكتوبر',
          'governorate': 'الجيزة',
          'verification_status': 'verified',
        },
        _FakePlaceRef('mall_of_egypt'),
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: const [Locale('ar'), Locale('en')],
          theme: buildOnewayTheme(LightModeTheme(), Brightness.light),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: SubmitAccessibilityReportWidget(
              placesLoader: () async => [registeredPlace],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Notice clearly states reports are strictly for existing registered places
      expect(
        find.textContaining('لا يُقبل الإبلاغ عن الشوارع العامة'),
        findsOneWidget,
      );
      expect(find.textContaining('عائق في الطريق'), findsNothing);

      // Search & select the registered place
      await tester.enterText(
        find.byKey(const Key('report_place_search_field')),
        'مول مصر',
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('report_place_option_mall_of_egypt')),
      );
      await tester.pumpAndSettle();

      // Selected place banner is locked in with place name & category
      expect(find.text('مول مصر'), findsOneWidget);
      expect(find.textContaining('تسوق ومراكز تجارية'), findsOneWidget);
    });
  });

  group('Report Clarification Edit & Resubmit Flow', () {
    testWidgets(
        'reporter edits needsMoreInformation report, adds notes, and resubmits back to unreplied status',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final reportRef = _CapturingReportRef('rep_clarify_1');
      final report = AccessibilityReportsRecord.getDocumentFromData(
        {
          'place_id': 'dokki_metro_station',
          'place_name': 'محطة مترو الدقي',
          'createdBy': 'user_123',
          'user_name': 'محمد أحمد',
          'problemCategory': 'مصعد غير مناسب',
          'description': 'المصعد متوقف عن العمل.',
          'photo_urls': <String>[],
          'status': 'needsMoreInformation',
          'admin_notes': 'يرجى تحديد أي مخرج أو رصيف يوجد به المصعد المعطل.',
        },
        reportRef,
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: const [Locale('ar'), Locale('en')],
          theme: buildOnewayTheme(LightModeTheme(), Brightness.light),
          home: Scaffold(
            body: ReportClarificationSheet(report: report),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('يرجى تحديد أي مخرج أو رصيف يوجد به المصعد المعطل.'),
        findsOneWidget,
      );

      final notesField = find.widgetWithText(
        TextField,
        'إضافة ملاحظات / توضيح للإدارة *',
      );
      expect(notesField, findsOneWidget);
      await tester.enterText(
        notesField,
        'المصعد الموجود في اتجاه حلوان بجانب شباك التذاكر الرئيسي.',
      );

      final submitBtn = find.text('إعادة إرسال البلاغ للإدارة بعد التعديل');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(reportRef.lastUpdateData, isNotNull);
      expect(reportRef.lastUpdateData!['status'], 'new');
      expect(reportRef.lastUpdateData!['admin_notes'], '');
      expect(
        reportRef.lastUpdateData!['previous_admin_notes'],
        'يرجى تحديد أي مخرج أو رصيف يوجد به المصعد المعطل.',
      );
      expect(
        reportRef.lastUpdateData!['user_notes'],
        'المصعد الموجود في اتجاه حلوان بجانب شباك التذاكر الرئيسي.',
      );
    });
  });
}
