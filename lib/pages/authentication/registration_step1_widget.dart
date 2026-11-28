import '/auth/auth_service.dart';
import '/components/button/button_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart'
    show FlutterFlowTheme;
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/nav/nav.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegistrationStep1Widget extends StatefulWidget {
  const RegistrationStep1Widget({super.key});

  static String routeName = 'RegistrationStep1';
  static String routePath = '/register/step1';

  @override
  State<RegistrationStep1Widget> createState() => _RegistrationStep1WidgetState();
}

class _RegistrationStep1WidgetState extends State<RegistrationStep1Widget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _isLoading = false;
  bool _agreedToTerms = false;

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
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
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
                        const SizedBox(height: 20),
                        // Back button
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 10,
                                  color: Colors.black.withValues(alpha: 0.08),
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: IconButton(
                              onPressed: () => context.safePop(),
                              icon: Icon(
                                Icons.arrow_forward_rounded,
                                color: theme.primaryText,
                                size: 22,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Header
                        _buildHeader(theme),
                        const SizedBox(height: 40),
                        // Progress indicator
                        _buildProgressIndicator(theme, 1),
                        const SizedBox(height: 32),
                        // Form
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Full Name
                              _buildNameField(theme),
                              const SizedBox(height: 16),
                              // Email
                              _buildEmailField(theme),
                              const SizedBox(height: 16),
                              // Phone
                              _buildPhoneField(theme),
                              const SizedBox(height: 16),
                              // Password
                              _buildPasswordField(theme),
                              const SizedBox(height: 16),
                              // Confirm Password
                              _buildConfirmPasswordField(theme),
                              const SizedBox(height: 24),
                              // Terms checkbox
                              _buildTermsCheckbox(theme),
                              const SizedBox(height: 32),
                              // Continue button
                              ButtonWidget(
                                content: 'متابعة',
                                variant: 'primary',
                                size: 'large',
                                fullWidth: true,
                                loading: _isLoading,
                                onPressed: _handleContinue,
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Login link
                        _buildLoginLink(theme),
                        const SizedBox(height: 24),
                        // Illustrated Cairo skyline footer (full-bleed).
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: -24),
                          child: Image.asset(
                            'assets/images/signup_skyline.jpg',
                            height: 110,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
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
    return Column(
      children: [
        Text(
          'إنشاء حساب جديد',
          style: theme.headlineSmall.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: theme.primaryText,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'انضم إلى مجتمع ONEWAY',
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

  Widget _buildNameField(FlutterFlowTheme theme) {
    return TextFormField(
      controller: _nameController,
      focusNode: _nameFocusNode,
      textInputAction: TextInputAction.next,
      style: theme.bodyLarge.copyWith(fontSize: 16, color: theme.primaryText),
      decoration: InputDecoration(
        labelText: 'الاسم الكامل *',
        hintText: 'أحمد محمد علي',
        prefixIcon: Icon(Icons.person_outline_rounded, color: theme.primary, size: 22),
        filled: true,
        fillColor: theme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: _inputBorder(theme),
        enabledBorder: _inputBorder(theme),
        focusedBorder: _focusedInputBorder(theme),
        errorBorder: _errorInputBorder(theme),
        focusedErrorBorder: _focusedErrorInputBorder(theme),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'الاسم الكامل مطلوب';
        }
        if (value.trim().length < 2) {
          return 'الاسم يجب أن يكون حرفين على الأقل';
        }
        return null;
      },
      onFieldSubmitted: (_) => _emailFocusNode.requestFocus(),
    );
  }

  Widget _buildEmailField(FlutterFlowTheme theme) {
    return TextFormField(
      controller: _emailController,
      focusNode: _emailFocusNode,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      style: theme.bodyLarge.copyWith(fontSize: 16, color: theme.primaryText),
      decoration: InputDecoration(
        labelText: 'البريد الإلكتروني *',
        hintText: 'example@mail.com',
        prefixIcon: Icon(Icons.email_outlined, color: theme.primary, size: 22),
        filled: true,
        fillColor: theme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: _inputBorder(theme),
        enabledBorder: _inputBorder(theme),
        focusedBorder: _focusedInputBorder(theme),
        errorBorder: _errorInputBorder(theme),
        focusedErrorBorder: _focusedErrorInputBorder(theme),
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
      onFieldSubmitted: (_) => _phoneFocusNode.requestFocus(),
    );
  }

  Widget _buildPhoneField(FlutterFlowTheme theme) {
    return TextFormField(
      controller: _phoneController,
      focusNode: _phoneFocusNode,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      style: theme.bodyLarge.copyWith(fontSize: 16, color: theme.primaryText),
      decoration: InputDecoration(
        labelText: 'رقم الهاتف *',
        hintText: '010xxxxxxxx',
        prefixIcon: Icon(Icons.phone_outlined, color: theme.primary, size: 22),
        filled: true,
        fillColor: theme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: _inputBorder(theme),
        enabledBorder: _inputBorder(theme),
        focusedBorder: _focusedInputBorder(theme),
        errorBorder: _errorInputBorder(theme),
        focusedErrorBorder: _focusedErrorInputBorder(theme),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'رقم الهاتف مطلوب';
        }
        if (!_isValidPhone(value.trim())) {
          return 'رقم هاتف مصري غير صالح (مثال: 010xxxxxxxx)';
        }
        return null;
      },
      onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
    );
  }

  Widget _buildPasswordField(FlutterFlowTheme theme) {
    return TextFormField(
      controller: _passwordController,
      focusNode: _passwordFocusNode,
      obscureText: !_passwordVisible,
      textInputAction: TextInputAction.next,
      style: theme.bodyLarge.copyWith(fontSize: 16, color: theme.primaryText),
      decoration: InputDecoration(
        labelText: 'كلمة المرور *',
        hintText: '••••••••',
        prefixIcon: Icon(Icons.lock_outline_rounded, color: theme.primary, size: 22),
        suffixIcon: IconButton(
          icon: Icon(
            _passwordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: theme.onSurfaceVariant,
            size: 22,
          ),
          onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
        ),
        filled: true,
        fillColor: theme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: _inputBorder(theme),
        enabledBorder: _inputBorder(theme),
        focusedBorder: _focusedInputBorder(theme),
        errorBorder: _errorInputBorder(theme),
        focusedErrorBorder: _focusedErrorInputBorder(theme),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'كلمة المرور مطلوبة';
        }
        if (value.length < 6) {
          return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
        }
        return null;
      },
      onFieldSubmitted: (_) => _confirmPasswordFocusNode.requestFocus(),
    );
  }

  Widget _buildConfirmPasswordField(FlutterFlowTheme theme) {
    return TextFormField(
      controller: _confirmPasswordController,
      focusNode: _confirmPasswordFocusNode,
      obscureText: !_confirmPasswordVisible,
      textInputAction: TextInputAction.done,
      style: theme.bodyLarge.copyWith(fontSize: 16, color: theme.primaryText),
      decoration: InputDecoration(
        labelText: 'تأكيد كلمة المرور *',
        hintText: '••••••••',
        prefixIcon: Icon(Icons.lock_outline_rounded, color: theme.primary, size: 22),
        suffixIcon: IconButton(
          icon: Icon(
            _confirmPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: theme.onSurfaceVariant,
            size: 22,
          ),
          onPressed: () => setState(() => _confirmPasswordVisible = !_confirmPasswordVisible),
        ),
        filled: true,
        fillColor: theme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: _inputBorder(theme),
        enabledBorder: _inputBorder(theme),
        focusedBorder: _focusedInputBorder(theme),
        errorBorder: _errorInputBorder(theme),
        focusedErrorBorder: _focusedErrorInputBorder(theme),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'تأكيد كلمة المرور مطلوب';
        }
        if (value != _passwordController.text) {
          return 'كلمات المرور غير متطابقة';
        }
        return null;
      },
      onFieldSubmitted: (_) => _handleContinue(),
    );
  }

  Widget _buildTermsCheckbox(FlutterFlowTheme theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _agreedToTerms,
          onChanged: (value) => setState(() => _agreedToTerms = value ?? false),
          activeColor: theme.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          side: BorderSide(color: theme.outlineVariant, width: 1.5),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: theme.bodySmall.copyWith(fontSize: 12, color: theme.secondaryText, height: 1.5),
              children: [
                const TextSpan(text: 'أوافق على '),
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
                const TextSpan(text: ' الخاصة بـ OneWay.'),
              ],
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
          'لديك حساب بالفعل؟ ',
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

  Future<void> _handleContinue() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('يجب الموافقة على الشروط والأحكام للمتابعة'),
          backgroundColor: FlutterFlowTheme.of(context).warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await AuthService.instance.createAccountWithEmail(
      context: context,
      email: _emailController.text.trim(),
      password: _passwordController.text,
      displayName: _nameController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      // Save phone number to profile
      await AuthService.instance.updateUserProfile(
        phoneNumber: _phoneController.text.trim(),
      );

      if (mounted) {
        context.pushNamed(
          RegistrationStep2Widget.routeName,
          extra: {
            'email': _emailController.text.trim(),
            'phone': _phoneController.text.trim(),
          },
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'فشل إنشاء الحساب'),
          backgroundColor: FlutterFlowTheme.of(context).error,
        ),
      );
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w.+-]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-]'), '');
    return RegExp(r'^(010|011|012|015)\d{8}$').hasMatch(cleaned);
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

  OutlineInputBorder _focusedErrorInputBorder(FlutterFlowTheme theme) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
        borderSide: BorderSide(color: FlutterFlowTheme.of(context).error, width: 2),
      );
}