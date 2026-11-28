import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '/backend/backend.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/core/analytics/analytics_service.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Centralized authentication service for OneWay app.
/// Handles all auth operations with proper error handling and user management.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuthManager _authManager = authManager;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// Current user stream with profile data
  Stream<UsersRecord?> get userProfileStream => authenticatedUserStream;

  /// Current user document (cached)
  UsersRecord? get currentUserProfile => currentUserDocument;

  /// Current user UID
  String get currentUserUid => currentUser?.uid ?? _firebaseAuth.currentUser?.uid ?? '';

  /// Current user email
  String get currentUserEmail =>
      currentUserDocument?.email ??
      currentUser?.email ??
      _firebaseAuth.currentUser?.email ??
      '';

  /// Current user display name
  String get currentUserDisplayName =>
      currentUserDocument?.displayName ??
      currentUser?.displayName ??
      _firebaseAuth.currentUser?.displayName ??
      '';

  /// Current user phone number
  String get currentPhoneNumber =>
      currentUserDocument?.phoneNumber ??
      currentUser?.phoneNumber ??
      _firebaseAuth.currentUser?.phoneNumber ??
      '';

  /// Current user role
  String get currentUserRole => currentUserDocument?.role ?? 'user';

  /// Whether user is admin
  bool get isAdmin => currentUserIsAdmin;

  /// Whether user is business owner
  bool get isBusinessOwner => currentUserRole == 'businessOwner';

  /// Whether user is logged in
  bool get isLoggedIn => loggedIn;

  /// Whether user email is verified
  bool get isEmailVerified => currentUserEmailVerified;

  /// Sign in with email and password
  Future<AuthResult> signInWithEmail({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    try {
      final user = await _authManager.signInWithEmail(context, email, password);
      if (user != null) {
        AnalyticsService.instance.logLogin(method: 'email');
        return AuthResult.success(user: user);
      }
      return AuthResult.failure(message: 'فشل تسجيل الدخول');
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(message: _getErrorMessage(e.code));
    } catch (e) {
      return AuthResult.failure(message: 'حدث خطأ غير متوقع: $e');
    }
  }

  /// Create account with email and password
  Future<AuthResult> createAccountWithEmail({
    required BuildContext context,
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final user = await _authManager.createAccountWithEmail(context, email, password);
      if (user != null) {
        AnalyticsService.instance.logSignUp(method: 'email');
        // Update display name if provided
        if (displayName != null && displayName.isNotEmpty) {
          await _firebaseAuth.currentUser?.updateDisplayName(displayName);
          await updateUserProfile(displayName: displayName);
        }
        return AuthResult.success(user: user);
      }
      return AuthResult.failure(message: 'فشل إنشاء الحساب');
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(message: _getErrorMessage(e.code));
    } catch (e) {
      return AuthResult.failure(message: 'حدث خطأ غير متوقع: $e');
    }
  }

  /// Sign in with Google
  Future<AuthResult> signInWithGoogle({required BuildContext context}) async {
    try {
      GoRouter.of(context).prepareAuthEvent();
      final user = await _authManager.signInWithGoogle(context);
      if (user != null) {
        AnalyticsService.instance.logLogin(method: 'google');
        return AuthResult.success(user: user);
      }
      return AuthResult.failure(message: 'تم إلغاء تسجيل الدخول أو فشل العملية');
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(message: _getErrorMessage(e.code));
    } catch (e) {
      return AuthResult.failure(message: 'حدث خطأ غير متوقع: $e');
    }
  }

  /// Sign in with Apple (iOS/macOS only)
  Future<AuthResult> signInWithApple({required BuildContext context}) async {
    try {
      GoRouter.of(context).prepareAuthEvent();
      final user = await _authManager.signInWithApple(context);
      if (user != null) {
        AnalyticsService.instance.logLogin(method: 'apple');
        return AuthResult.success(user: user);
      }
      return AuthResult.failure(message: 'تم إلغاء تسجيل الدخول أو فشل العملية');
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(message: _getErrorMessage(e.code));
    } catch (e) {
      return AuthResult.failure(message: 'حدث خطأ غير متوقع: $e');
    }
  }

  /// Guest / anonymous entry is permanently disabled across ONEWAY.
  Future<AuthResult> signInAnonymously({required BuildContext context}) async {
    return AuthResult.failure(
      message: 'تم إيقاف الدخول كزائر. يرجى تسجيل الدخول أو إنشاء حساب للمتابعة.',
    );
  }

  /// Send password reset email
  Future<AuthResult> sendPasswordResetEmail({
    required BuildContext context,
    required String email,
  }) async {
    try {
      await _authManager.resetPassword(email: email, context: context);
      return AuthResult.success(message: 'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني');
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(message: _getErrorMessage(e.code));
    } catch (e) {
      return AuthResult.failure(message: 'حدث خطأ غير متوقع: $e');
    }
  }

  /// Update user password (requires recent login)
  Future<AuthResult> updatePassword({
    required BuildContext context,
    required String newPassword,
  }) async {
    try {
      await _authManager.updatePassword(newPassword: newPassword, context: context);
      return AuthResult.success(message: 'تم تحديث كلمة المرور بنجاح');
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(message: _getErrorMessage(e.code));
    } catch (e) {
      return AuthResult.failure(message: 'حدث خطأ غير متوقع: $e');
    }
  }

  /// Update user email (requires recent login)
  Future<AuthResult> updateEmail({
    required BuildContext context,
    required String email,
  }) async {
    try {
      await _authManager.updateEmail(email: email, context: context);
      return AuthResult.success(message: 'تم تحديث البريد الإلكتروني بنجاح');
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(message: _getErrorMessage(e.code));
    } catch (e) {
      return AuthResult.failure(message: 'حدث خطأ غير متوقع: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await AnalyticsService.instance.clearUserId();
    await _authManager.signOut();
  }

  /// Delete user account (requires recent login)
  Future<AuthResult> deleteAccount({required BuildContext context}) async {
    try {
      await _authManager.deleteUser(context);
      return AuthResult.success(message: 'تم حذف الحساب بنجاح');
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(message: _getErrorMessage(e.code));
    } catch (e) {
      return AuthResult.failure(message: 'حدث خطأ غير متوقع: $e');
    }
  }

  /// Send email verification
  Future<AuthResult> sendEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        return AuthResult.success(message: 'تم إرسال رابط التحقق إلى بريدك الإلكتروني');
      }
      return AuthResult.failure(message: 'البريد الإلكتروني مُحقق بالفعل أو لا يوجد مستخدم');
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(message: _getErrorMessage(e.code));
    } catch (e) {
      return AuthResult.failure(message: 'حدث خطأ غير متوقع: $e');
    }
  }

  /// Reload user to get latest email verification status
  Future<void> reloadUser() async {
    await _firebaseAuth.currentUser?.reload();
  }

  /// Check if user profile exists in Firestore
  Future<bool> hasUserProfile() async {
    if (!loggedIn) return false;
    final doc = await UsersRecord.collection.doc(currentUserUid).get();
    return doc.exists;
  }

  /// Get user profile from Firestore
  Future<UsersRecord?> getUserProfile() async {
    if (!loggedIn) return null;
    return await UsersRecord.getDocumentOnce(UsersRecord.collection.doc(currentUserUid));
  }

  /// Update user profile in Firestore
  Future<AuthResult> updateUserProfile({
    String? displayName,
    String? phoneNumber,
    String? photoUrl,
  }) async {
    try {
      if (!loggedIn) {
        return AuthResult.failure(message: 'يجب تسجيل الدخول أولاً');
      }

      final updates = <String, dynamic>{};
      if (displayName != null) updates['display_name'] = displayName;
      if (phoneNumber != null) updates['phone_number'] = phoneNumber;
      if (photoUrl != null) updates['photo_url'] = photoUrl;
      updates['updated_time'] = FieldValue.serverTimestamp();

      await UsersRecord.collection.doc(currentUserUid).update(updates);

      // Refresh cached user document
      currentUserDocument = await UsersRecord.getDocumentOnce(UsersRecord.collection.doc(currentUserUid));

      return AuthResult.success(message: 'تم تحديث الملف الشخصي بنجاح');
    } on FirebaseException catch (e) {
      return AuthResult.failure(message: e.message ?? 'فشل تحديث الملف الشخصي');
    } catch (e) {
      return AuthResult.failure(message: 'حدث خطأ غير متوقع: $e');
    }
  }

  /// Complete user profile after Google/Apple sign-in
  Future<AuthResult> completeProfileAfterSocialLogin({
    required String displayName,
    String? phoneNumber,
  }) async {
    try {
      if (!loggedIn) {
        return AuthResult.failure(message: 'يجب تسجيل الدخول أولاً');
      }

      final userDoc = UsersRecord.collection.doc(currentUserUid);
      final doc = await userDoc.get();

      if (doc.exists) {
        final existingData = doc.data() as Map<String, dynamic>;
        // Only update if fields are missing
        final updates = <String, dynamic>{};
        if (existingData['display_name'] == null || existingData['display_name'].toString().isEmpty) {
          updates['display_name'] = displayName;
        }
        if (phoneNumber != null && (existingData['phone_number'] == null || existingData['phone_number'].toString().isEmpty)) {
          updates['phone_number'] = phoneNumber;
        }
        if (updates.isNotEmpty) {
          updates['updated_time'] = FieldValue.serverTimestamp();
          await userDoc.update(updates);
        }
      } else {
        // Create new profile (shouldn't happen as maybeCreateUser runs on auth)
        await maybeCreateUser(_firebaseAuth.currentUser!);
      }

      currentUserDocument = await UsersRecord.getDocumentOnce(userDoc);
      return AuthResult.success(message: 'تم إكمال الملف الشخصي');
    } on FirebaseException catch (e) {
      return AuthResult.failure(message: e.message ?? 'فشل إكمال الملف الشخصي');
    } catch (e) {
      return AuthResult.failure(message: 'حدث خطأ غير متوقع: $e');
    }
  }

  /// Check if user needs profile completion (missing required fields)
  bool get needsProfileCompletion {
    if (!loggedIn) return false;
    final profile = currentUserProfile;
    if (profile == null) return true;
    // Check for required fields
    return profile.displayName.isEmpty || profile.phoneNumber.isEmpty;
  }

  /// Get user's business application status
  Future<BusinessApplicationStatus> getBusinessApplicationStatus() async {
    if (!loggedIn) return BusinessApplicationStatus.none;

    final businesses = await BusinessesRecord.collection
        .where('ownerId', isEqualTo: currentUserUid)
        .limit(1)
        .get();

    if (businesses.docs.isEmpty) {
      return BusinessApplicationStatus.none;
    }

    final business = BusinessesRecord.fromSnapshot(businesses.docs.first);
    switch (business.status) {
      case 'pending':
        return BusinessApplicationStatus.pending;
      case 'active':
        return BusinessApplicationStatus.approved;
      case 'rejected':
        return BusinessApplicationStatus.rejected;
      case 'suspended':
        return BusinessApplicationStatus.suspended;
      default:
        return BusinessApplicationStatus.none;
    }
  }

  /// Refresh current user token
  Future<String?> getCurrentUserToken() async {
    try {
      return await _firebaseAuth.currentUser?.getIdToken(true);
    } catch (e) {
      debugPrint('Error getting user token: $e');
      return null;
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'هذا البريد الإلكتروني مستخدم بالفعل';
      case 'invalid-email':
        return 'بريد إلكتروني غير صالح';
      case 'operation-not-allowed':
        return 'هذه العملية غير مفعلة';
      case 'weak-password':
        return 'كلمة المرور ضعيفة جداً (يجب أن تكون 6 أحرف على الأقل)';
      case 'user-disabled':
        return 'تم تعطيل هذا الحساب';
      case 'user-not-found':
        return 'لا يوجد حساب بهذا البريد الإلكتروني';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة';
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
      case 'invalid-login-credentials':
        return 'بيانات تسجيل الدخول غير صحيحة';
      case 'requires-recent-login':
        return 'يرجى تسجيل الدخول مرة أخرى لإجراء هذا الإجراء';
      case 'network-request-failed':
        return 'خطأ في الاتصال بالإنترنت';
      case 'too-many-requests':
        return 'محاولات كثيرة جداً، يرجى المحاولة لاحقاً';
      default:
        return 'حدث خطأ: $code';
    }
  }
}

