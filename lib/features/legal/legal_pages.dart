import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart' as ll;

import '/auth/auth_service.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/core/analytics/analytics_service.dart';
import '/core/constants/app_constants.dart';
import '/core/constants/profile_options.dart';
import '/core/network/connectivity_service.dart';
import '/features/discovery/discovery_pages.dart' show PlaceDetailPage;
import '/features/discovery/place_deduplication_service.dart';
import '/features/discovery/places_repository.dart';
import '/features/emergency/emergency_service.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/widgets/main_photo_picker_card.dart';
import '/widgets/offline_status_banner.dart';

void _safeLegalBack(BuildContext context) {
  if (GoRouter.maybeOf(context) != null) {
    context.safePop();
  } else {
    Navigator.of(context).maybePop();
  }
}

/// Privacy Policy screen — required for Google Play & App Store compliance.
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  static const String routeName = 'PrivacyPolicy';
  static const String routePath = '/privacy';

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return _LegalScaffold(
      title: 'سياسة الخصوصية',
      subtitle: 'آخر تحديث: نوفمبر 2026',
      sections: const [
        _LegalSection(
          heading: '1. البيانات التي نجمعها وموافقتك الصريحة',
          body:
              'نجمع فقط البيانات اللازمة لتشغيل تطبيق ONEWAY وتحسين تجربتك بموافقتك الصريحة وفق قانون حماية البيانات الشخصية المصري رقم 151 لسنة 2020:\n'
              '• بيانات الحساب: الاسم، البريد الإلكتروني، رقم الهاتف، تاريخ الميلاد، المحافظة، وطريقة التنقل واحتياجات الوصول (لتخصيص نسب ملاءمة الأماكن لاحتياجاتك الفعلية).\n'
              '• الموقع الجغرافي: يُستخدم فقط عند طلبك عرض الأماكن القريبة أو مشاركة موقعك في حالات الطوارئ (SOS)، ولا يتم تتبعك في الخلفية.\n'
              '• المساعد الصوتي: يُستخدم الميكروفون فقط عند ضغطك على زر التحدث لتنفيذ أوامرك بالصوت دون الحاجة للكتابة.\n'
              '• الصور: تُرفع فقط عندما تختار إرفاق صورة مع بلاغ عن عائق أو اقتراح مكان أو تسجيل مكانك كصاحب منشأة.',
        ),
        _LegalSection(
          heading: '2. كيف نستخدم بياناتك',
          body:
              '• عرض الأماكن المهيأة القريبة منك وحفظ مفضلاتك وبلاغاتك.\n'
              '• مراجعة بلاغات العوائق وطلبات أصحاب الأماكن واقتراحات المجتمع لتحسين دقة الخريطة للجميع.\n'
              '• إرسال إشعارات حول حالة بلاغاتك أو اعتماد الأماكن المقترحة.\n'
              'نحن لا نبيع بياناتك الشخصية لأي طرف ثالث ولا نستخدمها في إعلانات موجهة.',
        ),
        _LegalSection(
          heading: '3. حفظ البيانات وأمانها',
          body:
              'تُحفظ البيانات عبر خدمات Google Firebase المؤمّنة بتشفير أثناء النقل والتخزين، مع اشتراط تسجيل الدخول وتأكيد البريد الإلكتروني وقواعد صلاحيات صارمة لحماية بياناتك.',
        ),
        _LegalSection(
          heading: '4. حقوقك وحذف الحساب',
          body:
              'يحق لك في أي وقت تعديل بياناتك الشخصية وتفضيلات الوصول من «ملفي الشخصي» أو «الإعدادات»، أو حذف حسابك وبياناتك بالكامل من «الإعدادات ← حذف الحساب والبيانات».',
        ),
        _LegalSection(
          heading: '5. التواصل المباشر مع الدعم',
          body:
              'لأي استفسار بخصوص الخصوصية أو الدعم الفني، تواصل معنا مباشرة:\n'
              '• البريد الإلكتروني: ${AppConstants.supportEmail}\n'
              '• واتساب / هاتف: ${AppConstants.supportWhatsAppNumber}',
        ),
      ],
      showContactActions: true,
      theme: theme,
    );
  }
}

