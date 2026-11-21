import '/components/button/button_widget.dart';
import '/components/checkbox/checkbox_widget.dart';
import '/components/photo_slot/photo_slot_widget.dart';
import '/flutter_flow/flutter_flow_choice_chips.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/schema/places_record.dart';
import '/index.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'submit_accessibility_report_model.dart';
export 'submit_accessibility_report_model.dart';

class SubmitAccessibilityReportWidget extends StatefulWidget {
  const SubmitAccessibilityReportWidget({super.key, this.place});

  final PlacesRecord? place;

  static String routeName = 'SubmitAccessibilityReport';
  static String routePath = '/report';

  @override
  State<SubmitAccessibilityReportWidget> createState() =>
      _SubmitAccessibilityReportWidgetState();
}

class _SubmitAccessibilityReportWidgetState
    extends State<SubmitAccessibilityReportWidget> {
  late SubmitAccessibilityReportModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SubmitAccessibilityReportModel());

    _model.textFieldTextController ??=
        TextEditingController(text: _model.reportDescription);
    _model.textFieldFocusNode ??= FocusNode();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  void _showPhotosUnavailable(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'رفع الصور سيتوفر قريباً بعد تفعيل خدمة التخزين.'),
      ),
    );
  }

  void _showReportHelp(BuildContext context, FlutterFlowTheme theme) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('كيف تكتب بلاغاً مفيداً؟'),
        content: const Text(
          'صف العائق بدقة: نوعه (منحدر مكسور، مدخل ضيق، مصعد معطل...)، '
          'ومكانه بالتفصيل. كلما كان الوصف أوضح، تمكن فريق التحقق من '
          'توثيقه أسرع وظهر للجميع على الخريطة.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('فهمت'),
          ),
        ],
      ),
    );
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
        body: Column(
          children: [
            // Header
            Container(
              decoration: BoxDecoration(
                color: theme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: theme.outlineVariant,
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _HeaderActionButton(
                            icon: Icons.arrow_forward_rounded,
                            onPressed: () => context.goNamed(PlaceDetailsWidget.routeName),
                            theme: theme,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'إبلاغ عن حالة الوصول',
                            style: theme.titleLarge.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: theme.primary,
                            ),
                          ),
                        ],
                      ),
                      _HeaderActionButton(
                        icon: Icons.help_outline_rounded,
                        iconColor: theme.onSurfaceVariant,
                        onPressed: () => _showReportHelp(context, theme),
                        theme: theme,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Place Header Card
                    _PlaceHeaderCard(
                      place: widget.place,
                      theme: theme,
                    ),
                    const SizedBox(height: 24),

                    // Category Selection
                    _ReportSection(
                      title: 'ما هي المشكلة التي واجهتها؟',
                      theme: theme,
                      child: _ReportCategoryChips(
                        value: _model.choiceChipsValue,
                        onChanged: (val) {
                          safeSetState(() {
                            _model.choiceChipsValue = val?.firstOrNull;
                            _model.reportCategory = _model.choiceChipsValue;
                          });
                        },
                        theme: theme,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Description
                    _ReportSection(
                      title: 'تفاصيل إضافية',
                      theme: theme,
                      child: TextFormField(
                        controller: _model.textFieldTextController ??= TextEditingController(),
                        focusNode: _model.textFieldFocusNode ??= FocusNode(),
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'وصف المشكلة',
                          hintText: 'اشرح العائق بالتفصيل لمساعدة الآخرين...',
                          hintStyle: theme.bodyMedium.copyWith(
                            fontSize: 14,
                            color: theme.hintText,
                          ),
                          labelStyle: theme.bodyMedium.copyWith(
                            fontSize: 14,
                            color: theme.onSurfaceVariant,
                          ),
                          floatingLabelStyle: theme.bodyMedium.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.primary,
                          ),
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
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        style: theme.bodyMedium.copyWith(
                          fontSize: 14,
                          color: theme.primaryText,
                        ),
                        onChanged: (_) => EasyDebounce.debounce(
                          '_model.textFieldTextController',
                          const Duration(milliseconds: 2000),
                          () async {
                            _model.reportDescription = _model.textFieldTextController!.text;
                            safeSetState(() {});
                          },
                        ),
                        validator: _model.textFieldTextControllerValidator.asValidator(context),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Photos Section
                    _ReportSection(
                      title: 'إضافة صور',
                      actionLabel: 'اختياري',
                      theme: theme,
                      child: Row(
                        children: [
                          _PhotoSlot(
                            label: 'صورة العائق',
                            onTap: () => _showPhotosUnavailable(context),
                            theme: theme,
                          ),
                          const SizedBox(width: 16),
                          _PhotoSlot(
                            label: 'صورة القياس',
                            onTap: () => _showPhotosUnavailable(context),
                            theme: theme,
                          ),
                          const SizedBox(width: 16),
                          _AddPhotoSlot(
                            onTap: () => _showPhotosUnavailable(context),
                            theme: theme,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Confirmation Checkbox
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
                        border: Border.all(
                          color: theme.primary.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: CheckboxWidget(
                        label: 'أؤكد أن هذه المعلومات دقيقة وبناءً على تجربتي الشخصية',
                        subtitle: 'بمجرد الإرسال، سيتم مراجعة البلاغ من قبل فريق التحقق',
                        color: theme.primary,
                        isChecked: false,
                        hasSubtitle: true,
                        disabled: false,
                        onChanged: (val) {
                          // Handle confirmation
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons
                    Column(
                      children: [
                        ButtonWidget(
                          content: 'إرسال التقرير',
                          variant: 'primary',
                          size: 'large',
                          fullWidth: true,
                          icon: Icon(
                            Icons.check_circle_rounded,
                            color: theme.onPrimary,
                            size: 24,
                          ),
                          iconPresent: true,
                          onPressed: _submitReport,
                        ),
                        const SizedBox(height: 12),
                        ButtonWidget(
                          content: 'إلغاء',
                          variant: 'ghost',
                          size: 'medium',
                          fullWidth: true,
                          onPressed: () => context.goNamed(HomeDashboardWidget.routeName),
                        ),
                      ],
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

  Future<void> _submitReport() async {
    final desc = _model.textFieldTextController?.text.trim() ?? '';
    if (desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('اكتب وصف العائق قبل الإرسال.'),
          duration: Duration(milliseconds: 4000),
        ),
      );
      return;
    }

    try {
      final category = _model.reportCategory ?? 'عائق في الإتاحة';
      final placeName = widget.place?.name ?? 'عائق في الطريق العام';

      await FirebaseFirestore.instance.collection('accessibilityReports').add({
        'place_id': widget.place?.reference.id ?? '',
        'place_name': placeName,
        'createdBy': currentUserUid,
        'user_name': currentUserDisplayName.isNotEmpty ? currentUserDisplayName : 'مستخدم ONEWAY',
        'problemCategory': category,
        'description': desc,
        'photo_urls': <String>[],
        'location': widget.place?.location != null
            ? GeoPoint(widget.place!.location!.latitude, widget.place!.location!.longitude)
            : const GeoPoint(30.0444, 31.2357),
        'status': 'new',
        'created_at': FieldValue.serverTimestamp(),
      });

      if (currentUserUid.isNotEmpty) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': currentUserUid,
          'title': 'تم استلام بلاغك بنجاح',
          'body': 'شكراً لمساهمتك! بلاغك عن ($placeName) قيد المراجعة لدى فريق التوثيق.',
          'type': 'report_status',
          'is_read': false,
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم إرسال البلاغ بنجاح وهو قيد المراجعة من الإدارة.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Color(0xFF2E7D32),
            duration: Duration(milliseconds: 4000),
          ),
        );
        context.pushNamed('MyReports');
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'تعذر إرسال البلاغ.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: ' + e.toString())),
        );
      }
    }
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.icon,
    this.iconColor,
    required this.onPressed,
    required this.theme,
  });

  final IconData icon;
  final Color? iconColor;
  final VoidCallback onPressed;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(theme.designToken.radius.full),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: theme.surfaceVariant,
            borderRadius: BorderRadius.circular(theme.designToken.radius.full),
          ),
          child: Icon(icon, color: iconColor ?? theme.primaryText, size: 22),
        ),
      ),
    );
  }
}

