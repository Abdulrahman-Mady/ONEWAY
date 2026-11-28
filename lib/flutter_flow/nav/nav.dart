import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/auth/firebase_auth/firebase_user_provider.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/features/discovery/discovery_pages.dart';
import '/features/account/account_pages.dart';
import '/features/admin/admin_dashboard_page.dart';
import '/features/guide/egypt_guide_page.dart';
import '/features/legal/legal_pages.dart';
import '/pages/authentication/registration_step1_widget.dart';
import '/pages/authentication/registration_step2_widget.dart';
import '/pages/authentication/registration_step3_widget.dart';
import '/pages/authentication/registration_success_widget.dart';
import '/pages/authentication/complete_profile_widget.dart';
import '/pages/authentication/verify_account_widget.dart';
import '/pages/authentication/forgot_password_widget.dart';
import '/pages/authentication/account_suspended_widget.dart';
import '/pages/business_registration/business_registration_widget.dart';
import '/pages/business_registration/business_registration_step1_widget.dart';
import '/pages/business_registration/business_registration_step2_widget.dart';
import '/pages/business_registration/business_registration_step3_widget.dart';
import '/pages/business_registration/business_registration_success_widget.dart';
import '/pages/business_registration/business_application_status_widget.dart';

import '/index.dart';

export '/flutter_flow/nav/auth_router.dart' show AuthRouterExtension;

export 'package:go_router/go_router.dart';
export 'serialization_util.dart';

const kTransitionInfoKey = '__transition_info__';

GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class AppStateNotifier extends ChangeNotifier {
  AppStateNotifier._();

  static AppStateNotifier? _instance;
  static AppStateNotifier get instance => _instance ??= AppStateNotifier._();

  BaseAuthUser? initialUser;
  BaseAuthUser? user;
  bool hasInitializedUser = false;
  // The app has no launch artwork that needs to block navigation.
  bool showSplashImage = false;
  String? _redirectLocation;

  /// Determines whether the app will refresh and build again when a sign
  /// in or sign out happens. This is useful when the app is launched or
  /// on an unexpected logout. However, this must be turned off when we
  /// intend to sign in/out and then navigate or perform any actions after.
  /// Otherwise, this will trigger a refresh and interrupt the action(s).
  bool notifyOnAuthChange = true;

  // Never leave the app blocked if Firebase's auth stream is slow or
  // unavailable. A signed-out user can safely use the authentication page.
  bool get loading => showSplashImage;
  bool get loggedIn => user?.loggedIn ?? false;
  bool get initiallyLoggedIn => initialUser?.loggedIn ?? false;
  bool get shouldRedirect => loggedIn && _redirectLocation != null;

  String getRedirectLocation() => _redirectLocation!;
  bool hasRedirect() => _redirectLocation != null;
  void setRedirectLocationIfUnset(String loc) => _redirectLocation ??= loc;
  void clearRedirectLocation() => _redirectLocation = null;

  /// Mark as not needing to notify on a sign in / out when we intend
  /// to perform subsequent actions (such as navigation) afterwards.
  void updateNotifyOnAuthChange(bool notify) => notifyOnAuthChange = notify;

  void update(BaseAuthUser newUser) {
    final shouldUpdate =
        user?.uid == null || newUser.uid == null || user?.uid != newUser.uid;
    initialUser ??= newUser;
    user = newUser;
    hasInitializedUser = true;
    // Refresh the app on auth change unless explicitly marked otherwise.
    // No need to update unless the user has changed.
    if (notifyOnAuthChange && shouldUpdate) {
      notifyListeners();
    }
    // Once again mark the notifier as needing to update on auth change
    // (in order to catch sign in / out events).
    updateNotifyOnAuthChange(true);
  }

  void stopShowingSplashImage() {
    showSplashImage = false;
    notifyListeners();
  }
}

