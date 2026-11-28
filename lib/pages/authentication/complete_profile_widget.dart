import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/auth/verification_service.dart';
import '/backend/schema/users_record.dart';
import '/components/button/button_widget.dart';
import '/core/analytics/analytics_service.dart';
import '/core/constants/app_constants.dart';
import '/core/constants/profile_options.dart';
import '/flutter_flow/flutter_flow_theme.dart' show FlutterFlowTheme;
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/nav/nav.dart';
import '/index.dart';

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
  final _addressController = TextEditingController();

  final _nameFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _addressFocusNode = FocusNode();

  String _selectedGender = 'ذكر';
  String? _selectedGovernorate;
  String? _selectedMobility;
  Set<String> _selectedAccessNeeds = {
    'step_free_entrance',
    'suitable_ramp',
  };
  DateTime? _selectedBirthDate;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.14),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.15, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    _prefillFromCurrentUser();
    _animationController.forward();
  }

  Future<void> _prefillFromCurrentUser() async {
    UsersRecord? doc = currentUserDocument;
    if (doc == null && currentUserUid.isNotEmpty) {
      try {
        doc = await UsersRecord.getDocumentOnce(
          UsersRecord.collection.doc(currentUserUid),
        );
        currentUserDocument = doc;
      } catch (_) {}
    }
    if (!mounted) return;
    final data = doc?.snapshotData;
    _nameController.text = AuthService.instance.currentUserDisplayName;
    _phoneController.text = AuthService.instance.currentPhoneNumber;
    _addressController.text = (data?['address'] as String?) ?? '';

    final gender = (data?['gender'] as String?) ?? '';
    if (ProfileOptions.genders.contains(gender) && gender != 'غير محدد') {
      _selectedGender = gender;
    }
    final gov = data?['governorate'] as String?;
    if (gov != null && ProfileOptions.governorates.contains(gov)) {
      _selectedGovernorate = gov;
    }
    final mobility = ProfileOptions.normalizeMobilityForDropdown(
          data?['mobility_type'] as String?,
        ) ??
        ProfileOptions.normalizeMobilityForDropdown(FFAppState().mobilityType);
    if (mobility != null) {
      _selectedMobility = mobility;
    }
    final savedNeeds = (data?['access_needs'] as List?)
            ?.map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList() ??
        FFAppState().accessNeeds;
    if (savedNeeds.isNotEmpty) {
      _selectedAccessNeeds = savedNeeds.toSet();
    } else if (_selectedMobility != null) {
      final opt = MobilityProfileOption.resolveOption(_selectedMobility);
      if (opt != null && opt.defaultAccessNeeds.isNotEmpty) {
        _selectedAccessNeeds = opt.defaultAccessNeeds.toSet();
      }
    }
    _selectedBirthDate = ProfileOptions.parseBirthDate(data?['birth_date']);
    setState(() {});
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _nameFocusNode.dispose();
    _phoneFocusNode.dispose();
    _addressFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'يرجى استكمال بياناتك الشخصية أولاً للمتابعة، أو تسجيل الخروج من الأسفل.',
            ),
          ),
        );
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: theme.background,
          appBar: AppBar(
            backgroundColor: theme.navy,
            foregroundColor: Colors.white,
            automaticallyImplyLeading: false,
            centerTitle: true,
            title: const Text(
              'استكمال البيانات الشخصية',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 24),
                            _buildHeader(theme),
                            const SizedBox(height: 24),
                            _buildNameField(theme),
                            const SizedBox(height: 16),
                            _buildPhoneField(theme),
                            const SizedBox(height: 16),
                            _buildDropdown(
                              theme,
                              label: 'النوع *',
                              icon: Icons.wc_outlined,
                              value: _selectedGender,
                              items: const ['ذكر', 'أنثى'],
                              onChanged: (v) => setState(
                                  () => _selectedGender = v ?? 'ذكر'),
                            ),
                            const SizedBox(height: 16),
                            _buildBirthDateField(theme),
                            const SizedBox(height: 16),
                            _buildDropdown(
                              theme,
                              label: 'المحافظة *',
                              icon: Icons.map_outlined,
                              value: _selectedGovernorate,
                              items: ProfileOptions.governorates,
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'يرجى اختيار المحافظة'
                                  : null,
                              onChanged: (v) =>
                                  setState(() => _selectedGovernorate = v),
                            ),
                            const SizedBox(height: 16),
                            _buildAddressField(theme),
                            const SizedBox(height: 16),
                            _buildDropdown(
                              theme,
                              label: 'طريقة التنقل (لتخصيص التوافق مع الأماكن) *',
                              icon: Icons.accessible_forward_rounded,
                              value: _selectedMobility,
                              items: ProfileOptions.mobilityTypes,
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'يرجى اختيار طريقة التنقل'
                                  : null,
                              onChanged: (v) {
                                setState(() {
                                  _selectedMobility = v;
                                  final opt =
                                      MobilityProfileOption.resolveOption(v);
                                  if (opt != null &&
                                      opt.defaultAccessNeeds.isNotEmpty) {
                                    _selectedAccessNeeds =
                                        opt.defaultAccessNeeds.toSet();
                                  }
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'احتياجات الوصول التي تهمك في المكان:',
                              style: theme.titleSmall.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: theme.primaryText,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: AccessNeedOption.all.map((need) {
                                final selected =
                                    _selectedAccessNeeds.contains(need.id);
                                return FilterChip(
                                  selected: selected,
                                  label: Text(
                                    need.titleAr,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: selected
                                          ? Colors.white
                                          : theme.primaryText,
                                    ),
                                  ),
                                  selectedColor: theme.primary,
                                  checkmarkColor: Colors.white,
                                  backgroundColor: theme.surface,
                                  side: BorderSide(
                                    color: selected
                                        ? theme.primary
                                        : theme.outlineVariant,
                                  ),
                                  onSelected: (val) {
                                    setState(() {
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
                            const SizedBox(height: 28),
                            ButtonWidget(
                              content: 'حفظ البيانات والمتابعة',
                              variant: 'primary',
                              size: 'large',
                              fullWidth: true,
                              loading: _isLoading,
                              onPressed: _isLoading ? null : _handleComplete,
                            ),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: _isLoading ? null : _handleSignOut,
                              icon: Icon(Icons.logout_rounded,
                                  size: 18, color: theme.secondaryText),
                              label: Text(
                                'تسجيل الخروج واستخدام حساب آخر',
                                style: theme.labelLarge.copyWith(
                                  fontSize: 13.5,
                                  color: theme.secondaryText,
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
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
      ),
      ),
    );
  }

  Widget _buildHeader(FlutterFlowTheme theme) {
    final email = AuthService.instance.currentUserEmail;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(Icons.badge_outlined, color: theme.primary, size: 38),
          const SizedBox(height: 10),
          Text(
            'أهلاً بك في ONEWAY!',
            style: theme.titleLarge.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.primaryText,
            ),
            textAlign: TextAlign.center,
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              email,
              style: theme.bodySmall.copyWith(
                color: theme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            'أكمل بياناتك الشخصية الخاصة بملفك الشخصي (رقم الهاتف، المحافظة، ونوع الحركة) لحساب توافق الأماكن معك بدقة.',
            style: theme.bodySmall.copyWith(
              color: theme.secondaryText,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
        prefixIcon:
            Icon(Icons.person_outline_rounded, color: theme.primary, size: 22),
        filled: true,
        fillColor: theme.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: _inputBorder(theme),
        enabledBorder: _inputBorder(theme),
        focusedBorder: _focusedInputBorder(theme),
        errorBorder: _errorInputBorder(theme),
      ),
      validator: (value) {
        if (value == null || value.trim().length < 2) {
          return 'الاسم الكامل مطلوب (حرفين على الأقل)';
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
        labelText: 'رقم الهاتف المصري *',
        hintText: '010xxxxxxxx',
        prefixIcon: Icon(Icons.phone_outlined, color: theme.primary, size: 22),
        filled: true,
        fillColor: theme.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: _inputBorder(theme),
        enabledBorder: _inputBorder(theme),
        focusedBorder: _focusedInputBorder(theme),
        errorBorder: _errorInputBorder(theme),
      ),
      validator: (value) {
        if (value == null || !ProfileOptions.isValidEgyptianPhone(value)) {
          return 'رقم هاتف مصري غير صالح (مثال: 010xxxxxxxx)';
        }
        return null;
      },
      onFieldSubmitted: (_) => _addressFocusNode.requestFocus(),
    );
  }

  Widget _buildAddressField(FlutterFlowTheme theme) {
    return TextFormField(
      controller: _addressController,
      focusNode: _addressFocusNode,
      maxLines: 2,
      textInputAction: TextInputAction.done,
      style: theme.bodyLarge.copyWith(fontSize: 16, color: theme.primaryText),
      decoration: InputDecoration(
        labelText: 'العنوان التفصيلي *',
        hintText: 'الشارع، المنطقة، المدينة',
        prefixIcon:
            Icon(Icons.location_on_outlined, color: theme.primary, size: 22),
        filled: true,
        fillColor: theme.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: _inputBorder(theme),
        enabledBorder: _inputBorder(theme),
        focusedBorder: _focusedInputBorder(theme),
        errorBorder: _errorInputBorder(theme),
      ),
      validator: (value) {
        if (value == null || value.trim().length < 3) {
          return 'يرجى كتابة العنوان أو المنطقة';
        }
        return null;
      },
    );
  }

  Widget _buildBirthDateField(FlutterFlowTheme theme) {
    return InkWell(
      borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
      onTap: () async {
        final now = DateTime.now();
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedBirthDate ??
              DateTime(now.year - 25, now.month, now.day),
          firstDate: DateTime(1920),
          lastDate: DateTime(now.year - 5, now.month, now.day),
        );
        if (date != null && mounted) {
          setState(() => _selectedBirthDate = date);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'تاريخ الميلاد',
          prefixIcon:
              Icon(Icons.cake_outlined, color: theme.primary, size: 22),
          filled: true,
          fillColor: theme.surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          border: _inputBorder(theme),
          enabledBorder: _inputBorder(theme),
        ),
        child: Text(
          _selectedBirthDate != null
              ? ProfileOptions.formatBirthDate(_selectedBirthDate)
              : 'اختر تاريخ الميلاد',
          style: theme.bodyLarge.copyWith(
            fontSize: 16,
            color:
                _selectedBirthDate != null ? theme.primaryText : theme.hintText,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(
    FlutterFlowTheme theme, {
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: theme.primary, size: 22),
        filled: true,
        fillColor: theme.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: _inputBorder(theme),
        enabledBorder: _inputBorder(theme),
        focusedBorder: _focusedInputBorder(theme),
        errorBorder: _errorInputBorder(theme),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(
                item,
                overflow: TextOverflow.ellipsis,
                style: theme.bodyLarge
                    .copyWith(fontSize: 16, color: theme.primaryText),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Future<void> _handleComplete() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBirthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار تاريخ الميلاد للمتابعة')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final uid = currentUserUid;
    final phone = ProfileOptions.normalizeEgyptianPhone(_phoneController.text);
    final coreUpdates = <String, dynamic>{
      'updated_time': FieldValue.serverTimestamp(),
      'display_name': _nameController.text.trim(),
      'phone_number': phone,
      'address': _addressController.text.trim(),
      'gender': _selectedGender,
      if (_selectedGovernorate != null) 'governorate': _selectedGovernorate,
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
      if (uid.isNotEmpty) {
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
          await AnalyticsService.instance.setMobilityType(_selectedMobility!);
        }
        await FFAppState()
            .setAccessNeeds(_selectedAccessNeeds.take(10).toList());
        currentUserDocument = await UsersRecord.getDocumentOnce(
          UsersRecord.collection.doc(uid),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر حفظ البيانات الشخصية: $e')),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    await AuthRouter.instance.navigateAfterLogin(context);
  }

  Future<void> _handleSignOut() async {
    GoRouter.of(context).prepareAuthEvent();
    await AuthService.instance.signOut();
    if (!mounted) return;
    context.goNamed(AuthenticationWidget.routeName);
  }

  OutlineInputBorder _inputBorder(FlutterFlowTheme theme) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
        borderSide: BorderSide(color: theme.outlineVariant, width: 1.5),
      );

  OutlineInputBorder _focusedInputBorder(FlutterFlowTheme theme) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
        borderSide: BorderSide(color: theme.primary, width: 2),
      );

  OutlineInputBorder _errorInputBorder(FlutterFlowTheme theme) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
        borderSide: BorderSide(color: theme.error, width: 1.5),
      );
}
