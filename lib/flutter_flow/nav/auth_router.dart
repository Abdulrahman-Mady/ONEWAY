import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// Import AuthService from index to avoid BusinessApplicationStatus conflict
import '/index.dart' show AuthService, AuthResult, BusinessApplicationStatus;
// Import other services directly
import '/auth/business_registration_service.dart' show BusinessRegistrationService;
import '/auth/user_profile_service.dart';
import '/auth/verification_service.dart';
import '/flutter_flow/nav/nav.dart';
import '/flutter_flow/flutter_flow_util.dart';
// Import specific pages
import '/pages/authentication/authentication_widget.dart';
import '/pages/home_dashboard/home_dashboard_widget.dart';
import '/pages/business_registration/business_registration_widget.dart';
import '/pages/business_registration/business_application_status_widget.dart';
import '/pages/authentication/registration_step1_widget.dart';
import '/pages/authentication/complete_profile_widget.dart';
import '/pages/authentication/verify_account_widget.dart';
import '/pages/authentication/account_suspended_widget.dart';
import '/pages/authentication/forgot_password_widget.dart';
import '/features/admin/admin_dashboard_page.dart';
import '/pages/business_admin_dashboard/business_admin_dashboard_widget.dart';

/// Centralized authentication routing logic for OneWay app.
/// Determines the correct destination based on user role, verification status, and profile completion.
class AuthRouter {
  AuthRouter._();
  static final AuthRouter instance = AuthRouter._();

  final AuthService _authService = AuthService.instance;
  final UserProfileService _profileService = UserProfileService.instance;
  final VerificationService _verificationService = VerificationService.instance;
  final BusinessRegistrationService _businessService = BusinessRegistrationService.instance;

  /// Determine the appropriate route for the current user
  Future<AuthRoute> determineRoute() async {
    if (!_authService.isLoggedIn) {
      return AuthRoute(route: '/login', reason: 'Not logged in');
    }

    // Check for suspended/banned accounts
    final user = await _profileService.getCurrentUserProfile();
    if (user != null && user.snapshotData['suspended'] == true) {
      return AuthRoute(
        route: '/account-suspended',
        reason: 'Account suspended',
        extra: {'suspensionReason': user.snapshotData['suspension_reason'] ?? ''},
      );
    }

    final role = _authService.currentUserRole;

    // Admin routes
    if (role == 'admin' || role == 'superAdmin' || role == 'moderator') {
      return AuthRoute(
        route: '/admin-dashboard',
        reason: 'Admin user',
      );
    }

    // Business owner routes
    if (role == 'businessOwner') {
      final businessStatus = await _businessService.getApplicationStatus();

      switch (businessStatus) {
        case BusinessApplicationStatus.pending:
          return AuthRoute(
            route: '/business-application-status',
            reason: 'Business application pending',
            extra: {'status': businessStatus},
          );
        case BusinessApplicationStatus.approved:
          return AuthRoute(
            route: '/business-admin',
            reason: 'Approved business owner',
          );
        case BusinessApplicationStatus.rejected:
          return AuthRoute(
            route: '/business-application-status',
            reason: 'Business application rejected',
            extra: {'status': businessStatus},
          );
        case BusinessApplicationStatus.suspended:
          return AuthRoute(
            route: '/business-application-status',
            reason: 'Business suspended',
            extra: {'status': businessStatus},
          );
        case BusinessApplicationStatus.none:
          // Business owner role but no business - go to registration
          return AuthRoute(
            route: '/business-registration',
            reason: 'Business owner without business',
          );
        default:
          // Should not reach here, but added for exhaustiveness
          return AuthRoute(
            route: '/business-registration',
            reason: 'Unknown business status',
          );
      }
    }

    // Customer routes
    if (role == 'user' || role == 'customer') {
      // Check profile completion
      final profile = await _profileService.getCurrentUserProfile();
      if (profile != null && !_profileService.isProfileComplete(profile)) {
        final missingFields = _profileService.getMissingFields(profile);
        return AuthRoute(
          route: '/complete-profile',
          reason: 'Incomplete profile',
          extra: {'missingFields': missingFields},
        );
      }

      // Verification is no longer a hard gate: users browse freely and get a
      // soft reminder banner on the home screen instead. /verify-account
      // stays reachable for anyone who wants to complete verification.
      return AuthRoute(
        route: '/home',
        reason: 'Customer signed in (verification is a soft reminder)',
      );
    }

    // Default to home for unknown roles
    return AuthRoute(route: '/home', reason: 'Default route');
  }

  /// Navigate to the appropriate route after login
  Future<void> navigateAfterLogin(BuildContext context) async {
    final route = await determineRoute();
    _navigate(context, route);
  }

  /// Navigate to the appropriate route after registration
  Future<void> navigateAfterRegistration(BuildContext context) async {
    // New registrations always start as customers
    final route = AuthRoute(
      route: '/complete-profile',
      reason: 'New registration - complete profile',
    );
    _navigate(context, route);
  }

  /// Navigate after social login (Google, Apple)
  Future<void> navigateAfterSocialLogin(BuildContext context) async {
    final user = _authService.currentUserProfile;

    if (user == null) {
      // Profile doesn't exist yet, will be created
      final route = AuthRoute(
        route: '/complete-profile',
        reason: 'Social login - new user',
      );
      _navigate(context, route);
      return;
    }

    // Check if profile needs completion
    if (!_profileService.isProfileComplete(user)) {
      final missingFields = _profileService.getMissingFields(user);
      final route = AuthRoute(
        route: '/complete-profile',
        reason: 'Social login - incomplete profile',
        extra: {'missingFields': missingFields},
      );
      _navigate(context, route);
      return;
    }

    // Profile complete. Verification is a soft reminder on the home screen,
    // not a gate - social sign-in users go straight to their normal route.
    final route = await determineRoute();
    _navigate(context, route);
  }

