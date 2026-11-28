import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '/auth/auth_service.dart' show AuthService;
import '/auth/firebase_auth/auth_util.dart';
import '/auth/verification_service.dart'
    show VerificationService, VerificationStatus;
import '/components/button/button_widget.dart';
import '/core/constants/profile_options.dart';
import '/flutter_flow/flutter_flow_theme.dart' show FlutterFlowTheme;
import '/flutter_flow/nav/nav.dart';
import '/index.dart';

class VerifyAccountWidget extends StatefulWidget {
  const VerifyAccountWidget({super.key});

  static String routeName = 'VerifyAccount';
  static String routePath = '/verify-account';

  @override
  State<VerifyAccountWidget> createState() => _VerifyAccountWidgetState();
}

class _VerifyAccountWidgetState extends State<VerifyAccountWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  bool _emailVerified = false;
  bool _phoneVerified = false;
  bool _emailLinkSent = false;
  bool _autoSentInitialEmail = false;
  bool _sendingEmail = false;
  bool _checkingEmail = false;
  bool _sendingSms = false;
  bool _verifyingSms = false;
  String? _verificationId;
  int _emailCooldownSec = 0;
  int _smsCooldownSec = 0;

  Timer? _cooldownTimer;
  Timer? _emailPollTimer;

  /// Mandatory email confirmation on all account registrations.
  bool get _canProceed => _emailVerified;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.14),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.15, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    _phoneCtrl.text = AuthService.instance.currentPhoneNumber;
    _loadVerificationStatus();
    _animationController.forward();
  }

  Future<void> _loadVerificationStatus() async {
    final status = await VerificationService.instance.getVerificationStatus();
    if (!mounted) return;
    final phone = AuthService.instance.currentPhoneNumber;
    if (_phoneCtrl.text.trim().isEmpty && phone.isNotEmpty) {
      _phoneCtrl.text = phone;
    }
    setState(() {
      _emailVerified = status == VerificationStatus.emailOnly ||
          status == VerificationStatus.fullyVerified;
      _phoneVerified = status == VerificationStatus.phoneOnly ||
          status == VerificationStatus.fullyVerified;
    });
    if (!_emailVerified) {
      _startEmailAutoPoll();
      if (!_autoSentInitialEmail &&
          AuthService.instance.currentUserEmail.isNotEmpty) {
        _autoSentInitialEmail = true;
        unawaited(_sendEmailConfirmation());
      }
    }
  }

  void _startEmailAutoPoll() {
    _emailPollTimer?.cancel();
    _emailPollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!mounted || _emailVerified) {
        _emailPollTimer?.cancel();
        return;
      }
      final verified = await VerificationService.instance.checkEmailVerified();
      if (verified && mounted) {
        _emailPollTimer?.cancel();
        setState(() => _emailVerified = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم تأكيد بريدك الإلكتروني بنجاح ✓'),
            backgroundColor: FlutterFlowTheme.of(context).success,
          ),
        );
      }
    });
  }

  void _startCooldown({bool email = false, bool sms = false}) {
    setState(() {
      if (email) _emailCooldownSec = 60;
      if (sms) _smsCooldownSec = 60;
    });
    _cooldownTimer ??= Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_emailCooldownSec > 0) _emailCooldownSec--;
        if (_smsCooldownSec > 0) _smsCooldownSec--;
      });
      if (_emailCooldownSec <= 0 && _smsCooldownSec <= 0) {
        timer.cancel();
        _cooldownTimer = null;
      }
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _emailPollTimer?.cancel();
    _animationController.dispose();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendEmailConfirmation() async {
    if (_sendingEmail || _emailCooldownSec > 0) return;
    setState(() => _sendingEmail = true);
    final result = await VerificationService.instance.sendEmailVerification();
    if (!mounted) return;
    setState(() {
      _sendingEmail = false;
      if (result.success) _emailLinkSent = true;
    });

    if (result.success) {
      _startCooldown(email: true);
      _startEmailAutoPoll();
      await _loadVerificationStatus();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'تم إرسال رسالة التأكيد لبريدك'),
          backgroundColor: FlutterFlowTheme.of(context).success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'تعذر إرسال رسالة التأكيد'),
          backgroundColor: FlutterFlowTheme.of(context).error,
        ),
      );
    }
  }

  Future<void> _checkEmailNow() async {
    if (_checkingEmail) return;
    setState(() => _checkingEmail = true);
    final ok = await VerificationService.instance.checkEmailVerified();
    if (!mounted) return;
    setState(() {
      _checkingEmail = false;
      _emailVerified = ok;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'تم تأكيد البريد الإلكتروني بنجاح ✓'
              : 'لم يتم التفعيل بعد — افتح الرسالة في بريدك (أو مجلد Spam) واضغط على الرابط أولاً.',
        ),
        backgroundColor: ok
            ? FlutterFlowTheme.of(context).success
            : FlutterFlowTheme.of(context).warning,
      ),
    );
  }

  Future<void> _sendPhoneSms({bool isResend = false}) async {
    if (_sendingSms || _smsCooldownSec > 0) return;
    final rawPhone = _phoneCtrl.text.trim();
    if (!ProfileOptions.isValidEgyptianPhone(rawPhone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('أدخل رقم هاتف مصري صحيح (مثال: 010xxxxxxxx)'),
          backgroundColor: FlutterFlowTheme.of(context).error,
        ),
      );
      return;
    }

    setState(() => _sendingSms = true);
    final result = await VerificationService.instance.sendPhoneVerification(
      phoneNumber: rawPhone,
      isResend: isResend,
      onCodeSent: (verId) {
        if (mounted) {
          setState(() => _verificationId = verId);
        }
      },
      onAutoVerified: () {
        if (mounted) {
          setState(() {
            _phoneVerified = true;
            _verificationId = null;
          });
        }
      },
    );

    if (!mounted) return;
    setState(() => _sendingSms = false);

    if (result.success) {
      _startCooldown(sms: true);
      await _loadVerificationStatus();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'تم إرسال كود التأكيد في رسالة SMS'),
          backgroundColor: FlutterFlowTheme.of(context).success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'تعذر إرسال رسالة SMS'),
          backgroundColor: FlutterFlowTheme.of(context).error,
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  Future<void> _verifySmsOtp() async {
    if (_verifyingSms || _verificationId == null) return;
    final code = _otpCtrl.text.trim();
    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('أدخل الكود المكون من 6 أرقام المرسل لهاتفك'),
          backgroundColor: FlutterFlowTheme.of(context).warning,
        ),
      );
      return;
    }

    setState(() => _verifyingSms = true);
    final result = await VerificationService.instance.verifyPhoneCode(
      verificationId: _verificationId!,
      smsCode: code,
      rawPhoneNumber: _phoneCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _verifyingSms = false;
      if (result.success) {
        _phoneVerified = true;
        _verificationId = null;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.message ??
              (result.success ? 'تم تأكيد رقم الهاتف ✓' : 'الكود غير صحيح'),
        ),
        backgroundColor: result.success
            ? FlutterFlowTheme.of(context).success
            : FlutterFlowTheme.of(context).error,
      ),
    );
  }

  Future<void> _handleContinue() async {
    if (!_canProceed) {
      final ok = await VerificationService.instance.checkEmailVerified();
      if (ok && mounted) {
        setState(() => _emailVerified = true);
      }
    }
    if (!mounted) return;
    if (!_canProceed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'يرجى تأكيد البريد الإلكتروني أولاً من خلال الرابط المرسل إلى بريدك للمتابعة.',
          ),
          backgroundColor: FlutterFlowTheme.of(context).warning,
        ),
      );
      return;
    }
    await AuthRouter.instance.navigateAfterLogin(context);
  }

  Future<void> _handleSignOut() async {
    GoRouter.of(context).prepareAuthEvent();
    await AuthService.instance.signOut();
    if (!mounted) return;
    context.goNamed(AuthenticationWidget.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final email = AuthService.instance.currentUserEmail;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'يرجى تأكيد بريدك الإلكتروني أولاً، أو اضغط تسجيل الخروج لاستخدام حساب آخر.',
            ),
          ),
        );
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: theme.background,
          appBar: AppBar(
            backgroundColor: theme.navy,
            foregroundColor: Colors.white,
            centerTitle: true,
            title: const Text(
              'تأكيد الحساب',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHeader(theme),
                          const SizedBox(height: 24),
                          if (email.isNotEmpty) ...[
                            _buildEmailCard(theme, email),
                            const SizedBox(height: 18),
                          ],
                          _buildPhoneCard(theme),
                          const SizedBox(height: 28),
                          ButtonWidget(
                            content: _canProceed
                                ? 'متابعة إلى التطبيق'
                                : 'يرجى تأكيد البريد الإلكتروني للمتابعة',
                            variant: 'primary',
                            size: 'large',
                            fullWidth: true,
                            disabled: !_canProceed,
                            icon: const Icon(
                              Icons.check_circle_outline_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            iconPresent: true,
                            onPressed: _handleContinue,
                          ),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: _handleSignOut,
                            icon: Icon(Icons.logout_rounded,
                                size: 18, color: theme.secondaryText),
                            label: Text(
                              'تسجيل الخروج واستخدام حساب آخر',
                              style: theme.labelLarge.copyWith(
                                fontSize: 13.5,
                                color: theme.secondaryText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildHeader(FlutterFlowTheme theme) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _canProceed
                  ? Icons.verified_rounded
                  : Icons.mark_email_read_outlined,
              color: theme.primary,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _canProceed
                      ? 'تم تأكيد البريد الإلكتروني بنجاح ✓'
                      : 'تأكيد البريد الإلكتروني (إلزامي لتفعيل الحساب)',
                  style: theme.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'أرسلنا رابط التفعيل إلى بريدك الإلكتروني. افتح الرسالة واضغط على الرابط لتأكيد حسابك والمتابعة.',
                  style: theme.bodySmall.copyWith(
                    color: theme.secondaryText,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailCard(FlutterFlowTheme theme, String email) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _emailVerified ? theme.success : theme.outlineVariant,
          width: _emailVerified ? 2 : 1.4,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (_emailVerified ? theme.success : theme.primary)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _emailVerified
                      ? Icons.check_circle_rounded
                      : Icons.alternate_email_rounded,
                  color: _emailVerified ? theme.success : theme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تأكيد البريد الإلكتروني',
                      style: theme.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.primaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: theme.bodySmall.copyWith(
                        color: theme.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              if (_emailVerified)
                _VerifiedPill(theme: theme),
            ],
          ),
          if (!_emailVerified) ...[
            const SizedBox(height: 14),
            if (_emailLinkSent)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'أرسلنا رسالة تأكيد إلى بريدك الإلكتروني. افتح الرسالة (تحقق أيضاً من الرسائل غير المرغوب فيها Spam) واضغط على الرابط — سيتم التحديث تلقائياً.',
                  style: theme.bodySmall.copyWith(
                    color: theme.primary,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
              ),
            FilledButton.icon(
              onPressed: _sendingEmail || _emailCooldownSec > 0
                  ? null
                  : _sendEmailConfirmation,
              icon: _sendingEmail
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.mark_email_unread_outlined, size: 19),
              label: Text(
                _emailCooldownSec > 0
                    ? 'إعادة إرسال الرابط بعد ($_emailCooldownSec ث)'
                    : _emailLinkSent
                        ? 'إعادة إرسال رابط التأكيد للبريد'
                        : 'إرسال رسالة تأكيد للبريد الإلكتروني',
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _checkingEmail ? null : _checkEmailNow,
              icon: _checkingEmail
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('ضغطت على الرابط في الإيميل — تحقق الآن'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhoneCard(FlutterFlowTheme theme) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _phoneVerified ? theme.success : theme.outlineVariant,
          width: _phoneVerified ? 2 : 1.4,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (_phoneVerified ? theme.success : theme.primary)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _phoneVerified
                      ? Icons.check_circle_rounded
                      : Icons.sms_outlined,
                  color: _phoneVerified ? theme.success : theme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تأكيد رقم الهاتف برسالة SMS',
                      style: theme.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.primaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _phoneVerified
                          ? (_phoneCtrl.text.trim().isNotEmpty
                              ? _phoneCtrl.text.trim()
                              : AuthService.instance.currentPhoneNumber)
                          : 'إرسال رمز تأكيد (OTP) مكوّن من 6 أرقام',
                      style: theme.bodySmall.copyWith(
                        color: theme.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              if (_phoneVerified)
                _VerifiedPill(theme: theme),
            ],
          ),
          if (!_phoneVerified) ...[
            const SizedBox(height: 14),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              enabled: !_sendingSms && !_verifyingSms,
              decoration: InputDecoration(
                labelText: 'رقم الهاتف المصري',
                hintText: '010xxxxxxxx',
                prefixIcon: const Icon(Icons.phone_android_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _sendingSms || _smsCooldownSec > 0
                  ? null
                  : () => _sendPhoneSms(isResend: _verificationId != null),
              icon: _sendingSms
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sms_rounded, size: 18),
              label: Text(
                _smsCooldownSec > 0
                    ? 'إعادة إرسال رسالة SMS بعد ($_smsCooldownSec ث)'
                    : _verificationId != null
                        ? 'إعادة إرسال كود SMS'
                        : 'إرسال رسالة كود التأكيد (SMS)',
              ),
            ),
            if (_verificationId != null) ...[
              const SizedBox(height: 14),
              TextField(
                controller: _otpCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: theme.titleLarge.copyWith(
                  letterSpacing: 8,
                  fontWeight: FontWeight.w800,
                ),
                decoration: InputDecoration(
                  labelText: 'أدخل كود الـ 6 أرقام',
                  hintText: '• • • • • •',
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onSubmitted: (_) => _verifySmsOtp(),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: _verifyingSms ? null : _verifySmsOtp,
                icon: _verifyingSms
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.verified_user_rounded, size: 19),
                label: const Text('تأكيد كود الهاتف'),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _VerifiedPill extends StatelessWidget {
  const _VerifiedPill({required this.theme});

  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: theme.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'مؤكد ✓',
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: theme.success,
        ),
      ),
    );
  }
}
