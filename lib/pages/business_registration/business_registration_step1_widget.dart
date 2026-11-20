import '/components/button/button_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart'
    show FlutterFlowTheme;
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/nav/nav.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Step 1 of Business Registration - Basic Business Information
/// This widget can be used standalone or as part of the full flow
class BusinessRegistrationStep1Widget extends StatefulWidget {
  const BusinessRegistrationStep1Widget({
    super.key,
    this.onNext,
    this.initialData,
  });

  static String routeName = 'BusinessRegistrationStep1';
  static String routePath = '/business/register/step1';

  final VoidCallback? onNext;
  final Map<String, dynamic>? initialData;

  @override
  State<BusinessRegistrationStep1Widget> createState() => _BusinessRegistrationStep1WidgetState();
}

class _BusinessRegistrationStep1WidgetState extends State<BusinessRegistrationStep1Widget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = 'مطاعم وكافيهات';
  bool _isLoading = false;

  static const List<String> _categories = [
    'مطاعم وكافيهات',
    'طبي ومستشفيات',
    'تسوق ومراكز تجارية',
    'فنادق وسياحة',
    'تعليم وجامعات',
    'بنوك ومصارف',
    'مكاتب حكومية',
    'أماكن ترفيهية',
    'محطات نقل',
    'أخرى',
  ];

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

    // Load initial data if provided
    if (widget.initialData != null) {
      _businessNameController.text = widget.initialData!['businessName'] ?? '';
      _selectedCategory = widget.initialData!['category'] ?? 'مطاعم وكافيهات';
      _phoneController.text = widget.initialData!['phoneNumber'] ?? '';
      _emailController.text = widget.initialData!['email'] ?? '';
      _descriptionController.text = widget.initialData!['description'] ?? '';
    }

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _businessNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _descriptionController.dispose();
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
                          // Progress
                          _buildProgressIndicator(theme, 1),
                          const SizedBox(height: 32),
                          // Form fields
                          _buildBusinessNameField(theme),
                          const SizedBox(height: 16),
                          _buildCategoryField(theme),
                          const SizedBox(height: 16),
                          _buildPhoneField(theme),
                          const SizedBox(height: 16),
                          _buildEmailField(theme),
                          const SizedBox(height: 16),
                          _buildDescriptionField(theme),
                          const Spacer(),
                          // Next button
                          ButtonWidget(
                            content: 'التالي',
                            variant: 'primary',
                            size: 'large',
                            fullWidth: true,
                            loading: _isLoading,
                            onPressed: _handleNext,
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
            Icons.storefront_outlined,
            color: theme.primary,
            size: 40,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'معلومات المنشأة',
          style: theme.headlineSmall.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: theme.primaryText,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'أدخل البيانات الأساسية لمنشأتك',
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

  Widget _buildBusinessNameField(FlutterFlowTheme theme) {
    return TextFormField(
      controller: _businessNameController,
      textInputAction: TextInputAction.next,
      style: theme.bodyLarge.copyWith(fontSize: 16, color: theme.primaryText),
      decoration: InputDecoration(
        labelText: 'اسم المنشأة *',
        hintText: 'مثال: مطعم البيتزا الشهير',
        prefixIcon: Icon(Icons.storefront_outlined, color: theme.onSurfaceVariant, size: 22),
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
          return 'اسم المنشأة مطلوب';
        }
        if (value.trim().length < 2) {
          return 'الاسم يجب أن يكون حرفين على الأقل';
        }
        return null;
      },
    );
  }

  Widget _buildCategoryField(FlutterFlowTheme theme) {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: InputDecoration(
        labelText: 'تصنيف المنشأة *',
        prefixIcon: Icon(Icons.category_outlined, color: theme.onSurfaceVariant, size: 22),
        filled: true,
        fillColor: theme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: _inputBorder(theme),
        enabledBorder: _inputBorder(theme),
        focusedBorder: _focusedInputBorder(theme),
      ),
      items: _categories.map((cat) => DropdownMenuItem(
        value: cat,
        child: Text(cat, style: theme.bodyLarge.copyWith(fontSize: 16, color: theme.primaryText)),
      )).toList(),
      onChanged: (val) => safeSetState(() => _selectedCategory = val!),
    );
  }

  Widget _buildPhoneField(FlutterFlowTheme theme) {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      style: theme.bodyLarge.copyWith(fontSize: 16, color: theme.primaryText),
      decoration: InputDecoration(
        labelText: 'رقم هاتف التواصل *',
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
          return 'رقم الهاتف مطلوب';
        }
        if (!_isValidPhone(value.trim())) {
          return 'رقم هاتف مصري غير صالح (مثال: 010xxxxxxxx)';
        }
        return null;
      },
    );
  }

  Widget _buildEmailField(FlutterFlowTheme theme) {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      style: theme.bodyLarge.copyWith(fontSize: 16, color: theme.primaryText),
      decoration: InputDecoration(
        labelText: 'البريد الإلكتروني (اختياري)',
        hintText: 'business@example.com',
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

  Widget _buildDescriptionField(FlutterFlowTheme theme) {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 3,
      textInputAction: TextInputAction.done,
      style: theme.bodyLarge.copyWith(fontSize: 16, color: theme.primaryText),
      decoration: InputDecoration(
        labelText: 'وصف المنشأة (اختياري)',
        hintText: 'أضف وصفاً مختصراً عن خدماتك ومميزاتك...',
        prefixIcon: Icon(Icons.description_outlined, color: theme.onSurfaceVariant, size: 22),
        filled: true,
        fillColor: theme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: _inputBorder(theme),
        enabledBorder: _inputBorder(theme),
        focusedBorder: _focusedInputBorder(theme),
      ),
    );
  }

  Future<void> _handleNext() async {
    if (!_formKey.currentState!.validate()) return;

    safeSetState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    safeSetState(() => _isLoading = false);

    // Return data to parent or navigate
    if (widget.onNext != null) {
      widget.onNext!();
    } else {
      context.pushNamed(
        BusinessRegistrationStep2Widget.routeName,
        extra: {
          'businessName': _businessNameController.text.trim(),
          'category': _selectedCategory,
          'phoneNumber': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
          'description': _descriptionController.text.trim(),
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