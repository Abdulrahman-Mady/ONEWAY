import '/auth/auth_service.dart'
    show AuthService;
import '/auth/verification_service.dart'
    show VerificationService, VerificationStatus;
import '/components/button/button_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart'
    show FlutterFlowTheme;
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/nav/nav.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

  VerificationStatus _status = VerificationStatus.unverified;
  bool _emailVerified = false;
  bool _phoneVerified = false;
  bool _isLoading = false;

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

    _loadVerificationStatus();
    _animationController.forward();
  }

  Future<void> _loadVerificationStatus() async {
    final status = await VerificationService.instance.getVerificationStatus();
    if (mounted) {
      setState(() {
        _status = status;
        _emailVerified = status == VerificationStatus.emailOnly || status == VerificationStatus.fullyVerified;
        _phoneVerified = status == VerificationStatus.phoneOnly || status == VerificationStatus.fullyVerified;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
        backgroundColor: FlutterFlowTheme.of(context).background,
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
                        const SizedBox(height: 40),
                        // Header
                        _buildHeader(theme),
                        const SizedBox(height: 48),
                        // Verification cards
                        _buildEmailVerificationCard(theme),
                        const SizedBox(height: 20),
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
                        const SizedBox(height: 16),
                        // Skip button
                        TextButton(
                          onPressed: _handleSkip,
                          child: Text(
                            'تخطي الآن وإكمال لاحقاً',
                            style: theme.labelLarge.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme.tertiaryText,
                            ),
                          ),
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
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(FlutterFlowTheme.of(context).designToken.radius.xxl),
            boxShadow: [
              BoxShadow(
                blurRadius: 20,
                color: FlutterFlowTheme.of(context).primary.withValues(alpha: 0.2),
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Icon(
            Icons.verified_user_rounded,
            color: FlutterFlowTheme.of(context).primary,
            size: 56,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'التحقق من الحساب',
          style: theme.displayMedium.copyWith(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: FlutterFlowTheme.of(context).primaryText,
            height: 1.2,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'لأمانك، نحتاج للتحقق من بريدك الإلكتروني ورقم هاتفك',
          style: theme.bodyLarge.copyWith(
            fontSize: 16,
            color: theme.secondaryText,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmailVerificationCard(FlutterFlowTheme theme) {
    return Card(
      color: FlutterFlowTheme.of(context).surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FlutterFlowTheme.of(context).designToken.radius.xl),
        side: BorderSide(
          color: _emailVerified ? FlutterFlowTheme.of(context).success : FlutterFlowTheme.of(context).outlineVariant,
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
                    color: _emailVerified ? FlutterFlowTheme.of(context).success.withValues(alpha: 0.1) : FlutterFlowTheme.of(context).primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(FlutterFlowTheme.of(context).designToken.radius.lg),
                  ),
                  child: Icon(
                    _emailVerified ? Icons.check_circle_rounded : Icons.email_outlined,
                    color: _emailVerified ? FlutterFlowTheme.of(context).success : FlutterFlowTheme.of(context).primary,
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
                          color: FlutterFlowTheme.of(context).primaryText,
                        ),
                      ),
                      Text(
                        _maskEmail(AuthService.instance.currentUserEmail),
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
                      color: FlutterFlowTheme.of(context).success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(FlutterFlowTheme.of(context).designToken.radius.full),
                    ),
                    child: Text(
                      'مُحقق',
                      style: theme.labelSmall.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: FlutterFlowTheme.of(context).success,
                      ),
                    ),
                  ),
              ],
            ),
            if (!_emailVerified) ...[
              const SizedBox(height: 16),
              ButtonWidget(
                content: 'إرسال رابط التحقق',
                variant: 'outline',
                size: 'medium',
                fullWidth: true,
                icon: Icon(Icons.send_rounded, color: FlutterFlowTheme.of(context).primary, size: 20),
                iconPresent: true,
                loading: _isLoading,
                onPressed: _sendEmailVerification,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneVerificationCard(FlutterFlowTheme theme) {
    return Card(
      color: FlutterFlowTheme.of(context).surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FlutterFlowTheme.of(context).designToken.radius.xl),
        side: BorderSide(
          color: _phoneVerified ? FlutterFlowTheme.of(context).success : FlutterFlowTheme.of(context).outlineVariant,
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
                    color: _phoneVerified ? FlutterFlowTheme.of(context).success.withValues(alpha: 0.1) : FlutterFlowTheme.of(context).primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(FlutterFlowTheme.of(context).designToken.radius.lg),
                  ),
                  child: Icon(
                    _phoneVerified ? Icons.check_circle_rounded : Icons.phone_outlined,
                    color: _phoneVerified ? FlutterFlowTheme.of(context).success : FlutterFlowTheme.of(context).primary,
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
                          color: FlutterFlowTheme.of(context).primaryText,
                        ),
                      ),
                      Text(
                        _maskPhone(AuthService.instance.currentPhoneNumber),
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
                      color: FlutterFlowTheme.of(context).success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(FlutterFlowTheme.of(context).designToken.radius.full),
                    ),
                    child: Text(
                      'مُحقق',
                      style: theme.labelSmall.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: FlutterFlowTheme.of(context).success,
                      ),
                    ),
                  ),
              ],
            ),
            if (!_phoneVerified) ...[
              const SizedBox(height: 16),
              ButtonWidget(
                content: 'إرسال رمز التحقق (SMS)',
                variant: 'outline',
                size: 'medium',
                fullWidth: true,
                icon: Icon(Icons.sms_rounded, color: FlutterFlowTheme.of(context).primary, size: 20),
                iconPresent: true,
                loading: _isLoading,
                onPressed: _sendPhoneVerification,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _sendEmailVerification() async {
    setState(() => _isLoading = true);

    final result = await VerificationService.instance.sendEmailVerification();

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'تم إرسال رابط التحقق'),
          backgroundColor: FlutterFlowTheme.of(context).success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'فشل إرسال رابط التحقق'),
          backgroundColor: FlutterFlowTheme.of(context).error,
        ),
      );
    }
  }

  Future<void> _sendPhoneVerification() async {
    final phone = AuthService.instance.currentPhoneNumber;
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('لا يوجد رقم هاتف مسجل، يرجى إكمال ملفك الشخصي أولاً'),
          backgroundColor: FlutterFlowTheme.of(context).warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await VerificationService.instance.sendPhoneVerification(
      phoneNumber: phone,
      onCodeSent: (verificationId) {
        // In production, show OTP dialog
        _showPhoneOTPDialog(verificationId);
      },
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'فشل إرسال رمز التحقق'),
          backgroundColor: FlutterFlowTheme.of(context).error,
        ),
      );
    }
  }

  void _showPhoneOTPDialog(String verificationId) {
    final otpController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('أدخل رمز التحقق'),
        content: TextFormField(
          controller: otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: FlutterFlowTheme.of(context).bodyLarge.copyWith(
            fontSize: 24,
            letterSpacing: 8,
          ),
          decoration: InputDecoration(
            hintText: '• • • • • •',
            counterText: '',
          ),
          onChanged: (value) {
            if (value.length == 6) {
              Navigator.pop(ctx);
              _verifyPhoneCode(verificationId, value);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyPhoneCode(String verificationId, String code) async {
    setState(() => _isLoading = true);

    final result = await VerificationService.instance.verifyPhoneCode(
      verificationId: verificationId,
      smsCode: code,
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _phoneVerified = result.success;
    });

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم التحقق من رقم الهاتف بنجاح'),
          backgroundColor: FlutterFlowTheme.of(context).success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'رمز التحقق غير صحيح'),
          backgroundColor: FlutterFlowTheme.of(context).error,
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

    // Navigate to next step (complete profile or home)
    AuthRouter.instance.navigateAfterLogin(context);
  }

  Future<void> _handleSkip() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _isLoading = false);

    AuthRouter.instance.navigateAfterLogin(context);
  }

  String _maskEmail(String email) {
    if (email.isEmpty) return 'غير محدد';
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 2) return email;
    return '${name[0]}${'*' * (name.length - 2)}${name[name.length - 1]}@$domain';
  }

  String _maskPhone(String phone) {
    if (phone.isEmpty) return 'غير محدد';
    if (phone.length <= 4) return phone;
    return '${phone.substring(0, 3)}${'*' * (phone.length - 7)}${phone.substring(phone.length - 4)}';
  }
}