/// Result class for auth operations
class AuthResult {
  final bool success;
  final String? message;
  final BaseAuthUser? user;

  AuthResult._({
    required this.success,
    this.message,
    this.user,
  });

  factory AuthResult.success({String? message, BaseAuthUser? user}) =>
      AuthResult._(success: true, message: message, user: user);

  factory AuthResult.failure({required String message}) =>
      AuthResult._(success: false, message: message);

  @override
  String toString() => 'AuthResult(success: $success, message: $message)';
}

/// Business application status enum
enum BusinessApplicationStatus {
  none,
  pending,
  approved,
  rejected,
  suspended,
}

extension BusinessApplicationStatusExtension on BusinessApplicationStatus {
  String get label {
    switch (this) {
      case BusinessApplicationStatus.none:
        return 'غير مسجل';
      case BusinessApplicationStatus.pending:
        return 'قيد المراجعة';
      case BusinessApplicationStatus.approved:
        return 'مقبول';
      case BusinessApplicationStatus.rejected:
        return 'مرفوض';
      case BusinessApplicationStatus.suspended:
        return 'معلق';
    }
  }

  String get description {
    switch (this) {
      case BusinessApplicationStatus.none:
        return 'لم تقدم طلب تسجيل منشأة بعد';
      case BusinessApplicationStatus.pending:
        return 'طلبك قيد المراجعة من قبل فريق OneWay';
      case BusinessApplicationStatus.approved:
        return 'منشأتك موثقة وتظهر للعملاء';
      case BusinessApplicationStatus.rejected:
        return 'تم رفض طلبك، تواصل مع الدعم للمزيد من التفاصيل';
      case BusinessApplicationStatus.suspended:
        return 'حساب منشأتك معلق مؤقتاً';
    }
  }
}