import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

/// Canonical analytics event names for ONEWAY.
class AnalyticsEvents {
  AnalyticsEvents._();

  // Onboarding
  static const String onboardingStarted = 'onboarding_started';
  static const String onboardingCompleted = 'onboarding_completed';
  static const String onboardingSkipped = 'onboarding_skipped';
  static const String onboardingPermissionPrompted =
      'onboarding_permission_prompted';

  // Discovery & Map
  static const String placeViewed = 'place_viewed';
  static const String placeSearched = 'place_searched';
  static const String mapFilterApplied = 'map_filter_applied';
  static const String navigationStarted = 'navigation_started';

  // Accessibility & Community
  static const String accessibilityReportSubmitted =
      'accessibility_report_submitted';
  static const String placeSuggested = 'place_suggested';
  static const String favoriteToggled = 'favorite_toggled';
  static const String placeShared = 'share_place';
  static const String reviewSubmitted = 'review_submitted';

  // Emergency / SOS
  static const String sosTriggered = 'sos_triggered';
  static const String emergencyContactAdded = 'emergency_contact_added';

  // Engagement
  static const String voiceAssistantUsed = 'voice_assistant_used';
  static const String guideViewed = 'guide_viewed';

  // Business / B2B
  static const String businessRegistrationStarted = 'biz_reg_started';
  static const String businessRegistrationCompleted = 'biz_reg_completed';
  static const String fieldAssessmentRequested = 'field_assessment_requested';
  static const String b2bPlanViewed = 'b2b_plan_viewed';
}

/// Canonical Firebase Analytics user property names.
class AnalyticsUserProperties {
  AnalyticsUserProperties._();

  static const String mobilityType = 'mobility_type';
  static const String verificationStatus = 'verification_status';
  static const String preferredLanguage = 'preferred_language';
  static const String highContrastEnabled = 'high_contrast_enabled';
  static const String fontScale = 'font_scale';
  static const String userRole = 'user_role';
}

/// Abstract backend interface so [AnalyticsService] is 100% unit-testable
/// without requiring Firebase native channels.
abstract class AnalyticsSink {
  Future<void> setCollectionEnabled(bool enabled);
  Future<void> logAppOpen();
  Future<void> logSignUp(String method);
  Future<void> logLogin(String method);
  Future<void> logEvent(String name, Map<String, Object>? parameters);
  Future<void> setUserProperty(String name, String? value);
  Future<void> setUserId(String? userId);
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
    Map<String, Object>? context,
  });
  Future<void> logMessage(String message);
  Future<void> setCustomKeys(Map<String, Object> keys);
}

/// Production sink backed by Firebase Analytics & Firebase Crashlytics.
class FirebaseAnalyticsSink implements AnalyticsSink {
  FirebaseAnalyticsSink({
    FirebaseAnalytics? analytics,
    FirebaseCrashlytics? crashlytics,
  })  : _analytics = analytics,
        _crashlytics = crashlytics;

  FirebaseAnalytics? _analytics;
  FirebaseCrashlytics? _crashlytics;

  static bool get _supportsCrashlytics =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  Future<void> init({bool enabled = true}) async {
    try {
      _analytics ??= FirebaseAnalytics.instance;
      await _analytics?.setAnalyticsCollectionEnabled(enabled);
      if (!kIsWeb) {
        await _analytics
            ?.setSessionTimeoutDuration(const Duration(minutes: 30));
      }
    } catch (e) {
      debugPrint('Analytics init skipped: $e');
    }

    if (_supportsCrashlytics) {
      try {
        _crashlytics ??= FirebaseCrashlytics.instance;
        await _crashlytics?.setCrashlyticsCollectionEnabled(enabled);
      } catch (e) {
        debugPrint('Crashlytics init skipped: $e');
      }
    }
  }

  @override
  Future<void> setCollectionEnabled(bool enabled) async {
    try {
      await _analytics?.setAnalyticsCollectionEnabled(enabled);
    } catch (_) {}
    if (_supportsCrashlytics) {
      try {
        await _crashlytics?.setCrashlyticsCollectionEnabled(enabled);
      } catch (_) {}
    }
  }

  @override
  Future<void> logAppOpen() async {
    try {
      await _analytics?.logAppOpen();
    } catch (_) {}
  }

  @override
  Future<void> logSignUp(String method) async {
    try {
      await _analytics?.logSignUp(signUpMethod: method);
    } catch (_) {}
  }

  @override
  Future<void> logLogin(String method) async {
    try {
      await _analytics?.logLogin(loginMethod: method);
    } catch (_) {}
  }