  /// Navigate after business registration submission
  Future<void> navigateAfterBusinessRegistration(BuildContext context) async {
    final route = AuthRoute(
      route: '/business-application-status',
      reason: 'Business application submitted',
      extra: {'status': BusinessApplicationStatus.pending},
    );
    _navigate(context, route);
  }

  /// Navigate after password reset
  Future<void> navigateAfterPasswordReset(BuildContext context) async {
    final route = AuthRoute(
      route: '/login',
      reason: 'Password reset complete',
      extra: {'showSuccess': true},
    );
    _navigate(context, route);
  }

  /// Navigate after email verification
  Future<void> navigateAfterEmailVerification(BuildContext context) async {
    final route = await determineRoute();
    _navigate(context, route);
  }

  /// Navigate after phone verification
  Future<void> navigateAfterPhoneVerification(BuildContext context) async {
    final route = await determineRoute();
    _navigate(context, route);
  }

  /// Navigate to business registration entry
  void navigateToBusinessRegistration(BuildContext context) {
    context.pushNamed(BusinessRegistrationWidget.routeName);
  }

  /// Navigate to login screen
  void navigateToLogin(BuildContext context) {
    context.goNamed(AuthenticationWidget.routeName);
  }

  /// Navigate to customer registration
  void navigateToCustomerRegistration(BuildContext context) {
    context.pushNamed(RegistrationStep1Widget.routeName);
  }

  /// Navigate to forgot password
  void navigateToForgotPassword(BuildContext context) {
    context.pushNamed(ForgotPasswordWidget.routeName);
  }

  /// Navigate to complete profile
  void navigateToCompleteProfile(BuildContext context, {List<String>? missingFields}) {
    context.pushNamed(
      CompleteProfileWidget.routeName,
      extra: {'missingFields': missingFields},
    );
  }

  /// Navigate to verify account
  void navigateToVerifyAccount(BuildContext context, {VerificationStatus? status}) {
    context.pushNamed(
      VerifyAccountWidget.routeName,
      extra: {'verificationStatus': status},
    );
  }

  /// Navigate to business application status
  void navigateToBusinessApplicationStatus(BuildContext context) {
    context.pushNamed(BusinessApplicationStatusWidget.routeName);
  }

  void _navigate(BuildContext context, AuthRoute route) {
    if (route.extra != null) {
      context.goNamed(
        _getRouteName(route.route),
        extra: route.extra,
      );
    } else {
      context.goNamed(_getRouteName(route.route));
    }
  }

  String _getRouteName(String path) {
    // Map paths to route names
    switch (path) {
      case '/login':
        return AuthenticationWidget.routeName;
      case '/home':
        return HomeDashboardWidget.routeName;
      case '/admin-dashboard':
        return AdminDashboardPage.routeName;
      case '/business-admin':
        return BusinessAdminDashboardWidget.routeName;
      case '/business-registration':
        return BusinessRegistrationWidget.routeName;
      case '/business-application-status':
        return BusinessApplicationStatusWidget.routeName;
      case '/complete-profile':
        return CompleteProfileWidget.routeName;
      case '/verify-account':
        return VerifyAccountWidget.routeName;
      case '/account-suspended':
        return AccountSuspendedWidget.routeName;
      default:
        return HomeDashboardWidget.routeName;
    }
  }
}

/// Auth route result
class AuthRoute {
  final String route;
  final String reason;
  final Map<String, dynamic>? extra;

  AuthRoute({
    required this.route,
    required this.reason,
    this.extra,
  });

  @override
  String toString() => 'AuthRoute(route: $route, reason: $reason, extra: $extra)';
}

/// Extension for easy access to auth router
extension AuthRouterExtension on BuildContext {
  AuthRouter get authRouter => AuthRouter.instance;

  Future<void> navigateAfterLogin() async {
    await authRouter.navigateAfterLogin(this);
  }

  Future<void> navigateAfterRegistration() async {
    await authRouter.navigateAfterRegistration(this);
  }

  Future<void> navigateAfterSocialLogin() async {
    await authRouter.navigateAfterSocialLogin(this);
  }

  Future<void> navigateAfterBusinessRegistration() async {
    await authRouter.navigateAfterBusinessRegistration(this);
  }

  Future<void> navigateAfterPasswordReset() async {
    await authRouter.navigateAfterPasswordReset(this);
  }

  Future<void> navigateAfterEmailVerification() async {
    await authRouter.navigateAfterEmailVerification(this);
  }

  Future<void> navigateAfterPhoneVerification() async {
    await authRouter.navigateAfterPhoneVerification(this);
  }

  void navigateToBusinessRegistration() {
    authRouter.navigateToBusinessRegistration(this);
  }

  void navigateToLogin() {
    authRouter.navigateToLogin(this);
  }

  void navigateToCustomerRegistration() {
    authRouter.navigateToCustomerRegistration(this);
  }

  void navigateToForgotPassword() {
    authRouter.navigateToForgotPassword(this);
  }

  void navigateToCompleteProfile({List<String>? missingFields}) {
    authRouter.navigateToCompleteProfile(this, missingFields: missingFields);
  }

  void navigateToVerifyAccount({VerificationStatus? status}) {
    authRouter.navigateToVerifyAccount(this, status: status);
  }

  void navigateToBusinessApplicationStatus() {
    authRouter.navigateToBusinessApplicationStatus(this);
  }
}