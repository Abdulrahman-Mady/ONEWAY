import 'dart:async';

import '/components/button/button_widget.dart';
import '/components/checkbox/checkbox_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/schema/places_record.dart';
import '/core/analytics/analytics_service.dart';
import '/core/network/connectivity_service.dart';
import '/core/utils/arabic_normalizer.dart';
import '/core/utils/image_compression_service.dart';
import '/features/discovery/places_repository.dart';
import '/features/emergency/emergency_service.dart';
import '/index.dart';
import '/l10n/app_strings.dart';
import '/widgets/offline_status_banner.dart';
import '/widgets/responsive_layout.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'submit_accessibility_report_model.dart';
export 'submit_accessibility_report_model.dart';

/// Submit an accessibility barrier report STRICTLY for an existing registered
/// place in ONEWAY (never arbitrary streets/roads or fake coordinates).
class SubmitAccessibilityReportWidget extends StatefulWidget {
  const SubmitAccessibilityReportWidget({
    super.key,
    this.place,
    this.placesLoader,
  });

  final PlacesRecord? place;

  /// Optional injectable loader for deterministic widget testing.
  final Future<List<PlacesRecord>> Function()? placesLoader;

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
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _placeSearchController = TextEditingController();
  final List<XFile> _pickedPhotos = [];

  PlacesRecord? _selectedPlace;
  List<PlacesRecord> _availablePlaces = const [];
  bool _loadingPlaces = false;
  String _searchQuery = '';