/// Terms of Use screen — required for Google Play & App Store compliance.
class TermsOfUsePage extends StatelessWidget {
  const TermsOfUsePage({super.key});

  static const String routeName = 'TermsOfUse';
  static const String routePath = '/terms';

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return _LegalScaffold(
      title: 'شروط الاستخدام',
      subtitle: 'آخر تحديث: نوفمبر 2026',
      sections: const [
        _LegalSection(
          heading: '1. قبول الشروط وتوثيق الحساب',
          body:
              'باستخدامك لتطبيق ONEWAY (مصر بدون عوائق)، فإنك توافق على هذه الشروط، وتلتزم بإنشاء حساب حقيقي مؤكد بالبريد الإلكتروني والبيانات الشخصية الصحيحة (الدخول كزائر غير متاح حفاظاً على موثوقية المجتمع).',
        ),
        _LegalSection(
          heading: '2. طبيعة المعلومات وإمكانية الوصول',
          body:
              'تعتمد معلومات إتاحة الأماكن (المدخل بدون درجات، المنحدرات، المصاعد، دورات المياه المهيأة، الممرات، والمواقف) على بيانات أصحاب الأماكن ومراجعات فريق ONEWAY ومساهمات المجتمع.',
        ),
        _LegalSection(
          heading: '3. إخلاء مسؤولية الطوارئ (SOS)',
          body:
              'ميزة الطوارئ تساعدك على الاتصال السريع بالأرقام الرسمية في مصر (الإسعاف 123، الشرطة 122، الحماية المدنية 180) ومشاركة موقعك الجغرافي مع مرافقك عبر واتساب أو الرسائل النصية.',
        ),
        _LegalSection(
          heading: '4. محتوى المستخدمين وأصحاب الأماكن',
          body:
              '• يجب أن تكون بيانات الأماكن المقترحة وطلبات أصحاب الأماكن والبلاغات والصور دقيقة وصادقة.\n'
              '• يحتفظ فريق ONEWAY بحق مراجعة أو تعديل أو رفض أو حذف أي طلب أو محتوى مخالف.',
        ),
        _LegalSection(
          heading: '5. التواصل والدعم الفني',
          body:
              'للتواصل المباشر مع إدارة ودعم تطبيق ONEWAY:\n'
              '• البريد الإلكتروني: ${AppConstants.supportEmail}\n'
              '• واتساب: ${AppConstants.supportWhatsAppNumber}',
        ),
      ],
      showContactActions: true,
      theme: theme,
    );
  }
}

/// About ONEWAY screen with direct Email & WhatsApp actions.
class AboutAppPage extends StatelessWidget {
  const AboutAppPage({super.key});

  static const String routeName = 'AboutApp';
  static const String routePath = '/about';

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.navy,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'رجوع',
          onPressed: () => _safeLegalBack(context),
        ),
        title: const Text('حول تطبيق ONEWAY'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.navy, theme.primary],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.accessible_forward_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'ONEWAY',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'مصر بدون عوائق — اعرف المكان قبل ما تروح',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'الإصدار 1.0.0',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _InfoCard(
                theme: theme,
                icon: Icons.flag_rounded,
                title: 'رسالتنا',
                body:
                    'تمكين مستخدمي الكراسي المتحركة، المشي بمساعدة، كبار السن، والأسر في مصر من معرفة مدى جاهزية أي مكان قبل زيارته، مع مساعد صوتي كامل بدون كتابة ونظام استغاثة ذكي.',
              ),
              const SizedBox(height: 14),
              _InfoCard(
                theme: theme,
                icon: Icons.map_outlined,
                title: 'الخرائط والتقييم المبني على الاحتياجات',
                body:
                    'تستخدم الخريطة التفاعلية بيانات OpenStreetMap مع تقييم ذكي مبني على معايير الإتاحة الهندسية الفعلية ومطابقتها مع احتياجات كل مستخدم.',
              ),
              const SizedBox(height: 14),
              _SupportContactButtonsCard(theme: theme),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-detail Community "Suggest a New Place" screen — captures ALL venue