GoRouter createRouter(AppStateNotifier appStateNotifier) => GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: true,
      refreshListenable: appStateNotifier,
      navigatorKey: appNavigatorKey,
      errorBuilder: (context, state) => appStateNotifier.loggedIn
          ? const HomeDashboardWidget()
          : const AuthenticationWidget(),
      routes: [
        FFRoute(
          name: '_initialize',
          path: '/',
          builder: (context, _) => _LaunchGate(
            loggedIn: appStateNotifier.loggedIn,
          ),
        ),
        FFRoute(
          name: SplashOnboardingWidget.routeName,
          path: SplashOnboardingWidget.routePath,
          builder: (context, params) => const SplashOnboardingWidget(),
        ),
        FFRoute(
          name: AuthenticationWidget.routeName,
          path: AuthenticationWidget.routePath,
          builder: (context, params) => const AuthenticationWidget(),
        ),
        FFRoute(
          name: HomeDashboardWidget.routeName,
          path: HomeDashboardWidget.routePath,
          builder: (context, params) => const HomeDashboardWidget(),
          requireAuth: true,
        ),
        FFRoute(
          name: ExploreMapWidget.routeName,
          path: ExploreMapWidget.routePath,
          builder: (context, params) => ExploreMapWidget(
            initialCategory: params.getParam('category', ParamType.String),
          ),
          requireAuth: true,
        ),
        FFRoute(
          name: SearchFiltersWidget.routeName,
          path: SearchFiltersWidget.routePath,
          builder: (context, params) => PlaceExplorerPage(
            initialCategory: params.getParam('category', ParamType.String),
          ),
          requireAuth: true,
        ),
        FFRoute(
          name: PlaceDetailsWidget.routeName,
          path: PlaceDetailsWidget.routePath,
          builder: (context, params) => PlaceDetailsWidget(
            placeId: params.getParam('id', ParamType.String),
          ),
          requireAuth: true,
        ),
        FFRoute(
          name: SubmitAccessibilityReportWidget.routeName,
          path: SubmitAccessibilityReportWidget.routePath,
          builder: (context, params) => const SubmitAccessibilityReportWidget(),
          requireAuth: true,
        ),
        FFRoute(
          name: VoiceAssistantInterfaceWidget.routeName,
          path: VoiceAssistantInterfaceWidget.routePath,
          builder: (context, params) => const VoiceAssistantInterfaceWidget(),
          requireAuth: true,
        ),
        FFRoute(
          name: BusinessAdminDashboardWidget.routeName,
          path: BusinessAdminDashboardWidget.routePath,
          builder: (context, params) => const RoleProtectedPage(
            allowedRoles: {'businessOwner', 'admin', 'superAdmin'},
            allowPlaceApplicants: true,
            child: BusinessAdminDashboardWidget(),
          ),
          requireAuth: true,
        ),
        FFRoute(
          name: AdminDashboardPage.routeName,
          path: AdminDashboardPage.routePath,
          builder: (context, params) => const RoleProtectedPage(
            allowedRoles: {'admin', 'superAdmin'},
            child: AdminDashboardPage(),
          ),
          requireAuth: true,
        ),
        FFRoute(
          name: EmergencySOSWidget.routeName,
          path: EmergencySOSWidget.routePath,
          builder: (context, params) => const EmergencySOSWidget(),
          requireAuth: true,
        ),
        FFRoute(
          name: FavoritesPageWidget.routeName,
          path: FavoritesPageWidget.routePath,
          builder: (context, params) => const FavoritePlacesPage(),
          requireAuth: true,
        ),
        FFRoute(
          name: HelpSupportPageWidget.routeName,
          path: HelpSupportPageWidget.routePath,
          builder: (context, params) => const HelpSupportPageWidget(),
          requireAuth: true,
        ),
        FFRoute(
          name: NotificationsPageWidget.routeName,
          path: NotificationsPageWidget.routePath,
          builder: (context, params) => const NotificationsCenterPage(),
          requireAuth: true,
        ),
        FFRoute(
          name: SettingsPageWidget.routeName,
          path: SettingsPageWidget.routePath,
          builder: (context, params) => const SettingsPageWidget(),
          requireAuth: true,
        ),
        FFRoute(
          name: UserProfileWidget.routeName,
          path: UserProfileWidget.routePath,
          builder: (context, params) => const UserProfileWidget(),
          requireAuth: true,
        ),
        FFRoute(
          name: EditProfileWidget.routeName,
          path: EditProfileWidget.routePath,
          builder: (context, params) => const EditProfileWidget(),
          requireAuth: true,
        ),
        FFRoute(
          name: 'MyReports',
          path: '/my-reports',
          builder: (context, params) => MyReportsPage(
            initialReportId: params.getParam('reportId', ParamType.String),
            autoOpenEdit: params.getParam('edit', ParamType.String) == '1',
          ),
          requireAuth: true,
        ),
        FFRoute(
          name: 'ReportModeration',
          path: '/admin/reports',
          builder: (context, params) => const RoleProtectedPage(
            allowedRoles: {'admin', 'superAdmin'},
            child: ReportModerationPage(),
          ),
          requireAuth: true,
        ),
        FFRoute(
          name: 'InitialAdminSetup',
          path: '/admin/setup',
          builder: (context, params) => const InitialAdminSetupPage(),
          requireAuth: true,
        ),
        FFRoute(
          name: PrivacyPolicyPage.routeName,
          path: PrivacyPolicyPage.routePath,
          builder: (context, params) => const PrivacyPolicyPage(),
        ),
        FFRoute(
          name: TermsOfUsePage.routeName,
          path: TermsOfUsePage.routePath,
          builder: (context, params) => const TermsOfUsePage(),
        ),
        FFRoute(
          name: AboutAppPage.routeName,
          path: AboutAppPage.routePath,
          builder: (context, params) => const AboutAppPage(),
        ),
        FFRoute(
          name: SuggestPlacePage.routeName,
          path: SuggestPlacePage.routePath,
          builder: (context, params) => const SuggestPlacePage(),
          requireAuth: true,
        ),
        FFRoute(
          name: EgyptGuidePage.routeName,
          path: EgyptGuidePage.routePath,
          builder: (context, params) => const EgyptGuidePage(),
        ),
        // Authentication routes
        FFRoute(
          name: RegistrationStep1Widget.routeName,
          path: RegistrationStep1Widget.routePath,
          builder: (context, params) => const RegistrationStep1Widget(),
        ),
        FFRoute(
          name: RegistrationStep2Widget.routeName,
          path: RegistrationStep2Widget.routePath,
          builder: (context, params) => const RegistrationStep2Widget(),
        ),
        FFRoute(
          name: RegistrationStep3Widget.routeName,
          path: RegistrationStep3Widget.routePath,
          builder: (context, params) => const RegistrationStep3Widget(),
        ),
        FFRoute(
          name: RegistrationSuccessWidget.routeName,
          path: RegistrationSuccessWidget.routePath,
          builder: (context, params) => const RegistrationSuccessWidget(),
        ),
        FFRoute(
          name: CompleteProfileWidget.routeName,
          path: CompleteProfileWidget.routePath,
          builder: (context, params) => const CompleteProfileWidget(),
          requireAuth: true,
        ),
        FFRoute(
          name: VerifyAccountWidget.routeName,
          path: VerifyAccountWidget.routePath,
          builder: (context, params) => const VerifyAccountWidget(),
          requireAuth: true,
        ),
        FFRoute(
          name: ForgotPasswordWidget.routeName,
          path: ForgotPasswordWidget.routePath,
          builder: (context, params) => const ForgotPasswordWidget(),
        ),
        FFRoute(
          name: AccountSuspendedWidget.routeName,
          path: AccountSuspendedWidget.routePath,
          builder: (context, params) => const AccountSuspendedWidget(),
          requireAuth: true,
        ),
        // Business Registration routes (accessible before login so tapping
        // "Are you a place owner? Register your place now" never bounces back
        // to the login screen; owner account creation happens inside the flow).
        FFRoute(
          name: BusinessRegistrationWidget.routeName,
          path: BusinessRegistrationWidget.routePath,
          builder: (context, params) => const BusinessRegistrationWidget(),
        ),
        FFRoute(
          name: BusinessRegistrationStep1Widget.routeName,
          path: BusinessRegistrationStep1Widget.routePath,
          builder: (context, params) => const BusinessRegistrationWidget(),
        ),
        FFRoute(
          name: BusinessRegistrationStep2Widget.routeName,
          path: BusinessRegistrationStep2Widget.routePath,
          builder: (context, params) => const BusinessRegistrationWidget(),
        ),
        FFRoute(
          name: BusinessRegistrationStep3Widget.routeName,
          path: BusinessRegistrationStep3Widget.routePath,
          builder: (context, params) => const BusinessRegistrationWidget(),
        ),
        FFRoute(
          name: BusinessRegistrationSuccessWidget.routeName,
          path: BusinessRegistrationSuccessWidget.routePath,
          builder: (context, params) => const BusinessRegistrationSuccessWidget(),
        ),
        FFRoute(
          name: BusinessApplicationStatusWidget.routeName,
          path: BusinessApplicationStatusWidget.routePath,
          builder: (context, params) => const BusinessApplicationStatusWidget(),
          requireAuth: true,
        ),
      ].map((r) => r.toRoute(appStateNotifier)).toList(),
    );

