import '/auth/firebase_auth/auth_util.dart';
import '/components/button/button_widget.dart';
import '/flutter_flow/ff_builtin_enums.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/nav/nav.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, TargetPlatform;
import 'package:go_router/go_router.dart';
import 'authentication_model.dart';
export 'authentication_model.dart';

class AuthenticationWidget extends StatefulWidget {
  const AuthenticationWidget({super.key});

  static String routeName = 'Authentication';
  static String routePath = '/login';

  @override
  State<AuthenticationWidget> createState() => _AuthenticationWidgetState();
}

class _AuthenticationWidgetState extends State<AuthenticationWidget>
    with SingleTickerProviderStateMixin {
  late AuthenticationModel _model;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  /// Adapts a validator with BuildContext to FormFieldValidator<String>
  String? _adaptValidator(String? Function(BuildContext, String?)? validator, String? value) {
    if (validator == null) return null;
    return validator(context, value);
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AuthenticationModel());
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _model.emailInputTextController ??= TextEditingController();
    _model.emailInputFocusNode ??= FocusNode();
    _model.passwordInputTextController ??= TextEditingController();
    _model.passwordInputFocusNode ??= FocusNode();

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _model.dispose();
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
        key: scaffoldKey,
        backgroundColor: theme.background,
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                // Plain scrollable column: the previous ConstrainedBox +
                // IntrinsicHeight + Spacer layout overflowed by a few pixels
                // on some devices (e.g. Android 15 edge-to-edge).
                // Phone-shaped column like the mockup, even on wide windows.
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Navy Cairo hero header
                    _buildHeader(theme),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 28),
                          _buildModeTitle(theme),
                          const SizedBox(height: 24),
                          // Form
                          _buildForm(theme),
                          const SizedBox(height: 24),
                          // Divider
                          _buildDivider(theme),
                          const SizedBox(height: 24),
                          // Social login
                          _buildSocialLogin(theme),
                          const SizedBox(height: 24),
                          // Business Owner CTA Section
                          _buildBusinessOwnerCTA(theme),
                          const SizedBox(height: 16),
                          // Footer
                          _buildFooter(theme),
                          const SizedBox(height: 32),
                        ],
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
    );
  }

  Widget _buildHeader(FlutterFlowTheme theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.navy,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // Flat spec navy header like the mockup (no photo).
            Positioned.fill(
              child: ColoredBox(color: theme.navy),
            ),
            // Teal wave along the bottom edge, like the mockup divider.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 34,
              child: ClipPath(
                clipper: _TealWaveClipper(),
                child: ColoredBox(color: theme.primary),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 34, 24, 52),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Mockup logo mark: wheelchair + glowing pin on navy.
                  ClipOval(
                    child: Image.asset(
                      'assets/images/oneway_logo_mark.jpg',
                      width: 110,
                      height: 110,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Mockup wordmark: white ONE + teal WAY.
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'ONE',
                          style: theme.displayMedium.copyWith(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.2,
                            letterSpacing: 1.5,
                          ),
                        ),
                        TextSpan(
                          text: 'WAY',
                          style: theme.displayMedium.copyWith(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: theme.primary,
                            height: 1.2,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeTitle(FlutterFlowTheme theme) {
    return Column(
      children: [
        Text(
          _model.createAccountMode! ? 'إنشاء حساب جديد' : 'مرحباً بك مجدداً',
          style: theme.headlineSmall.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: theme.primaryText,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _model.createAccountMode!
              ? 'أدخل بياناتك لإنشاء حسابك والبدء في استكشاف الأماكن المجهزة'
              : 'عد للمتابعة',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Email/Phone Field
        _AuthTextField(
          controller: _model.emailInputTextController!,
          focusNode: _model.emailInputFocusNode!,
          label: _model.createAccountMode! ? 'البريد الإلكتروني أو رقم الهاتف' : 'البريد الإلكتروني أو رقم الهاتف',
          hint: 'example@mail.com أو 010xxxxxxxx',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          prefixIcon: Icons.mail_outline_rounded,
          validator: (value) => _adaptValidator(_model.emailInputTextControllerValidator, value),
        ),
        const SizedBox(height: 16),
        // Password Field
        _AuthTextField(
          controller: _model.passwordInputTextController!,
          focusNode: _model.passwordInputFocusNode!,
          label: 'كلمة المرور',
          hint: '********',
          obscureText: !_model.passwordInputVisibility,
          textInputAction: TextInputAction.done,
          prefixIcon: Icons.lock_outline_rounded,
          suffixIcon: IconButton(
            icon: Icon(
              _model.passwordInputVisibility
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: theme.onSurfaceVariant,
              size: 22,
            ),
            onPressed: () {
              safeSetState(() =>
                  _model.passwordInputVisibility = !_model.passwordInputVisibility);
            },
          ),
          validator: (value) => _adaptValidator(_model.passwordInputTextControllerValidator, value),
        ),
        const SizedBox(height: 8),
        // Forgot Password
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton(
            onPressed: () => context.pushNamed(ForgotPasswordWidget.routeName),
            child: Text(
              'نسيت كلمة المرور؟',
              style: theme.labelLarge.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Submit Button
        ButtonWidget(
          content: _model.createAccountMode! ? 'إنشاء الحساب' : 'دخول',
          variant: 'primary',
          size: 'large',
          fullWidth: true,
          onPressed: _handleAuthSubmit,
        ),
        // Terms and Privacy (only in registration mode)
        if (_model.createAccountMode!) ...[
          const SizedBox(height: 16),
          _buildTermsAndPrivacy(theme),
        ],
      ],
    );
  }

  Widget _buildTermsAndPrivacy(FlutterFlowTheme theme) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: theme.bodySmall.copyWith(
          fontSize: 12,
          color: theme.tertiaryText,
          height: 1.5,
        ),
        children: [
          const TextSpan(text: 'بإنشاء حساب، أنت توافق على '),
          TextSpan(
            text: 'شروط الخدمة',
            style: TextStyle(
              color: theme.primary,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
          ),
          const TextSpan(text: ' و '),
          TextSpan(
            text: 'سياسة الخصوصية',
            style: TextStyle(
              color: theme.primary,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(FlutterFlowTheme theme) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            height: 1,
            thickness: 1,
            color: theme.outlineVariant,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'أو',
            style: theme.labelMedium.copyWith(
              fontSize: 13,
              color: theme.tertiaryText,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            height: 1,
            thickness: 1,
            color: theme.outlineVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialLogin(FlutterFlowTheme theme) {
    return Column(
      children: [
        // Toggle mode button
        ButtonWidget(
          content: _model.createAccountMode!
              ? 'لديك حساب؟ تسجيل الدخول'
              : 'إنشاء حساب جديد',
          variant: 'outline',
          size: 'medium',
          fullWidth: true,
          icon: Icon(
            _model.createAccountMode!
                ? Icons.login_rounded
                : Icons.person_add_alt_1_rounded,
            color: theme.primaryText,
            size: 20,
          ),
          iconPresent: true,
          onPressed: () {
            safeSetState(() {
              _model.createAccountMode = !_model.createAccountMode!;
            });
          },
        ),
        const SizedBox(height: 16),
        // Google Sign In
        ButtonWidget(
          content: 'متابعة مع Google',
          variant: 'outline',
          size: 'medium',
          fullWidth: true,
          icon: Container(
            width: 22,
            height: 22,
            child: Image.asset(
              'assets/images/google_logo.png',
              errorBuilder: (_, __, ___) => Icon(
                Icons.g_mobiledata_rounded,
                color: theme.primaryText,
                size: 22,
              ),
            ),
          ),
          iconPresent: true,
          onPressed: () async {
            GoRouter.of(context).prepareAuthEvent();
            final user = await authManager.signInWithGoogle(context);
            if (user != null && context.mounted) {
              await AuthRouter.instance.navigateAfterSocialLogin(context);
            }
          },
        ),
        // Apple Sign In (iOS/macOS only)
        if (!kIsWeb &&
            (Theme.of(context).platform == TargetPlatform.iOS ||
                Theme.of(context).platform == TargetPlatform.macOS)) ...[
          const SizedBox(height: 12),
          ButtonWidget(
            content: 'متابعة مع Apple',
            variant: 'outline',
            size: 'medium',
            fullWidth: true,
            icon: Icon(
              Icons.apple_rounded,
              color: theme.primaryText,
              size: 22,
            ),
            iconPresent: true,
            onPressed: () async {
            GoRouter.of(context).prepareAuthEvent();
            final user = await authManager.signInWithApple(context);
            if (user != null && context.mounted) {
              await AuthRouter.instance.navigateAfterSocialLogin(context);
            }
          },
          ),
        ],
      ],
    );
  }

  Widget _buildBusinessOwnerCTA(FlutterFlowTheme theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primary.withValues(alpha: 0.1),
            theme.primary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(theme.designToken.radius.xxl),
        border: Border.all(
          color: theme.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.primary,
                  borderRadius: BorderRadius.circular(theme.designToken.radius.lg),
                ),
                child: const Icon(
                  Icons.business_center_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'هل أنت صاحب عمل؟',
                      style: theme.titleMedium.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: theme.primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'سجّل مكانك على OneWay وابدأ في استقبال العملاء من ذوي الإعاقة وأسرهم.',
                      style: theme.bodySmall.copyWith(
                        fontSize: 13,
                        color: theme.secondaryText,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ButtonWidget(
            content: 'سجّل مكانك الآن',
            variant: 'primary',
            size: 'medium',
            fullWidth: true,
            iconEnd: const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 20,
            ),
            iconEndPresent: true,
            onPressed: () => AuthRouter.instance.navigateToBusinessRegistration(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(FlutterFlowTheme theme) {
    return Column(
      children: [
        // Guest entry
        ButtonWidget(
          content: 'الدخول كزائر',
          variant: 'ghost',
          size: 'medium',
          fullWidth: false,
          icon: Icon(
            Icons.arrow_back_rounded,
            color: theme.primaryText,
            size: 22,
          ),
          iconPresent: true,
          onPressed: () => context.pushNamed(HomeDashboardWidget.routeName),
        ),
        const SizedBox(height: 24),
        // Language
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.language_rounded,
              color: theme.tertiaryText,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'English',
              style: theme.labelMedium.copyWith(
                fontSize: 13,
                color: theme.tertiaryText,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _handleAuthSubmit() async {
    final email = _model.emailInputTextController!.text.trim();
    final password = _model.passwordInputTextController!.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('أدخل البريد الإلكتروني/الهاتف وكلمة المرور.'),
          duration: Duration(milliseconds: 4000),
        ),
      );
      return;
    }

    GoRouter.of(context).prepareAuthEvent();

    AuthResult result;
    if (_model.createAccountMode!) {
      result = await AuthService.instance.createAccountWithEmail(
        context: context,
        email: email,
        password: password,
      );
    } else {
      result = await AuthService.instance.signInWithEmail(
        context: context,
        email: email,
        password: password,
      );
    }

    if (result.success && context.mounted) {
      if (_model.createAccountMode!) {
        await AuthRouter.instance.navigateAfterRegistration(context);
      } else {
        await AuthRouter.instance.navigateAfterLogin(context);
      }
    }
  }
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    required this.prefixIcon,
    this.suffixIcon,
    this.validator,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final IconData prefixIcon;
  final Widget? suffixIcon;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      style: theme.bodyLarge.copyWith(
        fontSize: 16,
        color: theme.primaryText,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: theme.bodyLarge.copyWith(
          fontSize: 16,
          color: theme.hintText,
        ),
        labelStyle: theme.bodyMedium.copyWith(
          fontSize: 14,
          color: theme.onSurfaceVariant,
        ),
        floatingLabelStyle: theme.bodyMedium.copyWith(
          fontSize: 14,
          color: theme.primary,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(
          prefixIcon,
          color: theme.primary,
          size: 22,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: theme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
          borderSide: BorderSide(color: theme.outlineVariant, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
          borderSide: BorderSide(color: theme.outlineVariant, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
          borderSide: BorderSide(color: theme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
          borderSide: BorderSide(color: theme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
          borderSide: BorderSide(color: theme.error, width: 2),
        ),
      ),
      validator: validator,
    );
  }
}
// Smooth teal wave divider for the auth header (mockup style).
class _TealWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(0, h * 0.65)
      ..quadraticBezierTo(w * 0.25, 0, w * 0.5, h * 0.45)
      ..quadraticBezierTo(w * 0.75, h * 0.9, w, h * 0.3)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
