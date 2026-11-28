import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '/auth/business_registration_service.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/schema/accessibility_reports_record.dart';
import '/backend/schema/businesses_record.dart';
import '/backend/schema/places_record.dart';
import '/core/analytics/analytics_service.dart';
import '/core/constants/app_constants.dart';
import '/features/business/b2b_portal_models.dart';
import '/features/business/b2b_verification_dashboard.dart';
import '/features/discovery/discovery_pages.dart' show PlaceDetailPage;
import '/features/discovery/places_repository.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/l10n/app_strings.dart';
import '/pages/business_registration/business_registration_widget.dart';
import '/widgets/main_photo_picker_card.dart';
import 'business_admin_dashboard_model.dart';
export 'business_admin_dashboard_model.dart';

/// Place Owner Portal (`صاحب مكان`):
/// Allows the Place Owner to view the place they uploaded (pending or approved),
/// inspect linked barrier reports without PERMISSION_DENIED, request field audits,
/// and edit all safe venue details, photos, working hours, and accessibility features.
class BusinessAdminDashboardWidget extends StatefulWidget {
  const BusinessAdminDashboardWidget({super.key});

  static String routeName = 'BusinessAdminDashboard';
  static String routePath = '/business-admin';

  @override
  State<BusinessAdminDashboardWidget> createState() =>
      _BusinessAdminDashboardWidgetState();
}

