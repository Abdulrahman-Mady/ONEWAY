import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/backend/backend.dart';
import '/backend/schema/users_record.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Service for handling email and phone verification.
/// Supports OTP verification, email verification links, and verification status tracking.
class VerificationService {
  VerificationService._();
  static final VerificationService instance = VerificationService._();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Verification code collection
  CollectionReference get _verificationCodesCollection =>
      _firestore.collection('verification_codes');

  /// Send email verification link
  Future<VerificationResult> sendEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return VerificationResult.failure(message: 'يجب تسجيل الدخول أولاً');
      }

      if (user.emailVerified) {
        return VerificationResult.failure(message: 'البريد الإلكتروني مُحقق بالفعل');
      }

      await user.sendEmailVerification();
      return VerificationResult.success(
        message: 'تم إرسال رابط التحقق إلى بريدك الإلكتروني',
      );
    } on FirebaseAuthException catch (e) {
      return VerificationResult.failure(message: _getErrorMessage(e.code));
    } catch (e) {
      return VerificationResult.failure(message: 'حدث خطأ غير متوقع: $e');
    }
  }

  /// Check if email is verified
  Future<bool> checkEmailVerified() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return false;

      await user.reload();
      return user.emailVerified;
    } catch (e) {
      return false;
    }
  }

  /// Send phone verification code (OTP)
  Future<VerificationResult> sendPhoneVerification({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
  }) async {
    try {
      if (phoneNumber.trim().isEmpty) {
        return VerificationResult.failure(message: 'رقم الهاتف مطلوب');
      }

      final formattedPhone = _formatPhoneNumber(phoneNumber);

      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification (Android only)
          await _firebaseAuth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          print('Phone verification failed: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
        timeout: const Duration(seconds: 60),
      );

      return VerificationResult.success(
        message: 'تم إرسال رمز التحقق إلى رقم هاتفك',
      );
    } on FirebaseAuthException catch (e) {
      return VerificationResult.failure(message: _getErrorMessage(e.code));
    } catch (e) {
      return VerificationResult.failure(message: 'حدث خطأ غير متوقع: $e');
    }
  }

  /// Verify phone OTP code
  Future<VerificationResult> verifyPhoneCode({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      if (smsCode.trim().isEmpty) {
        return VerificationResult.failure(message: 'رمز التحقق مطلوب');
      }

      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );

      await _firebaseAuth.signInWithCredential(credential);

      // Update user profile with phone number
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await UsersRecord.collection.doc(user.uid).update({
          'phone_number': user.phoneNumber,
          'phone_verified': true,
          'updated_time': FieldValue.serverTimestamp(),
        });
      }

      return VerificationResult.success(
        message: 'تم التحقق من رقم الهاتف بنجاح',
      );
    } on FirebaseAuthException catch (e) {
      return VerificationResult.failure(message: _getErrorMessage(e.code));
    } catch (e) {
      return VerificationResult.failure(message: 'حدث خطأ غير متوقع: $e');
    }
  }

  /// Send email OTP code (for password reset or email change)
  Future<VerificationResult> sendEmailOTP({
    required String email,
    VerificationPurpose purpose = VerificationPurpose.emailVerification,
  }) async {
    try {
      if (email.trim().isEmpty) {
        return VerificationResult.failure(message: 'البريد الإلكتروني مطلوب');
      }

      if (!_isValidEmail(email)) {
        return VerificationResult.failure(message: 'بريد إلكتروني غير صالح');
      }

      // Generate 6-digit code
      final code = _generateOTP();

      // Store code in Firestore with expiration
      await _verificationCodesCollection.doc(email.toLowerCase()).set({
        'code': code,
        'purpose': purpose.name,
        'email': email.toLowerCase(),
        'created_at': FieldValue.serverTimestamp(),
        'expires_at': Timestamp.fromDate(
          DateTime.now().add(const Duration(minutes: 10)),
        ),
        'attempts': 0,
      });

      // In production, send email via Cloud Function or email service
      // For now, we'll log the code (in production, use SendGrid, Mailgun, etc.)
      print('OTP for $email (${purpose.name}): $code');

      return VerificationResult.success(
        message: 'تم إرسال رمز التحقق إلى بريدك الإلكتروني',
        // In development, return code for testing
        otpCode: const bool.fromEnvironment('dart.vm.product') == false ? code : null,
      );
    } on FirebaseException catch (e) {
      return VerificationResult.failure(message: e.message ?? 'فشل إرسال رمز التحقق');
    } catch (e) {
      return VerificationResult.failure(message: 'حدث خطأ غير متوقع: $e');
    }
  }

  /// Verify email OTP code
  Future<VerificationResult> verifyEmailOTP({
    required String email,
    required String code,
    VerificationPurpose purpose = VerificationPurpose.emailVerification,
  }) async {
    try {
      if (code.trim().isEmpty) {
        return VerificationResult.failure(message: 'رمز التحقق مطلوب');
      }

      final doc = await _verificationCodesCollection
          .doc(email.toLowerCase())
          .get();

      if (!doc.exists) {
        return VerificationResult.failure(
          message: 'رمز التحقق منتهي الصلاحية أو غير موجود، يرجى طلب رمز جديد',
        );
      }

      final data = doc.data() as Map<String, dynamic>;
      final storedCode = data['code'] as String?;
      final storedPurpose = data['purpose'] as String?;
      final expiresAt = data['expires_at'] as Timestamp?;
      final attempts = data['attempts'] as int? ?? 0;

      // Check expiration
      if (expiresAt != null && expiresAt.toDate().isBefore(DateTime.now())) {
        await doc.reference.delete();
        return VerificationResult.failure(
          message: 'انتهت صلاحية رمز التحقق، يرجى طلب رمز جديد',
        );
      }

      // Check attempts
      if (attempts >= 5) {
        await doc.reference.delete();
        return VerificationResult.failure(
          message: 'تم تجاوز عدد المحاولات المسموح، يرجى طلب رمز جديد',
        );
      }

      // Verify code
      if (storedCode != code.trim()) {
        // Increment attempts
        await doc.reference.update({'attempts': attempts + 1});
        return VerificationResult.failure(
          message: 'رمز التحقق غير صحيح، متبقي ${5 - attempts - 1} محاولات',
        );
      }

      // Check purpose
      if (storedPurpose != purpose.name) {
        return VerificationResult.failure(
          message: 'رمز التحقق غير صالح لهذا الغرض',
        );
      }

      // Code verified successfully - delete it
      await doc.reference.delete();

      // Handle purpose-specific actions
      switch (purpose) {
        case VerificationPurpose.emailVerification:
          // Update user profile
          if (loggedIn) {
            await UsersRecord.collection.doc(currentUserUid).update({
              'email_verified': true,
              'email': email.toLowerCase(),
              'updated_time': FieldValue.serverTimestamp(),
            });
          }
          break;
        case VerificationPurpose.passwordReset:
          // Allow password reset (handled by caller)
          break;
        case VerificationPurpose.emailChange:
          // Update email in Firebase Auth and Firestore
          // Using verifyBeforeUpdateEmail which is the recommended approach
          if (loggedIn) {
            final user = _firebaseAuth.currentUser;
            if (user != null) {
              await user.verifyBeforeUpdateEmail(email.toLowerCase());
              // Note: The email will be updated in Auth after user clicks the verification link
              // We update Firestore immediately since we already verified via OTP
              await UsersRecord.collection.doc(currentUserUid).update({
                'email': email.toLowerCase(),
                'email_verified': true,
                'updated_time': FieldValue.serverTimestamp(),
              });
            }
          }
          break;
      }

      return VerificationResult.success(
        message: 'تم التحقق بنجاح',
      );
    } on FirebaseException catch (e) {
      return VerificationResult.failure(message: e.message ?? 'فشل التحقق من الرمز');
    } catch (e) {
      return VerificationResult.failure(message: 'حدث خطأ غير متوقع: $e');
    }
  }

  /// Resend verification code
  Future<VerificationResult> resendCode({
    required String contact,
    VerificationMethod method = VerificationMethod.email,
    VerificationPurpose purpose = VerificationPurpose.emailVerification,
  }) async {
    switch (method) {
      case VerificationMethod.email:
        return sendEmailOTP(email: contact, purpose: purpose);
      case VerificationMethod.phone:
        return VerificationResult.failure(
          message: 'إعادة إرسال رمز SMS غير مدعومة حالياً',
        );
    }
  }

  /// Get verification status for current user
  Future<VerificationStatus> getVerificationStatus() async {
    if (!loggedIn) {
      return VerificationStatus.unverified;
    }

    final profile = currentUserDocument;
    if (profile == null) {
      return VerificationStatus.unverified;
    }

    final emailVerified = profile.hasEmail() &&
        (currentUser?.emailVerified ?? false);
    // Access phone_verified from raw snapshot data since it's not in the model
    final phoneVerified = profile.hasPhoneNumber() &&
        (profile.snapshotData['phone_verified'] == true);

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

  /// Check if user needs verification
  bool get needsVerification {
    final status = getVerificationStatusSync();
    return status != VerificationStatus.fullyVerified;
  }

  /// Synchronous check (uses cached data)
  VerificationStatus getVerificationStatusSync() {
    if (!loggedIn) return VerificationStatus.unverified;

    final profile = currentUserDocument;
    if (profile == null) return VerificationStatus.unverified;

    final emailVerified = profile.hasEmail() &&
        (currentUser?.emailVerified ?? false);
    // Access phone_verified from raw snapshot data since it's not in the model
    final phoneVerified = profile.hasPhoneNumber() &&
        (profile.snapshotData['phone_verified'] == true);

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
    String formatted = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Handle Egyptian numbers
    if (formatted.startsWith('0')) {
      formatted = '+2$formatted';
    } else if (!formatted.startsWith('+')) {
      formatted = '+$formatted';
    }

    return formatted;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w.+-]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  String _generateOTP() {
    return (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'invalid-phone-number':
        return 'رقم الهاتف غير صالح';
      case 'missing-phone-number':
        return 'رقم الهاتف مطلوب';
      case 'quota-exceeded':
        return 'تم تجاوز الحد المسموح، يرجى المحاولة لاحقاً';
      case 'captcha-check-failed':
        return 'فشل التحقق من الكابتشا';
      case 'session-expired':
        return 'انتهت الجلسة، يرجى المحاولة مرة أخرى';
      case 'invalid-verification-code':
        return 'رمز التحقق غير صحيح';
      case 'invalid-verification-id':
        return 'جلسة التحقق غير صالحة';
      default:
        return 'حدث خطأ: $code';
    }
  }
}

/// Verification result
class VerificationResult {
  final bool success;
  final String? message;
  final String? otpCode; // Only in development

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

/// Verification method
enum VerificationMethod {
  email,
  phone,
}

/// Verification purpose
enum VerificationPurpose {
  emailVerification,
  passwordReset,
  emailChange,
}

/// Verification status
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
        return 'غير مُحقق';
      case VerificationStatus.emailOnly:
        return 'البريد الإلكتروني مُحقق فقط';
      case VerificationStatus.phoneOnly:
        return 'الهاتف مُحقق فقط';
      case VerificationStatus.fullyVerified:
        return 'مُحقق بالكامل';
    }
  }

  String get description {
    switch (this) {
      case VerificationStatus.unverified:
        return 'يجب التحقق من البريد الإلكتروني والهاتف';
      case VerificationStatus.emailOnly:
        return 'تم التحقق من البريد الإلكتروني، يلزم التحقق من الهاتف';
      case VerificationStatus.phoneOnly:
        return 'تم التحقق من الهاتف، يلزم التحقق من البريد الإلكتروني';
      case VerificationStatus.fullyVerified:
        return 'تم التحقق من جميع وسائل الاتصال';
    }
  }
}