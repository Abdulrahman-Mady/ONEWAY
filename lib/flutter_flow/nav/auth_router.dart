import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// Import AuthService from index to avoid BusinessApplicationStatus conflict
import '/index.dart' show AuthService, AuthResult, BusinessApplicationStatus;
// Import other services directly
import '/auth/business_registration_service.dart' show BusinessRegistrationService;
import '/auth/firebase_auth/auth_util.dart';
import '/auth/firebase_auth/firebase_user_provider.dart';
import '/auth/user_profile_service.dart';
import '/auth/verification_service.dart';
import '/backend/backend.dart';
import '/core/network/connectivity_service.dart';
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
    User? fbUser;
    try {
      fbUser = FirebaseAuth.instance.currentUser;
      if (fbUser != null && fbUser.isAnonymous) {
        await FirebaseAuth.instance.signOut();
        return AuthRoute(route: '/login', reason: 'Anonymous entry disabled');
      }
    } catch (_) {}

    if (fbUser != null && !fbUser.isAnonymous && !_authService.isLoggedIn) {
      final wrapped = OneWayEgyptFirebaseUser(fbUser);
      currentUser = wrapped;
      AppStateNotifier.instance.update(wrapped);
    }

    if (!_authService.isLoggedIn && fbUser == null) {
      return AuthRoute(route: '/login', reason: 'Not logged in');
    }

    final isOffline = ConnectivityService.instance.isOffline;

    // Ensure Firestore user document exists (skip network call when offline)
    if (fbUser != null && !isOffline) {
      try {
        await maybeCreateUser(fbUser).timeout(const Duration(seconds: 4));
      } catch (_) {}
    }

    // Read fresh profile from Firestore (with instant local cache fallback when offline)
    final user = await _profileService.getCurrentUserProfile();
    if (user != null) {
      currentUserDocument = user;
    }
    if (user != null && user.snapshotData['suspended'] == true) {
      return AuthRoute(
        route: '/account-suspended',
        reason: 'Account suspended',
        extra: {'suspensionReason': user.snapshotData['suspension_reason'] ?? ''},
      );
    }

    final role = user?.role ?? _authService.currentUserRole;
    final hasUploadedPlace =
        ((user?.snapshotData['business_application_id'] as String?) ?? '')
            .trim()
            .isNotEmpty;

    // 1. Admin role (canonical 'admin' + legacy 'superAdmin' root compatibility)
    if (role == 'admin' || role == 'superAdmin') {
      return AuthRoute(
        route: '/admin-dashboard',
        reason: 'Admin user',
      );
    }

    // 2. Mandatory Email Confirmation on ANY account registration (Customer,
    // Google, or Place Owner). Reload once if online & local state still shows unverified.
    var emailConfirmed = _verificationService.isEmailConfirmed(user);
    if (!emailConfirmed && !isOffline) {
      emailConfirmed = await _verificationService.checkEmailVerified();
    }
    if (!emailConfirmed) {
      return AuthRoute(
        route: '/verify-account',
        reason: 'Email confirmation required',
      );
    }

    // 3. Place Owner role ('businessOwner' or any owner who uploaded a place)
    // Routes to Place Owner Dashboard (/business-admin) after email confirmation.
    if (role == 'businessOwner' || hasUploadedPlace) {
      if (isOffline) {
        return AuthRoute(
          route: '/business-admin',
          reason: 'Place owner dashboard (offline cache)',
        );
      }
      final business = await _businessService.getCurrentUserBusiness();
      if (business == null && !hasUploadedPlace) {
        return AuthRoute(
          route: '/business-registration',
          reason: 'Place owner without uploaded place yet',
        );
      }
      return AuthRoute(
        route: '/business-admin',
        reason: 'Place owner dashboard',
      );
    }

    // 4. Mandatory Personal Profile Completion before opening HomeDashboard
    // (Full Name, Egyptian Phone, Gender, Birth Date, Governorate, Address, Mobility)
    if (user == null && isOffline) {
      // Allow returning offline user to browse cached Home when local profile cache is cold
      return AuthRoute(
        route: '/home',
        reason: 'Returning user offline with cold profile cache',
      );
    }
    if (user == null || !_profileService.isProfileComplete(user)) {
      final missingFields = _profileService.getMissingFields(user);
      return AuthRoute(
        route: '/complete-profile',
        reason: 'Incomplete personal profile',
        extra: {'missingFields': missingFields},
      );
    }

    return AuthRoute(
      route: '/home',
      reason: 'Regular user email verified & personal profile complete',
    );
  }

  /// Navigate to the appropriate route after login
  Future<void> navigateAfterLogin(BuildContext context) async {
    final route = await determineRoute();
    _navigate(context, route);
  }

  /// Navigate to the appropriate route after registration
  Future<void> navigateAfterRegistration(BuildContext context) async {
    final route = await determineRoute();
    if (!context.mounted) return;
    _navigate(context, route);
  }

  /// Navigate after social login (Google, Apple)
  Future<void> navigateAfterSocialLogin(BuildContext context) async {
    // Ensure Firestore profile doc exists first
    final fbUser = FirebaseAuth.instance.currentUser;
    if (fbUser != null) {
      await maybeCreateUser(fbUser);
    }
    if (!context.mounted) return;
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
    // Clear any stale GoRouter redirect (e.g. '/home') so auth gates such as
    // /verify-account and /complete-profile are NEVER bypassed after login.
    AppStateNotifier.instance.clearRedirectLocation();
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