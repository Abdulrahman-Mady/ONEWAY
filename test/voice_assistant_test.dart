// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:one_way_egypt/backend/schema/places_record.dart';
import 'package:one_way_egypt/core/theme/oneway_theme.dart';
import 'package:one_way_egypt/features/ai/oneway_ai_engine.dart';
import 'package:one_way_egypt/features/emergency/emergency_service.dart';
import 'package:one_way_egypt/flutter_flow/flutter_flow_theme.dart';
import 'package:one_way_egypt/flutter_flow/flutter_flow_util.dart';
import 'package:one_way_egypt/pages/voice_assistant_interface/voice_assistant_interface_widget.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Minimal fake [DocumentReference] so [PlacesRecord] can be instantiated in
/// pure unit & widget tests without initializing Firebase.
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
  required String city,
  required String governorate,
  required double lat,
  required double lng,
  String phone = '+20238356030',
  String hours = '24 ساعة',
  double rating = 4.8,
  bool entrance = true,
  bool ramp = true,
  bool elevator = true,
  bool restroom = true,
  bool parking = true,
  String obstacles = 'لا يوجد عوائق',
  String verificationEvidence = '',
}) {
  return PlacesRecord.getDocumentFromData(
    {
      'name': name,
      'category': category,
      'description': '$name - $category في $city',
      'address': 'شارع رئيسي، $city',
      'city': city,
      'governorate': governorate,
      'location': GeoPoint(lat, lng),
      'phone_number': phone,
      'opening_hours': hours,
      'rating': rating,
      'verification_status': 'verified',
      'verification_evidence': verificationEvidence,
      'accessibility_features': {
        'wheelchairEntrance': entrance,
        'ramp': ramp,
        'suitableElevator': elevator,
        'accessibleRestroom': restroom,
        'accessibleParking': parking,
        'corridorWidth': 'واسع (180 سم)',
        'entranceObstacles': obstacles,
      },
    },
    _FakeDocRef(id),
  );
}

