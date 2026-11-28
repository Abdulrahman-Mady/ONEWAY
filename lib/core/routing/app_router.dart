/// Core routing facade for ONEWAY.
///
/// Re-exports the active GoRouter setup and auth guards while exposing typed
/// route names and paths from `core/routing/` so features do not need to
/// import `flutter_flow/nav/` directly.
library;

export '/flutter_flow/nav/nav.dart'
    show
        AppStateNotifier,
        FFRoute,
        GoRouter,
        NavigationExtensions,
        RoleProtectedPage,
        appNavigatorKey,
        createRouter,
        kOnboardingSeenKey;
export '/flutter_flow/nav/auth_router.dart'
    show AuthRoute, AuthRouter, AuthRouterExtension;

/// Named route registry for ONEWAY screens.
class AppRoutes {
  AppRoutes._();

  static const String root = '/';
  static const String onboarding = '/splashOnboarding';
  static const String login = '/login';
  static const String home = '/home';
  static const String map = '/map';
  static const String search = '/search';
  static const String report = '/report';
  static const String assistant = '/assistant';
  static const String emergency = '/emergency';
  static const String egyptGuide = '/egypt-guide';
  static const String suggestPlace = '/suggest-place';
  static const String settings = '/settings';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String businessPortal = '/business-admin';
  static const String businessRegister = '/business-registration';
  static const String adminDashboard = '/admin-dashboard';
}