/// fields just like a Place Owner upload (Main & Facility Photos, Category,
/// Governorate, City, Detailed Address, Interactive Map Pin + GPS, Phone,
/// Opening Hours, Website, Description, Amenities, and Full Accessibility
/// Features) so Admin sees complete place data ready for 1-tap approval.
class SuggestPlacePage extends StatefulWidget {
  const SuggestPlacePage({super.key});

  static const String routeName = 'SuggestPlace';
  static const String routePath = '/suggest-place';

  @override
  State<SuggestPlacePage> createState() => _SuggestPlacePageState();
}

class _SuggestPlacePageState extends State<SuggestPlacePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _corridorCtrl = TextEditingController();

  String _governorate = 'القاهرة';
  String _category = 'مطاعم وكافيهات';

  // Photos: Main + Entrance + Elevator + Restroom
  Uint8List? _mainPhotoBytes;
  Uint8List? _entrancePhotoBytes;
  Uint8List? _elevatorPhotoBytes;
  Uint8List? _restroomPhotoBytes;

  // Interactive Map Pin + GPS
  final MapController _mapController = MapController();
  ll.LatLng _mapPin = const ll.LatLng(30.0444, 31.2357);
  GeoPoint? _selectedLocation;
  bool _fetchingGps = false;

  // Full Accessibility Features + Amenities
  bool _hasWheelchairEntrance = true;
  bool _hasRamp = true;
  bool _hasElevator = false;
  bool _hasRestroom = false;
  bool _hasParking = false;
  final Set<String> _selectedAmenities = <String>{};

  bool _submitting = false;

  static const List<String> _categories = [
    'مطاعم وكافيهات',
    'طبي ومستشفيات',
    'تسوق ومراكز تجارية',
    'فنادق وسياحة',
    'تعليم وجامعات',
    'بنوك ومصارف',
    'مكاتب حكومية',
    'أماكن ترفيهية',
    'مواصلات ونقل',
    'مرافق عامة',
    'أخرى',
  ];

  static const List<String> _amenityChoices = [
    'مدخل بدون درجات',
    'منحدر قياسي',
    'مصعد واسع',
    'حمام مجهز',
    'ممرات واسعة',
    'موقف قريب',
    'جلسات مريحة',
    'مساعدة موظفين',
    'واي فاي',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _hoursCtrl.dispose();
    _websiteCtrl.dispose();
    _descCtrl.dispose();
    _corridorCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhotoSlot(
    ImageSource source,
    void Function(Uint8List bytes) assign,
  ) async {
    try {
      final bytes = await PlacePhotoUploadHelper.pickImageBytes(source: source);
      if (bytes != null && mounted) {
        setState(() => assign(bytes));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر اختيار الصورة: $e')),
        );
      }
    }
  }

  Future<void> _useCurrentGps() async {
    setState(() => _fetchingGps = true);
    try {
      final pos = await EmergencyService.determineCurrentPosition();
      if (pos != null && mounted) {
        final pin = ll.LatLng(pos.latitude, pos.longitude);
        setState(() {
          _mapPin = pin;
          _selectedLocation = GeoPoint(pos.latitude, pos.longitude);
        });
        _mapController.move(pin, 15.5);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تعذر تحديد موقعك تلقائياً — اضغط على الخريطة لوضع الدبوس يدوياً.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _fetchingGps = false);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!loggedIn || currentUserUid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تسجيل الدخول بحساب مفعّل لاقتراح مكان جديد.'),
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
              'لا يمكن إرسال اقتراح المكان بدون اتصال بالإنترنت. جميع البيانات والصور التي أدخلتها محفوظة في الصفحة ولن تضيع — تأكد من الشبكة واضغط «إعادة المحاولة».',
        );
        if (retry && mounted) {
          unawaited(_submit());
        }
        return;
      }
      // Smart duplicate check
      DuplicatePlaceMatch? duplicate;
      try {
        duplicate =
            await PlaceDeduplicationService.checkDuplicateAgainstPublishedPlaces(
          candidateName: _nameCtrl.text.trim(),
          candidateGovernorate: _governorate,
          candidateAddress: _addressCtrl.text.trim(),
          candidatePhone: _phoneCtrl.text.trim(),
          candidateLocation: _selectedLocation,
        );
      } catch (_) {}

      if (duplicate != null && mounted) {
        final match = duplicate;
        final proceedAnyway = await showDialog<bool>(
          context: context,
          builder: (ctx) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: Text(
                match.isOwned
                    ? 'هذا المكان مسجّل رسمياً بواسطة صاحبه!'
                    : 'هذا المكان موجود بالفعل على ONEWAY!',
              ),
              content: Text(
                match.isOwned
                    ? 'المكان «${match.place.name}» مرفوع ومُدار رسمياً بواسطة صاحبه على ONEWAY (${match.reasonAr}).'
                    : 'المكان «${match.place.name}» مضاف بالفعل على خريطة ONEWAY (${match.reasonAr}). هل تقصد فرعاً آخر مختلفاً؟',
              ),
              actions: [
                if (!match.isOwned)
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('نعم، هذا فرع آخر مختلف'),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('إلغاء'),
                ),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx, false);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PlaceDetailPage(place: match.place),
                      ),
                    );
                  },
                  icon: const Icon(Icons.place_rounded, size: 18),
                  label: const Text('عرض صفحة المكان'),
                ),
              ],
            ),
          ),
        );
        if (proceedAnyway != true) {
          if (mounted) setState(() => _submitting = false);
          return;
        }
      }

      // Upload selected photos under users/{uid}/businesses/ (permitted by storage.rules)
      String mainPhotoUrl = '';
      String entrancePhotoUrl = '';
      String elevatorPhotoUrl = '';
      String restroomPhotoUrl = '';

      Future<String> uploadIfPresent(Uint8List? bytes, String prefix) async {
        if (bytes == null) return '';
        try {
          return await PlacePhotoUploadHelper.uploadImageBytes(
            bytes: bytes,
            uid: currentUserUid,
            folder: 'businesses',
            prefix: 'suggest_$prefix',
          ).timeout(const Duration(seconds: 20));
        } on TimeoutException {
          rethrow;
        } catch (e) {
          final stillOnline =
              await ConnectivityService.instance.checkHasInternet();
          if (!stillOnline) {
            throw TimeoutException('Connection lost while uploading photo');
          }
          debugPrint('SuggestPlace photo upload ($prefix) skipped: $e');
          return '';
        }
      }

      mainPhotoUrl = await uploadIfPresent(_mainPhotoBytes, 'main');
      entrancePhotoUrl = await uploadIfPresent(_entrancePhotoBytes, 'entrance');
      elevatorPhotoUrl = await uploadIfPresent(_elevatorPhotoBytes, 'elevator');
      restroomPhotoUrl = await uploadIfPresent(_restroomPhotoBytes, 'restroom');

      final allPhotos = <String>[
        if (mainPhotoUrl.isNotEmpty) mainPhotoUrl,
        if (entrancePhotoUrl.isNotEmpty) entrancePhotoUrl,
        if (elevatorPhotoUrl.isNotEmpty) elevatorPhotoUrl,
        if (restroomPhotoUrl.isNotEmpty) restroomPhotoUrl,
      ];

      final a11yFeatures = <String, dynamic>{
        'wheelchairEntrance': _hasWheelchairEntrance,
        'ramp': _hasRamp,
        'suitableElevator': _hasElevator,
        'accessibleRestroom': _hasRestroom,
        'accessibleParking': _hasParking,
        if (_corridorCtrl.text.trim().isNotEmpty)
          'corridorWidth': _corridorCtrl.text.trim(),
      };

      final resolvedLocation = _selectedLocation ??
          GeoPoint(_mapPin.latitude, _mapPin.longitude);

      final coreSubmission = <String, dynamic>{
        'place_name': _nameCtrl.text.trim(),
        'category': _category,
        'governorate': _governorate,
        'address': _addressCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'location': resolvedLocation,
        if (mainPhotoUrl.isNotEmpty) 'photo_url': mainPhotoUrl,
        'accessibility_features': a11yFeatures,
        'submittedBy': currentUserUid,
        'status': 'new',
        'created_at': FieldValue.serverTimestamp(),
      };

      final fullSubmission = <String, dynamic>{
        ...coreSubmission,
        'status': 'pending',
        if (_cityCtrl.text.trim().isNotEmpty) 'city': _cityCtrl.text.trim(),
        if (_phoneCtrl.text.trim().isNotEmpty)
          'phone_number': ProfileOptions.normalizeEgyptianPhone(
            _phoneCtrl.text.trim(),
          ),
        if (_hoursCtrl.text.trim().isNotEmpty)
          'opening_hours': _hoursCtrl.text.trim(),
        if (_websiteCtrl.text.trim().isNotEmpty)
          'website': _websiteCtrl.text.trim(),
        'geo': PlacesRepository.buildGeoField(
          resolvedLocation.latitude,
          resolvedLocation.longitude,
        ),
        if (entrancePhotoUrl.isNotEmpty) 'entrance_photo_url': entrancePhotoUrl,
        if (elevatorPhotoUrl.isNotEmpty) 'elevator_photo_url': elevatorPhotoUrl,
        if (restroomPhotoUrl.isNotEmpty) 'restroom_photo_url': restroomPhotoUrl,
        if (allPhotos.isNotEmpty) 'photos': allPhotos,
        if (_selectedAmenities.isNotEmpty)
          'amenities': _selectedAmenities.take(20).toList(),
        if (AuthService.instance.currentUserDisplayName.isNotEmpty)
          'submitter_name': AuthService.instance.currentUserDisplayName,
        if (AuthService.instance.currentUserEmail.isNotEmpty)
          'submitter_email': AuthService.instance.currentUserEmail,
        if (AuthService.instance.currentPhoneNumber.isNotEmpty)
          'submitter_phone': AuthService.instance.currentPhoneNumber,
        'source': 'community_app',
      };

      DocumentReference<Map<String, dynamic>> createdSubmission;
      try {
        createdSubmission = await FirebaseFirestore.instance
            .collection('placeSubmissions')
            .add(fullSubmission)
            .timeout(const Duration(seconds: 15));
      } on FirebaseException catch (e) {
        if (e.code == 'permission-denied') {
          // Safe fallback if older console rules restrict newly added keys:
          // pack extra metadata cleanly into description so Admin still sees everything!
          final extraLines = <String>[
            if (_descCtrl.text.trim().isNotEmpty) _descCtrl.text.trim(),
            if (_cityCtrl.text.trim().isNotEmpty)
              'المدينة: ${_cityCtrl.text.trim()}',
            if (_phoneCtrl.text.trim().isNotEmpty)
              'هاتف المكان: ${_phoneCtrl.text.trim()}',
            if (_hoursCtrl.text.trim().isNotEmpty)
              'مواعيد العمل: ${_hoursCtrl.text.trim()}',
            if (_websiteCtrl.text.trim().isNotEmpty)
              'الموقع الإلكتروني: ${_websiteCtrl.text.trim()}',
            if (_selectedAmenities.isNotEmpty)
              'التجهيزات الإضافية: ${_selectedAmenities.join("، ")}',
          ];
          createdSubmission = await FirebaseFirestore.instance
              .collection('placeSubmissions')
              .add({
            ...coreSubmission,
            'description': extraLines.join('\n'),
          }).timeout(const Duration(seconds: 15));
        } else {
          rethrow;
        }
      }

      // Notify Admin dashboard about the new community place suggestion
      try {
        await FirebaseFirestore.instance.collection('admin_notifications').add({
          'type': 'new_place_submission',
          'submission_id': createdSubmission.id,
          'business_name': _nameCtrl.text.trim(),
          'title': 'اقتراح مكان جديد من المجتمع',
          'body':
              'اقترح المستخدم إضافة «${_nameCtrl.text.trim()}» ($_category - $_governorate) بكامل بياناته.',
          'is_read': false,
          'created_at': FieldValue.serverTimestamp(),
        });
      } catch (_) {}

      AnalyticsService.instance.logPlaceSuggested(
        category: _category,
        hasAccessibilityInfo: true,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'شكراً لمساهمتك! تم إرسال جميع بيانات وصور المكان المقترح لإدارة ONEWAY للمراجعة والنشر.',
          ),
          backgroundColor: FlutterFlowTheme.of(context).success,
        ),
      );
      _safeLegalBack(context);
    } on TimeoutException {
      if (!mounted) return;
      setState(() => _submitting = false);
      final retry = await showOfflineUploadRetryDialog(
        context,
        title: 'انقطع الاتصال أثناء رفع المكان',
        message:
            'انقطع الإنترنت أو ضعفت الشبكة أثناء رفع بيانات وصور المكان. لم تضِع أي بيانات من الصفحة — تأكد من الاتصال واضغط «إعادة المحاولة».',
      );
      if (retry && mounted) {
        unawaited(_submit());
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر إرسال الاقتراح حالياً: $e'),
          backgroundColor: FlutterFlowTheme.of(context).error,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: theme.background,
        appBar: AppBar(
          backgroundColor: theme.navy,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'رجوع',
            onPressed: () => _safeLegalBack(context),
          ),
          title: const Text('اقتراح مكان جديد بكامل بياناته'),
          centerTitle: true,
          elevation: 0,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.primary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.add_location_alt_rounded,
                            color: theme.primary, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'أضف كل تفاصيل وصور المكان لتسهيل اعتماده فوراً',
                                style: theme.titleSmall.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: theme.primaryText,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'جميع البيانات التي تدخلها (الصور، الموقع على الخريطة، الهاتف، المواعيد، وتجهيزات الإتاحة) تظهر كاملة لدى الإدارة لنشر المكان بدقة.',
                                style: theme.bodySmall.copyWith(
                                  color: theme.secondaryText,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 1. Main Photo + Facility Photos
                  MainPhotoPickerCard(
                    title: 'الصورة الرئيسية للمكان',
                    subtitle: 'التقط أو اختر صورة واضحة لواجهة المكان',
                    imageBytes: _mainPhotoBytes,
                    onRemove: () => setState(() => _mainPhotoBytes = null),
                    onPickGallery: () => _pickPhotoSlot(
                      ImageSource.gallery,
                      (b) => _mainPhotoBytes = b,
                    ),
                    onPickCamera: () => _pickPhotoSlot(
                      ImageSource.camera,
                      (b) => _mainPhotoBytes = b,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'صور تفصيلية لتجهيزات الإتاحة (اختياري):',
                    style: theme.labelLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniFacilityPhotoButton(
                          label: 'المدخل / المنحدر',
                          icon: Icons.accessible_rounded,
                          bytes: _entrancePhotoBytes,
                          theme: theme,
                          onPick: () => _pickPhotoSlot(
                            ImageSource.gallery,
                            (b) => _entrancePhotoBytes = b,
                          ),
                          onClear: () =>
                              setState(() => _entrancePhotoBytes = null),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MiniFacilityPhotoButton(
                          label: 'المصعد',
                          icon: Icons.elevator_rounded,
                          bytes: _elevatorPhotoBytes,
                          theme: theme,
                          onPick: () => _pickPhotoSlot(
                            ImageSource.gallery,
                            (b) => _elevatorPhotoBytes = b,
                          ),
                          onClear: () =>
                              setState(() => _elevatorPhotoBytes = null),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MiniFacilityPhotoButton(
                          label: 'الحمام المجهز',
                          icon: Icons.wc_rounded,
                          bytes: _restroomPhotoBytes,
                          theme: theme,
                          onPick: () => _pickPhotoSlot(
                            ImageSource.gallery,
                            (b) => _restroomPhotoBytes = b,
                          ),
                          onClear: () =>
                              setState(() => _restroomPhotoBytes = null),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // 2. Core Place Details
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'اسم المكان *',
                      hintText: 'مثال: مول سيتي ستارز / مستشفى دار الفؤاد',
                      prefixIcon: Icon(Icons.storefront_rounded),
                    ),
                    validator: (v) => (v == null || v.trim().length < 2)
                        ? 'يرجى إدخال اسم المكان'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'تصنيف المكان *',
                      prefixIcon: Icon(Icons.category_rounded),
                    ),
                    items: _categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _category = v);
                    },
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _governorate,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'المحافظة *',
                            prefixIcon: Icon(Icons.map_outlined),
                          ),
                          items: ProfileOptions.governorates
                              .map((g) =>
                                  DropdownMenuItem(value: g, child: Text(g)))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _governorate = v);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _cityCtrl,
                          decoration: const InputDecoration(
                            labelText: 'المدينة / الحي *',
                            hintText: 'مدينة نصر / الدقي',
                            prefixIcon: Icon(Icons.location_city_rounded),
                          ),
                          validator: (v) => (v == null || v.trim().length < 2)
                              ? 'أدخل المدينة أو الحي'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _addressCtrl,
                    decoration: const InputDecoration(
                      labelText: 'العنوان التفصيلي *',
                      hintText: 'اسم الشارع ورقم المبنى أو أقرب علامة مميزة',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    validator: (v) => (v == null || v.trim().length < 3)
                        ? 'يرجى إدخال العنوان التفصيلي'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'رقم هاتف المكان (إن وجد)',
                            hintText: '010xxxxxxxx أو الخط الساخن',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _hoursCtrl,
                          decoration: const InputDecoration(
                            labelText: 'ساعات العمل',
                            hintText: '9 ص - 11 م',
                            prefixIcon: Icon(Icons.access_time_rounded),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _websiteCtrl,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'الموقع الإلكتروني أو صفحة فيسبوك (اختياري)',
                      hintText: 'https://...',
                      prefixIcon: Icon(Icons.language_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. Interactive Map Pin + GPS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'موقع المكان على الخريطة (اضغط لتحديد الدبوس):',
                          style: theme.titleSmall.copyWith(
                            fontWeight: FontWeight.w800,
                            color: theme.primaryText,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _fetchingGps ? null : _useCurrentGps,
                        icon: _fetchingGps
                            ? const SizedBox.square(
                                dimension: 14,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.my_location_rounded, size: 17),
                        label: const Text('موقعي الحالي'),
                      ),
                    ],
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 190,
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _mapPin,
                          initialZoom: 13.5,
                          onTap: (_, point) {
                            setState(() {
                              _mapPin = point;
                              _selectedLocation =
                                  GeoPoint(point.latitude, point.longitude);
                            });
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: AppConstants.mapTileUrlTemplate,
                            userAgentPackageName:
                                AppConstants.mapUserAgentPackage,
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _mapPin,
                                width: 42,
                                height: 42,
                                child: const Icon(
                                  Icons.location_on_rounded,
                                  color: Color(0xFFE5484D),
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _selectedLocation != null
                        ? 'تم تحديد الإحداثيات: ${_selectedLocation!.latitude.toStringAsFixed(5)}, ${_selectedLocation!.longitude.toStringAsFixed(5)}'
                        : 'الإحداثيات الافتراضية: ${_mapPin.latitude.toStringAsFixed(5)}, ${_mapPin.longitude.toStringAsFixed(5)} (اضغط على الخريطة للتعديل)',
                    textAlign: TextAlign.center,
                    style: theme.bodySmall.copyWith(
                      fontSize: 11.5,
                      color: theme.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4. Full Accessibility Features (same as Owner upload)
                  Text(
                    'تجهيزات الإتاحة المتوفرة في المكان:',
                    style: theme.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Material(
                    color: theme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: theme.divider),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        SwitchListTile.adaptive(
                          value: _hasWheelchairEntrance,
                          onChanged: (v) =>
                              setState(() => _hasWheelchairEntrance = v),
                          title: const Text('مدخل مستوٍ بدون درجات'),
                          secondary: Icon(Icons.meeting_room_outlined,
                              color: theme.primary),
                        ),
                        Divider(height: 1, color: theme.divider),
                        SwitchListTile.adaptive(
                          value: _hasRamp,
                          onChanged: (v) => setState(() => _hasRamp = v),
                          title: const Text('منحدر مجهز (Ramp)'),
                          secondary: Icon(Icons.accessible_rounded,
                              color: theme.primary),
                        ),
                        Divider(height: 1, color: theme.divider),
                        SwitchListTile.adaptive(
                          value: _hasElevator,
                          onChanged: (v) => setState(() => _hasElevator = v),
                          title: const Text('مصعد متاح ومناسب'),
                          secondary: Icon(Icons.elevator_rounded,
                              color: theme.primary),
                        ),
                        Divider(height: 1, color: theme.divider),
                        SwitchListTile.adaptive(
                          value: _hasRestroom,
                          onChanged: (v) => setState(() => _hasRestroom = v),
                          title: const Text('حمام مجهز لذوي الإعاقة'),
                          secondary:
                              Icon(Icons.wc_rounded, color: theme.primary),
                        ),
                        Divider(height: 1, color: theme.divider),
                        SwitchListTile.adaptive(
                          value: _hasParking,
                          onChanged: (v) => setState(() => _hasParking = v),
                          title: const Text('أماكن انتظار سيارات قريبة ومناسبة'),
                          secondary: Icon(Icons.local_parking_rounded,
                              color: theme.primary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _corridorCtrl,
                    decoration: const InputDecoration(
                      labelText: 'عرض الممرات والأبواب (اختياري)',
                      hintText: 'مثال: ممرات واسعة تسمح بمرور الكرسي المتحرك بسهولة',
                      prefixIcon: Icon(Icons.swap_horiz_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'خدمات ومرافق إضافية:',
                    style: theme.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _amenityChoices.map((am) {
                      final selected = _selectedAmenities.contains(am);
                      return FilterChip(
                        selected: selected,
                        label: Text(am),
                        selectedColor: theme.primary,
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: selected ? Colors.white : theme.primaryText,
                        ),
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              _selectedAmenities.add(am);
                            } else {
                              _selectedAmenities.remove(am);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'وصف المكان وملاحظات تجربتك (اختياري)',
                      hintText:
                          'اكتب أي تفاصيل تساعد المستخدمين والإدارة مثل موقع الباب المجهز أو المصعد...',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _submitting ? null : _submit,
                      icon: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded),
                      label: Text(
                        _submitting
                            ? 'جاري رفع الصور وإرسال بيانات المكان...'
                            : 'إرسال بيانات المكان للمراجعة والنشر',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniFacilityPhotoButton extends StatelessWidget {
  const _MiniFacilityPhotoButton({
    required this.label,
    required this.icon,
    required this.bytes,
    required this.theme,
    required this.onPick,
    required this.onClear,
  });

  final String label;
  final IconData icon;
  final Uint8List? bytes;
  final FlutterFlowTheme theme;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 92,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: bytes != null ? theme.primary : theme.outlineVariant,
            width: bytes != null ? 1.8 : 1.1,
          ),
        ),
        child: bytes != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(bytes!, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 2,
                    left: 2,
                    child: InkWell(
                      onTap: onClear,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: theme.primary, size: 22),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.bodySmall.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: theme.primaryText,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _SupportContactButtonsCard extends StatelessWidget {
  const _SupportContactButtonsCard({required this.theme});

  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.support_agent_rounded, color: theme.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'تواصل معنا مباشرة',
                  style: theme.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.primaryText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
            ),
            onPressed: () => AppConstants.launchSupportWhatsApp(),
            icon: const Icon(Icons.chat_rounded, size: 18),
            label: const Text(
              'واتساب مباشر: ${AppConstants.supportWhatsAppNumber}',
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => AppConstants.launchSupportEmail(),
            icon: const Icon(Icons.email_outlined, size: 18),
            label: const Text(
              'إرسال بريد: ${AppConstants.supportEmail}',
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalSection {
  const _LegalSection({required this.heading, required this.body});
  final String heading;
  final String body;
}

class _LegalScaffold extends StatelessWidget {
  const _LegalScaffold({
    required this.title,
    required this.subtitle,
    required this.sections,
    required this.theme,
    this.showContactActions = false,
  });

  final String title;
  final String subtitle;
  final List<_LegalSection> sections;
  final FlutterFlowTheme theme;
  final bool showContactActions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.navy,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'رجوع',
          onPressed: () => _safeLegalBack(context),
        ),
        title: Text(title),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                subtitle,
                style: theme.bodySmall.copyWith(color: theme.secondaryText),
              ),
              const SizedBox(height: 16),
              for (final s in sections) ...[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: theme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.heading,
                        style: theme.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        s.body,
                        style: theme.bodyMedium.copyWith(
                          color: theme.primaryText,
                          height: 1.7,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (showContactActions) ...[
                const SizedBox(height: 4),
                _SupportContactButtonsCard(theme: theme),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.theme,
    required this.icon,
    required this.title,
    required this.body,
  });

  final FlutterFlowTheme theme;
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: theme.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.primaryText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: theme.bodyMedium.copyWith(
              color: theme.secondaryText,
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }
}