Position _fakePosition(double lat, double lng) => Position(
      longitude: lng,
      latitude: lat,
      timestamp: DateTime(2026, 11, 24),
      accuracy: 5,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  late List<PlacesRecord> samplePlaces;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FFAppState.reset();
    await FFAppState().initializePersistedState();
    OnewayAIEngine.resetProvidersForTesting();

    samplePlaces = [
      _makePlace(
        id: 'dar_al_fouad',
        name: 'مستشفى دار الفؤاد (6 أكتوبر)',
        category: 'طبي ومستشفيات',
        city: '6 أكتوبر',
        governorate: 'الجيزة',
        lat: 29.9882,
        lng: 30.9577,
        phone: '+20238356030',
        rating: 4.9,
        verificationEvidence: 'فحص ميداني معتمد بالصور 2026',
      ),
      _makePlace(
        id: 'kasr_alainy',
        name: 'مستشفى قصر العيني الفرنساوي',
        category: 'طبي ومستشفيات',
        city: 'منيل الروضة',
        governorate: 'القاهرة',
        lat: 30.0308,
        lng: 31.2294,
        phone: '+20223654060',
        rating: 4.8,
        restroom: false,
      ),
      _makePlace(
        id: 'mall_of_egypt',
        name: 'مول مصر (Mall of Egypt)',
        category: 'تسوق ومراكز تجارية',
        city: '6 أكتوبر',
        governorate: 'الجيزة',
        lat: 29.9722,
        lng: 31.0163,
        phone: '+20235390000',
        rating: 4.9,
      ),
      _makePlace(
        id: 'greater_cairo_library',
        name: 'مكتبة القاهرة الكبرى (الزمالك)',
        category: 'سياحة وثقافة',
        city: 'الزمالك',
        governorate: 'القاهرة',
        lat: 30.0631,
        lng: 31.2212,
        phone: '+20227362278',
        rating: 3.6,
        entrance: false,
        ramp: true,
        elevator: false,
        restroom: false,
        parking: false,
        obstacles: 'درجات بالمدخل الرئيسي والمنحدر بالبوابة الجانبية',
      ),
    ];

    OnewayAIEngine.placesProvider = () async => samplePlaces;
    OnewayAIEngine.remoteAssistantCaller = (_) async => {'fallback': true};
    OnewayAIEngine.mobilityProvider = () => 'كرسي متحرك كهربائي';
    OnewayAIEngine.uidProvider = () => 'test_uid';
  });

  tearDown(() {
    OnewayAIEngine.resetProvidersForTesting();
  });

  group('OnewayAIEngine — Emergency & Egyptian Hotlines', () {
    test('triggers honest SOS flow without calling remote LLM', () async {
      var sosCalled = false;
      OnewayAIEngine.sosTrigger = ({lat, lng, customNote}) async {
        sosCalled = true;
        return EmergencyResult(
          success: true,
          message: 'تم فتح مسودة رسالة الاستغاثة للمرافق (أحمد).',
          contactName: 'أحمد',
          phone: '01012345678',
          mapsUrl: 'https://maps.google.com/?q=30.03,31.23',
          draftOpened: true,
          locationStatus: SosLocationStatus.gps,
        );
      };

      final res = await OnewayAIEngine.processQuery(
        null,
        'اطلب استغاثة من مرافقي وابعث موقعي',
      );
      expect(sosCalled, isTrue);
      expect(res.intent, AIIntentType.emergency);
      expect(res.emergencyResult?.draftOpened, isTrue);
      expect(res.spokenText, isNot(contains('https://')));
      expect(res.quickActions.any((a) => a.phoneNumber == '01012345678'), isTrue);
    });

    test('dials official Egyptian hotlines (Ambulance 123, Disability Council 16736)', () async {
      final amb = await OnewayAIEngine.processQuery(null, 'اتصل بالإسعاف فوراً');
      expect(amb.intent, AIIntentType.emergency);
      expect(amb.primaryAction?.type, AssistantActionType.callPhone);
      expect(amb.primaryAction?.phoneNumber, '123');
      expect(amb.primaryAction?.autoExecute, isTrue);

      final council = await OnewayAIEngine.processQuery(
        null,
        'رقم المجلس القومي لذوي الإعاقة',
      );
      expect(council.intent, AIIntentType.egyptGuide);
      expect(council.replyText, contains('16736'));
      expect(council.quickActions.any((a) => a.phoneNumber == '16736'), isTrue);

      final allHotlines = await OnewayAIEngine.processQuery(
        null,
        'Show all official hotlines',
      );
      expect(allHotlines.isEnglish, isTrue);
      expect(allHotlines.quickActions.length, greaterThanOrEqualTo(6));
    });

    test('never falsely triggers SOS on normal Egyptian help or hospital queries', () async {
      var sosCalled = false;
      OnewayAIEngine.sosTrigger = ({lat, lng, customNote}) async {
        sosCalled = true;
        return EmergencyResult(
          success: true,
          message: 'SOS',
        );
      };

      final helpSearch = await OnewayAIEngine.processQuery(
        null,
        'ساعدني ألاقي مستشفى مجهزة في القاهرة',
      );
      expect(sosCalled, isFalse);
      expect(helpSearch.intent, AIIntentType.placeSearch);
      expect(helpSearch.replyText, contains('لقيتلك'));

      final erDept = await OnewayAIEngine.processQuery(
        null,
        'أرقام الطوارئ الرسمية في مصر',
      );
      expect(sosCalled, isFalse);
      expect(erDept.intent, AIIntentType.egyptGuide);

      final ownerPortal = await OnewayAIEngine.processQuery(
        null,
        'افتح لوحة صاحب المكان عشان أعدل مكاني',
      );
      expect(sosCalled, isFalse);
      expect(ownerPortal.intent, AIIntentType.navigation);
      expect(ownerPortal.primaryAction?.route, 'BusinessAdminDashboard');
    });
  });

  group('OnewayAIEngine — Live App & Accessibility Controls', () {
    test('handles font size, high contrast, dark mode, language & mobility profile', () async {
      final session = AssistantSession();

      final font = await OnewayAIEngine.processQuery(null, 'كبّر الخط', session: session);
      expect(font.intent, AIIntentType.appControl);
      expect(font.primaryAction?.settingKey, 'font_scale');
      expect(font.primaryAction?.settingValue, 'increase');

      final contrast = await OnewayAIEngine.processQuery(null, 'شغّل التباين العالي', session: session);
      expect(contrast.primaryAction?.settingKey, 'high_contrast');
      expect(contrast.primaryAction?.settingValue, isTrue);

      final dark = await OnewayAIEngine.processQuery(null, 'شغّل الوضع الليلي', session: session);
      expect(dark.primaryAction?.settingKey, 'theme_mode');
      expect(dark.primaryAction?.settingValue, 'dark');

      final eng = await OnewayAIEngine.processQuery(null, 'حوّل للإنجليزي', session: session);
      expect(eng.primaryAction?.settingKey, 'language');
      expect(eng.primaryAction?.settingValue, 'en');
      expect(session.localeCode, 'en');

      final mob = await OnewayAIEngine.processQuery(
        null,
        'أنا بستخدم كرسي متحرك يدوي',
        session: session,
      );
      expect(mob.intent, AIIntentType.appControl);
      expect(mob.primaryAction?.settingKey, 'mobility_type');
      expect(mob.primaryAction?.settingValue, 'كرسي متحرك');

      // Voice-only access needs & direct support contact commands
      final needs = await OnewayAIEngine.processQuery(
        null,
        'احفظ احتياجاتي منحدر وحمام مجهز ومصعد',
        session: session,
      );
      expect(needs.intent, AIIntentType.appControl);
      expect(needs.primaryAction?.settingKey, 'access_needs');
      expect(
        needs.primaryAction?.settingValue,
        containsAll(['suitable_ramp', 'accessible_restroom', 'accessible_elevator']),
      );

      final wa = await OnewayAIEngine.processQuery(
        null,
        'كلم الدعم واتساب',
        session: session,
      );
      expect(wa.primaryAction?.type, AssistantActionType.openUrl);
      expect(wa.primaryAction?.url, contains('201023266750'));

      final mail = await OnewayAIEngine.processQuery(
        null,
        'ابعت ايميل للدعم',
        session: session,
      );
      expect(mail.primaryAction?.type, AssistantActionType.openUrl);
      expect(mail.primaryAction?.url, contains('mailto:bdalrhmnmady93@gmail.com'));

      final profile = await OnewayAIEngine.processQuery(
        null,
        'اقرأ بياناتي',
        session: session,
      );
      expect(profile.intent, AIIntentType.userData);
      expect(profile.spokenText, isNotEmpty);
    });
  });

  group('OnewayAIEngine — GPS Search, Personalized Scoring & Multi-Turn Actions', () {
    test('sorts nearest hospitals using GPS distance and supports multi-turn follow-ups', () async {
      // Position right next to Kasr Al-Ainy in Central Cairo
      OnewayAIEngine.positionProvider = () async => _fakePosition(30.0310, 31.2290);
      final session = AssistantSession(mobilityType: 'كرسي متحرك كهربائي');

      // Turn 1: Search nearest hospital with ramp
      final search = await OnewayAIEngine.processQuery(
        null,
        'أقرب مستشفى فيها منحدر',
        session: session,
      );
      expect(search.intent, AIIntentType.placeSearch);
      expect(search.places, isNotEmpty);
      expect(search.places.first.reference.id, 'kasr_alainy');
      expect(search.placeMatches.first.distanceKm, lessThan(1.0));
      expect(search.followUpSuggestions, isNotEmpty);

      // Turn 2: Contextual directions to "الأول"
      final dirs = await OnewayAIEngine.processQuery(
        null,
        'وديني للمكان الأول',
        session: session,
      );
      expect(dirs.intent, AIIntentType.placeAction);
      expect(dirs.primaryAction?.type, AssistantActionType.directions);
      expect(dirs.primaryAction?.place?.reference.id, 'kasr_alainy');

      // Turn 3: Save "التاني" to favorites
      final fav = await OnewayAIEngine.processQuery(
        null,
        'احفظ التاني في المفضلة',
        session: session,
      );
      expect(fav.primaryAction?.type, AssistantActionType.toggleFavorite);
      expect(fav.primaryAction?.place?.reference.id, 'dar_al_fouad');
      expect(fav.primaryAction?.addFavorite, isTrue);

      // Turn 4: Call "الأول"
      final call = await OnewayAIEngine.processQuery(
        null,
        'اتصل بالأول',
        session: session,
      );
      expect(call.primaryAction?.type, AssistantActionType.callPhone);
      expect(call.primaryAction?.phoneNumber, '+20223654060');

      // Turn 5: Compare the two places
      final cmp = await OnewayAIEngine.processQuery(
        null,
        'قارن بين الأول والتاني',
        session: session,
      );
      expect(cmp.intent, AIIntentType.placeDetails);
      expect(cmp.places.length, 2);
      expect(cmp.replyText, contains('دار الفؤاد'));
    });

    test('honestly reports place accessibility details & missing features', () async {
      final res = await OnewayAIEngine.processQuery(
        null,
        'هل مكتبة القاهرة الكبرى فيها مصعد؟',
      );
      expect(res.intent, AIIntentType.placeDetails);
      expect(res.places.first.reference.id, 'greater_cairo_library');
      expect(res.replyText, contains('مصعد مناسب: لا ❌'));
      expect(res.replyText, contains('غير موثقة ميدانياً'));
    });
  });

  group('OnewayAIEngine — Personal Data, Navigation, Egypt Guide & Cloud Mapping', () {
    test('reads personal favorites, reports, notifications and GPS location', () async {
      OnewayAIEngine.favoritesProvider = () async => const [
            UserFavoriteSummary(
              placeId: 'mall_of_egypt',
              placeName: 'مول مصر',
            ),
          ];
      OnewayAIEngine.reportsProvider = () async => const [
            UserReportSummary(
              placeName: 'محطة مترو العتبة',
              problemCategory: 'مصعد معطل',
              status: 'قيد المراجعة',
            ),
          ];
      OnewayAIEngine.notificationsProvider = () async => const [
            UserNotificationSummary(
              title: 'تحديث البلاغ',
              body: 'تمت مراجعة بلاغك بنجاح',
              isRead: false,
            ),
          ];
      OnewayAIEngine.positionProvider = () async => _fakePosition(30.0444, 31.2357);

      final favRes = await OnewayAIEngine.processQuery(null, 'إيه في مفضلتي؟');
      expect(favRes.intent, AIIntentType.userData);
      expect(favRes.replyText, contains('مول مصر'));

      final repRes = await OnewayAIEngine.processQuery(null, 'أخبار بلاغاتي');
      expect(repRes.intent, AIIntentType.userData);
      expect(repRes.replyText, contains('محطة مترو العتبة'));

      final notifRes = await OnewayAIEngine.processQuery(null, 'عندي إشعارات جديدة؟');
      expect(notifRes.intent, AIIntentType.userData);
      expect(notifRes.replyText, contains('1 إشعار غير مقروء'));

      final locRes = await OnewayAIEngine.processQuery(null, 'أنا فين دلوقتي؟');
      expect(locRes.intent, AIIntentType.userData);
      expect(locRes.replyText, contains('30.04440'));
    });

    test('navigates all key routes with category deep-linking & Egypt Guide answers', () async {
      final mapHosp = await OnewayAIEngine.processQuery(null, 'افتح الخريطة على المستشفيات');
      expect(mapHosp.intent, AIIntentType.navigation);
      expect(mapHosp.primaryAction?.route, 'ExploreMap');
      expect(mapHosp.primaryAction?.routeParams['category'], 'طبي');

      final suggest = await OnewayAIEngine.processQuery(null, 'عايز أقترح مكان جديد');
      expect(suggest.primaryAction?.route, 'SuggestPlace');

      final card = await OnewayAIEngine.processQuery(null, 'خطوات بطاقة الخدمات المتكاملة');
      expect(card.intent, AIIntentType.egyptGuide);
      expect(card.quickActions.any((a) => a.url == 'https://rdis.moss.gov.eg/'), isTrue);

      final law10 = await OnewayAIEngine.processQuery(null, 'What are my rights in Law 10 of 2018?');
      expect(law10.intent, AIIntentType.egyptGuide);
      expect(law10.isEnglish, isTrue);
      expect(law10.replyText, contains('16736'));
    });

    test('maps rich Gemini cloud response including interactionId and follow-ups', () async {
      OnewayAIEngine.remoteAssistantCaller = (_) async => {
            'fallback': false,
            'reply': 'أنصحك بمول مصر في 6 أكتوبر لأنه مهيأ بالكامل.',
            'spokenReply': 'أنصحك بمول مصر في 6 أكتوبر.',
            'action': 'open_place',
            'actionParams': {},
            'placeIds': ['mall_of_egypt'],
            'followUpSuggestions': ['وديني للمول', 'اتصل بمول مصر'],
            'interactionId': 'v1_test_interaction_123',
          };

      final session = AssistantSession();
      final res = await OnewayAIEngine.processQuery(
        null,
        'اقترحلي خروجة حلوة يوم الجمعة بالكرسي',
        session: session,
      );
      expect(res.source, 'cloud');
      expect(res.places.first.reference.id, 'mall_of_egypt');
      expect(res.primaryAction?.type, AssistantActionType.openPlace);
      expect(session.lastInteractionId, 'v1_test_interaction_123');
      expect(res.followUpSuggestions, hasLength(2));
    });
  });

  group('VoiceAssistantInterfaceWidget — Responsive UI & Multi-Turn Flow', () {
    Widget wrapWidget({
      Locale locale = const Locale('ar'),
      double textScale = 1.0,
    }) {
      return ChangeNotifierProvider<FFAppState>.value(
        value: FFAppState(),
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('ar'), Locale('en')],
          theme: buildOnewayTheme(LightModeTheme(), Brightness.light),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
            ),
            child: child!,
          ),
          home: const VoiceAssistantInterfaceWidget(
            enableAutoGreeting: false,
            enableSpeechInit: false,
          ),
        ),
      );
    }

    testWidgets('renders with zero overflow on 320px compact phone at 1.45x max font scale (AR & EN)', (tester) async {
      final errors = <FlutterErrorDetails>[];
      final oldHandler = FlutterError.onError;
      FlutterError.onError = errors.add;
      addTearDown(() => FlutterError.onError = oldHandler);

      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        wrapWidget(locale: const Locale('ar'), textScale: 1.45),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('أهلاً بك في مساعد وان واي الذكي'), findsOneWidget);
      expect(find.text('أقدر أساعدك إزاي؟'), findsOneWidget);
      expect(find.byKey(const Key('voice_assistant_mic_btn')), findsOneWidget);
      expect(find.byKey(const Key('voice_assistant_keyboard_btn')), findsOneWidget);
      expect(find.byKey(const Key('voice_assistant_capabilities_btn')), findsOneWidget);
      expect(errors.where((e) => e.toString().contains('overflowed')), isEmpty);

      // Switch to English LTR at 1.45x max font scale
      await FFAppState().setLocaleCode('en');
      await tester.pumpWidget(
        wrapWidget(locale: const Locale('en'), textScale: 1.45),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(errors.where((e) => e.toString().contains('overflowed')), isEmpty);
      await FFAppState().setLocaleCode('ar');
    });

    testWidgets('sends multi-turn queries, renders enriched place cards, and keeps bottom dock visible at 1.45x', (tester) async {
      final errors = <FlutterErrorDetails>[];
      final oldHandler = FlutterError.onError;
      FlutterError.onError = errors.add;
      addTearDown(() => FlutterError.onError = oldHandler);

      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrapWidget(textScale: 1.45));
      await tester.pump(const Duration(milliseconds: 100));

      // Open keyboard input
      await tester.tap(find.byKey(const Key('voice_assistant_keyboard_btn')));
      await tester.pump(const Duration(milliseconds: 150));

      // Send a place search query
      await tester.enterText(
        find.byKey(const Key('voice_assistant_text_input')),
        'عايز مول مجهز في 6 أكتوبر',
      );
      await tester.tap(find.byKey(const Key('voice_assistant_send_btn')));
      await tester.pump(const Duration(milliseconds: 300));

      // Place card & compatibility badge rendered with zero overflow
      expect(find.textContaining('مول مصر'), findsWidgets);
      expect(errors.where((e) => e.toString().contains('overflowed')), isEmpty);

      // Hide text input and confirm bottom mic dock is STILL visible!
      await tester.tap(find.byKey(const Key('voice_assistant_keyboard_btn')));
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.byKey(const Key('voice_assistant_mic_btn')), findsOneWidget);
      expect(find.byKey(const Key('voice_assistant_capabilities_btn')), findsOneWidget);

      // Open capabilities drawer
      await tester.tap(find.byKey(const Key('voice_assistant_capabilities_btn')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('كل ما أقدر أعمله لك'), findsOneWidget);
      expect(errors.where((e) => e.toString().contains('overflowed')), isEmpty);
    });
  });
}
