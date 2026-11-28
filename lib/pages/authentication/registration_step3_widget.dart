import '/auth/auth_service.dart'
    show AuthService;
import '/auth/firebase_auth/auth_util.dart';
import '/backend/schema/emergency_contacts_record.dart';
import '/components/button/button_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart'
    show FlutterFlowTheme;
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/nav/nav.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegistrationStep3Widget extends StatefulWidget {
  const RegistrationStep3Widget({super.key});

  static String routeName = 'RegistrationStep3';
  static String routePath = '/register/step3';

  @override
  State<RegistrationStep3Widget> createState() => _RegistrationStep3WidgetState();
}

class _RegistrationStep3WidgetState extends State<RegistrationStep3Widget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  final _nameFocusNode = FocusNode();
  final _addressFocusNode = FocusNode();

  String _email = '';
  String _phone = '';
  String _selectedGender = 'غير محدد';
  String? _selectedGovernorate;
  String? _selectedMobility;
  DateTime? _selectedBirthDate;
  bool _isLoading = false;

  static const List<String> _genders = ['ذكر', 'أنثى', 'غير محدد'];

  static const List<String> _governorates = [
    'القاهرة', 'الجيزة', 'الإسكندرية', 'الدقهلية', 'الشرقية', 'الغربية',
    'المنوفية', 'القليوبية', 'البحيرة', 'كفر الشيخ', 'دمياط', 'بورسعيد',
    'الإسماعيلية', 'السويس', 'الفيوم', 'بني سويف', 'المنيا', 'أسيوط',
    'سوهاج', 'قنا', 'الأقصر', 'أسوان', 'البحر الأحمر', 'الوادي الجديد',
    'مطروح', 'شمال سيناء', 'جنوب سيناء',
  ];

  static const List<String> _mobilityTypes = [
    'كرسي متحرك يدوي',
    'كرسي متحرك كهربائي',
    'عكاز / مشاية',
    'مرافق لشخص من ذوي الإعاقة',
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final extra = GoRouter.of(context).routerDelegate.currentConfiguration.uri.queryParameters;
      _email = extra['email'] ?? '';
      _phone = extra['phone'] ?? '';
    });

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _nameFocusNode.dispose();
    _addressFocusNode.dispose();
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
                        _buildProgressIndicator(theme, 3),
                        const SizedBox(height: 32),
                        // Form
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Full Name (if not set)
                              _buildNameField(theme),
                              const SizedBox(height: 16),
                              // Gender
                              _buildGenderField(theme),
                              const SizedBox(height: 16),
                              // Birth Date
                              _buildBirthDateField(theme),
                              const SizedBox(height: 16),
                              // Address
                              _buildAddressField(theme),
                              const SizedBox(height: 16),
                              // Governorate
                              _buildDropdownField(
                                theme,
                                label: 'المحافظة',
                                icon: Icons.map_outlined,
                                value: _selectedGovernorate,
                                items: _governorates,
                                onChanged: (value) => setState(
                                    () => _selectedGovernorate = value),
                              ),
                              const SizedBox(height: 16),
                              // Mobility type
                              _buildDropdownField(
                                theme,
                                label: 'نوع الحركة',
                                icon: Icons.accessible_forward_rounded,
                                value: _selectedMobility,
                                items: _mobilityTypes,
                                onChanged: (value) =>
                                    setState(() => _selectedMobility = value),
                              ),
                              const SizedBox(height: 24),
                              // Emergency contact (optional)
                              _buildEmergencyContactSection(theme),
                              const SizedBox(height: 32),
                              // Complete button
                              ButtonWidget(
                                content: 'إكمال التسجيل',
                                variant: 'primary',
                                size: 'large',
                                fullWidth: true,
                                loading: _isLoading,
                                onPressed: _handleComplete,
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
                            ],
                          ),
                        ),
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
            Icons.person_outline_rounded,
            color: theme.primary,
            size: 40,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'إكمال الملف الشخصي',
          style: theme.headlineSmall.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: theme.primaryText,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'أضف معلومات إضافية لتحسين تجربتك (اختياري)',
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

  Widget _buildNameField(FlutterFlowTheme theme) {
    return TextFormField(
      controller: _nameController,
      focusNode: _nameFocusNode,
      textInputAction: TextInputAction.next,
      style: theme.bodyLarge.copyWith(fontSize: 16, color: theme.primaryText),
      decoration: InputDecoration(
        labelText: 'الاسم الكامل *',
        hintText: 'أحمد محمد علي',
        prefixIcon: Icon(Icons.person_outline_rounded, color: theme.onSurfaceVariant, size: 22),
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
      onFieldSubmitted: (_) => _addressFocusNode.requestFocus(),
    );
  }

  Widget _buildGenderField(FlutterFlowTheme theme) {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      decoration: InputDecoration(
        labelText: 'النوع',
        prefixIcon: Icon(Icons.person_outline_rounded, color: theme.onSurfaceVariant, size: 22),
        filled: true,
        fillColor: theme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: _inputBorder(theme),
        enabledBorder: _inputBorder(theme),
        focusedBorder: _focusedInputBorder(theme),
      ),
      items: _genders.map((gender) => DropdownMenuItem(
        value: gender,
        child: Text(gender, style: theme.bodyLarge.copyWith(fontSize: 16, color: theme.primaryText)),
      )).toList(),
      onChanged: (value) => setState(() => _selectedGender = value!),
    );
  }

  Widget _buildDropdownField(
    FlutterFlowTheme theme, {
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: theme.onSurfaceVariant, size: 22),
        filled: true,
        fillColor: theme.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: _inputBorder(theme),
        enabledBorder: _inputBorder(theme),
        focusedBorder: _focusedInputBorder(theme),
      ),
      items: items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(item,
                    style: theme.bodyLarge.copyWith(
                        fontSize: 16, color: theme.primaryText)),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildEmergencyContactSection(FlutterFlowTheme theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
        border: Border.all(color: theme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.emergency_outlined, color: theme.primary, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'جهة اتصال طوارئ (اختياري)',
                  style: theme.titleMedium.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: theme.primaryText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'شخص موثوق نرسل له موقعك عند الاستغاثة من صفحة الطوارئ.',
            style: theme.bodySmall.copyWith(
              fontSize: 12,
              color: theme.secondaryText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emergencyNameController,
            textInputAction: TextInputAction.next,
            style: theme.bodyLarge
                .copyWith(fontSize: 16, color: theme.primaryText),
            decoration: InputDecoration(
              labelText: 'اسم المرافق',
              hintText: 'مثال: أحمد (أخويا)',
              prefixIcon: Icon(Icons.person_outline_rounded,
                  color: theme.onSurfaceVariant, size: 22),
              filled: true,
              fillColor: theme.surface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              border: _inputBorder(theme),
              enabledBorder: _inputBorder(theme),
              focusedBorder: _focusedInputBorder(theme),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emergencyPhoneController,
            textInputAction: TextInputAction.done,
            keyboardType: TextInputType.phone,
            style: theme.bodyLarge
                .copyWith(fontSize: 16, color: theme.primaryText),
            decoration: InputDecoration(
              labelText: 'رقم هاتف المرافق',
              hintText: '01xxxxxxxxx',
              prefixIcon: Icon(Icons.phone_outlined,
                  color: theme.onSurfaceVariant, size: 22),
              filled: true,
              fillColor: theme.surface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              border: _inputBorder(theme),
              enabledBorder: _inputBorder(theme),
              focusedBorder: _focusedInputBorder(theme),
              errorBorder: _errorInputBorder(theme),
              focusedErrorBorder: _focusedErrorInputBorder(theme),
            ),
            validator: (value) {
              final raw = (value ?? '').trim();
              if (raw.isEmpty) return null; // optional
              final normalized = raw
                  .replaceAll(RegExp(r'[\s-]'), '')
                  .replaceFirst(RegExp(r'^0020'), '0')
                  .replaceFirst(RegExp(r'^\+?20'), '0');
              if (!RegExp(r'^(010|011|012|015)\d{8}$').hasMatch(normalized)) {
                return 'رقم غير صحيح - اكتب رقماً مصرياً مثل 010xxxxxxxx';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBirthDateField(FlutterFlowTheme theme) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
          firstDate: DateTime(1920),
          lastDate: DateTime.now().subtract(const Duration(days: 365 * 13)),
          locale: const Locale('ar', 'EG'),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(primary: theme.primary),
            ),
            child: child!,
          ),
        );
        if (date != null && mounted) {
          setState(() => _selectedBirthDate = date);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'تاريخ الميلاد',
          prefixIcon: Icon(Icons.cake_outlined, color: theme.onSurfaceVariant, size: 22),
          filled: true,
          fillColor: theme.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          border: _inputBorder(theme),
          enabledBorder: _inputBorder(theme),
          focusedBorder: _focusedInputBorder(theme),
        ),
        child: Text(
          _selectedBirthDate != null
              ? '${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year}'
              : 'اختر تاريخ الميلاد',
          style: theme.bodyLarge.copyWith(
            fontSize: 16,
            color: _selectedBirthDate != null ? theme.primaryText : theme.hintText,
          ),
        ),
      ),
    );
  }

  Widget _buildAddressField(FlutterFlowTheme theme) {
    return TextFormField(
      controller: _addressController,
      focusNode: _addressFocusNode,
      textInputAction: TextInputAction.done,
      maxLines: 2,
      style: theme.bodyLarge.copyWith(fontSize: 16, color: theme.primaryText),
      decoration: InputDecoration(
        labelText: 'العنوان (اختياري)',
        hintText: 'الشارع، المنطقة، المدينة، المحافظة',
        prefixIcon: Icon(Icons.location_on_outlined, color: theme.onSurfaceVariant, size: 22),
        filled: true,
        fillColor: theme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: _inputBorder(theme),
        enabledBorder: _inputBorder(theme),
        focusedBorder: _focusedInputBorder(theme),
        errorBorder: _errorInputBorder(theme),
        focusedErrorBorder: _focusedErrorInputBorder(theme),
      ),
      onFieldSubmitted: (_) => _handleComplete(),
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
          onPressed: () => context.goNamed(AuthenticationWidget.routeName),
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

  Future<void> _handleComplete() async {
    if (!(_formKey.currentState?.validate() ?? true)) return;
    setState(() => _isLoading = true);

    // Build the full profile update (every field the form collected).
    final updates = <String, dynamic>{
      'updated_time': FieldValue.serverTimestamp(),
    };
    final displayName = _nameController.text.trim();
    if (displayName.isNotEmpty) {
      updates['display_name'] = displayName;
    }
    if (_addressController.text.trim().isNotEmpty) {
      updates['address'] = _addressController.text.trim();
    }
    if (_selectedGender != 'غير محدد') {
      updates['gender'] = _selectedGender;
    }
    if (_selectedGovernorate != null) {
      updates['governorate'] = _selectedGovernorate;
    }
    if (_selectedMobility != null) {
      updates['mobility_type'] = _selectedMobility;
    }
    if (_selectedBirthDate != null) {
      updates['birth_date'] = Timestamp.fromDate(_selectedBirthDate!);
    }

    final uid = currentUserUid;
    try {
      // Keep Firebase Auth display name in sync (cheap, best-effort).
      if (displayName.isNotEmpty) {
        await AuthService.instance.updateUserProfile(displayName: displayName);
      }
      // Write everything to the Firestore users document - this is what
      // the app and the security rules actually read.
      if (uid.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update(updates);
      }

      // Optional emergency contact: powers the emergency page immediately.
      final contactName = _emergencyNameController.text.trim();
      final contactPhone = _emergencyPhoneController.text
          .trim()
          .replaceAll(RegExp(r'[\s-]'), '')
          .replaceFirst(RegExp(r'^0020'), '0')
          .replaceFirst(RegExp(r'^\+?20'), '0');
      if (uid.isNotEmpty && contactName.isNotEmpty && contactPhone.isNotEmpty) {
        await EmergencyContactsRecord.collection.add(
          createEmergencyContactsRecordData(
            userId: uid,
            name: contactName,
            relationship: 'مرافق',
            phoneNumber: contactPhone,
            isPrimary: true,
            createdAt: DateTime.now(),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error completing registration profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر حفظ بعض البيانات - يمكنك تعديلها لاحقاً من الملف الشخصي.'),
          ),
        );
      }
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    context.pushNamed(
      RegistrationSuccessWidget.routeName,
      extra: {
        'email': _email,
        'phone': _phone,
      },
    );
  }

  Future<void> _handleSkip() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _isLoading = false);

    context.pushNamed(
      RegistrationSuccessWidget.routeName,
      extra: {
        'email': _email,
        'phone': _phone,
      },
    );
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

  OutlineInputBorder _focusedErrorInputBorder(FlutterFlowTheme theme) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
        borderSide: BorderSide(color: theme.error, width: 2),
      );
}