extension NavParamExtensions on Map<String, String?> {
  Map<String, String> get withoutNulls => Map.fromEntries(
        entries
            .where((e) => e.value != null)
            .map((e) => MapEntry(e.key, e.value!)),
      );
}

extension NavigationExtensions on BuildContext {
  void goNamedAuth(
    String name,
    bool mounted, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, String> queryParameters = const <String, String>{},
    Object? extra,
    bool ignoreRedirect = false,
  }) =>
      !mounted || GoRouter.of(this).shouldRedirect(ignoreRedirect)
          ? null
          : goNamed(
              name,
              pathParameters: pathParameters,
              queryParameters: queryParameters,
              extra: extra,
            );

  void pushNamedAuth(
    String name,
    bool mounted, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, String> queryParameters = const <String, String>{},
    Object? extra,
    bool ignoreRedirect = false,
  }) =>
      !mounted || GoRouter.of(this).shouldRedirect(ignoreRedirect)
          ? null
          : pushNamed(
              name,
              pathParameters: pathParameters,
              queryParameters: queryParameters,
              extra: extra,
            );

  void safePop() {
    // If there is only one route on the stack, return to Home (when signed in)
    // or Login (when signed out) instead of popping out of the app or looping '/'.
    if (canPop()) {
      pop();
    } else {
      go(loggedIn
          ? HomeDashboardWidget.routePath
          : AuthenticationWidget.routePath);
    }
  }
}