class _BusinessAdminDashboardWidgetState
    extends State<BusinessAdminDashboardWidget> {
  late BusinessAdminDashboardModel _model;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => BusinessAdminDashboardModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _showEditOwnerPlaceSheet(
    BuildContext context,
    BusinessesRecord business,
    List<PlacesRecord> linkedPlaces,
  ) async {
    final raw = business.snapshotData;
    final linked = linkedPlaces.isNotEmpty ? linkedPlaces.first : null;
    final rawFeatures = (raw['accessibility_features'] is Map)
        ? Map<String, dynamic>.from(raw['accessibility_features'] as Map)
        : (linked?.accessibilityFeatures.toMap() ?? <String, dynamic>{});

    final nameCtrl = TextEditingController(text: business.businessName);
    final phoneCtrl = TextEditingController(text: business.phoneNumber);
    final emailCtrl = TextEditingController(text: business.email);
    final addressCtrl = TextEditingController(
      text: business.address.isNotEmpty
          ? business.address
          : (linked?.address ?? ''),
    );
    final cityCtrl = TextEditingController(
      text: business.city.isNotEmpty ? business.city : (linked?.city ?? 'القاهرة'),
    );
    final govCtrl = TextEditingController(
      text: business.governorate.isNotEmpty
          ? business.governorate
          : (linked?.governorate ?? 'القاهرة'),
    );
    final hoursCtrl = TextEditingController(
      text: business.openingHours.isNotEmpty
          ? business.openingHours
          : (linked?.openingHours ?? ''),
    );
    final webCtrl = TextEditingController(
      text: ((raw['website'] as String?) ?? linked?.website ?? ''),
    );
    final descCtrl = TextEditingController(
      text: business.description.isNotEmpty
          ? business.description
          : (linked?.description ?? ''),
    );

    final categories = <String>{
      ...BusinessRegistrationService.businessCategories,
      if (business.category.isNotEmpty) business.category,
    }.toList();
    String selectedCategory =
        business.category.isNotEmpty ? business.category : categories.first;

    String photoUrl = business.photoUrl.isNotEmpty
        ? business.photoUrl
        : (linked?.photoUrl ?? '');
    Uint8List? pickedMainBytes;

    bool wheelchairEntrance =
        (rawFeatures['wheelchairEntrance'] as bool?) ?? true;
    bool ramp = (rawFeatures['ramp'] as bool?) ?? true;
    bool elevator = (rawFeatures['suitableElevator'] as bool?) ?? false;
    bool restroom = (rawFeatures['accessibleRestroom'] as bool?) ?? false;
    bool parking = (rawFeatures['accessibleParking'] as bool?) ?? false;
    bool saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final theme = FlutterFlowTheme.of(ctx);
          return Directionality(
            textDirection: TextDirection.rtl,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'تعديل بيانات مكانك على ONEWAY',
                            style: theme.titleMedium.copyWith(
                              fontWeight: FontWeight.w800,
                              color: theme.primaryText,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(sheetCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    MainPhotoPickerCard(
                      compact: true,
                      title: 'الصورة الرئيسية للمكان',
                      subtitle: 'حدث صورة واجهة أو مدخل مكانك',
                      imageBytes: pickedMainBytes,
                      imageUrl: photoUrl,
                      isUploading: saving,
                      onRemove: () => setSheetState(() {
                        pickedMainBytes = null;
                        photoUrl = '';
                      }),
                      onPickGallery: () async {
                        final bytes =
                            await PlacePhotoUploadHelper.pickImageBytes(
                          source: ImageSource.gallery,
                        );
                        if (bytes != null) {
                          setSheetState(() => pickedMainBytes = bytes);
                        }
                      },
                      onPickCamera: () async {
                        final bytes =
                            await PlacePhotoUploadHelper.pickImageBytes(
                          source: ImageSource.camera,
                        );
                        if (bytes != null) {
                          setSheetState(() => pickedMainBytes = bytes);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'اسم المكان *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'التصنيف',
                        border: OutlineInputBorder(),
                      ),
                      items: categories
                          .map((c) =>
                              DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setSheetState(() => selectedCategory = v);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'رقم التواصل *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: cityCtrl,
                            decoration: const InputDecoration(
                              labelText: 'المدينة / الحي',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: govCtrl,
                            decoration: const InputDecoration(
                              labelText: 'المحافظة',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: addressCtrl,
                      decoration: const InputDecoration(
                        labelText: 'العنوان التفصيلي',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: hoursCtrl,
                      decoration: const InputDecoration(
                        labelText: 'مواعيد العمل',
                        hintText: 'يومياً من 9 صباحاً إلى 11 مساءً',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: webCtrl,
                      decoration: const InputDecoration(
                        labelText: 'الموقع الإلكتروني أو صفحة المكان (اختياري)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'وصف المكان وتفاصيل الوصول',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'تجهيزات الإتاحة في مكانك:',
                      style: theme.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.primaryText,
                      ),
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('مدخل مستوٍ مناسب للكراسي المتحركة'),
                      value: wheelchairEntrance,
                      onChanged: (v) =>
                          setSheetState(() => wheelchairEntrance = v),
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('منحدر مجهز (Ramp)'),
                      value: ramp,
                      onChanged: (v) => setSheetState(() => ramp = v),
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('مصعد مناسب للكراسي المتحركة'),
                      value: elevator,
                      onChanged: (v) => setSheetState(() => elevator = v),
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('دورة مياه مهيأة لذوي الإعاقة'),
                      value: restroom,
                      onChanged: (v) => setSheetState(() => restroom = v),
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('موقف سيارات مخصص قريب من المدخل'),
                      value: parking,
                      onChanged: (v) => setSheetState(() => parking = v),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: saving
                          ? null
                          : () async {
                              if (nameCtrl.text.trim().isEmpty ||
                                  phoneCtrl.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'يرجى إدخال اسم المكان ورقم التواصل.'),
                                  ),
                                );
                                return;
                              }
                              setSheetState(() => saving = true);
                              try {
                                String finalPhoto = photoUrl;
                                if (pickedMainBytes != null &&
                                    currentUserUid.isNotEmpty) {
                                  finalPhoto = await BusinessRegistrationService
                                      .instance
                                      .uploadBusinessMainPhoto(
                                    bytes: pickedMainBytes!,
                                    uid: currentUserUid,
                                  );
                                }

                                final a11yMap = <String, dynamic>{
                                  'wheelchairEntrance': wheelchairEntrance,
                                  'ramp': ramp,
                                  'suitableElevator': elevator,
                                  'accessibleRestroom': restroom,
                                  'accessibleParking': parking,
                                };

                                final ok = await BusinessRegistrationService
                                    .instance
                                    .updateOwnerPlaceAndNotifyAdmin(
                                  businessId: business.reference.id,
                                  businessName: nameCtrl.text.trim(),
                                  category: selectedCategory,
                                  phoneNumber: phoneCtrl.text.trim(),
                                  email: emailCtrl.text.trim(),
                                  description: descCtrl.text.trim(),
                                  address: addressCtrl.text.trim(),
                                  city: cityCtrl.text.trim(),
                                  governorate: govCtrl.text.trim(),
                                  openingHours: hoursCtrl.text.trim(),
                                  website: webCtrl.text.trim(),
                                  photoUrl: finalPhoto,
                                  accessibilityFeatures: a11yMap,
                                  currentStatus: business.status,
                                );

                                // Also sync safe non-verification fields onto the published place if already linked & owner role is active
                                if (ok &&
                                    linked != null &&
                                    currentUserDocument?.role ==
                                        'businessOwner') {
                                  try {
                                    await linked.reference.update({
                                      'name': nameCtrl.text.trim(),
                                      'category': selectedCategory,
                                      'phone_number': phoneCtrl.text.trim(),
                                      'description': descCtrl.text.trim(),
                                      'address': addressCtrl.text.trim(),
                                      'city': cityCtrl.text.trim(),
                                      'governorate': govCtrl.text.trim(),
                                      'opening_hours': hoursCtrl.text.trim(),
                                      'website': webCtrl.text.trim(),
                                      if (finalPhoto.isNotEmpty)
                                        'photo_url': finalPhoto,
                                      'accessibility_features': a11yMap,
                                      'updated_at':
                                          FieldValue.serverTimestamp(),
                                    });
                                    PlacesRepository.instance.invalidateCache();
                                  } catch (_) {}
                                }

                                if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        ok
                                            ? 'تم حفظ تعديلات مكانك بنجاح وإشعار الإدارة ✓'
                                            : 'تعذر حفظ التعديلات حالياً.',
                                      ),
                                      backgroundColor:
                                          ok ? Colors.green : theme.error,
                                    ),
                                  );
                                }
                              } finally {
                                if (sheetCtx.mounted) {
                                  setSheetState(() => saving = false);
                                }
                              }
                            },
                      icon: saving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(
                          saving ? 'جاري الحفظ...' : 'حفظ التعديلات'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _submitFieldAuditRequest(
    BusinessesRecord? business,
    B2bSelfAssessment assessment,
  ) async {
    final uid = currentUserUid;
    if (uid.isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('field_assessment_requests')
          .add({
        'owner_id': uid,
        'business_id': business?.reference.id ?? '',
        'business_name': business?.businessName ?? currentUserDisplayName,
        'status': 'pending',
        'readiness_percent': assessment.readinessPercent,
        'self_assessment': assessment.toFirestoreMap(),
        'created_at': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': uid,
        'title': 'تم استلام طلب التقييم الميداني',
        'body':
            'سيتواصل معك فريق ONEWAY لتنسيق موعد الزيارة الميدانية المستقلة.',
        'type': 'business_assessment',
        'is_read': false,
        'created_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.t(
              context,
              'تم إرسال طلب التقييم الميداني بنجاح. سيتواصل معك فريق ONEWAY قريباً.',
              'Field audit request submitted! Our engineering team will reach out shortly.',
            )),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ??
                S.t(context, 'تعذر إرسال طلب التقييم.',
                    'Could not submit audit request.')),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = currentUserUid;
    return StreamBuilder<QuerySnapshot>(
      stream: BusinessesRecord.collection
          .where('ownerId', isEqualTo: uid)
          .limit(5)
          .snapshots(),
      builder: (context, bizSnap) {
        BusinessesRecord? business;
        if (bizSnap.hasData && bizSnap.data!.docs.isNotEmpty) {
          business = BusinessesRecord.fromSnapshot(bizSnap.data!.docs.first);
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('field_assessment_requests')
              .where('owner_id', isEqualTo: uid)
              .limit(5)
              .snapshots(),
          builder: (context, auditSnap) {
            String? auditStatus;
            if (auditSnap.hasData && auditSnap.data!.docs.isNotEmpty) {
              final data = auditSnap.data!.docs.first.data()
                  as Map<String, dynamic>?;
              auditStatus = data?['status'] as String?;
            }

            // Strictly scoped to this owner's business_id so Firestore rules allow it cleanly (Zero PERMISSION_DENIED!)
            final Stream<QuerySnapshot> ownerReportsStream = business != null
                ? AccessibilityReportsRecord.collection
                    .where('business_id', isEqualTo: business.reference.id)
                    .limit(25)
                    .snapshots()
                : const Stream<QuerySnapshot>.empty();

            return StreamBuilder<QuerySnapshot>(
              stream: ownerReportsStream,
              builder: (context, repSnap) {
                return StreamBuilder<QuerySnapshot>(
                  stream: business != null
                      ? PlacesRecord.collection
                          .where('business_id',
                              isEqualTo: business.reference.id)
                          .limit(20)
                          .snapshots()
                      : const Stream<QuerySnapshot>.empty(),
                  builder: (context, placesSnap) {
                    final placeRecords = placesSnap.hasData
                        ? placesSnap.data!.docs
                            .map(PlacesRecord.fromSnapshot)
                            .toList()
                        : <PlacesRecord>[];

                    final branches = placeRecords
                        .map(
                          (p) => B2bBranchSummary(
                            placeId: p.reference.id,
                            name: p.name,
                            category: p.category,
                            address: p.address,
                            features: p.accessibilityFeatures,
                            isGenuinelyVerified: p.isGenuinelyVerified,
                            effectiveVerificationStatus:
                                p.effectiveVerificationStatus,
                            verificationEvidence: p.verificationEvidence,
                            rating: p.rating,
                            reviewCount: p.reviewCount,
                          ),
                        )
                        .toList();

                    final rawBiz =
                        business?.snapshotData ?? const <String, dynamic>{};
                    final adminFeedback =
                        ((rawBiz['rejection_reason'] as String?)?.trim().isNotEmpty ==
                                true)
                            ? (rawBiz['rejection_reason'] as String)
                            : ((rawBiz['admin_notes'] as String?) ?? '');

                    final snapshot = B2bPortalSnapshot(
                      businessId: business?.reference.id,
                      businessName: business?.businessName ?? '',
                      category: business?.category ?? '',
                      businessStatus: business?.status ?? 'none',
                      subscriptionTier: business?.subscriptionTier ?? 'free',
                      pendingAuditStatus: auditStatus,
                      branches: branches,
                      reportsCount:
                          repSnap.hasData ? repSnap.data!.size : 0,
                      reportsAccessDenied: false,
                    );

                    return B2bVerificationDashboardView(
                      snapshot: snapshot,
                      displayName: currentUserDisplayName,
                      venueAddress: business?.address ?? '',
                      venuePhone: business?.phoneNumber ?? '',
                      venueHours: business?.openingHours ?? '',
                      venueDescription: business?.description ?? '',
                      venuePhotoUrl: business?.photoUrl ?? '',
                      adminFeedback: adminFeedback,
                      hasPendingEdits: business?.hasPendingEdits ?? false,
                      onRegisterBusiness: () =>
                          context.pushNamed(BusinessRegistrationWidget.routeName),
                      onEditPlace: business != null
                          ? () => _showEditOwnerPlaceSheet(
                              context, business!, placeRecords)
                          : null,
                      onRequestFieldAudit: (assessment) =>
                          _submitFieldAuditRequest(business, assessment),
                      onContactSales: (plan) {
                        final theme = FlutterFlowTheme.of(context);
                        showModalBottomSheet<void>(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                          ),
                          builder: (sheetCtx) => SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    S.t(
                                      context,
                                      'التواصل لتفعيل ${plan.titleAr}',
                                      'Contact us for ${plan.titleEn}',
                                    ),
                                    style: theme.titleMedium.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    S.t(
                                      context,
                                      'اختر وسيلة التواصل المباشر مع فريق ONEWAY:',
                                      'Choose how to reach the ONEWAY team directly:',
                                    ),
                                    style: theme.bodySmall.copyWith(
                                      color: theme.secondaryText,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  FilledButton.icon(
                                    onPressed: () {
                                      Navigator.pop(sheetCtx);
                                      AppConstants.launchSupportWhatsApp(
                                        message:
                                            'مرحباً، أرغب في الاستفسار عن تفعيل باقة ${plan.titleAr} لمكاني في تطبيق ONEWAY.',
                                      );
                                    },
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF16A34A),
                                      minimumSize: const Size.fromHeight(48),
                                    ),
                                    icon: const Icon(Icons.chat_rounded),
                                    label: Text(
                                      'واتساب مباشر (${AppConstants.supportWhatsAppNumber})',
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.pop(sheetCtx);
                                      AppConstants.launchSupportEmail(
                                        subject: 'ONEWAY — ${plan.titleAr}',
                                        body:
                                            'مرحباً، أرغب في التواصل بخصوص ${plan.titleAr}.',
                                      );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(48),
                                    ),
                                    icon: const Icon(Icons.email_outlined),
                                    label: Text(
                                      'بريد إلكتروني (${AppConstants.businessEmail})',
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  TextButton.icon(
                                    onPressed: () {
                                      Navigator.pop(sheetCtx);
                                      AppConstants.launchSupportPhoneCall();
                                    },
                                    icon: const Icon(Icons.call_rounded),
                                    label: Text(
                                      'اتصال هاتفي (${AppConstants.supportWhatsAppNumber})',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      onOpenBranch: (summary) {
                        final match = placeRecords.where(
                          (p) => p.reference.id == summary.placeId,
                        );
                        if (match.isNotEmpty) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  PlaceDetailPage(place: match.first),
                            ),
                          );
                        }
                      },
                      onClose: () => context.safePop(),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
