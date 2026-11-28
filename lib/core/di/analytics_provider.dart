import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/app_state.dart';
import '../analytics/analytics_service.dart';
import '../constants/app_constants.dart';

/// Core Riverpod DI providers for ONEWAY.
/// Enables clean dependency injection, overriding in tests, and progressive
/// migration away from legacy FlutterFlow singletons.

/// Provider for the [AnalyticsService] singleton (override in tests with a fake sink).
final analyticsProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService.instance;
});

/// Provider for initialized [AnalyticsService].
final initializedAnalyticsProvider =
    FutureProvider<AnalyticsService>((ref) async {
  final analytics = ref.read(analyticsProvider);
  await analytics.initialize();
  return analytics;
});

/// Bridges legacy [FFAppState] into Riverpod so new features can read
/// settings/locale/accessibility via Riverpod without depending on Provider.
final appStateProvider = Provider<FFAppState>((ref) {
  return FFAppState();
});

/// Provider for user analytics properties synchronized with Firebase Analytics.
final userAnalyticsProvider =
    StateNotifierProvider<UserAnalyticsNotifier, UserAnalyticsState>(
  (ref) => UserAnalyticsNotifier(ref.read(analyticsProvider)),
);

/// State for user-level analytics attributes.
class UserAnalyticsState {
  const UserAnalyticsState({
    this.mobilityType,
    this.verificationStatus,
    this.preferredLanguage,
    this.highContrastEnabled,
    this.fontScale,
    this.userRole,
    this.analyticsEnabled = true,
  });

  final String? mobilityType;
  final String? verificationStatus;
  final String? preferredLanguage;
  final bool? highContrastEnabled;
  final double? fontScale;
  final String? userRole;
  final bool analyticsEnabled;

  UserAnalyticsState copyWith({
    String? mobilityType,
    String? verificationStatus,
    String? preferredLanguage,
    bool? highContrastEnabled,
    double? fontScale,
    String? userRole,
    bool? analyticsEnabled,
  }) {
    return UserAnalyticsState(
      mobilityType: mobilityType ?? this.mobilityType,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      highContrastEnabled: highContrastEnabled ?? this.highContrastEnabled,
      fontScale: fontScale ?? this.fontScale,
      userRole: userRole ?? this.userRole,
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
    );
  }
}

/// Notifier that syncs user properties to [AnalyticsService].
class UserAnalyticsNotifier extends StateNotifier<UserAnalyticsState> {
  UserAnalyticsNotifier(this._analytics)
      : super(UserAnalyticsState(analyticsEnabled: _analytics.isEnabled));

  final AnalyticsService _analytics;

  Future<void> updateMobilityType(String mobilityType) async {
    final canonical = MobilityProfileOption.canonicalIdFor(mobilityType);
    state = state.copyWith(mobilityType: canonical);
    await _analytics.setMobilityType(mobilityType);
  }

  Future<void> updateVerificationStatus(String status) async {
    state = state.copyWith(verificationStatus: status);
    await _analytics.setVerificationStatus(status);
  }

  Future<void> updatePreferredLanguage(String languageCode) async {
    state = state.copyWith(preferredLanguage: languageCode);
    await _analytics.setPreferredLanguage(languageCode);
  }

  Future<void> updateHighContrastEnabled(bool enabled) async {
    state = state.copyWith(highContrastEnabled: enabled);
    await _analytics.setHighContrastEnabled(enabled);
  }

  Future<void> updateFontScale(double scale) async {
    state = state.copyWith(fontScale: scale);
    await _analytics.setFontScale(scale);
  }

  Future<void> updateUserRole(String role) async {
    state = state.copyWith(userRole: role);
    await _analytics.setUserRole(role);
  }

  Future<void> setAnalyticsEnabled(bool enabled) async {
    state = state.copyWith(analyticsEnabled: enabled);
    await _analytics.setEnabled(enabled);
  }

  Future<void> setUserId(String userId) async {
    await _analytics.setUserId(userId);
  }

  Future<void> clearUserId() async {
    await _analytics.clearUserId();
  }
}
