import '/auth/auth_service.dart'
    show AuthService;
import '/components/button/button_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart'
    show FlutterFlowTheme;
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/nav/nav.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ForgotPasswordWidget extends StatefulWidget {
  const ForgotPasswordWidget({super.key});

  static String routeName = 'ForgotPassword';
  static String routePath = '/forgot-password';

  @override
  State<ForgotPasswordWidget> createState() => _ForgotPasswordWidgetState();
}

class _ForgotPasswordWidgetState extends State<ForgotPasswordWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _emailFocusNode = FocusNode();

  bool _isLoading = false;
  bool _emailSent = false;

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

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _emailFocusNode.dispose();
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
                        const SizedBox(height: 40),
                        // Back button
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: IconButton(
                            onPressed: () => context.pop(),
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
                        const SizedBox(height: 48),
                        // Form or Success
                        _emailSent ? _buildSuccessView(theme) : _buildForm(theme),
                        const Spacer(),
                        // Login link
                        _buildLoginLink(theme),
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
            color: theme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(theme.designToken.radius.xxl),
            boxShadow: [
              BoxShadow(
                blurRadius: 20,
                color: theme.primary.withValues(alpha: 0.2),
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Icon(
            _emailSent ? Icons.check_circle_rounded : Icons.lock_reset_rounded,
            color: _emailSent ? theme.success : theme.primary,
            size: 56,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _emailSent ? 'تم الإرسال!' : 'إعادة تعيين كلمة المرور',
          style: theme.displayMedium.copyWith(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: theme.primaryText,
            height: 1.2,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _emailSent
              ? 'أرسلنا رابط إعادة التعيين إلى بريدك الإلكتروني'
              : 'أدخل بريدك الإلكتروني لاستلام رابط إعادة تعيين كلمة المرور',
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

  Widget _buildForm(FlutterFlowTheme theme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email Field
          TextFormField(
            controller: _emailController,
            focusNode: _emailFocusNode,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            style: theme.bodyLarge.copyWith(fontSize: 16, color: theme.primaryText),
            decoration: InputDecoration(
              labelText: 'البريد الإلكتروني *',
              hintText: 'example@mail.com',
              prefixIcon: Icon(Icons.email_outlined, color: theme.onSurfaceVariant, size: 22),
              filled: true,
              fillColor: theme.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              border: _inputBorder(theme),
              enabledBorder: _inputBorder(theme),
              focusedBorder: _focusedInputBorder(theme),
              errorBorder: _errorInputBorder(theme),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'البريد الإلكتروني مطلوب';
              }
              if (!_isValidEmail(value.trim())) {
                return 'بريد إلكتروني غير صالح';
              }
              return null;
            },
            onFieldSubmitted: (_) => _handleSubmit(),
          ),
          const SizedBox(height: 32),
          // Submit Button
          ButtonWidget(
            content: 'إرسال رابط إعادة التعيين',
            variant: 'primary',
            size: 'large',
            fullWidth: true,
            loading: _isLoading,
            onPressed: _handleSubmit,
          ),
          const SizedBox(height: 16),
          // Info text
          Text(
            'سيصلك رابط إعادة التعيين خلال دقائق قليلة.\nتحقق من مجلد السبام إذا لم تجده.',
            style: theme.bodySmall.copyWith(
              fontSize: 12,
              color: theme.tertiaryText,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(FlutterFlowTheme theme) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: theme.success.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.mark_email_read_rounded,
            color: theme.success,
            size: 50,
          ),
        ).animate().scale(duration: Duration(milliseconds: 600), curve: Curves.elasticOut),
        const SizedBox(height: 24),
        Text(
          'تم إرسال الرابط!',
          style: theme.headlineSmall.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: theme.primaryText,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'أرسلنا رابط إعادة تعيين كلمة المرور إلى\n${_maskEmail(_emailController.text)}',
          style: theme.bodyLarge.copyWith(
            fontSize: 16,
            color: theme.secondaryText,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        ButtonWidget(
          content: 'العودة لتسجيل الدخول',
          variant: 'primary',
          size: 'large',
          fullWidth: true,
          onPressed: () => context.pushNamed(AuthenticationWidget.routeName),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _resendEmail,
          child: Text(
            'إعادة إرسال الرابط',
            style: theme.labelLarge.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginLink(FlutterFlowTheme theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'تذكرت كلمة المرور؟ ',
          style: theme.bodyMedium.copyWith(fontSize: 14, color: theme.secondaryText),
        ),
        TextButton(
          onPressed: () => context.pushNamed(AuthenticationWidget.routeName),
          child: Text(
            'تسجيل الدخول',
            style: theme.labelLarge.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await AuthService.instance.sendPasswordResetEmail(
      context: context,
      email: _emailController.text.trim(),
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _emailSent = result.success;
    });

    if (!result.success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'فشل إرسال رابط إعادة التعيين'),
          backgroundColor: FlutterFlowTheme.of(context).error,
        ),
      );
    }
  }

  Future<void> _resendEmail() async {
    setState(() {
      _emailSent = false;
      _isLoading = true;
    });

    await _handleSubmit();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w.+-]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  String _maskEmail(String email) {
    if (email.isEmpty) return 'البريد الإلكتروني';
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 2) return email;
    return '${name[0]}${'*' * (name.length - 2)}${name[name.length - 1]}@$domain';
  }

  OutlineInputBorder _inputBorder(FlutterFlowTheme theme) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
        borderSide: BorderSide(color: theme.outlineVariant, width: 1.5),
      );

  OutlineInputBorder _focusedInputBorder(FlutterFlowTheme theme) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
        borderSide: BorderSide(color: theme.primary, width: 2),
      );

  OutlineInputBorder _errorInputBorder(FlutterFlowTheme theme) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
        borderSide: BorderSide(color: FlutterFlowTheme.of(context).error, width: 1.5),
      );
}