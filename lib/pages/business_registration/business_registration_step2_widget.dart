import '/auth/firebase_auth/auth_util.dart';
import '/components/button/button_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart'
    show FlutterFlowTheme;
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/nav/nav.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BusinessRegistrationStep2Widget extends StatefulWidget {
  const BusinessRegistrationStep2Widget({
    super.key,
    this.onNext,
    this.onPrevious,
    this.initialData,
  });

  static String routeName = 'BusinessRegistrationStep2';
  static String routePath = '/business/register/step2';

  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final Map<String, dynamic>? initialData;

  @override
  State<BusinessRegistrationStep2Widget> createState() => _BusinessRegistrationStep2WidgetState();
}

class _BusinessRegistrationStep2WidgetState extends State<BusinessRegistrationStep2Widget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _formKey = GlobalKey<FormState>();
  final _ownerNameController = TextEditingController();
  final _ownerPhoneController = TextEditingController();
  final _ownerEmailController = TextEditingController();

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

    // Load initial data
    if (widget.initialData != null) {
      _ownerNameController.text = widget.initialData!['ownerName'] ?? currentUserDisplayName;
      _ownerPhoneController.text = widget.initialData!['ownerPhone'] ?? currentPhoneNumber;
      _ownerEmailController.text = widget.initialData!['ownerEmail'] ?? currentUserEmail;
    } else {
      _ownerNameController.text = currentUserDisplayName;
      _ownerPhoneController.text = currentPhoneNumber;
      _ownerEmailController.text = currentUserEmail;
    }

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _ownerNameController.dispose();
    _ownerPhoneController.dispose();
    _ownerEmailController.dispose();
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
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top -
                        MediaQuery.of(context).padding.bottom,
                  ),
                  child: IntrinsicHeight(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 20),
                          // Back button
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: IconButton(
                              onPressed: () {
              if (widget.onPrevious != null) {
                widget.onPrevious!();
              } else {
                context.safePop();
              }
            },
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
                          // Progress
                          _buildProgressIndicator(theme, 2),
                          const SizedBox(height: 32),
                          // Info card
                          _buildInfoCard(theme),
                          const SizedBox(height: 24),
                          // Form fields
                          _buildOwnerNameField(theme),
                          const SizedBox(height: 16),
                          _buildOwnerPhoneField(theme),
                          const SizedBox(height: 16),
                          _buildOwnerEmailField(theme),
                          const Spacer(),
                          // Navigation buttons
                          _buildNavigationButtons(theme),
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
            Icons.person_outlined,
            color: theme.primary,
            size: 40,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'معلومات المالك',
          style: theme.headlineSmall.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: theme.primaryText,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'بيانات التواصل مع صاحب المنشأة',
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

  Widget _buildInfoCard(FlutterFlowTheme theme) {
    return Card(
      color: theme.primary.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
        side: BorderSide(color: theme.primary.withValues(alpha: 0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: theme.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'ستستخدم هذه البيانات للتواصل معك بخصوص طلب التسجيل ولن تظهر للعملاء.',
                style: theme.bodySmall.copyWith(
                  fontSize: 13,
                  color: theme.secondaryText,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnerNameField(FlutterFlowTheme theme) {
    return TextFormField(
      controller: _ownerNameController,
      textInputAction: TextInputAction.next,
      style: theme.bodyLarge.copyWith(fontSize: 16, color: theme.primaryText),
      decoration: InputDecoration(
        labelText: 'اسم المالك *',
        hintText: 'أحمد محمد علي',
        prefixIcon: Icon(Icons.person_outlined, color: theme.onSurfaceVariant, size: 22),
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
          return 'اسم المالك مطلوب';
        }
        if (value.trim().length < 2) {
          return 'الاسم يجب أن يكون حرفين على الأقل';
        }
        return null;
      },
    );
  }

  Widget _buildOwnerPhoneField(FlutterFlowTheme theme) {
    return TextFormField(
      controller: _ownerPhoneController,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      style: theme.bodyLarge.copyWith(fontSize: 16, color: theme.primaryText),
      decoration: InputDecoration(
        labelText: 'رقم هاتف المالك *',
        hintText: '010xxxxxxxx',
        prefixIcon: Icon(Icons.phone_outlined, color: theme.onSurfaceVariant, size: 22),
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
          return 'رقم هاتف المالك مطلوب';
        }
        if (!_isValidPhone(value.trim())) {
          return 'رقم هاتف مصري غير صالح (مثال: 010xxxxxxxx)';
        }
        return null;
      },
    );
  }

  Widget _buildOwnerEmailField(FlutterFlowTheme theme) {
    return TextFormField(
      controller: _ownerEmailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.done,
      style: theme.bodyLarge.copyWith(fontSize: 16, color: theme.primaryText),
      decoration: InputDecoration(
        labelText: 'بريد المالك الإلكتروني (اختياري)',
        hintText: 'owner@example.com',
        prefixIcon: Icon(Icons.email_outlined, color: theme.onSurfaceVariant, size: 22),
        filled: true,
        fillColor: theme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: _inputBorder(theme),
        enabledBorder: _inputBorder(theme),
        focusedBorder: _focusedInputBorder(theme),
      ),
      validator: (value) {
        if (value != null && value.trim().isNotEmpty && !_isValidEmail(value.trim())) {
          return 'بريد إلكتروني غير صالح';
        }
        return null;
      },
    );
  }

  Widget _buildNavigationButtons(FlutterFlowTheme theme) {
    return Row(
      children: [
        Expanded(
          child: ButtonWidget(
            content: 'السابق',
            variant: 'outline',
            size: 'medium',
            fullWidth: true,
            onPressed: widget.onPrevious?.call ?? () => context.safePop(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ButtonWidget(
            content: 'التالي',
            variant: 'primary',
            size: 'medium',
            fullWidth: true,
            loading: _isLoading,
            iconEnd: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
            iconEndPresent: true,
            onPressed: _handleNext,
          ),
        ),
      ],
    );
  }

  Future<void> _handleNext() async {
    if (!_formKey.currentState!.validate()) return;

    safeSetState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    safeSetState(() => _isLoading = false);

    if (widget.onNext != null) {
      widget.onNext!();
    } else {
      context.pushNamed(
        BusinessRegistrationStep3Widget.routeName,
        extra: {
          'ownerName': _ownerNameController.text.trim(),
          'ownerPhone': _ownerPhoneController.text.trim(),
          'ownerEmail': _ownerEmailController.text.trim(),
        },
      );
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
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
        borderSide: BorderSide(color: theme.error, width: 1.5),
      );
}