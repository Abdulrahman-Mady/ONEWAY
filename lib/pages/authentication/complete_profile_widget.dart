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
import 'package:cloud_firestore/cloud_firestore.dart';

class CompleteProfileWidget extends StatefulWidget {
  const CompleteProfileWidget({super.key});

  static String routeName = 'CompleteProfile';
  static String routePath = '/complete-profile';

  @override
  State<CompleteProfileWidget> createState() => _CompleteProfileWidgetState();
}

class _CompleteProfileWidgetState extends State<CompleteProfileWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  final _nameFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();

  List<String> _missingFields = [];
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final extra = GoRouter.of(context).routerDelegate.currentConfiguration.uri.queryParameters;
      final missingFieldsStr = extra['missingFields'] ?? '';
      if (missingFieldsStr.isNotEmpty) {
        _missingFields = missingFieldsStr.split(',');
      } else {
        // Auto-detect missing fields
        final profile = AuthService.instance.currentUserProfile;
        if (profile != null) {
          if (profile.displayName.isEmpty) _missingFields.add('displayName');
          if (profile.phoneNumber.isEmpty) _missingFields.add('phoneNumber');
        }
      }

      // Pre-fill existing data
      _nameController.text = AuthService.instance.currentUserDisplayName;
      _phoneController.text = AuthService.instance.currentPhoneNumber;
    });

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _nameFocusNode.dispose();
    _phoneFocusNode.dispose();
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 40),
                          // Header
                          _buildHeader(theme),
                          const SizedBox(height: 48),
                          // Missing fields info
                          if (_missingFields.isNotEmpty) ...[
                            _buildMissingFieldsInfo(theme),
                            const SizedBox(height: 32),
                          ],
                          // Form fields
                          if (_missingFields.contains('displayName') || _nameController.text.isEmpty) ...[
                            _buildNameField(theme),
                            const SizedBox(height: 16),
                          ],
                          if (_missingFields.contains('phoneNumber') || _phoneController.text.isEmpty) ...[
                            _buildPhoneField(theme),
                            const SizedBox(height: 16),
                          ],
                          const Spacer(),
                          // Complete button
                          ButtonWidget(
                            content: 'إكمال الملف الشخصي',
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
            Icons.person_outline_rounded,
            color: theme.primary,
            size: 56,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'إكمال الملف الشخصي',
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
          _missingFields.isNotEmpty
              ? 'يرجى إكمال البيانات الناقصة للمتابعة'
              : 'أضف معلوماتك لتحسين تجربتك',
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

  Widget _buildMissingFieldsInfo(FlutterFlowTheme theme) {
    return Card(
      color: theme.warning.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
        side: BorderSide(color: theme.warning.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline_rounded, color: theme.warning, size: 24),
                const SizedBox(width: 12),
                Text(
                  'بيانات ناقصة',
                  style: theme.titleSmall.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: theme.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'الحقول التالية مطلوبة لإكمال حسابك:',
              style: theme.bodyMedium.copyWith(
                fontSize: 14,
                color: theme.secondaryText,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _missingFields.map((field) {
                String label;
                IconData icon;
                switch (field) {
                  case 'displayName':
                    label = 'الاسم الكامل';
                    icon = Icons.person_outline;
                    break;
                  case 'phoneNumber':
                    label = 'رقم الهاتف';
                    icon = Icons.phone_outlined;
                    break;
                  default:
                    label = field;
                    icon = Icons.help_outline;
                }
                return Chip(
                  avatar: Icon(icon, size: 16, color: theme.warning),
                  label: Text(
                    label,
                    style: theme.labelMedium.copyWith(
                      fontSize: 12,
                      color: theme.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  backgroundColor: theme.warning.withValues(alpha: 0.1),
                  side: BorderSide(color: theme.warning.withValues(alpha: 0.3)),
                );
              }).toList(),
            ),
          ],
        ),
      ),
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
      onFieldSubmitted: (_) => _phoneFocusNode.requestFocus(),
    );
  }

  Widget _buildPhoneField(FlutterFlowTheme theme) {
    return TextFormField(
      controller: _phoneController,
      focusNode: _phoneFocusNode,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.done,
      style: theme.bodyLarge.copyWith(fontSize: 16, color: theme.primaryText),
      decoration: InputDecoration(
        labelText: 'رقم الهاتف *',
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
      onFieldSubmitted: (_) => _handleComplete(),
    );
  }

  Future<void> _handleComplete() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final updates = <String, dynamic>{};

    if (_nameController.text.trim().isNotEmpty) {
      updates['display_name'] = _nameController.text.trim();
    }
    if (_phoneController.text.trim().isNotEmpty) {
      updates['phone_number'] = _phoneController.text.trim();
    }

    if (updates.isNotEmpty) {
      updates['updated_time'] = FieldValue.serverTimestamp();
      await AuthService.instance.updateUserProfile(
        displayName: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
      );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    AuthRouter.instance.navigateAfterLogin(context);
  }

  Future<void> _handleSkip() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _isLoading = false);

    AuthRouter.instance.navigateAfterLogin(context);
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