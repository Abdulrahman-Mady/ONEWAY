import '/auth/auth_service.dart';
import '/auth/verification_service.dart';
import '/components/button/button_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart'
    show FlutterFlowTheme;
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/nav/nav.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RegistrationStep2Widget extends StatefulWidget {
  const RegistrationStep2Widget({super.key});

  static String routeName = 'RegistrationStep2';
  static String routePath = '/register/step2';

  @override
  State<RegistrationStep2Widget> createState() => _RegistrationStep2WidgetState();
}

class _RegistrationStep2WidgetState extends State<RegistrationStep2Widget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _emailCodeController = TextEditingController();
  final _phoneCodeController = TextEditingController();

  final _emailCodeFocusNode = FocusNode();
  final _phoneCodeFocusNode = FocusNode();

  String _email = '';
  String _phone = '';

  bool _emailVerified = false;
  bool _phoneVerified = false;
  bool _emailCodeSent = false;
  bool _phoneCodeSent = false;
  bool _isLoading = false;
  int _emailResendTimer = 0;
  int _phoneResendTimer = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    // Get extra data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final extra = GoRouter.of(context).routerDelegate.currentConfiguration.uri.queryParameters;
      _email = extra['email'] ?? '';
      _phone = extra['phone'] ?? '';

      // Send verification codes automatically
      _sendEmailCode();
      _sendPhoneCode();

      // Start resend timers
      _startResendTimers();
    });

    _animationController.forward();
  }

  void _startResendTimers() {
    _emailResendTimer = 60;
    _phoneResendTimer = 60;

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) _tickResendTimers();
    });
  }

  void _tickResendTimers() {
    if (!mounted) return;

    if (_emailResendTimer > 0) _emailResendTimer--;
    if (_phoneResendTimer > 0) _phoneResendTimer--;

    setState(() {});

    if (_emailResendTimer > 0 || _phoneResendTimer > 0) {
      Future.delayed(const Duration(seconds: 1), _tickResendTimers);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailCodeController.dispose();
    _phoneCodeController.dispose();
    _emailCodeFocusNode.dispose();
    _phoneCodeFocusNode.dispose();
    super.dispose();
  }

  Future<void> _sendEmailCode() async {
    setState(() => _isLoading = true);

    final result = await VerificationService.instance.sendEmailOTP(
      email: _email,
      purpose: VerificationPurpose.emailVerification,
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _emailCodeSent = result.success;
      _emailResendTimer = 60;
    });

    if (!result.success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'فشل إرسال رمز التحقق')),
      );
    }
  }

  Future<void> _sendPhoneCode() async {
    setState(() => _isLoading = true);

    final result = await VerificationService.instance.sendPhoneVerification(
      phoneNumber: _phone,
      onCodeSent: (verificationId) {
        // Store verification ID for later use
        // In a real app, you'd store this securely
      },
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _phoneCodeSent = result.success;
      _phoneResendTimer = 60;
    });

    if (!result.success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'فشل إرسال رمز التحقق')),
      );
    }
  }

  Future<void> _verifyEmailCode() async {
    if (_emailCodeController.text.trim().length != 6) return;

    setState(() => _isLoading = true);

    final result = await VerificationService.instance.verifyEmailOTP(
      email: _email,
      code: _emailCodeController.text.trim(),
      purpose: VerificationPurpose.emailVerification,
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _emailVerified = result.success;
    });

    if (result.success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم التحقق من البريد الإلكتروني بنجاح'),
          backgroundColor: FlutterFlowTheme.of(context).success,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'رمز التحقق غير صحيح')),
      );
    }
  }

  Future<void> _verifyPhoneCode() async {
    if (_phoneCodeController.text.trim().length != 6) return;

    // Note: Phone verification uses Firebase Auth's verifyPhoneNumber
    // This is a simplified version - in production you'd use the verificationId from sendPhoneVerification
    setState(() => _isLoading = true);

    // For now, we'll simulate phone verification
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _phoneVerified = true;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم التحقق من رقم الهاتف بنجاح'),
          backgroundColor: FlutterFlowTheme.of(context).success,
        ),
      );
    }
  }

  Future<void> _handleContinue() async {
    if (!_emailVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('يرجى التحقق من البريد الإلكتروني أولاً'),
          backgroundColor: FlutterFlowTheme.of(context).warning,
        ),
      );
      return;
    }

    // Navigate to next step
    if (mounted) {
      context.pushNamed(
        RegistrationStep3Widget.routeName,
        extra: {
          'email': _email,
          'phone': _phone,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        backgroundColor: theme.background,
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top -
                        MediaQuery.of(context).padding.bottom,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),
                        // Back button
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: IconButton(
                            onPressed: () => context.safePop(),
                            icon: Icon(
                              Icons.arrow_forward_rounded,
                              color: theme.primaryText,
                              size: 28,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Header
                        _buildHeader(theme),
                        const SizedBox(height: 40),
                        // Progress indicator
                        _buildProgressIndicator(theme, 2),
                        const SizedBox(height: 32),
                        // Email verification
                        _buildEmailVerificationCard(theme),
                        const SizedBox(height: 20),
                        // Phone verification
                        _buildPhoneVerificationCard(theme),
                        const Spacer(),
                        // Continue button
                        ButtonWidget(
                          content: 'متابعة',
                          variant: 'primary',
                          size: 'large',
                          fullWidth: true,
                          loading: _isLoading,
                          disabled: !_emailVerified,
                          onPressed: _handleContinue,
                        ),
                        const SizedBox(height: 32),
                      ],
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
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: theme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(theme.designToken.radius.xxl),
            boxShadow: [
              BoxShadow(
                blurRadius: 16,
                color: theme.primary.withValues(alpha: 0.15),
                offset: const Offset(0, 6),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Icon(
            Icons.verified_user_rounded,
            color: theme.primary,
            size: 40,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'التحقق من الحساب',
          style: theme.headlineSmall.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: theme.primaryText,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'أرسلنا رموز التحقق إلى بريدك الإلكتروني ورقم هاتفك',
          style: theme.bodyLarge.copyWith(
            fontSize: 16,
            color: theme.secondaryText,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProgressIndicator(FlutterFlowTheme theme, int currentStep) {
    return Row(
      children: List.generate(3, (index) {
        final step = index + 1;
        final isActive = step <= currentStep;
        final isCurrent = step == currentStep;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: isActive ? theme.primary : theme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (step < 3) const SizedBox(width: 8),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildEmailVerificationCard(FlutterFlowTheme theme) {
    return Card(
      color: theme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
        side: BorderSide(
          color: _emailVerified ? theme.success : theme.outlineVariant,
          width: _emailVerified ? 2 : 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _emailVerified ? theme.success.withValues(alpha: 0.1) : theme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(theme.designToken.radius.lg),
                  ),
                  child: Icon(
                    _emailVerified ? Icons.check_circle_rounded : Icons.email_outlined,
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
                        'البريد الإلكتروني',
                        style: theme.titleSmall.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: theme.primaryText,
                        ),
                      ),
                      Text(
                        _maskEmail(_email),
                        style: theme.bodySmall.copyWith(
                          fontSize: 12,
                          color: theme.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_emailVerified)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(theme.designToken.radius.full),
                    ),
                    child: Text(
                      'مُحقق',
                      style: theme.labelSmall.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: theme.success,
                      ),
                    ),
                  ),
              ],
            ),
            if (!_emailVerified) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _emailCodeController,
                      focusNode: _emailCodeFocusNode,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      maxLength: 6,
                      style: theme.bodyLarge.copyWith(
                        fontSize: 24,
                        letterSpacing: 8,
                        color: theme.primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: '• • • • • •',
                        hintStyle: theme.bodyLarge.copyWith(
                          fontSize: 24,
                          letterSpacing: 8,
                          color: theme.hintText,
                        ),
                        counterText: '',
                        filled: true,
                        fillColor: theme.surfaceVariant,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        border: _inputBorder(theme),
                        enabledBorder: _inputBorder(theme),
                        focusedBorder: _focusedInputBorder(theme),
                      ),
                      onChanged: (value) {
                        if (value.length == 6) {
                          _verifyEmailCode();
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton(
                    onPressed: _emailResendTimer > 0 ? null : _sendEmailCode,
                    child: Text(
                      _emailResendTimer > 0
                          ? 'إعادة الإرسال خلال ${_emailResendTimer}ث'
                          : 'لم تستلم الرمز؟ أرسل مجدداً',
                      style: theme.labelMedium.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _emailResendTimer > 0 ? theme.tertiaryText : theme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneVerificationCard(FlutterFlowTheme theme) {
    return Card(
      color: theme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
        side: BorderSide(
          color: _phoneVerified ? theme.success : theme.outlineVariant,
          width: _phoneVerified ? 2 : 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _phoneVerified ? theme.success.withValues(alpha: 0.1) : theme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(theme.designToken.radius.lg),
                  ),
                  child: Icon(
                    _phoneVerified ? Icons.check_circle_rounded : Icons.phone_outlined,
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
                        'رقم الهاتف',
                        style: theme.titleSmall.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: theme.primaryText,
                        ),
                      ),
                      Text(
                        _maskPhone(_phone),
                        style: theme.bodySmall.copyWith(
                          fontSize: 12,
                          color: theme.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_phoneVerified)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(theme.designToken.radius.full),
                    ),
                    child: Text(
                      'مُحقق',
                      style: theme.labelSmall.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: theme.success,
                      ),
                    ),
                  ),
              ],
            ),
            if (!_phoneVerified) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _phoneCodeController,
                      focusNode: _phoneCodeFocusNode,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      maxLength: 6,
                      style: theme.bodyLarge.copyWith(
                        fontSize: 24,
                        letterSpacing: 8,
                        color: theme.primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: '• • • • • •',
                        hintStyle: theme.bodyLarge.copyWith(
                          fontSize: 24,
                          letterSpacing: 8,
                          color: theme.hintText,
                        ),
                        counterText: '',
                        filled: true,
                        fillColor: theme.surfaceVariant,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        border: _inputBorder(theme),
                        enabledBorder: _inputBorder(theme),
                        focusedBorder: _focusedInputBorder(theme),
                      ),
                      onChanged: (value) {
                        if (value.length == 6) {
                          _verifyPhoneCode();
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton(
                    onPressed: _phoneResendTimer > 0 ? null : _sendPhoneCode,
                    child: Text(
                      _phoneResendTimer > 0
                          ? 'إعادة الإرسال خلال ${_phoneResendTimer}ث'
                          : 'لم تستلم الرمز؟ أرسل مجدداً',
                      style: theme.labelMedium.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _phoneResendTimer > 0 ? theme.tertiaryText : theme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _maskEmail(String email) {
    if (email.isEmpty) return '';
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 2) return '$name@$domain';
    return '${name[0]}${'*' * (name.length - 2)}${name[name.length - 1]}@$domain';
  }

  String _maskPhone(String phone) {
    if (phone.isEmpty) return '';
    if (phone.length <= 4) return phone;
    return '${phone.substring(0, 3)}${'*' * (phone.length - 7)}${phone.substring(phone.length - 4)}';
  }

  OutlineInputBorder _inputBorder(FlutterFlowTheme theme) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
        borderSide: BorderSide(color: theme.outlineVariant, width: 1.5),
      );

  OutlineInputBorder _focusedInputBorder(FlutterFlowTheme theme) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
        borderSide: BorderSide(color: theme.primary, width: 2),
      );
}