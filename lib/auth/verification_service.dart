import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/core/constants/profile_options.dart';

/// Service for handling real Firebase Auth email confirmation links and SMS OTP
/// phone verification, linking credentials safely to the signed-in account.
class VerificationService {
  VerificationService._();
  static final VerificationService instance = VerificationService._();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int? _lastResendToken;
  ConfirmationResult? _webConfirmationResult;

  /// Verification code collection (Admin SDK only in production)
  CollectionReference get _verificationCodesCollection =>
      _firestore.collection('verification_codes');

  /// Send email verification link via Firebase Auth
  Future<VerificationResult> sendEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null || user.isAnonymous) {
        return VerificationResult.failure(message: 'يجب تسجيل الدخول أولاً');
      }

      await user.reload();
      final refreshed = _firebaseAuth.currentUser;
      if (refreshed != null && refreshed.emailVerified) {
        await _markEmailVerifiedInFirestore(refreshed);
        return VerificationResult.success(
          message: 'البريد الإلكتروني مؤكد بالفعل ✓',
        );
      }

      await user.sendEmailVerification();
      return VerificationResult.success(
        message:
            'تم إرسال رسالة التأكيد إلى بريدك الإلكتروني (${user.email ?? ''}). افتح الرسالة واضغط على رابط التفعيل.',
      );
    } on FirebaseAuthException catch (e) {
      return VerificationResult.failure(message: _getErrorMessage(e.code));
    } catch (e) {
      return VerificationResult.failure(message: 'حدث خطأ غير متوقع: $e');
    }
  }

  /// Reloads Firebase user and syncs `email_verified: true` to Firestore when confirmed.
  Future<bool> checkEmailVerified() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null || user.isAnonymous) return false;

      await user.reload();
      final refreshed = _firebaseAuth.currentUser;
      final verified = refreshed?.emailVerified ?? false;
      if (verified && refreshed != null) {
        await _markEmailVerifiedInFirestore(refreshed);
      }
      return verified;
    } catch (_) {
      return false;
    }
  }

  Future<void> _markEmailVerifiedInFirestore(User user) async {
    try {
      await UsersRecord.collection.doc(user.uid).update({
        'email_verified': true,
        if (user.email != null && user.email!.isNotEmpty)
          'email': user.email,
        'updated_time': FieldValue.serverTimestamp(),
      });
      currentUserDocument = await UsersRecord.getDocumentOnce(
        UsersRecord.collection.doc(user.uid),
      );
    } catch (e) {
      debugPrint('Sync email_verified warning: $e');
    }
  }

  /// Sends a real SMS OTP code to [phoneNumber] via Firebase Phone Auth,
  /// awaiting the actual `codeSent` / `verificationFailed` callback so errors
  /// are surfaced accurately to the user.
  Future<VerificationResult> sendPhoneVerification({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    VoidCallback? onAutoVerified,
    bool isResend = false,
  }) async {
    try {
      final trimmed = phoneNumber.trim();
      if (trimmed.isEmpty) {
        return VerificationResult.failure(message: 'رقم الهاتف مطلوب');
      }
      if (!ProfileOptions.isValidEgyptianPhone(trimmed) &&
          !trimmed.startsWith('+')) {
        return VerificationResult.failure(
          message: 'أدخل رقم هاتف مصري صحيح (مثال: 010xxxxxxxx)',
        );
      }

      final formattedPhone = _formatPhoneNumber(trimmed);
      final localPhone = ProfileOptions.normalizeEgyptianPhone(trimmed);

      // Persist the phone number on the user profile first so it isn't lost
      final current = _firebaseAuth.currentUser;
      if (current != null && !current.isAnonymous) {
        try {
          await UsersRecord.collection.doc(current.uid).update({
            'phone_number': localPhone,
            'updated_time': FieldValue.serverTimestamp(),
          });
        } catch (_) {}
      }

      if (kIsWeb) {
        final user = _firebaseAuth.currentUser;
        if (user != null && !user.isAnonymous) {
          _webConfirmationResult = await user.linkWithPhoneNumber(formattedPhone);
        } else {
          _webConfirmationResult =
              await _firebaseAuth.signInWithPhoneNumber(formattedPhone);
        }
        onCodeSent('web_phone_verification');
        return VerificationResult.success(
          message: 'تم إرسال كود التأكيد في رسالة SMS إلى $localPhone',
        );
      }

      final completer = Completer<VerificationResult>();

      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        forceResendingToken: isResend ? _lastResendToken : null,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await _linkOrUpdatePhoneCredential(credential, localPhone);
            onAutoVerified?.call();
            if (!completer.isCompleted) {
              completer.complete(
                VerificationResult.success(
                  message: 'تم تأكيد رقم الهاتف تلقائياً بنجاح ✓',
                ),
              );
            }
          } on FirebaseAuthException catch (e) {
            if (!completer.isCompleted) {
              completer.complete(
                VerificationResult.failure(message: _getErrorMessage(e.code)),
              );
            }
          } catch (e) {
            if (!completer.isCompleted) {
              completer.complete(
                VerificationResult.failure(message: 'تعذر تأكيد الهاتف: $e'),
              );
            }
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('Phone verification failed (${e.code}): ${e.message}');
          if (!completer.isCompleted) {
            completer.complete(
              VerificationResult.failure(message: _getErrorMessage(e.code)),
            );
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          _lastResendToken = resendToken;
          onCodeSent(verificationId);
          if (!completer.isCompleted) {
            completer.complete(
              VerificationResult.success(
                message: 'تم إرسال كود التأكيد (6 أرقام) في رسالة SMS إلى $localPhone',
              ),
            );
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );

      return await completer.future.timeout(
        const Duration(seconds: 25),
        onTimeout: () => VerificationResult.failure(
          message: 'انتهت مهلة الاتصال بخدمة الرسائل. تحقق من الشبكة وحاول مجدداً.',
        ),
      );
    } on FirebaseAuthException catch (e) {
      return VerificationResult.failure(message: _getErrorMessage(e.code));
    } catch (e) {
      return VerificationResult.failure(message: 'حدث خطأ غير متوقع: $e');
    }
  }

  /// Verifies the 6-digit SMS OTP code and links/updates the phone on the
  /// current signed-in user WITHOUT replacing their Email/Google UID.
  Future<VerificationResult> verifyPhoneCode({
    required String verificationId,
    required String smsCode,
    String? rawPhoneNumber,
  }) async {
    try {
      final cleanCode = smsCode.trim();
      if (cleanCode.length < 6) {
        return VerificationResult.failure(
          message: 'أدخل كود التأكيد المكوّن من 6 أرقام',
        );
      }

      if (kIsWeb && verificationId == 'web_phone_verification') {
        if (_webConfirmationResult == null) {
          return VerificationResult.failure(
            message: 'انتهت جلسة التحقق، يرجى طلب كود جديد',
          );
        }
        await _webConfirmationResult!.confirm(cleanCode);
        _webConfirmationResult = null;
      } else {
        final credential = PhoneAuthProvider.credential(
          verificationId: verificationId,
          smsCode: cleanCode,
        );
        await _linkOrUpdatePhoneCredential(credential, rawPhoneNumber);
      }

      final user = _firebaseAuth.currentUser;
      if (user != null) {
        final savedPhone = (rawPhoneNumber != null && rawPhoneNumber.trim().isNotEmpty)
            ? ProfileOptions.normalizeEgyptianPhone(rawPhoneNumber)
            : (user.phoneNumber != null && user.phoneNumber!.isNotEmpty
                ? ProfileOptions.normalizeEgyptianPhone(user.phoneNumber!)
                : currentPhoneNumber);
        await UsersRecord.collection.doc(user.uid).update({
          if (savedPhone.isNotEmpty) 'phone_number': savedPhone,
          'phone_verified': true,
          'updated_time': FieldValue.serverTimestamp(),
        });
        currentUserDocument = await UsersRecord.getDocumentOnce(
          UsersRecord.collection.doc(user.uid),
        );
      }

      return VerificationResult.success(
        message: 'تم تأكيد رقم الهاتف بنجاح ✓',
      );
    } on FirebaseAuthException catch (e) {
      return VerificationResult.failure(message: _getErrorMessage(e.code));
    } catch (e) {
      return VerificationResult.failure(message: 'حدث خطأ غير متوقع: $e');
    }
  }

  Future<void> _linkOrUpdatePhoneCredential(
    PhoneAuthCredential credential,
    String? rawPhoneNumber,
  ) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      await _firebaseAuth.signInWithCredential(credential);
      return;
    }

    try {
      await user.linkWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'provider-already-linked') {
        await user.updatePhoneNumber(credential);
      } else {
        rethrow;
      }
    }

    final savedPhone = (rawPhoneNumber != null && rawPhoneNumber.trim().isNotEmpty)
        ? ProfileOptions.normalizeEgyptianPhone(rawPhoneNumber)
        : (user.phoneNumber != null
            ? ProfileOptions.normalizeEgyptianPhone(user.phoneNumber!)
            : '');
    await UsersRecord.collection.doc(user.uid).update({
      if (savedPhone.isNotEmpty) 'phone_number': savedPhone,
      'phone_verified': true,
      'updated_time': FieldValue.serverTimestamp(),
    });
    currentUserDocument = await UsersRecord.getDocumentOnce(
      UsersRecord.collection.doc(user.uid),
    );
  }

  /// Send email OTP code (legacy helper)
  Future<VerificationResult> sendEmailOTP({
    required String email,
    VerificationPurpose purpose = VerificationPurpose.emailVerification,
  }) async {
    return sendEmailVerification();
  }

  /// Verify email OTP code (legacy helper)
  Future<VerificationResult> verifyEmailOTP({
    required String email,
    required String code,
    VerificationPurpose purpose = VerificationPurpose.emailVerification,
  }) async {
    final ok = await checkEmailVerified();
    return ok
        ? VerificationResult.success(message: 'تم التحقق بنجاح')
        : VerificationResult.failure(
            message: 'لم يتم تأكيد البريد بعد. اضغط على الرابط في رسالتك أولاً.',
          );
  }

  /// Resend verification
  Future<VerificationResult> resendCode({
    required String contact,
    VerificationMethod method = VerificationMethod.email,
    VerificationPurpose purpose = VerificationPurpose.emailVerification,
  }) async {
    switch (method) {
      case VerificationMethod.email:
        return sendEmailVerification();
      case VerificationMethod.phone:
        return VerificationResult.failure(
          message: 'استخدم زر إعادة إرسال الكود لإرسال رسالة SMS جديدة',
        );
    }
  }

  /// Returns true when the user's email address has been verified via Firebase
  /// Auth link or verified OAuth provider (e.g. Google Sign-In).
  bool isEmailConfirmed(UsersRecord? profile) {
    try {
      final fbUser = _firebaseAuth.currentUser;
      if (fbUser != null && fbUser.isAnonymous) return false;
      if (fbUser != null && fbUser.emailVerified) return true;
      // Google / Apple OAuth accounts carry verified provider emails
      if (fbUser != null &&
          fbUser.providerData.any(
            (p) => p.providerId == 'google.com' || p.providerId == 'apple.com',
          ) &&
          (fbUser.email ?? '').isNotEmpty) {
        return true;
      }
    } catch (_) {}
    if (profile == null) return false;
    return profile.snapshotData['email_verified'] == true;
  }

  /// Returns true when the user has verified their email (mandatory on all
  /// account registrations).
  bool isAtLeastOneChannelVerified(UsersRecord? profile) {
    return isEmailConfirmed(profile);
  }

  /// Get verification status for current user (reloads Firebase Auth state first)
  Future<VerificationStatus> getVerificationStatus() async {
    if (!loggedIn) {
      return VerificationStatus.unverified;
    }

    try {
      await _firebaseAuth.currentUser?.reload();
    } catch (_) {}

    final fbUser = _firebaseAuth.currentUser;
    if (fbUser != null && fbUser.isAnonymous) {
      return VerificationStatus.unverified;
    }

    UsersRecord? profile = currentUserDocument;
    if (profile == null && currentUserUid.isNotEmpty) {
      try {
        profile = await UsersRecord.getDocumentOnce(
          UsersRecord.collection.doc(currentUserUid),
        );
        currentUserDocument = profile;
      } catch (_) {}
    }

    final emailVerified = isEmailConfirmed(profile);
    final phoneVerified = (profile?.snapshotData['phone_verified'] == true) ||
        ((fbUser?.phoneNumber ?? '').trim().isNotEmpty);

    if (emailVerified &&
        fbUser != null &&
        profile != null &&
        profile.snapshotData['email_verified'] != true) {
      await _markEmailVerifiedInFirestore(fbUser);
    }

    if (emailVerified && phoneVerified) {
      return VerificationStatus.fullyVerified;
    } else if (emailVerified) {
      return VerificationStatus.emailOnly;
    } else if (phoneVerified) {
      return VerificationStatus.phoneOnly;
    } else {
      return VerificationStatus.unverified;
    }
  }

  /// Check if user needs verification (neither email nor phone verified)
  bool get needsVerification {
    return !isAtLeastOneChannelVerified(currentUserDocument);
  }

  /// Synchronous check (uses cached data)
  VerificationStatus getVerificationStatusSync() {
    if (!loggedIn) return VerificationStatus.unverified;

    final profile = currentUserDocument;
    final fbUser = _firebaseAuth.currentUser;
    final emailVerified = (fbUser?.emailVerified ?? false) ||
        (profile?.snapshotData['email_verified'] == true);
    final phoneVerified = (profile?.snapshotData['phone_verified'] == true) ||
        ((fbUser?.phoneNumber ?? '').trim().isNotEmpty);

    if (emailVerified && phoneVerified) {
      return VerificationStatus.fullyVerified;
    } else if (emailVerified) {
      return VerificationStatus.emailOnly;
    } else if (phoneVerified) {
      return VerificationStatus.phoneOnly;
    } else {
      return VerificationStatus.unverified;
    }
  }

  String _formatPhoneNumber(String phone) {
    String formatted = phone.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (formatted.startsWith('0020')) {
      formatted = '+20${formatted.substring(4)}';
    } else if (formatted.startsWith('0')) {
      formatted = '+2$formatted';
    } else if (formatted.startsWith('20') && formatted.length == 12) {
      formatted = '+$formatted';
    } else if (!formatted.startsWith('+')) {
      formatted = '+$formatted';
    }
    return formatted;
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'invalid-phone-number':
        return 'رقم الهاتف غير صالح. تأكد من كتابته بصيغة صحيحة مثل 010xxxxxxxx';
      case 'missing-phone-number':
        return 'رقم الهاتف مطلوب';
      case 'quota-exceeded':
      case 'too-many-requests':
        return 'تم إرسال طلبات كثيرة خلال وقت قصير. يرجى الانتظار قليلاً أو التأكيد بالوسيلة الأخرى.';
      case 'captcha-check-failed':
      case 'app-not-authorized':
      case 'missing-client-identifier':
        return 'تحقق الأمان لرسائل SMS يتطلب تفعيل بصمات SHA-1/SHA-256 وخطة الرسائل في Firebase Console. يمكنك تأكيد البريد الإلكتروني فوراً كبديل.';
      case 'billing-not-enabled':
        return 'إرسال رسائل SMS الحقيقية في Firebase يتطلب تفعيل باقة Blaze في الكونسول. يمكنك تأكيد حسابك عبر رسالة البريد الإلكتروني مجاناً الآن.';
      case 'credential-already-in-use':
      case 'phone-number-already-exists':
        return 'رقم الهاتف هذا مرتبط بحساب آخر بالفعل';
      case 'session-expired':
        return 'انتهت صلاحية الكود، اضغط إعادة إرسال الكود للحصول على رمز جديد';
      case 'invalid-verification-code':
        return 'كود التأكيد غير صحيح، تأكد من الأرقام الستة وحاول مرة أخرى';
      case 'invalid-verification-id':
        return 'جلسة التحقق غير صالحة، اطلب كود جديد';
      default:
        return 'تعذر إتمام التحقق ($code)';
    }
  }
}