  @override
  Future<void> logEvent(String name, Map<String, Object>? parameters) async {
    try {
      await _analytics?.logEvent(name: name, parameters: parameters);
    } catch (e) {
      debugPrint('Analytics logEvent($name) error: $e');
    }
  }

  @override
  Future<void> setUserProperty(String name, String? value) async {
    try {
      await _analytics?.setUserProperty(name: name, value: value);
    } catch (_) {}
  }

  @override
  Future<void> setUserId(String? userId) async {
    try {
      await _analytics?.setUserId(id: userId);
    } catch (_) {}
    if (_supportsCrashlytics) {
      try {
        await _crashlytics?.setUserIdentifier(userId ?? '');
      } catch (_) {}
    }
  }

  @override
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
    Map<String, Object>? context,
  }) async {
    if (!_supportsCrashlytics || _crashlytics == null) return;
    try {
      if (context != null) {
        await setCustomKeys(context);
      }
      await _crashlytics!.recordError(
        exception,
        stack ?? StackTrace.current,
        reason: reason,
        fatal: fatal,
      );
    } catch (_) {}
  }

  @override
  Future<void> logMessage(String message) async {
    if (!_supportsCrashlytics || _crashlytics == null) return;
    try {
      await _crashlytics!.log(message);
    } catch (_) {}
  }

  @override
  Future<void> setCustomKeys(Map<String, Object> keys) async {
    if (!_supportsCrashlytics || _crashlytics == null) return;
    for (final entry in keys.entries) {
      try {
        await _crashlytics!.setCustomKey(entry.key, entry.value);
      } catch (_) {}
    }
  }
}

/// Centralized analytics, crash reporting, and performance tracing service for ONEWAY.
///
/// Automatically sanitizes parameters for Firebase Analytics constraints
/// (booleans -> `1`/`0`, strings <= 100 chars) and safely guards platform-specific
/// plugins (Crashlytics on Web/Desktop).
class AnalyticsService {
  AnalyticsService._({AnalyticsSink? sink}) : _sink = sink;

  /// Creates an isolated instance backed by a custom [AnalyticsSink] (for tests/DI).
  factory AnalyticsService.forTesting(
    AnalyticsSink sink, {
    bool initialized = true,
    bool enabled = true,
  }) {
    final service = AnalyticsService._(sink: sink);
    service._initialized = initialized;
    service._enabled = enabled;
    return service;
  }

  static final AnalyticsService instance = AnalyticsService._();

  AnalyticsSink? _sink;
  bool _initialized = false;
  bool _enabled = true;

  /// Replaces the global singleton's sink during widget/unit tests.
  @visibleForTesting
  void configureForTesting(
    AnalyticsSink sink, {
    bool initialized = true,
    bool enabled = true,
  }) {
    _sink = sink;
    _initialized = initialized;
    _enabled = enabled;
  }

  /// Whether analytics is initialized and user consent is enabled.
  bool get isReady => _initialized && _enabled && _sink != null;

  /// Current analytics consent flag.
  bool get isEnabled => _enabled;

