import '/auth/firebase_auth/auth_util.dart';
import '/auth/verification_service.dart';
import '/backend/schema/users_record.dart';
import '/components/button/button_widget.dart';
import '/core/analytics/analytics_service.dart';
import '/core/constants/app_constants.dart';
import '/core/constants/profile_options.dart';
import '/flutter_flow/ff_builtin_enums.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/nav/nav.dart';
import '/features/legal/legal_pages.dart';
import '/index.dart';
import '/l10n/app_strings.dart';
import '/widgets/google_logo_icon.dart';
import '/widgets/responsive_layout.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
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
  final _registerFormKey = GlobalKey<FormState>();

  // Registration personal profile controllers (matching User Profile fields)
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _nameFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _addressFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  String _selectedGender = 'ذكر';
  String? _selectedGovernorate;
  String? _selectedMobility;
  Set<String> _selectedAccessNeeds = {
    'step_free_entrance',
    'suitable_ramp',
  };
  DateTime? _selectedBirthDate;
  bool _confirmPasswordVisible = false;
  bool _agreedToTerms = false;
  bool _isSubmitting = false;
  bool _autoRoutingPersistedSession = false;

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

    final savedMobility = ProfileOptions.normalizeMobilityForDropdown(
      FFAppState().mobilityType,
    );
    if (savedMobility != null) {
      _selectedMobility = savedMobility;
    }
    if (FFAppState().accessNeeds.isNotEmpty) {
      _selectedAccessNeeds = FFAppState().accessNeeds.toSet();
    }

    // If a persisted Firebase Auth session is already active (or finishes
    // restoring asynchronously right after /login opens), route the user
    // directly to their destination instead of asking to sign in again.
    AppStateNotifier.instance.addListener(_onAuthStateChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeRoutePersistedSession();
    });

    _animationController.forward();
  }

  void _onAuthStateChanged() {
    _maybeRoutePersistedSession();
  }

  void _maybeRoutePersistedSession() {
    if (!mounted || _isSubmitting || _autoRoutingPersistedSession) return;
    if (loggedIn) {
      _autoRoutingPersistedSession = true;
      AuthRouter.instance.navigateAfterLogin(context).whenComplete(() {
        _autoRoutingPersistedSession = false;
      });
    }
  }

  @override
  void dispose() {
    AppStateNotifier.instance.removeListener(_onAuthStateChanged);
    _animationController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _confirmPasswordController.dispose();
    _nameFocusNode.dispose();
    _phoneFocusNode.dispose();
    _addressFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
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
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 48),
              child: const OnewayBrandLockup(
                iconSize: 88,
                fontSize: 32,
                lightText: true,
                vertical: true,
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
          _model.createAccountMode!
              ? S.t(context, 'إنشاء حساب جديد', 'Create Account')
              : S.t(context, 'مرحباً بك مجدداً', 'Welcome Back'),
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
              ? S.t(
                  context,
                  'أدخل بياناتك لإنشاء حسابك والبدء في استكشاف الأماكن المجهزة',
                  'Enter your details to start exploring accessible places',
                )
              : S.t(context, 'عد للمتابعة', 'Sign in to continue'),
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
    final isCreateMode = _model.createAccountMode == true;

    return Form(
      key: _registerFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isCreateMode) ...[
            // Full Name
            _AuthTextField(
              key: const Key('register_name_field'),
              controller: _nameController,
              focusNode: _nameFocusNode,
              label: S.t(context, 'الاسم الكامل *', 'Full Name *'),
              hint: S.t(context, 'أحمد محمد علي', 'Full name'),
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.person_outline_rounded,
              validator: (value) {
                if (value == null || value.trim().length < 2) {
                  return S.t(context, 'الاسم الكامل مطلوب (حرفين على الأقل)',
                      'Full name is required (at least 2 chars)');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
          ],

          // Email Field
          _AuthTextField(
            controller: _model.emailInputTextController!,
            focusNode: _model.emailInputFocusNode!,
            label: isCreateMode
                ? S.t(context, 'البريد الإلكتروني *', 'Email *')
                : S.t(context, 'البريد الإلكتروني', 'Email'),
            hint: 'example@mail.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            prefixIcon: Icons.mail_outline_rounded,
            validator: (value) {
              if (isCreateMode) {
                if (value == null || !ProfileOptions.isValidEmail(value)) {
                  return S.t(context, 'أدخل بريداً إلكترونياً صالحاً',
                      'Enter a valid email address');
                }
                return null;
              }
              return _adaptValidator(
                  _model.emailInputTextControllerValidator, value);
            },
          ),
          const SizedBox(height: 16),

          if (isCreateMode) ...[
            // Phone Number
            _AuthTextField(
              key: const Key('register_phone_field'),
              controller: _phoneController,
              focusNode: _phoneFocusNode,
              label: S.t(context, 'رقم الهاتف *', 'Phone Number *'),
              hint: '010xxxxxxxx',
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.phone_outlined,
              validator: (value) {
                if (value == null ||
                    !ProfileOptions.isValidEgyptianPhone(value)) {
                  return S.t(
                    context,
                    'أدخل رقم هاتف مصري صحيح (مثال: 010xxxxxxxx)',
                    'Enter a valid Egyptian phone (e.g. 010xxxxxxxx)',
                  );
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
          ],

          // Password Field
          _AuthTextField(
            controller: _model.passwordInputTextController!,
            focusNode: _model.passwordInputFocusNode!,
            label: isCreateMode
                ? S.t(context, 'كلمة المرور *', 'Password *')
                : S.t(context, 'كلمة المرور', 'Password'),
            hint: '********',
            obscureText: !_model.passwordInputVisibility,
            textInputAction:
                isCreateMode ? TextInputAction.next : TextInputAction.done,
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
                safeSetState(() => _model.passwordInputVisibility =
                    !_model.passwordInputVisibility);
              },
            ),
            validator: (value) {
              if (isCreateMode) {
                if (value == null || value.length < 6) {
                  return S.t(context, 'كلمة المرور يجب أن تكون 6 أحرف على الأقل',
                      'Password must be at least 6 characters');
                }
                return null;
              }
              return _adaptValidator(
                  _model.passwordInputTextControllerValidator, value);
            },
          ),

          if (isCreateMode) ...[
            const SizedBox(height: 16),
            // Confirm Password
            _AuthTextField(
              key: const Key('register_confirm_password_field'),
              controller: _confirmPasswordController,
              focusNode: _confirmPasswordFocusNode,
              label: S.t(context, 'تأكيد كلمة المرور *', 'Confirm Password *'),
              hint: '********',
              obscureText: !_confirmPasswordVisible,
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                icon: Icon(
                  _confirmPasswordVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: theme.onSurfaceVariant,
                  size: 22,
                ),
                onPressed: () => safeSetState(
                    () => _confirmPasswordVisible = !_confirmPasswordVisible),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return S.t(context, 'تأكيد كلمة المرور مطلوب',
                      'Please confirm your password');
                }
                if (value != _model.passwordInputTextController?.text) {
                  return S.t(context, 'كلمات المرور غير متطابقة',
                      'Passwords do not match');
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Personal Info section header (matches User Profile)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.badge_outlined, color: theme.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      S.t(
                        context,
                        'البيانات الشخصية (تُحفظ مباشرة في ملفك الشخصي)',
                        'Personal Details (saved to your profile)',
                      ),
                      style: theme.titleSmall.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: theme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Gender
            _buildProfileDropdown(
              theme,
              key: const Key('register_gender_field'),
              label: S.t(context, 'النوع *', 'Gender *'),
              icon: Icons.wc_outlined,
              value: _selectedGender,
              items: const ['ذكر', 'أنثى'],
              validator: (v) => (v == null || v.isEmpty)
                  ? S.t(context, 'يرجى اختيار النوع', 'Please select gender')
                  : null,
              onChanged: (v) =>
                  safeSetState(() => _selectedGender = v ?? 'ذكر'),
            ),
            const SizedBox(height: 16),

            // Birth Date
            _buildBirthDateField(theme),
            const SizedBox(height: 16),

            // Governorate
            _buildProfileDropdown(
              theme,
              key: const Key('register_governorate_field'),
              label: S.t(context, 'المحافظة *', 'Governorate *'),
              icon: Icons.map_outlined,
              value: _selectedGovernorate,
              items: ProfileOptions.governorates,
              validator: (v) => (v == null || v.isEmpty)
                  ? S.t(context, 'يرجى اختيار المحافظة',
                      'Please select governorate')
                  : null,
              onChanged: (v) => safeSetState(() => _selectedGovernorate = v),
            ),
            const SizedBox(height: 16),

            // Address
            _AuthTextField(
              key: const Key('register_address_field'),
              controller: _addressController,
              focusNode: _addressFocusNode,
              label: S.t(context, 'العنوان التفصيلي *', 'Detailed Address *'),
              hint: S.t(context, 'الشارع، المنطقة، المدينة',
                  'Street, District, City'),
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.location_on_outlined,
              maxLines: 2,
              validator: (v) {
                if (v == null || v.trim().length < 3) {
                  return S.t(context, 'يرجى إدخال العنوان أو المنطقة',
                      'Please enter your address or district');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Mobility Type
            _buildProfileDropdown(
              theme,
              key: const Key('register_mobility_field'),
              label: S.t(context, 'طريقة التنقل *', 'Mobility Way *'),
              icon: Icons.accessible_forward_rounded,
              value: _selectedMobility,
              items: ProfileOptions.mobilityTypes,
              validator: (v) => (v == null || v.isEmpty)
                  ? S.t(context, 'يرجى اختيار طريقة التنقل',
                      'Please select mobility way')
                  : null,
              onChanged: (v) {
                safeSetState(() {
                  _selectedMobility = v;
                  final opt = MobilityProfileOption.resolveOption(v);
                  if (opt != null && opt.defaultAccessNeeds.isNotEmpty) {
                    _selectedAccessNeeds = opt.defaultAccessNeeds.toSet();
                  }
                });
              },
            ),
            const SizedBox(height: 14),
            Text(
              S.t(
                context,
                'احتياجات الوصول في المكان (يمكنك اختيار أكثر من احتياج):',
                'Access needs at venues (select all that apply):',
              ),
              style: theme.labelLarge.copyWith(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: theme.primaryText,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AccessNeedOption.all.map((need) {
                final selected = _selectedAccessNeeds.contains(need.id);
                return FilterChip(
                  selected: selected,
                  label: Text(
                    S.isEn(context) ? need.titleEn : need.titleAr,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : theme.primaryText,
                    ),
                  ),
                  selectedColor: theme.primary,
                  checkmarkColor: Colors.white,
                  backgroundColor: theme.surface,
                  side: BorderSide(
                    color: selected ? theme.primary : theme.outlineVariant,
                  ),
                  onSelected: (val) {
                    safeSetState(() {
                      if (val) {
                        _selectedAccessNeeds.add(need.id);
                      } else {
                        _selectedAccessNeeds.remove(need.id);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ] else ...[
            const SizedBox(height: 8),
            // Forgot Password (login mode only)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: () =>
                    context.pushNamed(ForgotPasswordWidget.routeName),
                child: Text(
                  S.t(context, 'نسيت كلمة المرور؟', 'Forgot Password?'),
                  style: theme.labelLarge.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.primary,
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),
          // Submit Button
          ButtonWidget(
            content: isCreateMode
                ? S.t(context, 'إنشاء الحساب', 'Create Account')
                : S.t(context, 'دخول', 'Sign In'),
            variant: 'primary',
            size: 'large',
            fullWidth: true,
            loading: _isSubmitting,
            onPressed: _isSubmitting ? null : _handleAuthSubmit,
          ),
          // Terms and Privacy (only in registration mode)
          if (isCreateMode) ...[
            const SizedBox(height: 16),
            _buildTermsAndPrivacy(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileDropdown(
    FlutterFlowTheme theme, {
    Key? key,
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      key: key,
      initialValue: value,
      isExpanded: true,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: theme.bodyMedium.copyWith(
          fontSize: 14,
          color: theme.onSurfaceVariant,
        ),
        prefixIcon: Icon(icon, color: theme.primary, size: 22),
        filled: true,
        fillColor: theme.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
      ),
      items: items
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(
                item,
                overflow: TextOverflow.ellipsis,
                style: theme.bodyLarge.copyWith(
                  fontSize: 15,
                  color: theme.primaryText,
                ),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildBirthDateField(FlutterFlowTheme theme) {
    final formatted = _selectedBirthDate != null
        ? ProfileOptions.formatBirthDate(_selectedBirthDate)
        : S.t(context, 'اختر تاريخ الميلاد', 'Select birth date');
    return InkWell(
      key: const Key('register_birthdate_field'),
      borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
      onTap: () async {
        final now = DateTime.now();
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedBirthDate ??
              DateTime(now.year - 25, now.month, now.day),
          firstDate: DateTime(1920),
          lastDate: DateTime(now.year - 10, now.month, now.day),
        );
        if (date != null && mounted) {
          safeSetState(() => _selectedBirthDate = date);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: S.t(context, 'تاريخ الميلاد', 'Birth Date'),
          labelStyle: theme.bodyMedium.copyWith(
            fontSize: 14,
            color: theme.onSurfaceVariant,
          ),
          prefixIcon:
              Icon(Icons.cake_outlined, color: theme.primary, size: 22),
          filled: true,
          fillColor: theme.surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
            borderSide: BorderSide(color: theme.outlineVariant, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
            borderSide: BorderSide(color: theme.outlineVariant, width: 1.5),
          ),
        ),
        child: Text(
          formatted,
          style: theme.bodyLarge.copyWith(
            fontSize: 15,
            color: _selectedBirthDate != null
                ? theme.primaryText
                : theme.hintText,
          ),
        ),
      ),
    );
  }

  Widget _buildTermsAndPrivacy(FlutterFlowTheme theme) {
    return CheckboxListTile(
      key: const Key('register_terms_checkbox'),
      value: _agreedToTerms,
      onChanged: (v) => safeSetState(() => _agreedToTerms = v ?? false),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      activeColor: theme.primary,
      title: RichText(
        text: TextSpan(
          style: theme.bodySmall.copyWith(
            fontSize: 12.5,
            color: theme.secondaryText,
            height: 1.5,
          ),
          children: [
            TextSpan(
              text: S.t(
                context,
                'أوافق صراحةً على معالجة بياناتي وملف الحركة وفقاً لـ ',
                'I explicitly consent to processing my data & mobility profile under the ',
              ),
            ),
            TextSpan(
              text: S.t(context, 'شروط الاستخدام', 'Terms of Use'),
              style: TextStyle(
                color: theme.primary,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const TermsOfUsePage(),
                      ),
                    ),
            ),
            TextSpan(text: S.t(context, ' و ', ' and ')),
            TextSpan(
              text: S.t(context, 'سياسة الخصوصية', 'Privacy Policy'),
              style: TextStyle(
                color: theme.primary,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PrivacyPolicyPage(),
                      ),
                    ),
            ),
          ],
        ),
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
          icon: const GoogleLogoIcon(size: 22),
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
            onPressed: () =>
                context.pushNamed(BusinessRegistrationWidget.routeName),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(FlutterFlowTheme theme) {
    return Column(
      children: [
        // Language toggle
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final nextCode = S.isEn(context) ? 'ar' : 'en';
            await FFAppState().setLocaleCode(nextCode);
            await AnalyticsService.instance.setPreferredLanguage(nextCode);
            if (mounted) safeSetState(() {});
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.language_rounded,
                  color: theme.secondaryText,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  S.isEn(context) ? 'العربية' : 'English',
                  style: theme.labelMedium.copyWith(
                    fontSize: 13,
                    color: theme.secondaryText,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleAuthSubmit() async {
    final isCreateMode = _model.createAccountMode == true;
    final email = _model.emailInputTextController!.text.trim();
    final password = _model.passwordInputTextController!.text;

    if (isCreateMode) {
      if (!(_registerFormKey.currentState?.validate() ?? false)) return;
      if (_selectedBirthDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.t(
              context,
              'يرجى اختيار تاريخ الميلاد لإكمال بيانات ملفك الشخصي.',
              'Please select your birth date to complete your profile.',
            )),
            duration: const Duration(milliseconds: 4000),
          ),
        );
        return;
      }
      if (!_agreedToTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.t(
              context,
              'يرجى الموافقة على شروط الاستخدام وسياسة الخصوصية أولاً.',
              'Please agree to the Terms of Use and Privacy Policy first.',
            )),
            duration: const Duration(milliseconds: 4000),
          ),
        );
        return;
      }
    } else if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.t(
            context,
            'أدخل البريد الإلكتروني وكلمة المرور.',
            'Please enter your email and password.',
          )),
          duration: const Duration(milliseconds: 4000),
        ),
      );
      return;
    }

    safeSetState(() => _isSubmitting = true);
    GoRouter.of(context).prepareAuthEvent();

    try {
      AuthResult result;
      if (isCreateMode) {
        result = await AuthService.instance.createAccountWithEmail(
          context: context,
          email: email,
          password: password,
          displayName: _nameController.text.trim(),
        );
      } else {
        result = await AuthService.instance.signInWithEmail(
          context: context,
          email: email,
          password: password,
        );
      }

      if (!mounted) return;

      if (result.success) {
        if (isCreateMode) {
          final uid = currentUserUid;
          if (uid.isNotEmpty) {
            final phone =
                ProfileOptions.normalizeEgyptianPhone(_phoneController.text);
            final coreUpdates = <String, dynamic>{
              'updated_time': FieldValue.serverTimestamp(),
              'display_name': _nameController.text.trim(),
              'phone_number': phone,
              'address': _addressController.text.trim(),
              'gender': _selectedGender,
              if (_selectedGovernorate != null)
                'governorate': _selectedGovernorate,
              if (_selectedMobility != null) 'mobility_type': _selectedMobility,
              if (_selectedBirthDate != null)
                'birth_date': Timestamp.fromDate(_selectedBirthDate!),
            };
            final fullUpdates = <String, dynamic>{
              ...coreUpdates,
              'access_needs': _selectedAccessNeeds.take(10).toList(),
              'profile_completed': true,
            };

            try {
              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .update(fullUpdates);
              } catch (_) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .update(coreUpdates);
              }
              if (_selectedMobility != null) {
                await FFAppState().setMobilityType(_selectedMobility!);
                await AnalyticsService.instance
                    .setMobilityType(_selectedMobility!);
              }
              await FFAppState()
                  .setAccessNeeds(_selectedAccessNeeds.take(10).toList());
              currentUserDocument = await UsersRecord.getDocumentOnce(
                UsersRecord.collection.doc(uid),
              );
            } catch (e) {
              debugPrint('Error saving registration profile fields: $e');
            }
          }
          // Dispatch confirmation email immediately on new registration
          final verifyRes =
              await VerificationService.instance.sendEmailVerification();
          if (mounted && verifyRes.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  verifyRes.message ??
                      'تم إرسال رسالة تأكيد إلى بريدك الإلكتروني',
                ),
                backgroundColor: FlutterFlowTheme.of(context).success,
              ),
            );
          }
          if (mounted) {
            await AuthRouter.instance.navigateAfterLogin(context);
          }
        } else {
          await AuthRouter.instance.navigateAfterLogin(context);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'فشل تسجيل الدخول'),
            duration: const Duration(milliseconds: 4000),
          ),
        );
      }
    } finally {
      if (mounted) safeSetState(() => _isSubmitting = false);
    }
  }
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
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
  final int maxLines;
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
      maxLines: obscureText ? 1 : maxLines,
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