  String _selectedCategory = 'عدم وجود منحدر';
  bool _confirmed = true;
  bool _submitting = false;
  bool _fetchingGps = false;
  GeoPoint? _capturedGps;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SubmitAccessibilityReportModel());
    _selectedPlace = widget.place;

    _model.textFieldTextController ??=
        TextEditingController(text: _model.reportDescription);
    _model.textFieldFocusNode ??= FocusNode();

    if (widget.place == null) {
      _loadRegisteredPlaces();
    }
  }

  Future<void> _loadRegisteredPlaces() async {
    setState(() => _loadingPlaces = true);
    try {
      final places = widget.placesLoader != null
          ? await widget.placesLoader!()
          : await PlacesRepository.instance.getVerifiedPlaces(limit: 100);
      if (mounted) {
        setState(() {
          _availablePlaces = places;
          _loadingPlaces = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingPlaces = false);
      }
    }
  }

  @override
  void dispose() {
    _placeSearchController.dispose();
    _model.dispose();
    super.dispose();
  }

  List<PlacesRecord> get _filteredPlaces {
    final q = ArabicNormalizer.normalize(_searchQuery.trim());
    if (q.isEmpty) return _availablePlaces.take(8).toList();
    return _availablePlaces
        .where((p) {
          final hay = ArabicNormalizer.normalize(
            '${p.name} ${p.category} ${p.city} ${p.governorate} ${p.address}',
          );
          return hay.contains(q);
        })
        .take(12)
        .toList();
  }

  Future<void> _captureCurrentLocation() async {
    if (_fetchingGps) return;
    setState(() => _fetchingGps = true);
    try {
      final pos = await EmergencyService.determineCurrentPosition();
      if (!mounted) return;
      if (pos != null) {
        setState(() => _capturedGps = GeoPoint(pos.latitude, pos.longitude));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرفاق موقعك الجغرافي الحالي لتأكيد التواجد ✓'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر تحديد موقعك الحالي — سيُعتمد موقع المكان المسجّل.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _fetchingGps = false);
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    if (_pickedPhotos.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الحد الأقصى 3 صور لكل بلاغ.')),
      );
      return;
    }
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        imageQuality: 80,
      );
      if (file != null && mounted) {
        setState(() => _pickedPhotos.add(file));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر فتح الكاميرا أو المعرض. تحقق من الأذونات.'),
          ),
        );
      }
    }
  }

  void _showPhotoPickerSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('التقاط صورة بالكاميرا'),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('اختيار من معرض الصور'),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                _pickPhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showReportHelp(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('كيف تكتب بلاغاً مفيداً؟'),
        content: const Text(
          'الإبلاغ متاح فقط للأماكن المسجّلة داخل ONEWAY لضمان مراجعة دقيقة مع إدارة المكان.\n\n'
          'اختر المكان من القائمة، ثم صف العائق بدقة (مثلاً: مصعد متعطل، منحدر شديد الميل، مدخل مغلق...) وأرفق صورة إن أمكن.',
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
        appBar: AppBar(
          backgroundColor: theme.navy,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'رجوع',
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.goNamed(HomeDashboardWidget.routeName);
              }
            },
          ),
          title: Text(
            S.t(context, 'الإبلاغ عن عائق بمكان مسجّل', 'Report Place Barrier'),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline_rounded),
              tooltip: S.t(context, 'مساعدة', 'Help'),
              onPressed: () => _showReportHelp(context),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding:
                EdgeInsets.all(OnewayResponsive.horizontalPadding(context)),
            child: ResponsiveContainer(
              maxWidth: 600,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Place Header Card
                  _PlaceHeaderCard(
                    place: _selectedPlace,
                    capturedGps: _capturedGps,
                    theme: theme,
                    canChangePlace:
                        widget.place == null && _selectedPlace != null,
                    onChangePlace: () =>
                        safeSetState(() => _selectedPlace = null),
                  ),

                  // Existing Registered Place Picker (when opened without pre-selected place)
                  if (widget.place == null && _selectedPlace == null) ...[
                    const SizedBox(height: 18),
                    _ReportSection(
                      title: 'اختر المكان المسجّل في التطبيق *',
                      actionLabel: 'للأماكن المسجّلة فقط',
                      theme: theme,
                      child: _buildExistingPlacePicker(theme),
                    ),
                  ] else if (_selectedPlace != null) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        onPressed: _fetchingGps ? null : _captureCurrentLocation,
                        icon: _fetchingGps
                            ? const SizedBox.square(
                                dimension: 15,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(
                                _capturedGps != null
                                    ? Icons.my_location_rounded
                                    : Icons.gps_fixed_rounded,
                                size: 17,
                              ),
                        label: Text(
                          _capturedGps != null
                              ? 'تم إرفاق تواجدك الحالي بـ GPS ✓'
                              : 'إرفاق موقعي الحالي لتأكيد التواجد (اختياري)',
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Category Selection
                  _ReportSection(
                    title: 'ما هي المشكلة التي واجهتها داخل المكان؟',
                    theme: theme,
                    child: _ReportCategoryChips(
                      value: _selectedCategory,
                      onChanged: (val) {
                        final picked = val?.firstOrNull;
                        if (picked != null && picked.isNotEmpty) {
                          safeSetState(() {
                            _selectedCategory = picked;
                            _model.reportCategory = picked;
                          });
                        }
                      },
                      theme: theme,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Description
                  _ReportSection(
                    title: 'تفاصيل العائق داخل المكان *',
                    theme: theme,
                    child: TextFormField(
                      key: const Key('report_description_field'),
                      controller: _model.textFieldTextController ??=
                          TextEditingController(),
                      focusNode: _model.textFieldFocusNode ??= FocusNode(),
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'وصف المشكلة',
                        hintText:
                            'اشرح مكان العائق داخل المنشأة بالتفصيل (مثال: المصعد الخلفي متوقف، أو المنحدر عند البوابة الرئيسية مغلق)...',
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
                          borderRadius:
                              BorderRadius.circular(theme.designToken.radius.xl),
                          borderSide:
                              BorderSide(color: theme.outlineVariant, width: 1.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(theme.designToken.radius.xl),
                          borderSide:
                              BorderSide(color: theme.outlineVariant, width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(theme.designToken.radius.xl),
                          borderSide: BorderSide(color: theme.primary, width: 2),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      style: theme.bodyMedium.copyWith(
                        fontSize: 14,
                        color: theme.primaryText,
                      ),
                      onChanged: (_) => EasyDebounce.debounce(
                        '_model.textFieldTextController',
                        const Duration(milliseconds: 500),
                        () async {
                          _model.reportDescription =
                              _model.textFieldTextController!.text;
                          safeSetState(() {});
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Photos Section
                  _ReportSection(
                    title: 'إضافة صور من المكان',
                    actionLabel: 'اختياري (${_pickedPhotos.length}/3)',
                    theme: theme,
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (var i = 0; i < _pickedPhotos.length; i++)
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              color: theme.surfaceVariant,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: theme.primary),
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.image_rounded,
                                            color: theme.primary, size: 28),
                                        const SizedBox(height: 4),
                                        Text(
                                          'صورة ${i + 1}',
                                          style: theme.bodySmall.copyWith(
                                            fontSize: 11,
                                            color: theme.primaryText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 2,
                                  left: 2,
                                  child: IconButton(
                                    tooltip: 'حذف الصورة ${i + 1}',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 36,
                                      minHeight: 36,
                                    ),
                                    onPressed: () => setState(
                                        () => _pickedPhotos.removeAt(i)),
                                    icon: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        color: theme.error,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close_rounded,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (_pickedPhotos.length < 3) ...[
                          _PhotoSlot(
                            label: 'الكاميرا',
                            onTap: () => _pickPhoto(ImageSource.camera),
                            theme: theme,
                          ),
                          _AddPhotoSlot(
                            onTap: () => _showPhotoPickerSheet(context),
                            theme: theme,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Confirmation Checkbox
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.primary.withValues(alpha: 0.08),
                      borderRadius:
                          BorderRadius.circular(theme.designToken.radius.xl),
                      border: Border.all(
                        color: theme.primary.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: CheckboxWidget(
                      label:
                          'أؤكد أن هذا العائق موجود فعلاً داخل المكان المختار وبناءً على زيارتي الشخصية',
                      subtitle:
                          'تُراجع البلاغات من فريق ONEWAY وتُبلّغ إدارة المكان لمعالجتها',
                      color: theme.primary,
                      isChecked: _confirmed,
                      hasSubtitle: true,
                      disabled: false,
                      onChanged: (val) {
                        setState(() => _confirmed = val);
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Column(
                    children: [
                      ButtonWidget(
                        key: const Key('submit_place_report_btn'),
                        content:
                            _submitting ? 'جاري الإرسال...' : 'إرسال البلاغ',
                        variant: 'primary',
                        size: 'large',
                        fullWidth: true,
                        icon: Icon(
                          Icons.check_circle_rounded,
                          color: theme.onPrimary,
                          size: 24,
                        ),
                        iconPresent: true,
                        onPressed: _submitting ? null : _submitReport,
                      ),
                      const SizedBox(height: 12),
                      ButtonWidget(
                        content: 'إلغاء',
                        variant: 'ghost',
                        size: 'medium',
                        fullWidth: true,
                        onPressed: () =>
                            context.goNamed(HomeDashboardWidget.routeName),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExistingPlacePicker(FlutterFlowTheme theme) {
    if (_loadingPlaces) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_availablePlaces.isEmpty) {
      return Container(
        key: const Key('report_no_registered_places_card'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.outlineVariant),
        ),
        child: Column(
          children: [
            Icon(Icons.store_mall_directory_outlined,
                color: theme.secondaryText, size: 36),
            const SizedBox(height: 8),
            Text(
              'لا توجد أماكن مسجّلة حالياً للإبلاغ عنها',
              textAlign: TextAlign.center,
              style: theme.titleSmall.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.primaryText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'التبليغ عن العوائق مخصص فقط للأماكن المسجّلة على ONEWAY (ولا يشمل الشوارع أو الطرق العامة).',
              textAlign: TextAlign.center,
              style: theme.bodySmall.copyWith(
                color: theme.secondaryText,
                height: 1.45,
              ),
            ),
          ],
        ),
      );
    }

    final matches = _filteredPlaces;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('report_place_search_field'),
          controller: _placeSearchController,
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: InputDecoration(
            labelText: 'ابحث عن المكان المسجّل بالاسم أو المنطقة',
            hintText: 'مثال: مول مصر، مستشفى دار الفؤاد...',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    tooltip: 'مسح البحث',
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      _placeSearchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (matches.isEmpty)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'لا يوجد مكان مسجّل بهذا الاسم. يرجى البحث عن مكان مسجّل داخل التطبيق.',
              textAlign: TextAlign.center,
              style: theme.bodySmall.copyWith(color: theme.secondaryText),
            ),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240),
            child: Material(
              color: theme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.outlineVariant),
              ),
              clipBehavior: Clip.antiAlias,
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: matches.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: theme.divider),
                itemBuilder: (context, index) {
                  final item = matches[index];
                  return ListTile(
                    key: Key('report_place_option_${item.reference.id}'),
                    leading: CircleAvatar(
                      backgroundColor: theme.primary.withValues(alpha: 0.12),
                      child: Icon(Icons.place_rounded,
                          color: theme.primary, size: 20),
                    ),
                    title: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      [
                        if (item.category.isNotEmpty) item.category,
                        if (item.city.isNotEmpty) item.city,
                      ].join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.check_circle_outline_rounded),
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      setState(() => _selectedPlace = item);
                    },
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _submitReport() async {
    if (_submitting) return;

    final targetPlace = _selectedPlace;
    if (targetPlace == null || targetPlace.reference.id.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'يرجى اختيار المكان من قائمة الأماكن المسجّلة أولاً — التبليغ متاح للأماكن الموجودة بالتطبيق فقط.',
          ),
        ),
      );
      return;
    }

    if (currentUserUid.isEmpty || currentUserIsAnonymous) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تسجيل الدخول بحساب مفعّل لإرسال البلاغ ومتابعة حالته.'),
        ),
      );
      return;
    }

    final desc = _model.textFieldTextController?.text.trim() ?? '';
    if (desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('اكتب وصف العائق داخل المكان قبل الإرسال.'),
          duration: Duration(milliseconds: 4000),
        ),
      );
      return;
    }
    if (!_confirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تأكيد دقة المعلومات قبل إرسال البلاغ.'),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final hasInternet = await ConnectivityService.instance.checkHasInternet();
      if (!mounted) return;
      if (!hasInternet) {
        setState(() => _submitting = false);
        final retry = await showOfflineUploadRetryDialog(
          context,
          title: 'لا يوجد اتصال بالإنترنت',
          message:
              'لا يمكن إرسال البلاغ بدون اتصال بالإنترنت. تفاصيل البلاغ والصور محفوظة كما هي في الصفحة — تأكد من الشبكة ثم اضغط «إعادة المحاولة».',
        );
        if (retry && mounted) {
          unawaited(_submitReport());
        }
        return;
      }

      final category = _selectedCategory;
      final placeName = targetPlace.name;
      final reportRef =
          FirebaseFirestore.instance.collection('accessibilityReports').doc();

      // Compress on-device and upload optional photos to Storage.
      final uploadedUrls = <String>[];
      if (_pickedPhotos.isNotEmpty && currentUserUid.isNotEmpty) {
        for (var i = 0; i < _pickedPhotos.length; i++) {
          try {
            final rawBytes = await _pickedPhotos[i].readAsBytes();
            final compressed =
                await ImageCompressionService.compressForUpload(rawBytes);
            final storageRef = FirebaseStorage.instance.ref(
                'reports/$currentUserUid/${reportRef.id}/photo_$i.jpg');
            await storageRef
                .putData(
                  compressed,
                  SettableMetadata(contentType: 'image/jpeg'),
                )
                .timeout(const Duration(seconds: 20));
            uploadedUrls.add(
              await storageRef.getDownloadURL().timeout(const Duration(seconds: 10)),
            );
          } on TimeoutException {
            rethrow;
          } catch (_) {
            final stillOnline =
                await ConnectivityService.instance.checkHasInternet();
            if (!stillOnline) {
              throw TimeoutException('Connection dropped during report upload');
            }
            // Never fail the report submission if Storage upload is unavailable online.
          }
        }
      }

      // Honest coordinates: user's verified GPS or the place's real coordinates (NEVER fake Cairo fallback!)
      GeoPoint? reportLocation;
      if (_capturedGps != null) {
        reportLocation = _capturedGps!;
      } else if (targetPlace.location != null) {
        reportLocation = GeoPoint(
          targetPlace.location!.latitude,
          targetPlace.location!.longitude,
        );
      }

      await reportRef.set({
        'place_id': targetPlace.reference.id,
        'place_name': placeName,
        if (targetPlace.businessId.trim().isNotEmpty)
          'business_id': targetPlace.businessId.trim(),
        'createdBy': currentUserUid,
        'user_name': currentUserDisplayName.isNotEmpty
            ? currentUserDisplayName
            : (currentUserEmail.isNotEmpty
                ? currentUserEmail
                : 'مستخدم ONEWAY'),
        'problemCategory': category,
        'description': desc,
        'photo_urls': uploadedUrls,
        if (reportLocation != null) 'location': reportLocation,
        'status': 'new',
        'created_at': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 15));

      AnalyticsService.instance.logAccessibilityReportSubmitted(
        placeId: targetPlace.reference.id,
        reportedFeatures: [category],
        hasPhotos: uploadedUrls.isNotEmpty,
      );

      if (currentUserUid.isNotEmpty) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': currentUserUid,
          'title': 'تم استلام بلاغك بنجاح',
          'body':
              'شكراً لمساهمتك! بلاغك عن ($placeName) قيد المراجعة لدى فريق التوثيق.',
          'type': 'report_status',
          'report_id': reportRef.id,
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
    } on TimeoutException {
      if (mounted) {
        setState(() => _submitting = false);
        final retry = await showOfflineUploadRetryDialog(
          context,
          title: 'انقطع الاتصال أثناء إرسال البلاغ',
          message:
              'انقطع الإنترنت أو ضعفت الشبكة أثناء رفع البلاغ. تفاصيلك وصورك محفوظة كما هي — تأكد من الاتصال ثم اضغط «إعادة المحاولة».',
        );
        if (retry && mounted) {
          unawaited(_submitReport());
        }
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
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _PlaceHeaderCard extends StatelessWidget {
  const _PlaceHeaderCard({
    required this.place,
    required this.theme,
    this.capturedGps,
    this.canChangePlace = false,
    this.onChangePlace,
  });

  final PlacesRecord? place;
  final GeoPoint? capturedGps;
  final FlutterFlowTheme theme;
  final bool canChangePlace;
  final VoidCallback? onChangePlace;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = (place?.photoUrl ?? '').trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.navy, theme.primaryDark],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(theme.designToken.radius.xxl),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            color: theme.navy.withValues(alpha: 0.2),
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(theme.designToken.radius.lg),
            child: SizedBox(
              width: 58,
              height: 58,
              child: hasPhoto
                  ? CachedNetworkImage(
                      fadeInDuration: const Duration(milliseconds: 200),
                      imageUrl: place!.photoUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _fallbackBadge(),
                    )
                  : _fallbackBadge(),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place?.name ?? 'إبلاغ عن عائق داخل مكان مسجّل',
                  style: theme.titleMedium.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 13,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        place != null
                            ? '${place!.category} • ${place!.city}'
                            : 'اختر المكان المسجّل أدناه لتقديم البلاغ (لا يُقبل الإبلاغ عن الشوارع العامة)',
                        style: theme.bodySmall.copyWith(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (canChangePlace && onChangePlace != null) ...[
            const SizedBox(width: 8),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: 0.16),
              ),
              onPressed: onChangePlace,
              child: const Text('تغيير'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _fallbackBadge() {
    return Container(
      color: Colors.white.withValues(alpha: 0.14),
      child: const Icon(
        Icons.report_problem_rounded,
        color: Colors.white,
        size: 28,
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
            Expanded(
              child: Text(
                title,
                style: theme.titleMedium.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: theme.primaryText,
                ),
              ),
            ),
            if (actionLabel != null) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  actionLabel!,
                  textAlign: TextAlign.end,
                  style: theme.labelMedium.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: theme.tertiaryText,
                  ),
                ),
              ),
            ],
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
    return Semantics(
      button: true,
      label: 'التقاط صورة من $label',
      child: GestureDetector(
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
    return Semantics(
      button: true,
      label: 'إضافة صورة من المعرض',
      child: GestureDetector(
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
    'موقف ذوي الإعاقة غير متاح',
    'معلومة إتاحة غير دقيقة',
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
          showCheckmark: true,
          checkmarkColor: theme.onPrimary,
          onSelected: (_) {
            onChanged([cat]);
          },
          selectedColor: theme.primary,
          backgroundColor: theme.surface,
          side: BorderSide(
            color: selected ? theme.primary : theme.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
          labelStyle: theme.bodyMedium.copyWith(
            color: selected ? theme.onPrimary : theme.primaryText,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        );
      }).toList(),
    );
  }
}
