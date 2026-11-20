import '/auth/business_registration_service.dart'
    show BusinessRegistrationService, BusinessApplicationData;
import '/components/button/button_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart'
    show FlutterFlowTheme;
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/nav/nav.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BusinessRegistrationWidget extends StatefulWidget {
  const BusinessRegistrationWidget({super.key});

  static String routeName = 'BusinessRegistration';
  static String routePath = '/business/register';

  @override
  State<BusinessRegistrationWidget> createState() => _BusinessRegistrationWidgetState();
}

class _BusinessRegistrationWidgetState extends State<BusinessRegistrationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  int _currentStep = 1;
  final PageController _pageController = PageController();
  bool _isLoading = false;

  // Helper getters for current user info
  String get _currentUserDisplayName => AuthService.instance.currentUserDisplayName;
  String get _currentUserEmail => AuthService.instance.currentUserEmail;
  String get _currentPhoneNumber => AuthService.instance.currentPhoneNumber;

  // Step 1 data
  final _businessNameController = TextEditingController();
  final _categoryController = TextEditingController(text: 'مطاعم وكافيهات');
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'مطاعم وكافيهات';

  // Step 2 data
  final _ownerNameController = TextEditingController();
  final _ownerPhoneController = TextEditingController();
  final _ownerEmailController = TextEditingController();

  // Step 3 data
  final _addressController = TextEditingController();
  GeoPoint? _selectedLocation;
  final _workingHoursController = TextEditingController();

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

    // Pre-fill owner info from current user
    _ownerNameController.text = _currentUserDisplayName;
    _ownerEmailController.text = _currentUserEmail;
    _ownerPhoneController.text = _currentPhoneNumber;

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    _businessNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _descriptionController.dispose();
    _ownerNameController.dispose();
    _ownerPhoneController.dispose();
    _ownerEmailController.dispose();
    _addressController.dispose();
    _workingHoursController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_validateCurrentStep()) {
      if (_currentStep < 3) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      } else {
        _submitApplication();
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 1) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 1:
        if (_businessNameController.text.trim().isEmpty) {
          _showError('اسم المنشأة مطلوب');
          return false;
        }
        if (_phoneController.text.trim().isEmpty) {
          _showError('رقم هاتف التواصل مطلوب');
          return false;
        }
        if (!_isValidPhone(_phoneController.text.trim())) {
          _showError('رقم هاتف غير صالح');
          return false;
        }
        return true;
      case 2:
        if (_ownerNameController.text.trim().isEmpty) {
          _showError('اسم المالك مطلوب');
          return false;
        }
        if (_ownerPhoneController.text.trim().isEmpty) {
          _showError('رقم هاتف المالك مطلوب');
          return false;
        }
        if (!_isValidPhone(_ownerPhoneController.text.trim())) {
          _showError('رقم هاتف المالك غير صالح');
          return false;
        }
        return true;
      case 3:
        return true; // Optional fields
      default:
        return false;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: FlutterFlowTheme.of(context).error,
      ),
    );
  }

  Future<void> _submitApplication() async {
    safeSetState(() => _isLoading = true);

    final data = BusinessApplicationData(
      businessName: _businessNameController.text.trim(),
      category: _selectedCategory,
      phoneNumber: _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      location: _selectedLocation,
      workingHours: _workingHoursController.text.trim().isEmpty ? null : _parseWorkingHours(_workingHoursController.text.trim()),
      services: null,
      ownerName: _ownerNameController.text.trim(),
      ownerPhone: _ownerPhoneController.text.trim(),
      ownerEmail: _ownerEmailController.text.trim().isEmpty ? null : _ownerEmailController.text.trim(),
    );

    final result = await BusinessRegistrationService.instance.submitBusinessApplication(
      data: data,
    );

    if (!mounted) return;
    safeSetState(() => _isLoading = false);

    if (result.success) {
      context.pushNamed(
        BusinessRegistrationSuccessWidget.routeName,
        extra: {
          'businessId': result.businessId,
          'businessName': _businessNameController.text.trim(),
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'فشل تسجيل المنشأة'),
          backgroundColor: FlutterFlowTheme.of(context).error,
        ),
      );
    }
  }

  Map<String, dynamic>? _parseWorkingHours(String text) {
    // Simple parsing - in production, use a proper time picker
    return {
      'raw': text,
      'note': 'أوقات العمل كما أدخلها المستخدم',
    };
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
              child: Column(
                children: [
                  // Header with progress
                  _buildHeader(theme),
                  // Step content
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (index) {
                        safeSetState(() => _currentStep = index + 1);
                      },
                      children: [
                        _buildStep1(theme),
                        _buildStep2(theme),
                        _buildStep3(theme),
                      ],
                    ),
                  ),
                  // Navigation buttons
                  _buildNavigationButtons(theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(FlutterFlowTheme theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border(
          bottom: BorderSide(color: theme.outlineVariant, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Progress indicator
          // Row(
          //   children: List.generate(3, (index) {
          //     final step = index + 1;
          //     final isActive = step <= _currentStep;
          //     final isCurrent = step == _currentStep;
          //
          //     return Expanded(
          //       child: Row(
          //         children: [
          //           // Circle
          //           Container(
          //             width: 28,
          //             height: 28,
          //             decoration: BoxDecoration(
          //               color: isActive ? theme.primary : theme.surfaceVariant,
          //               shape: BoxShape.circle,
          //               border: Border.all(
          //                 color: isActive ? theme.primary : theme.outlineVariant,
          //                 width: 2,
          //               ),
          //             ),
          //             child: Center(
          //               child: isActive
          //                   ? Icon(
          //                       isCurrent ? Icons.radio_button_checked : Icons.check,
          //                       color: isActive ? Colors.white : theme.primary,
          //                       size: 16,
          //                     )
          //                   : Text(
          //                       '$step',
          //                       style: theme.labelMedium.copyWith(
          //                         fontSize: 12,
          //                         color: theme.tertiaryText,
          //                       ),
          //                     ),
          //             ),
          //           ),
          //           if (step < 3)
          //             Expanded(
          //               child: Container(
          //                 height: 2,
          //                 margin: const EdgeInsets.symmetric(horizontal: 8),
          //                 color: step < _currentStep ? theme.primary : theme.outlineVariant,
          //               ),
          //             ),
          //         ],
          //       ),
          //     );
          //   },
          // ),
          const SizedBox(height: 16),
          // Step title
          Text(
            _getStepTitle(),
            style: theme.titleMedium.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: theme.primaryText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            _getStepSubtitle(),
            style: theme.bodySmall.copyWith(
              fontSize: 12,
              color: theme.tertiaryText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 1:
        return 'معلومات المنشأة';
      case 2:
        return 'معلومات المالك';
      case 3:
        return 'الموقع والتفاصيل';
      default:
        return '';
    }
  }

  String _getStepSubtitle() {
    switch (_currentStep) {
      case 1:
        return 'أدخل بيانات منشأتك الأساسية';
      case 2:
        return 'بيانات التواصل مع صاحب المنشأة';
      case 3:
        return 'عنوان المنشأة وساعات العمل (اختياري)';
      default:
        return '';
    }
  }

  Widget _buildStep1(FlutterFlowTheme theme) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Business name
          TextFormField(
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
            ),
          ),
          const SizedBox(height: 16),
          // Category
          DropdownButtonFormField<String>(
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
          ),
          const SizedBox(height: 16),
          // Phone
          TextFormField(
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
            ),
          ),
          const SizedBox(height: 16),
          // Email (optional)
          TextFormField(
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
          ),
          const SizedBox(height: 16),
          // Description (optional)
          TextFormField(
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
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(FlutterFlowTheme theme) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Info card
          Card(
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
          ),
          const SizedBox(height: 24),
          // Owner name
          TextFormField(
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
            ),
          ),
          const SizedBox(height: 16),
          // Owner phone
          TextFormField(
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
            ),
          ),
          const SizedBox(height: 16),
          // Owner email
          TextFormField(
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
          ),
        ],
      ),
    );
  }

  Widget _buildStep3(FlutterFlowTheme theme) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Address
          TextFormField(
            controller: _addressController,
            maxLines: 2,
            textInputAction: TextInputAction.next,
            style: theme.bodyLarge.copyWith(fontSize: 16, color: theme.primaryText),
            decoration: InputDecoration(
              labelText: 'العنوان التفصيلي (اختياري)',
              hintText: 'الشارع، المنطقة، المدينة، المحافظة',
              prefixIcon: Icon(Icons.location_on_outlined, color: theme.onSurfaceVariant, size: 22),
              filled: true,
              fillColor: theme.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              border: _inputBorder(theme),
              enabledBorder: _inputBorder(theme),
              focusedBorder: _focusedInputBorder(theme),
            ),
          ),
          const SizedBox(height: 16),
          // Location picker
          Card(
            color: theme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
              side: BorderSide(color: theme.outlineVariant, width: 1.5),
            ),
            child: InkWell(
              onTap: _pickLocation,
              borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _selectedLocation != null
                            ? theme.success.withValues(alpha: 0.1)
                            : theme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(theme.designToken.radius.lg),
                      ),
                      child: Icon(
                        _selectedLocation != null
                            ? Icons.location_on_rounded
                            : Icons.add_location_alt_outlined,
                        color: _selectedLocation != null ? theme.success : theme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'موقع المنشأة على الخريطة',
                            style: theme.bodyMedium.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme.primaryText,
                            ),
                          ),
                          Text(
                            _selectedLocation != null
                                ? 'خط العرض: ${_selectedLocation!.latitude.toStringAsFixed(4)}, خط الطول: ${_selectedLocation!.longitude.toStringAsFixed(4)}'
                                : 'اضغط لاختيار الموقع على الخريطة (اختياري)',
                            style: theme.bodySmall.copyWith(
                              fontSize: 12,
                              color: theme.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_back_ios,
                      color: theme.tertiaryText,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Working hours
          TextFormField(
            controller: _workingHoursController,
            maxLines: 2,
            textInputAction: TextInputAction.done,
            style: theme.bodyLarge.copyWith(fontSize: 16, color: theme.primaryText),
            decoration: InputDecoration(
              labelText: 'ساعات العمل (اختياري)',
              hintText: 'مثال: الأحد-الخميس: 9 ص - 10 م\nالجمعة-السبت: 10 ص - 11 م',
              prefixIcon: Icon(Icons.access_time_outlined, color: theme.onSurfaceVariant, size: 22),
              filled: true,
              fillColor: theme.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              border: _inputBorder(theme),
              enabledBorder: _inputBorder(theme),
              focusedBorder: _focusedInputBorder(theme),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickLocation() async {
    // In production, use Google Maps place picker
    // For now, simulate location selection
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  bottom: BorderSide(color: FlutterFlowTheme.of(context).outlineVariant),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'اختر الموقع على الخريطة',
                    style: FlutterFlowTheme.of(context).titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map_outlined,
                      size: 64,
                      color: FlutterFlowTheme.of(context).tertiaryText,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'اختيار الموقع على الخريطة',
                      style: FlutterFlowTheme.of(context).titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'في الإصدار الكامل، سيتم فتح Google Maps هنا',
                      style: FlutterFlowTheme.of(context).bodyMedium.copyWith(
                        color: FlutterFlowTheme.of(context).tertiaryText,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () {
                        // Simulate Cairo location
                        safeSetState(() {
                          _selectedLocation = GeoPoint(30.0444, 31.2357);
                        });
                        Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.my_location),
                      label: const Text('استخدام موقعي الحالي (تجريبي)'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(FlutterFlowTheme theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border(
          top: BorderSide(color: theme.outlineVariant, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            color: theme.shadow.withValues(alpha: 0.1),
            offset: const Offset(0, -4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 1)
            Expanded(
              child: ButtonWidget(
                content: 'السابق',
                variant: 'outline',
                size: 'medium',
                fullWidth: true,
                onPressed: _previousStep,
              ),
            ),
          if (_currentStep > 1) const SizedBox(width: 16),
          Expanded(
            child: ButtonWidget(
              content: _currentStep < 3 ? 'التالي' : 'إرسال الطلب',
              variant: 'primary',
              size: 'medium',
              fullWidth: true,
              loading: _isLoading,
              iconEnd: _currentStep < 3
                  ? const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20)
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              iconEndPresent: true,
              onPressed: _nextStep,
            ),
          ),
        ],
      ),
    );
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
}