/// Verification result
class VerificationResult {
  final bool success;
  final String? message;
  final String? otpCode;

  VerificationResult._({
    required this.success,
    this.message,
    this.otpCode,
  });

  factory VerificationResult.success({
    String? message,
    String? otpCode,
  }) =>
      VerificationResult._(
        success: true,
        message: message,
        otpCode: otpCode,
      );

  factory VerificationResult.failure({required String message}) =>
      VerificationResult._(success: false, message: message);
}

enum VerificationMethod {
  email,
  phone,
}

enum VerificationPurpose {
  emailVerification,
  passwordReset,
  emailChange,
}

enum VerificationStatus {
  unverified,
  emailOnly,
  phoneOnly,
  fullyVerified,
}

extension VerificationStatusExtension on VerificationStatus {
  String get label {
    switch (this) {
      case VerificationStatus.unverified:
        return 'بانتظار التأكيد';
      case VerificationStatus.emailOnly:
        return 'البريد الإلكتروني مؤكد ✓';
      case VerificationStatus.phoneOnly:
        return 'رقم الهاتف مؤكد ✓';
      case VerificationStatus.fullyVerified:
        return 'الحساب مؤكد بالكامل ✓';
    }
  }

  String get description {
    switch (this) {
      case VerificationStatus.unverified:
        return 'يرجى تأكيد البريد الإلكتروني أو رقم الهاتف برسالة تأكيد';
      case VerificationStatus.emailOnly:
        return 'تم تأكيد البريد الإلكتروني (يمكنك تأكيد الهاتف أيضاً اختيارياً)';
      case VerificationStatus.phoneOnly:
        return 'تم تأكيد رقم الهاتف (يمكنك تأكيد البريد الإلكتروني أيضاً اختيارياً)';
      case VerificationStatus.fullyVerified:
        return 'تم تأكيد البريد الإلكتروني ورقم الهاتف بنجاح';
    }
  }
}
