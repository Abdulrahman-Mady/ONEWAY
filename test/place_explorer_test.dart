// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:one_way_egypt/backend/schema/places_record.dart';
import 'package:one_way_egypt/core/theme/oneway_theme.dart';
import 'package:one_way_egypt/features/discovery/discovery_pages.dart';
import 'package:one_way_egypt/flutter_flow/flutter_flow_theme.dart';

class _FakeDocRef implements DocumentReference<Map<String, dynamic>> {
  _FakeDocRef(this.id);

  @override
  final String id;

  @override
  String get path => 'places/$id';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

PlacesRecord _makePlace({
  required String id,
  required String name,
  required String category,
  String address = 'شارع رئيسي',
  String city = 'القاهرة',
  String governorate = 'القاهرة',
  String openingHours = 'طوارئ 24 ساعة',
  double rating = 4.8,
  bool entrance = true,
  bool ramp = true,
  bool elevator = true,
  bool restroom = true,
  bool parking = true,
  String verificationEvidence = '',
}) {
  return PlacesRecord.getDocumentFromData(
    {
      'name': name,
      'category': category,
      'description': '$name - $category',
      'photo_url': '',
      'address': address,
      'city': city,
      'governorate': governorate,
      'location': const GeoPoint(30.0308, 31.2294),
      'opening_hours': openingHours,
      'rating': rating,
      'verification_status': 'verified',
      'verification_evidence': verificationEvidence,
      'accessibility_features': {
        'wheelchairEntrance': entrance,
        'ramp': ramp,
        'suitableElevator': elevator,
        'accessibleRestroom': restroom,
        'accessibleParking': parking,
      },
    },
    _FakeDocRef(id),
  );
}

List<PlacesRecord> _samplePlaces() => [
      _makePlace(
        id: 'kasr_alainy',
        name: 'مستشفى قصر العيني الفرنساوي',
        category: 'طبي ومستشفيات',
        address: 'شارع قصر العيني، منيل الروضة',
        city: 'منيل الروضة',
        governorate: 'القاهرة',
        rating: 4.8,
        verificationEvidence: 'فحص ميداني معتمد 2026',
      ),
      _makePlace(
        id: 'dar_al_fouad',
        name: 'مستشفى دار الفؤاد (6 أكتوبر)',
        category: 'طبي ومستشفيات',
        address: 'امتداد محور 26 يوليو، 6 أكتوبر',
        city: '6 أكتوبر',
        governorate: 'الجيزة',
        rating: 4.9,
      ),
      _makePlace(
        id: 'mall_of_egypt',
        name: 'مول مصر (Mall of Egypt)',
        category: 'تسوق ومراكز تجارية',
        address: 'طريق الواحات، مدينة 6 أكتوبر',
        city: '6 أكتوبر',
        governorate: 'الجيزة',
        openingHours: '10:00 ص - 11:00 م',
        rating: 4.9,
      ),
      _makePlace(
        id: 'greater_cairo_library',
        name: 'مكتبة القاهرة الكبرى (الزمالك)',
        category: 'سياحة وثقافة',
        address: '15 شارع محمد مظهر، الزمالك',
        city: 'الزمالك',
        governorate: 'القاهرة',
        openingHours: '09:00 ص - 04:00 م',
        rating: 3.6,
        entrance: false,
        ramp: true,
        elevator: false,
        restroom: false,
        parking: false,
      ),
    ];

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('PlaceCategoryCatalog', () {
    test('resolves HomeDashboard and AI category aliases to canonical specs', () {
      expect(PlaceCategoryCatalog.resolve('مستشف')?.id, 'medical');
      expect(PlaceCategoryCatalog.resolve('طبي')?.id, 'medical');
      expect(PlaceCategoryCatalog.resolve('طبي ومستشفيات')?.id, 'medical');
      expect(PlaceCategoryCatalog.resolve('Hospital')?.id, 'medical');

      expect(PlaceCategoryCatalog.resolve('تسوق')?.id, 'shopping');
      expect(PlaceCategoryCatalog.resolve('تسوق ومراكز تجارية')?.id, 'shopping');

      expect(PlaceCategoryCatalog.resolve('مواصلات')?.id, 'transit');
      expect(PlaceCategoryCatalog.resolve('مواصلات ونقل')?.id, 'transit');

      expect(PlaceCategoryCatalog.resolve('ثقاف')?.id, 'culture');
      expect(PlaceCategoryCatalog.resolve('سياحة وثقافة')?.id, 'culture');

      expect(PlaceCategoryCatalog.resolve('تعليم')?.id, 'education');
      expect(PlaceCategoryCatalog.resolve('تعليم وجامعات')?.id, 'education');

      expect(PlaceCategoryCatalog.resolve('مطعم')?.id, 'dining');
      expect(PlaceCategoryCatalog.resolve('مرافق')?.id, 'facilities');
    });

    test('returns null for empty or overly short non-matching tokens', () {
      expect(PlaceCategoryCatalog.resolve(null), isNull);
      expect(PlaceCategoryCatalog.resolve(''), isNull);
      expect(PlaceCategoryCatalog.resolve('م'), isNull);
    });
  });

