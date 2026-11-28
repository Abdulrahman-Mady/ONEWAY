import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth/firebase_auth/auth_util.dart';
import 'auth/firebase_auth/firebase_user_provider.dart';
import 'backend/firebase/firebase_config.dart';
import 'backend/schema/users_record.dart';
import 'core/analytics/analytics_service.dart';
import 'core/constants/app_constants.dart';
import 'core/network/connectivity_service.dart';
import 'core/notifications/push_notification_service.dart';
import 'core/theme/oneway_theme.dart';
import 'flutter_flow/flutter_flow_theme.dart';
import 'flutter_flow/flutter_flow_util.dart';
import 'notifications_page/notifications_page_widget.dart';
import 'widgets/offline_status_banner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoRouter.optionURLReflectsImperativeAPIs = true;
  usePathUrlStrategy();

  // Initialize Firebase
  await initFirebase();

  // Activate Firebase App Check to protect Firestore, Storage, and Cloud Functions
  if (!kIsWeb) {
    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider: kDebugMode
            ? AndroidProvider.debug
            : AndroidProvider.playIntegrity,
        appleProvider: kDebugMode
            ? AppleProvider.debug
            : AppleProvider.appAttestWithDeviceCheckFallback,
      );
    } catch (e) {
      debugPrint('Firebase App Check activation skipped: $e');
    }
  }

  // Enable Firestore offline persistence with a bounded 50 MB local cache
  // so repeated screen visits & map browses read from disk instead of quota.
  try {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: 50 * 1024 * 1024,
    );
  } catch (e) {
    debugPrint('Firestore persistence settings skipped: $e');
  }

  // Register background FCM handler for killed / background push delivery
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  // Initialize theme
  await FlutterFlowTheme.initialize();

  // Initialize app state
  final appState = FFAppState();
  await appState.initializePersistedState();

  // Start real-time connectivity monitoring before routing/data reads
  await ConnectivityService.instance.initialize();

  // Restore persisted Firebase Auth session BEFORE building GoRouter so closing
  // and reopening the app (even days later) keeps the user signed in reliably.
  try {
    User? persistedUser = FirebaseAuth.instance.currentUser;
    persistedUser ??= await FirebaseAuth.instance
        .authStateChanges()
        .first
        .timeout(
          const Duration(seconds: 4),
          onTimeout: () => FirebaseAuth.instance.currentUser,
        );
    if (persistedUser != null && persistedUser.isAnonymous) {
      await FirebaseAuth.instance.signOut();
      persistedUser = null;
    }
    currentUser = OneWayEgyptFirebaseUser(persistedUser);
    AppStateNotifier.instance.update(currentUser!);
  } catch (e) {
    debugPrint('Persisted Firebase Auth restore skipped: $e');
  }

  // Initialize Analytics & Crashlytics and sync baseline user properties
  await AnalyticsService.instance.initialize();
  await AnalyticsService.instance.setPreferredLanguage(appState.localeCode);
  await AnalyticsService.instance
      .setHighContrastEnabled(appState.highContrast);
  await AnalyticsService.instance.setFontScale(appState.fontScale);

  // Set up global Flutter & platform error handling -> Crashlytics
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
    AnalyticsService.instance.recordError(
      details.exception,
      details.stack,
      reason: 'Flutter Framework Error',
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught Platform Error: $error');
    AnalyticsService.instance.recordFatalError(
      error,
      stack,
      reason: 'Uncaught Platform Error',
    );
    return true;
  };

  // Wrap with ProviderScope (Riverpod DI) + ChangeNotifierProvider (legacy FFAppState)
  runApp(
    ProviderScope(
      child: ChangeNotifierProvider(
        create: (context) => appState,
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => MyAppState();

  static MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<MyAppState>()!;
}

class MyAppState extends State<MyApp> {
  ThemeMode _themeMode = FlutterFlowTheme.themeMode;

  late AppStateNotifier _appStateNotifier;
  late GoRouter _router;
  String getRoute([RouteMatchBase? routeMatch]) {
    final RouteMatchBase lastMatch =
        routeMatch ?? _router.routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : _router.routerDelegate.currentConfiguration;
    return matchList.uri.path;
  }

  List<String> getRouteStack() =>
      _router.routerDelegate.currentConfiguration.matches
          .map((e) => getRoute(e))
          .toList();

  late Stream<BaseAuthUser> userStream;
  StreamSubscription<BaseAuthUser>? _userStreamSub;
  StreamSubscription<UsersRecord?>? _authUserSub;
  StreamSubscription<dynamic>? _jwtSub;

  @override
  void initState() {
    super.initState();

    _appStateNotifier = AppStateNotifier.instance;
    _router = createRouter(_appStateNotifier);

    // Initialize OS-level push & local notifications; tapping opens Notifications
    PushNotificationService.instance.initialize(
      initialEnabled: FFAppState().notificationsEnabled,
      onOpenNotifications: () {
        if (_appStateNotifier.loggedIn) {
          _router.pushNamed(NotificationsPageWidget.routeName);
        }
      },
    );

    userStream = oneWayEgyptFirebaseUserStream();
    _userStreamSub = userStream.listen((user) {
      _appStateNotifier.update(user);
      if (user.loggedIn && (user.uid ?? '').isNotEmpty) {
        AnalyticsService.instance.setUserId(user.uid!);
        PushNotificationService.instance.attachUser(
          user.uid!,
          enabled: FFAppState().notificationsEnabled,
        );
      } else {
        AnalyticsService.instance.clearUserId();
        PushNotificationService.instance.detachUser();
      }
    });

    _authUserSub = authenticatedUserStream.listen(_syncUserAnalyticsAndProfile);

    _jwtSub = jwtTokenStream.listen((_) {});
    Future.delayed(
      const Duration(milliseconds: 1000),
      () => _appStateNotifier.stopShowingSplashImage(),
    );
  }

  /// Syncs signed-in user properties to Analytics and flushes any mobility
  /// profile selected during pre-login onboarding into Firestore.
  Future<void> _syncUserAnalyticsAndProfile(UsersRecord? userDoc) async {
    if (userDoc == null) return;
    final analytics = AnalyticsService.instance;
    final data = userDoc.snapshotData;
    final role = userDoc.role;
    final mobility = (data['mobility_type'] as String?) ?? '';
    final emailVerified = data['email_verified'] == true;
    final phoneVerified = data['phone_verified'] == true;
    final verificationStatus = (emailVerified && phoneVerified)
        ? 'verified'
        : (emailVerified || phoneVerified)
            ? 'pending'
            : 'unverified';

    await analytics.setUserRole(role);
    await analytics.setVerificationStatus(verificationStatus);

    if (mobility.isNotEmpty) {
      await analytics.setMobilityType(mobility);
      await FFAppState().setMobilityType(mobility);
    }

    final existingNeeds = (data['access_needs'] as List?)
            ?.map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList() ??
        const <String>[];
    if (existingNeeds.isNotEmpty) {
      await FFAppState().setAccessNeeds(existingNeeds);
    }

    // Apply pending mobility & access needs captured during onboarding before sign-in
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingMobility =
          prefs.getString(AppConstants.kPendingMobilityTypeKey);
      final pendingNeeds =
          prefs.getStringList(AppConstants.kPendingAccessNeedsKey);
      final updates = <String, dynamic>{};
      if (mobility.isEmpty &&
          pendingMobility != null &&
          pendingMobility.isNotEmpty) {
        updates['mobility_type'] = pendingMobility;
        await FFAppState().setMobilityType(pendingMobility);
        await analytics.setMobilityType(pendingMobility);
      }
      if (existingNeeds.isEmpty &&
          pendingNeeds != null &&
          pendingNeeds.isNotEmpty) {
        updates['access_needs'] = pendingNeeds.take(10).toList();
        await FFAppState().setAccessNeeds(pendingNeeds.take(10).toList());
      }
      if (updates.isNotEmpty) {
        updates['updated_time'] = FieldValue.serverTimestamp();
        try {
          await userDoc.reference.update(updates);
        } catch (_) {
          // Fallback if older deployed rules do not allow access_needs yet
          if (updates.containsKey('mobility_type')) {
            await userDoc.reference.update({
              'mobility_type': updates['mobility_type'],
              'updated_time': FieldValue.serverTimestamp(),
            });
          }
        }
        await prefs.remove(AppConstants.kPendingMobilityTypeKey);
        await prefs.remove(AppConstants.kPendingAccessNeedsKey);
      }
    } catch (e) {
      debugPrint('Pending mobility sync skipped: $e');
    }
  }

  @override
  void dispose() {
    _userStreamSub?.cancel();
    _authUserSub?.cancel();
    _jwtSub?.cancel();
    super.dispose();
  }

  void setThemeMode(ThemeMode mode) => safeSetState(() {
        _themeMode = mode;
        FlutterFlowTheme.saveThemeMode(mode);
      });

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<FFAppState>();
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: AppConstants.appNameAr,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', ''),
        Locale('en', ''),
      ],
      locale: Locale(appState.localeCode, ''),
      theme: buildOnewayTheme(
        LightModeTheme(),
        Brightness.light,
        highContrast: appState.highContrast,
        disableAnimations: disableAnimations,
      ),
      darkTheme: buildOnewayTheme(
        DarkModeTheme(),
        Brightness.dark,
        highContrast: appState.highContrast,
        disableAnimations: disableAnimations,
      ),
      themeMode: _themeMode,
      routerConfig: _router,
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        final combinedScale = (mq.textScaler.scale(1.0) * appState.fontScale)
            .clamp(AppConstants.minFontScale, AppConstants.maxFontScale);
        return FocusTraversalGroup(
          policy: OrderedTraversalPolicy(),
          child: Directionality(
            textDirection:
                appState.isEnglish ? TextDirection.ltr : TextDirection.rtl,
            child: MediaQuery(
              data: mq.copyWith(
                textScaler: TextScaler.linear(combinedScale),
                highContrast: mq.highContrast || appState.highContrast,
              ),
              child: OfflineStatusOverlay(
                isEnglish: appState.isEnglish,
                child: child!,
              ),
            ),
          ),
        );
      },
    );
  }
}
