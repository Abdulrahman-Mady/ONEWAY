import 'dart:async';
import '/auth/firebase_auth/auth_util.dart';
import '/core/analytics/analytics_service.dart';
import '/core/constants/app_constants.dart';
import '/core/constants/profile_options.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/backend/schema/users_record.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Lets the signed-in user edit their own profile fields. Writes go
/// straight to the Firestore users document (the same document the app
/// and the security rules read).
class EditProfileWidget extends StatefulWidget {
  const EditProfileWidget({super.key});

  static String routeName = 'EditProfile';
  static String routePath = '/profile/edit';

  @override
  State<EditProfileWidget> createState() => _EditProfileWidgetState();
}

class _EditProfileWidgetState extends State<EditProfileWidget> {
  final _formKey = GlobalKey<FormState>();
  final scaffoldKey = GlobalKey<ScaffoldState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  String _selectedGender = 'غير محدد';
  String? _selectedGovernorate;
  String? _selectedMobility;
  Set<String> _selectedAccessNeeds = {};
  DateTime? _selectedBirthDate;
  bool _saving = false;

  static const List<String> _genders = ProfileOptions.genders;
  static const List<String> _governorates = ProfileOptions.governorates;
  static const List<String> _mobilityTypes = ProfileOptions.mobilityTypes;

  bool _prefilled = false;
  StreamSubscription<UsersRecord?>? _userSub;

  @override
  void initState() {
    super.initState();
    _prefill(currentUserDocument?.snapshotData);
    _ensureListener();
  }

  /// Attaches a direct listener to the user document once the signed-in
  /// uid is known. Called from initState and from build: on a cold load
  /// (deep link) the auth restore can finish after this page's first
  /// build, so neither spot alone is enough. The document stream replays
  /// the current doc, unlike the global broadcast auth stream.
  void _ensureListener() {
    if (_userSub != null) return;
    final uid = currentUserUid;
    if (uid.isEmpty) return;
    _userSub = UsersRecord.getDocument(UsersRecord.collection.doc(uid))
        .listen((doc) {
      if (!_prefilled && mounted) {
        setState(() => _prefill(doc.snapshotData));
      }
    });
  }

  /// Fills the form from the user document once. On a cold load (deep
  /// link) the document stream has not emitted yet in initState, so build
  /// calls this again when the document arrives - unless the user already
  /// started typing (then _prefilled is true).
  void _prefill(Map<String, dynamic>? data) {
    if (_prefilled || data == null) return;
    _prefilled = true;
    _nameController.text = (data['display_name'] as String?) ?? '';
    _phoneController.text = (data['phone_number'] as String?) ?? '';
    _addressController.text = (data['address'] as String?) ?? '';
    final gender = (data['gender'] as String?) ?? 'غير محدد';
    _selectedGender = _genders.contains(gender) ? gender : 'غير محدد';
    final governorate = data['governorate'] as String?;
    _selectedGovernorate =
        governorate != null && _governorates.contains(governorate)
            ? governorate
            : null;
    _selectedMobility =
        ProfileOptions.normalizeMobilityForDropdown(data['mobility_type'] as String?);
    final savedNeeds = (data['access_needs'] as List?)
            ?.map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toSet() ??
        FFAppState().accessNeeds.toSet();
    _selectedAccessNeeds = savedNeeds;
    _selectedBirthDate = ProfileOptions.parseBirthDate(data['birth_date']);
  }