class _PlaceHeaderCard extends StatelessWidget {
  const _PlaceHeaderCard({
    required this.place,
    required this.theme,
  });

  final PlacesRecord? place;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.primary, theme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(theme.designToken.radius.lg),
            child: Container(
              width: 64,
              height: 64,
              child: CachedNetworkImage(
                fadeInDuration: const Duration(milliseconds: 200),
                imageUrl: place?.photoUrl ??
                    'https://dimg.dreamflow.cloud/v1/image/Cairo%20Festival%20City%20Mall%20entrance',
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: theme.surfaceVariant,
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.onPrimary,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: theme.surfaceVariant,
                  child: Icon(
                    Icons.local_hospital_rounded,
                    color: theme.onPrimary.withValues(alpha: 0.5),
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place?.name ?? 'إبلاغ عن عائق في مكان عام',
                  style: theme.titleMedium.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: theme.onPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 13,
                      color: theme.onPrimary.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        place != null
                            ? '${place!.category} • ${place!.city}'
                            : 'موقعك الجغرافي الحالي (GPS)',
                        style: theme.bodySmall.copyWith(
                          fontSize: 12,
                          color: theme.onPrimary.withValues(alpha: 0.8),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportSection extends StatelessWidget {
  const _ReportSection({
    required this.title,
    this.actionLabel,
    required this.theme,
    required this.child,
  });

  final String title;
  final String? actionLabel;
  final FlutterFlowTheme theme;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: theme.titleMedium.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: theme.primaryText,
              ),
            ),
            if (actionLabel != null)
              Text(
                actionLabel!,
                style: theme.labelMedium.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: theme.tertiaryText,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _PhotoSlot extends StatelessWidget {
  const _PhotoSlot({
    required this.label,
    required this.onTap,
    required this.theme,
  });

  final String label;
  final VoidCallback onTap;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: theme.surfaceVariant,
          borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
          border: Border.all(color: theme.outlineVariant, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_a_photo_rounded,
              color: theme.onSurfaceVariant,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.labelSmall.copyWith(
                fontSize: 11,
                color: theme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddPhotoSlot extends StatelessWidget {
  const _AddPhotoSlot({
    required this.onTap,
    required this.theme,
  });

  final VoidCallback onTap;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: theme.surfaceVariant,
          borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
          border: Border.all(
            color: theme.outlineVariant,
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.add_rounded,
          color: theme.onSurfaceVariant,
          size: 28,
        ),
      ),
    );
  }
}

class _ReportCategoryChips extends StatelessWidget {
  const _ReportCategoryChips({
    this.value,
    required this.onChanged,
    required this.theme,
  });

  final String? value;
  final ValueChanged<List<String>?> onChanged;
  final FlutterFlowTheme theme;

  static const categories = [
    'عدم وجود منحدر',
    'مصعد عاطل',
    'مدخل ضيق',
    'دورة مياه غير مجهزة',
    'رصيف مرتفع',
    'أخرى',
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((cat) {
        final selected = value == cat;
        return ChoiceChip(
          label: Text(cat),
          selected: selected,
          onSelected: (isSelected) {
            onChanged(isSelected ? [cat] : null);
          },
          selectedColor: theme.primary,
          backgroundColor: theme.surface,
          labelStyle: theme.bodyMedium.copyWith(
            color: selected ? theme.onPrimary : theme.primaryText,
          ),
        );
      }).toList(),
    );
  }
}