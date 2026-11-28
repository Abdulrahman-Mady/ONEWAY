import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_way_egypt/core/analytics/analytics_service.dart';
import 'package:one_way_egypt/core/di/analytics_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InMemoryAnalyticsSink implements AnalyticsSink {
  final List<({String name, Map<String, Object>? params})> events = [];
  final Map<String, String?> userProperties = {};
  final List<String> logins = [];
  final List<String> signUps = [];
  final List<({dynamic exception, bool fatal, String? reason})> errors = [];
  String? userId;
  bool collectionEnabled = true;
  int appOpens = 0;

  @override
  Future<void> setCollectionEnabled(bool enabled) async {
    collectionEnabled = enabled;
  }

  @override
  Future<void> logAppOpen() async {
    appOpens++;
  }

  @override
  Future<void> logLogin(String method) async {
    logins.add(method);
  }

  @override
  Future<void> logSignUp(String method) async {
    signUps.add(method);
  }

  @override
  Future<void> logEvent(String name, Map<String, Object>? parameters) async {
    events.add((name: name, params: parameters));
  }

  @override
  Future<void> setUserProperty(String name, String? value) async {
    userProperties[name] = value;
  }

  @override
  Future<void> setUserId(String? userId) async {
    this.userId = userId;
  }

  @override
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
    Map<String, Object>? context,
  }) async {
    errors.add((exception: exception, fatal: fatal, reason: reason));
  }

  @override
  Future<void> logMessage(String message) async {}

  @override
  Future<void> setCustomKeys(Map<String, Object> keys) async {}
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AnalyticsService', () {
    test('sanitizes booleans to 1/0 and caps string lengths at 100 chars', () {
      final longString = 'a' * 150;
      final clean = AnalyticsService.sanitizeParameters({
        'flag_true': true,
        'flag_false': false,
        'count': 42,
        'long_text': longString,
        'omitted': null,
      });

      expect(clean['flag_true'], 1);
      expect(clean['flag_false'], 0);
      expect(clean['count'], 42);
      expect((clean['long_text'] as String).length, 100);
      expect(clean.containsKey('omitted'), isFalse);
    });

    test('logs full taxonomy events with Firebase-safe parameter types',
        () async {
      final sink = InMemoryAnalyticsSink();
      final analytics = AnalyticsService.forTesting(sink);

      await analytics.logOnboardingStarted();
      await analytics.logOnboardingCompleted(
          mobilityType: 'كرسي متحرك كهربائي');
      await analytics.logPlaceViewed(
        placeId: 'nmec_cairo',
        category: 'سياحة وثقافة',
        scorePercent: 100,
        accessibilityLevel: 'full',
        isPersonalized: true,
      );
      await analytics.logSosTriggered(
        locationStatus: 'gps',
        draftOpened: true,
        contactType: 'primary',
      );
      await analytics.logVoiceAssistantUsed(
        intent: 'placeSearch',
        success: true,
      );
      await analytics.logFieldAssessmentRequested(
        businessId: 'biz_1',
        readinessScore: 85,
      );

      expect(sink.events.map((e) => e.name), [
        AnalyticsEvents.onboardingStarted,
        AnalyticsEvents.onboardingCompleted,
        AnalyticsEvents.placeViewed,
        AnalyticsEvents.sosTriggered,
        AnalyticsEvents.voiceAssistantUsed,
        AnalyticsEvents.fieldAssessmentRequested,
      ]);

      // Canonicalized mobility type (manual & electric wheelchairs unified)
      expect(sink.events[1].params?['mobility_type'], 'wheelchair');
      // Booleans serialized as int (1/0) for Firebase Analytics safety
      expect(sink.events[2].params?['is_personalized'], 1);
      expect(sink.events[3].params?['draft_opened'], 1);
      expect(sink.events[4].params?['success'], 1);
    });

    test('respects user opt-out via setEnabled(false)', () async {
      final sink = InMemoryAnalyticsSink();
      final analytics = AnalyticsService.forTesting(sink);

      await analytics.setEnabled(false);
      await analytics.logPlaceViewed(
        placeId: 'p1',
        category: 'طبي',
        scorePercent: 80,
        accessibilityLevel: 'full',
      );

      expect(sink.collectionEnabled, isFalse);
      expect(sink.events, isEmpty);
    });

    test('records non-fatal and fatal errors and clears userId to null',
        () async {
      final sink = InMemoryAnalyticsSink();
      final analytics = AnalyticsService.forTesting(sink);

      await analytics.setUserId('uid-123');
      expect(sink.userId, 'uid-123');

      await analytics.recordError(StateError('boom'), StackTrace.empty,
          reason: 'test');
      await analytics.recordFatalError(Exception('crash'), StackTrace.empty);
      expect(sink.errors, hasLength(2));
      expect(sink.errors.first.fatal, isFalse);
      expect(sink.errors.last.fatal, isTrue);

      await analytics.clearUserId();
      expect(sink.userId, isNull);
    });

    test('Riverpod userAnalyticsProvider syncs properties via DI override',
        () async {
      final sink = InMemoryAnalyticsSink();
      final analytics = AnalyticsService.forTesting(sink);
      final container = ProviderContainer(
        overrides: [analyticsProvider.overrideWithValue(analytics)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(userAnalyticsProvider.notifier);
      await notifier.updateMobilityType('كبار السن');
      await notifier.updatePreferredLanguage('en');
      await notifier.updateHighContrastEnabled(true);
      await notifier.updateFontScale(1.25);

      final state = container.read(userAnalyticsProvider);
      expect(state.mobilityType, 'assisted_walking');
      expect(state.preferredLanguage, 'en');
      expect(state.highContrastEnabled, isTrue);
      expect(state.fontScale, 1.25);

      expect(
          sink.userProperties[AnalyticsUserProperties.mobilityType],
          'assisted_walking');
      expect(sink.userProperties[AnalyticsUserProperties.preferredLanguage],
          'en');
      expect(sink.userProperties[AnalyticsUserProperties.highContrastEnabled],
          'true');
      expect(sink.userProperties[AnalyticsUserProperties.fontScale], '1.25');
    });
  });
}