  @override
  void dispose() {
    _userSub?.cancel();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final uid = currentUserUid;
    if (uid.isEmpty) return;

    setState(() => _saving = true);

    final phone = _phoneController.text
        .trim()
        .replaceAll(RegExp(r'[\s-]'), '')
        .replaceFirst(RegExp(r'^0020'), '0')
        .replaceFirst(RegExp(r'^\+?20'), '0');

    final updates = <String, dynamic>{
      'updated_time': FieldValue.serverTimestamp(),
      'display_name': _nameController.text.trim(),
      'phone_number': phone,
      'address': _addressController.text.trim(),
    };
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

    try {
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          ...updates,
          'access_needs': _selectedAccessNeeds.take(10).toList(),
        });
      } catch (_) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update(updates);
      }
      if (_selectedMobility != null) {
        await FFAppState().setMobilityType(_selectedMobility!);
        await AnalyticsService.instance.setMobilityType(_selectedMobility!);
      }
      await FFAppState().setAccessNeeds(_selectedAccessNeeds.take(10).toList());
      // Refresh the cached user document so the profile page shows the
      // new values immediately.
      currentUserDocument = await UsersRecord.getDocumentOnce(
          UsersRecord.collection.doc(uid));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ بياناتك بنجاح')),
        );
        context.safePop();
      }
    } catch (e) {
      debugPrint('Edit profile save failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر حفظ البيانات - حاول مرة أخرى.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return AuthUserStreamWidget(
      builder: (context) {
        _ensureListener();
        if (!_prefilled) _prefill(currentUserDocument?.snapshotData);
        return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: theme.background,
        appBar: AppBar(
          backgroundColor: theme.background,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: true,
          title: Text(
            'تعديل البيانات الشخصية',
            style: theme.titleLarge.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: theme.primaryText,
            ),
          ),
          centerTitle: true,
          elevation: 0,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTextField(
                    theme,
                    controller: _nameController,
                    label: 'الاسم الكامل *',
                    icon: Icons.person_outline_rounded,
                    validator: (value) {
                      if (value == null || value.trim().length < 2) {
                        return 'الاسم مطلوب (حرفين على الأقل)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    theme,
                    controller: _phoneController,
                    label: 'رقم الهاتف *',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      final raw = (value ?? '')
                          .trim()
                          .replaceAll(RegExp(r'[\s-]'), '')
                          .replaceFirst(RegExp(r'^0020'), '0')
                          .replaceFirst(RegExp(r'^\+?20'), '0');
                      if (!RegExp(r'^(010|011|012|015)\d{8}$').hasMatch(raw)) {
                        return 'رقم غير صحيح - اكتب رقماً مصرياً مثل 010xxxxxxxx';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown(
                    theme,
                    label: 'النوع',
                    icon: Icons.wc_outlined,
                    value: _selectedGender,
                    items: _genders,
                    onChanged: (v) =>
                        setState(() => _selectedGender = v ?? 'غير محدد'),
                  ),
                  const SizedBox(height: 16),
                  _buildBirthDateField(theme),
                  const SizedBox(height: 16),
                  _buildTextField(
                    theme,
                    controller: _addressController,
                    label: 'العنوان',
                    icon: Icons.location_on_outlined,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown(
                    theme,
                    label: 'المحافظة',
                    icon: Icons.map_outlined,
                    value: _selectedGovernorate,
                    items: _governorates,
                    onChanged: (v) =>
                        setState(() => _selectedGovernorate = v),
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown(
                    theme,
                    label: 'طريقة التنقل',
                    icon: Icons.accessible_forward_rounded,
                    value: _selectedMobility,
                    items: _mobilityTypes,
                    onChanged: (v) {
                      setState(() {
                        _selectedMobility = v;
                        final opt = MobilityProfileOption.resolveOption(v);
                        if (opt != null && opt.defaultAccessNeeds.isNotEmpty) {
                          _selectedAccessNeeds = opt.defaultAccessNeeds.toSet();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'احتياجات الوصول في المكان:',
                    style: theme.titleSmall.copyWith(
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
                        label: Text(need.titleAr),
                        selectedColor: theme.primary,
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: selected ? Colors.white : theme.primaryText,
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
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : const Text('حفظ التعديلات'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
        );
      },
    );
  }

  Widget _buildTextField(
    FlutterFlowTheme theme, {
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: theme.bodyLarge.copyWith(fontSize: 16, color: theme.primaryText),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: theme.onSurfaceVariant, size: 22),
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
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: theme.onSurfaceVariant, size: 22),
      ),
      items: items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(
                  item,
                  style: theme.bodyLarge
                      .copyWith(fontSize: 16, color: theme.primaryText),
                ),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildBirthDateField(FlutterFlowTheme theme) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedBirthDate ??
              DateTime.now().subtract(const Duration(days: 365 * 25)),
          firstDate: DateTime(1920),
          lastDate: DateTime.now(),
          locale: const Locale('ar', 'EG'),
        );
        if (date != null && mounted) {
          setState(() => _selectedBirthDate = date);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'تاريخ الميلاد',
          prefixIcon:
              Icon(Icons.cake_outlined, color: theme.onSurfaceVariant, size: 22),
        ),
        child: Text(
          _selectedBirthDate != null
              ? '${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year}'
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
}