extension GoRouterExtensions on GoRouter {
  AppStateNotifier get appState => AppStateNotifier.instance;
  void prepareAuthEvent([bool ignoreRedirect = false]) =>
      appState.hasRedirect() && !ignoreRedirect
          ? null
          : appState.updateNotifyOnAuthChange(false);
  bool shouldRedirect(bool ignoreRedirect) =>
      !ignoreRedirect && appState.hasRedirect();
  void clearRedirectLocation() => appState.clearRedirectLocation();
  void setRedirectLocationIfUnset(String location) =>
      appState.updateNotifyOnAuthChange(false);
}

extension _GoRouterStateExtensions on GoRouterState {
  Map<String, dynamic> get extraMap =>
      extra != null ? extra as Map<String, dynamic> : {};
  Map<String, dynamic> get allParams => <String, dynamic>{}
    ..addAll(pathParameters)
    ..addAll(uri.queryParameters)
    ..addAll(extraMap);
  TransitionInfo get transitionInfo => extraMap.containsKey(kTransitionInfoKey)
      ? extraMap[kTransitionInfoKey] as TransitionInfo
      : TransitionInfo.appDefault();
}

/// A presentation-layer guard for privileged routes. Firestore rules remain
/// Key of the SharedPreferences flag recording that the welcome/onboarding
/// screens were shown once.
const kOnboardingSeenKey = 'onboarding_seen_v1';