  /// Initialize Firebase Analytics & Crashlytics once at startup.
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(AppConstants.kAnalyticsConsentKey) ?? true;
    } catch (_) {
      _enabled = true;
    }

    final firebaseSink = FirebaseAnalyticsSink();
    await firebaseSink.init(enabled: _enabled);
    _sink = firebaseSink;
    _initialized = true;

    await logAppOpen();

    if (kDebugMode) {
      debugPrint('AnalyticsService initialized (enabled=$_enabled)');
    }
  }

  /// Enable or disable analytics & Crashlytics collection (user consent).
  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.kAnalyticsConsentKey, enabled);
    } catch (_) {}
    await _sink?.setCollectionEnabled(enabled);
  }

  /// Sanitizes parameters to satisfy Firebase Analytics strict type rules:
  /// - `bool` -> `1` / `0` (Firebase rejects booleans in event parameters)
  /// - `String` -> trimmed & capped at 100 characters
  /// - `num` -> preserved directly
  @visibleForTesting
  static Map<String, Object> sanitizeParameters(
    Map<String, Object?> raw,
  ) {
    final sanitized = <String, Object>{};
    for (final entry in raw.entries) {
      final value = entry.value;
      if (value == null) continue;
      if (value is bool) {
        sanitized[entry.key] = value ? 1 : 0;
      } else if (value is num) {
        sanitized[entry.key] = value;
      } else {
        final str = value.toString().trim();
        sanitized[entry.key] = str.length > 100 ? str.substring(0, 100) : str;
      }
    }
    return sanitized;
  }

  Future<void> _emit(String name, [Map<String, Object?>? params]) async {
    if (!isReady) return;
    final clean =
        params == null || params.isEmpty ? null : sanitizeParameters(params);
    await _sink!.logEvent(name, clean);
  }

  // ============================================================
  // CORE & AUTH EVENTS
  // ============================================================

  Future<void> logAppOpen() async {
    if (!isReady) return;
    await _sink!.logAppOpen();
  }

  Future<void> logSignUp({required String method}) async {
    if (!isReady) return;
    await _sink!.logSignUp(method);
  }

  Future<void> logLogin({required String method}) async {
    if (!isReady) return;
    await _sink!.logLogin(method);
  }

  // ============================================================
  // ONBOARDING EVENTS
  // ============================================================

  Future<void> logOnboardingStarted() =>
      _emit(AnalyticsEvents.onboardingStarted);

  Future<void> logOnboardingCompleted({required String mobilityType}) => _emit(
        AnalyticsEvents.onboardingCompleted,
        {'mobility_type': MobilityProfileOption.canonicalIdFor(mobilityType)},
      );

  Future<void> logOnboardingSkipped({int? step}) => _emit(
        AnalyticsEvents.onboardingSkipped,
        {if (step != null) 'step': step},
      );

  Future<void> logOnboardingPermissionPrompted({
    required String permission,
    required bool granted,
  }) =>
      _emit(AnalyticsEvents.onboardingPermissionPrompted, {
        'permission': permission,
        'granted': granted,
      });

  // ============================================================
  // DISCOVERY & MAP EVENTS
  // ============================================================

  Future<void> logPlaceViewed({
    required String placeId,
    required String category,
    required int scorePercent,
    required String accessibilityLevel,
    bool isPersonalized = false,
  }) =>
      _emit(AnalyticsEvents.placeViewed, {
        'place_id': placeId,
        'category': category,
        'score_percent': scorePercent,
        'accessibility_level': accessibilityLevel,
        'is_personalized': isPersonalized,
      });

  Future<void> logPlaceSearched({
    required String query,
    required int resultsCount,
    String? categoryFilter,
    bool? rampOnly,
    bool? verifiedOnly,
  }) =>
      _emit(AnalyticsEvents.placeSearched, {
        'query': query,
        'results_count': resultsCount,
        'category_filter': categoryFilter,
        'ramp_only': rampOnly,
        'verified_only': verifiedOnly,
      });

  Future<void> logMapFilterApplied({
    required String filterType,
    required String filterValue,
  }) =>
      _emit(AnalyticsEvents.mapFilterApplied, {
        'filter_type': filterType,
        'filter_value': filterValue,
      });

  Future<void> logNavigationStarted({
    required String placeId,
    required String navigationMode,
  }) =>
      _emit(AnalyticsEvents.navigationStarted, {
        'place_id': placeId,
        'navigation_mode': navigationMode,
      });

  // ============================================================
  // ACCESSIBILITY & COMMUNITY EVENTS
  // ============================================================

  Future<void> logAccessibilityReportSubmitted({
    required String placeId,
    required List<String> reportedFeatures,
    required bool hasPhotos,
  }) =>
      _emit(AnalyticsEvents.accessibilityReportSubmitted, {
        'place_id': placeId,
        'reported_features_count': reportedFeatures.length,
        'has_photos': hasPhotos,
        'reported_features': reportedFeatures.join(','),
      });

  Future<void> logPlaceSuggested({
    required String category,
    required bool hasAccessibilityInfo,
  }) =>
      _emit(AnalyticsEvents.placeSuggested, {
        'category': category,
        'has_accessibility_info': hasAccessibilityInfo,
      });

  Future<void> logFavoriteToggled({
    required String placeId,
    required bool added,
  }) =>
      _emit(AnalyticsEvents.favoriteToggled, {
        'place_id': placeId,
        'added': added,
      });

  Future<void> logSharePlace({
    required String placeId,
    required String method,
  }) =>
      _emit(AnalyticsEvents.placeShared, {
        'place_id': placeId,
        'method': method,
      });

  Future<void> logReviewSubmitted({
    required String placeId,
    required double rating,
  }) =>
      _emit(AnalyticsEvents.reviewSubmitted, {
        'place_id': placeId,
        'rating': rating,
      });

  // ============================================================
  // EMERGENCY / SOS EVENTS
  // ============================================================

  Future<void> logSosTriggered({
    required String locationStatus,
    required bool draftOpened,
    required String contactType,
  }) =>
      _emit(AnalyticsEvents.sosTriggered, {
        'location_status': locationStatus,
        'draft_opened': draftOpened,
        'contact_type': contactType,
      });

  Future<void> logEmergencyContactAdded({required bool isPrimary}) => _emit(
        AnalyticsEvents.emergencyContactAdded,
        {'is_primary': isPrimary},
      );

  // ============================================================
  // ENGAGEMENT & B2B EVENTS
  // ============================================================

  Future<void> logVoiceAssistantUsed({
    required String intent,
    required bool success,
    String? placeId,
  }) =>
      _emit(AnalyticsEvents.voiceAssistantUsed, {
        'intent': intent,
        'success': success,
        'place_id': placeId,
      });

  Future<void> logGuideViewed({required String section}) => _emit(
        AnalyticsEvents.guideViewed,
        {'section': section},
      );

  Future<void> logBusinessRegistrationStarted() =>
      _emit(AnalyticsEvents.businessRegistrationStarted);

  Future<void> logBusinessRegistrationCompleted({
    required String businessType,
    required bool isVerified,
  }) =>
      _emit(AnalyticsEvents.businessRegistrationCompleted, {
        'business_type': businessType,
        'is_verified': isVerified,
      });

  Future<void> logFieldAssessmentRequested({
    required String businessId,
    required int readinessScore,
  }) =>
      _emit(AnalyticsEvents.fieldAssessmentRequested, {
        'business_id': businessId,
        'readiness_score': readinessScore,
      });

  Future<void> logB2bPlanViewed({required String planId}) => _emit(
        AnalyticsEvents.b2bPlanViewed,
        {'plan_id': planId},
      );

  // ============================================================
  // USER PROPERTIES
  // ============================================================

  Future<void> setMobilityType(String mobilityType) async {
    if (!isReady) return;
    await _sink!.setUserProperty(
      AnalyticsUserProperties.mobilityType,
      MobilityProfileOption.canonicalIdFor(mobilityType),
    );
  }

  Future<void> setVerificationStatus(String status) async {
    if (!isReady) return;
    await _sink!.setUserProperty(
      AnalyticsUserProperties.verificationStatus,
      status,
    );
  }

  Future<void> setPreferredLanguage(String languageCode) async {
    if (!isReady) return;
    await _sink!.setUserProperty(
      AnalyticsUserProperties.preferredLanguage,
      languageCode,
    );
  }

  Future<void> setHighContrastEnabled(bool enabled) async {
    if (!isReady) return;
    await _sink!.setUserProperty(
      AnalyticsUserProperties.highContrastEnabled,
      enabled.toString(),
    );
  }

  Future<void> setFontScale(double scale) async {
    if (!isReady) return;
    await _sink!.setUserProperty(
      AnalyticsUserProperties.fontScale,
      scale.toStringAsFixed(2),
    );
  }

  Future<void> setUserRole(String role) async {
    if (!isReady) return;
    await _sink!.setUserProperty(AnalyticsUserProperties.userRole, role);
  }

  Future<void> setUserId(String userId) async {
    if (!isReady) return;
    await _sink!.setUserId(userId.isEmpty ? null : userId);
  }

  Future<void> clearUserId() async {
    if (!isReady) return;
    await _sink!.setUserId(null);
  }

  // ============================================================
  // CRASHLYTICS
  // ============================================================

  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    String? reason,
    Map<String, Object>? context,
  }) async {
    if (!isReady) return;
    await _sink!.recordError(
      exception,
      stack,
      reason: reason,
      fatal: false,
      context: context,
    );
  }

  Future<void> recordFatalError(
    dynamic exception,
    StackTrace? stack, {
    String? reason,
  }) async {
    if (!isReady) return;
    await _sink!.recordError(
      exception,
      stack,
      reason: reason,
      fatal: true,
    );
  }

  Future<void> log(String message) async {
    if (!isReady) return;
    await _sink!.logMessage(message);
  }

  Future<void> setCustomKeys(Map<String, Object> keys) async {
    if (!isReady) return;
    await _sink!.setCustomKeys(keys);
  }

  // ============================================================
  // PERFORMANCE TRACING (firebase_performance)
  // ============================================================

  /// Starts a Firebase Performance custom trace safely (returns `null` if unavailable).
  Future<Trace?> startTrace(String traceName) async {
    if (!isReady) return null;
    try {
      final trace = FirebasePerformance.instance.newTrace(traceName);
      await trace.start();
      return trace;
    } catch (_) {
      return null;
    }
  }

  /// Stops a previously started trace safely.
  Future<void> stopTrace(Trace? trace) async {
    if (trace == null) return;
    try {
      await trace.stop();
    } catch (_) {}
  }
}

/// Mixin for widgets/controllers that want direct analytics access.
mixin AnalyticsMixin {
  AnalyticsService get analytics => AnalyticsService.instance;
}
