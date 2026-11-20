import '/components/button/button_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart'
    show FlutterFlowTheme;
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/nav/nav.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BusinessRegistrationStep3Widget extends StatefulWidget {
  const BusinessRegistrationStep3Widget({
    super.key,
    this.onSubmit,
    this.onPrevious,
    this.initialData,
  });

  static String routeName = 'BusinessRegistrationStep3';
  static String routePath = '/business/register/step3';

  final VoidCallback? onSubmit;
  final VoidCallback? onPrevious;
  final Map<String, dynamic>? initialData;

  @override
  State<BusinessRegistrationStep3Widget> createState() => _BusinessRegistrationStep3WidgetState();
}

class _BusinessRegistrationStep3WidgetState extends State<BusinessRegistrationStep3Widget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _workingHoursController = TextEditingController();

  GeoPoint? _selectedLocation;
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
      _addressController.text = widget.initialData!['address'] ?? '';
      _workingHoursController.text = widget.initialData!['workingHours'] ?? '';
      _selectedLocation = widget.initialData!['location'];
    }

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _addressController.dispose();
    _workingHoursController.dispose();
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
                              onPressed: widget.onPrevious?.call ?? () => context.safePop(),
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
                          _buildProgressIndicator(theme, 3),
                          const SizedBox(height: 32),
                          // Form fields
                          _buildAddressField(theme),
                          const SizedBox(height: 16),
                          _buildLocationPicker(theme),
                          const SizedBox(height: 16),
                          _buildWorkingHoursField(theme),
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
            Icons.location_on_outlined,
            color: theme.primary,
            size: 40,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'الموقع والتفاصيل',
          style: theme.headlineSmall.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: theme.primaryText,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'عنوان المنشأة وساعات العمل (اختياري)',
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

  Widget _buildAddressField(FlutterFlowTheme theme) {
    return TextFormField(
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
    );
  }

  Widget _buildLocationPicker(FlutterFlowTheme theme) {
    return Card(
      color: theme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
        side: BorderSide(
          color: _selectedLocation != null ? theme.success : theme.outlineVariant,
          width: _selectedLocation != null ? 2 : 1.5,
        ),
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
    );
  }

  Future<void> _pickLocation() async {
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
                          _selectedLocation = const GeoPoint(30.0444, 31.2357);
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

  Widget _buildWorkingHoursField(FlutterFlowTheme theme) {
    return TextFormField(
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
            content: 'إرسال الطلب',
            variant: 'primary',
            size: 'medium',
            fullWidth: true,
            loading: _isLoading,
            iconEnd: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            iconEndPresent: true,
            onPressed: _handleSubmit,
          ),
        ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    safeSetState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    safeSetState(() => _isLoading = false);

    if (widget.onSubmit != null) {
      widget.onSubmit!();
    } else {
      // Navigate to success
      context.pushNamed(
        BusinessRegistrationSuccessWidget.routeName,
        extra: {
          'businessName': 'المنشأة',
        },
      );
    }
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