/// Decides the very first screen of the app: welcome/onboarding slides on
/// first launch, then the usual signed-in/signed-out split.
class _LaunchGate extends StatefulWidget {
  const _LaunchGate({required this.loggedIn});

  final bool loggedIn;

  @override
  State<_LaunchGate> createState() => _LaunchGateState();
}

class _LaunchGateState extends State<_LaunchGate> {
  static Future<bool>? _seenFuture;
  late final Stream<BaseAuthUser> _authStream;
  bool _routed = false;

  @override
  void initState() {
    super.initState();
    _authStream = oneWayEgyptFirebaseUserStream();
  }

  Future<bool> _loadSeen() =>
      _seenFuture ??= SharedPreferences.getInstance()
          .then((prefs) => prefs.getBool(kOnboardingSeenKey) ?? false);

  bool _hasActiveAuthSession() {
    if (currentUser?.loggedIn == true || widget.loggedIn) return true;
    try {
      final fbUser = FirebaseAuth.instance.currentUser;
      if (fbUser != null && !fbUser.isAnonymous) {
        final wrapped = OneWayEgyptFirebaseUser(fbUser);
        currentUser = wrapped;
        AppStateNotifier.instance.update(wrapped);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> _dispatchInitialRoute() async {
    if (_routed || !mounted) return;
    _routed = true;
    final isSignedIn = _hasActiveAuthSession();
    if (!isSignedIn) {
      if (mounted) {
        context.goNamed(AuthenticationWidget.routeName);
      }
      return;
    }
    if (mounted) {
      await AuthRouter.instance.navigateAfterLogin(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _loadSeen(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const _OneWaySplash();
        }
        if (snapshot.data == false) return const SplashOnboardingWidget();
        // Wait for Firebase Auth to emit its initial restored session ONCE
        // before deciding between /login and AuthRouter destination, so closing
        // and reopening the app days later never bounces back to /login.
        return StreamBuilder<BaseAuthUser>(
          stream: _authStream,
          builder: (context, authSnapshot) {
            if (authSnapshot.connectionState == ConnectionState.waiting &&
                !_hasActiveAuthSession()) {
              return const _OneWaySplash();
            }
            if (authSnapshot.hasData && authSnapshot.data!.loggedIn) {
              currentUser = authSnapshot.data;
              AppStateNotifier.instance.update(authSnapshot.data!);
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _dispatchInitialRoute();
            });
            return const _OneWaySplash();
          },
        );
      },
    );
  }
}

/// Full-bleed splash shown while launch state resolves: navy brand block
/// (wheelchair + pin mark, ONEWAY wordmark, tagline), an illustrated Cairo
/// band, and a teal wave rolling into a white sheet with the loading line.
class _OneWaySplash extends StatelessWidget {
  const _OneWaySplash();

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Scaffold(
      backgroundColor: theme.navy,
      body: Column(
        children: [
          // Brand block on navy.
          Expanded(
            flex: 44,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipOval(
                    child: Image.asset(
                      'assets/images/oneway_logo_mark.jpg',
                      width: 112,
                      height: 112,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 18),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'ONE',
                          style: GoogleFonts.cairo(
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                        TextSpan(
                          text: 'WAY',
                          style: GoogleFonts.cairo(
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            color: theme.primary,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'اعرف المكان قبل ما تروح',
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Illustrated Cairo band with a teal wave into the white sheet.
          Expanded(
            flex: 56,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/splash_hero_band.jpg',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipPath(
                        clipper: _SplashWaveClipper(),
                        child: Container(height: 26, color: theme.primary),
                      ),
                      Container(
                        width: double.infinity,
                        color: theme.surface,
                        padding: const EdgeInsets.fromLTRB(24, 6, 24, 26),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 26,
                              height: 26,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.6,
                                color: theme.primary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'جاري التحميل...',
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: theme.primaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Wavy top edge for the teal strip above the splash sheet.
class _SplashWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()..moveTo(0, size.height);
    path.lineTo(0, size.height * 0.55);
    path.quadraticBezierTo(
        size.width * 0.25, 0, size.width * 0.5, size.height * 0.45);
    path.quadraticBezierTo(
        size.width * 0.75, size.height * 0.9, size.width, size.height * 0.3);
    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// the authority for data access; this prevents an ordinary signed-in user
/// from being shown a portal they are not authorized to use.
class RoleProtectedPage extends StatelessWidget {
  const RoleProtectedPage({
    super.key,
    required this.allowedRoles,
    required this.child,
    this.allowPlaceApplicants = false,
  });

  final Set<String> allowedRoles;
  final Widget child;
  final bool allowPlaceApplicants;

  @override
  Widget build(BuildContext context) => AuthUserStreamWidget(
        builder: (context) {
          final user = currentUserDocument;
          if (user == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final hasBusinessApp =
              ((user.snapshotData['business_application_id'] as String?) ?? '')
                  .trim()
                  .isNotEmpty;
          if (allowedRoles.contains(user.role) ||
              (allowPlaceApplicants && hasBusinessApp)) {
            return child;
          }

          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'رجوع',
                onPressed: () => context.safePop(),
              ),
              title: const Text('صلاحيات غير كافية'),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'هذه الصفحة متاحة لأصحاب الأماكن أو إدارة المنصة فقط.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => context.safePop(),
                      icon: const Icon(Icons.home_outlined),
                      label: const Text('العودة للرئيسية'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
}

class FFParameters {
  FFParameters(this.state, [this.asyncParams = const {}]);

  final GoRouterState state;
  final Map<String, Future<dynamic> Function(String)> asyncParams;

  Map<String, dynamic> futureParamValues = {};

  // Parameters are empty if the params map is empty or if the only parameter
  // present is the special extra parameter reserved for the transition info.
  bool get isEmpty =>
      state.allParams.isEmpty ||
      (state.allParams.length == 1 &&
          state.extraMap.containsKey(kTransitionInfoKey));
  bool isAsyncParam(MapEntry<String, dynamic> param) =>
      asyncParams.containsKey(param.key) && param.value is String;
  bool get hasFutures => state.allParams.entries.any(isAsyncParam);
  Future<bool> completeFutures() => Future.wait(
        state.allParams.entries.where(isAsyncParam).map(
          (param) async {
            final doc = await asyncParams[param.key]!(param.value)
                .onError((_, __) => null);
            if (doc != null) {
              futureParamValues[param.key] = doc;
              return true;
            }
            return false;
          },
        ),
      ).onError((_, __) => [false]).then((v) => v.every((e) => e));

  dynamic getParam<T>(
    String paramName,
    ParamType type, {
    bool isList = false,
    List<String>? collectionNamePath,
    StructBuilder<T>? structBuilder,
  }) {
    if (futureParamValues.containsKey(paramName)) {
      return futureParamValues[paramName];
    }
    if (!state.allParams.containsKey(paramName)) {
      return null;
    }
    final param = state.allParams[paramName];
    // Got parameter from `extras`, so just directly return it.
    if (param is! String) {
      return param;
    }
    // Return serialized value.
    return deserializeParam<T>(
      param,
      type,
      isList,
      collectionNamePath: collectionNamePath,
      structBuilder: structBuilder,
    );
  }
}

class FFRoute {
  const FFRoute({
    required this.name,
    required this.path,
    required this.builder,
    this.requireAuth = false,
    this.asyncParams = const {},
    this.routes = const [],
  });

  final String name;
  final String path;
  final bool requireAuth;
  final Map<String, Future<dynamic> Function(String)> asyncParams;
  final Widget Function(BuildContext, FFParameters) builder;
  final List<GoRoute> routes;

  GoRoute toRoute(AppStateNotifier appStateNotifier) => GoRoute(
        name: name,
        path: path,
        redirect: (context, state) {
          const authGatePaths = <String>{
            '/complete-profile',
            '/verify-account',
            '/account-suspended',
            '/admin-dashboard',
            '/business-admin',
            '/business/register',
          };
          if (appStateNotifier.shouldRedirect && !authGatePaths.contains(path)) {
            final redirectLocation = appStateNotifier.getRedirectLocation();
            appStateNotifier.clearRedirectLocation();
            return redirectLocation;
          }

          if (requireAuth && !appStateNotifier.loggedIn) {
            appStateNotifier.setRedirectLocationIfUnset(state.uri.toString());
            return '/login';
          }
          return null;
        },
        pageBuilder: (context, state) {
          fixStatusBarOniOS16AndBelow(context);
          final ffParams = FFParameters(state, asyncParams);
          final page = ffParams.hasFutures
              ? FutureBuilder(
                  future: ffParams.completeFutures(),
                  builder: (context, _) => builder(context, ffParams),
                )
              : builder(context, ffParams);
          const rootOrSelfHandledPaths = <String>{
            '/',
            '/splashOnboarding',
            '/login',
            '/home',
            '/complete-profile',
            '/verify-account',
            '/account-suspended',
            '/admin-dashboard',
            '/business/register',
          };
          final guardedPage = rootOrSelfHandledPaths.contains(path)
              ? page
              : _SubScreenBackFallback(child: page);
          final child = appStateNotifier.loading
              ? Center(
                  child: SizedBox(
                    width: 50.0,
                    height: 50.0,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        FlutterFlowTheme.of(context).primary,
                      ),
                    ),
                  ),
                )
              : guardedPage;

          final transitionInfo = state.transitionInfo;
          return transitionInfo.hasTransition
              ? CustomTransitionPage(
                  key: state.pageKey,
                  name: state.name,
                  child: child,
                  transitionDuration: transitionInfo.duration,
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) =>
                          PageTransition(
                    type: transitionInfo.transitionType,
                    duration: transitionInfo.duration,
                    reverseDuration: transitionInfo.duration,
                    alignment: transitionInfo.alignment,
                    curve: transitionInfo.transitionType ==
                            PageTransitionType.scale
                        ? const Interval(0.0, 0.5)
                        : Curves.linear,
                    child: child,
                  ).buildTransitions(
                    context,
                    animation,
                    secondaryAnimation,
                    child,
                  ),
                )
              : MaterialPage(
                  key: state.pageKey, name: state.name, child: child);
        },
        routes: routes,
      );
}

class TransitionInfo {
  const TransitionInfo({
    required this.hasTransition,
    this.transitionType = PageTransitionType.fade,
    this.duration = const Duration(milliseconds: 300),
    this.alignment,
  });

  final bool hasTransition;
  final PageTransitionType transitionType;
  final Duration duration;
  final Alignment? alignment;

  static TransitionInfo appDefault() =>
      const TransitionInfo(hasTransition: false);
}

class RootPageContext {
  const RootPageContext(this.isRootPage, [this.errorRoute]);
  final bool isRootPage;
  final String? errorRoute;

  static bool isInactiveRootPage(BuildContext context) {
    final rootPageContext = context.read<RootPageContext?>();
    final isRootPage = rootPageContext?.isRootPage ?? false;
    final location = GoRouterState.of(context).uri.toString();
    return isRootPage &&
        location != '/' &&
        location != rootPageContext?.errorRoute;
  }

  static Widget wrap(Widget child, {String? errorRoute}) => Provider.value(
        value: RootPageContext(true, errorRoute),
        child: child,
      );
}

extension GoRouterLocationExtension on GoRouter {
  String getCurrentLocation() {
    final RouteMatchBase lastMatch = routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }
}

/// Prevents hardware/system back on sub-screens opened via `goNamed` from
/// exiting the app when the GoRouter stack has a single entry; navigates to
/// Home (or Login when signed out) instead.
class _SubScreenBackFallback extends StatelessWidget {
  const _SubScreenBackFallback({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final canNavigatorPop = Navigator.of(context).canPop();
    return PopScope(
      canPop: canNavigatorPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.safePop();
      },
      child: child,
    );
  }
}