  group('PlaceExplorerPage interactions', () {
    Widget wrapApp(
      Widget child, {
      Locale locale = const Locale('ar'),
      Brightness brightness = Brightness.light,
      Size size = const Size(390, 844),
      double textScale = 1.0,
    }) {
      final brand =
          brightness == Brightness.dark ? DarkModeTheme() : LightModeTheme();
      return MaterialApp(
        locale: locale,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('ar'), Locale('en')],
        theme: buildOnewayTheme(brand, brightness),
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
      );
    }

    testWidgets(
        'opening with Home Hospitals param filters places and shows Hospitals title',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        wrapApp(
          PlaceExplorerPage(
            initialCategory: 'مستشف',
            placesOverride: _samplePlaces(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header displays Hospitals category title & result count
      expect(find.text('المستشفيات والمراكز الطبية'), findsOneWidget);
      expect(find.text('2 أماكن مهيأة ومتاحة'), findsOneWidget);

      // Both hospitals appear; Mall of Egypt and Library are filtered out
      expect(find.text('مستشفى قصر العيني الفرنساوي'), findsOneWidget);
      expect(find.text('مستشفى دار الفؤاد (6 أكتوبر)'), findsOneWidget);
      expect(find.text('مول مصر (Mall of Egypt)'), findsNothing);
      expect(find.text('مكتبة القاهرة الكبرى (الزمالك)'), findsNothing);

      // Ethical verification transparency: field-audited hospital shows 'موثق ميدانياً',
      // unaudited hospital shows 'بانتظار فحص ميداني' (never falsely field-verified).
      expect(find.text('بانتظار فحص ميداني'), findsOneWidget);

      // Filtering to genuinely verified only keeps only Kasr Al-Ainy
      await tester.scrollUntilVisible(
        find.byKey(const Key('filter_verified')),
        150,
        scrollable: find.descendant(
          of: find.byKey(const Key('explorer_filter_bar')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.tap(find.byKey(const Key('filter_verified')));
      await tester.pumpAndSettle();

      expect(find.text('مستشفى قصر العيني الفرنساوي'), findsOneWidget);
      expect(find.text('مستشفى دار الفؤاد (6 أكتوبر)'), findsNothing);

      // Resetting restores all 4 places
      await tester.tap(find.byKey(const Key('explorer_reset_filters_btn')));
      await tester.pumpAndSettle();

      expect(find.text('استكشف الأماكن'), findsOneWidget);
      expect(find.text('4 أماكن مهيأة ومتاحة'), findsOneWidget);
    });

    testWidgets('empty category shows helpful empty state with Show All action',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        wrapApp(
          PlaceExplorerPage(
            initialCategory: 'مطعم',
            placesOverride: _samplePlaces(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('لا توجد أماكن في «مطاعم» حالياً'), findsOneWidget);
      expect(find.byKey(const Key('empty_state_show_all_btn')), findsOneWidget);

      await tester.tap(find.byKey(const Key('empty_state_show_all_btn')));
      await tester.pumpAndSettle();

      expect(find.text('4 أماكن مهيأة ومتاحة'), findsOneWidget);
      expect(find.text('مستشفى دار الفؤاد (6 أكتوبر)'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('مستشفى قصر العيني الفرنساوي'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('مستشفى قصر العيني الفرنساوي'), findsOneWidget);
    });

    testWidgets('search filters by Arabic-normalized city and name',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        wrapApp(
          PlaceExplorerPage(
            placesOverride: _samplePlaces(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('explorer_search_field')),
        'الزمالك',
      );
      await tester.pumpAndSettle();

      expect(find.text('مكتبة القاهرة الكبرى (الزمالك)'), findsOneWidget);
      expect(find.text('مستشفى قصر العيني الفرنساوي'), findsNothing);
    });
  });

  group('PlaceExplorerPage responsive & theme overflow audit', () {
    const viewports = <(String, Size, double, Locale, Brightness)>[
      ('small-phone-320-ar', Size(320, 568), 1.0, Locale('ar'), Brightness.light),
      ('small-phone-1.3x-ar', Size(320, 568), 1.3, Locale('ar'), Brightness.light),
      ('standard-phone-dark', Size(390, 844), 1.0, Locale('ar'), Brightness.dark),
      ('landscape-phone-ar', Size(667, 375), 1.0, Locale('ar'), Brightness.light),
      ('tablet-portrait-ar', Size(768, 1024), 1.15, Locale('ar'), Brightness.light),
      ('small-phone-en-ltr', Size(320, 568), 1.25, Locale('en'), Brightness.light),
    ];

    for (final (label, size, scale, locale, brightness) in viewports) {
      testWidgets('zero RenderFlex overflow on $label', (tester) async {
        final errors = <FlutterErrorDetails>[];
        final previousOnError = FlutterError.onError;

        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final brand =
            brightness == Brightness.dark ? DarkModeTheme() : LightModeTheme();

        FlutterError.onError = (details) => errors.add(details);
        try {
          await tester.pumpWidget(
            MaterialApp(
              locale: locale,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              supportedLocales: const [Locale('ar'), Locale('en')],
              theme: buildOnewayTheme(brand, brightness),
              home: Directionality(
                textDirection: locale.languageCode == 'en'
                    ? TextDirection.ltr
                    : TextDirection.rtl,
                child: MediaQuery(
                  data: MediaQueryData(
                    size: size,
                    textScaler: TextScaler.linear(scale),
                  ),
                  child: PlaceExplorerPage(
                    initialCategory: 'مستشف',
                    placesOverride: _samplePlaces(),
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
          reason: 'Overflow detected on $label: '
              '${overflowErrors.map((e) => e.exceptionAsString()).join('\n')}',
        );
      });
    }
  });
}
