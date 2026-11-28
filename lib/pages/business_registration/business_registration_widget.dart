import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart' as ll;

import '/auth/firebase_auth/auth_util.dart';
import '/auth/verification_service.dart';
import '/backend/backend.dart';
import '/components/button/button_widget.dart';
import '/core/analytics/analytics_service.dart';
import '/core/constants/app_constants.dart';
import '/core/constants/profile_options.dart';
import '/core/network/connectivity_service.dart';
import '/features/discovery/discovery_pages.dart' show PlaceDetailPage;
import '/features/discovery/place_deduplication_service.dart';
import '/features/emergency/emergency_service.dart';
import '/features/legal/legal_pages.dart';
import '/flutter_flow/flutter_flow_theme.dart' show FlutterFlowTheme;
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/l10n/app_strings.dart';
import '/widgets/google_logo_icon.dart';
import '/widgets/main_photo_picker_card.dart';
import '/widgets/offline_status_banner.dart';

class BusinessRegistrationWidget extends StatefulWidget {
  const BusinessRegistrationWidget({super.key});

  static String routeName = 'BusinessRegistration';
  static String routePath = '/business/register';

  @override
  State<BusinessRegistrationWidget> createState() =>
      _BusinessRegistrationWidgetState();
}

class _BusinessRegistrationWidgetState extends State<BusinessRegistrationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  int _currentStep = 1;
  final PageController _pageController = PageController();
  bool _isLoading = false;

  // Step 1: Venue details + Main Photo
  final _businessNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'مطاعم وكافيهات';
  Uint8List? _mainPhotoBytes;

  // Step 2: Owner info (+ inline account creation/login when not signed in)
  final _ownerNameController = TextEditingController();
  final _ownerPhoneController = TextEditingController();
  final _ownerEmailController = TextEditingController();
  final _ownerPasswordController = TextEditingController();
  final _ownerConfirmPasswordController = TextEditingController();
  bool _ownerPasswordVisible = false;
  bool _ownerConfirmPasswordVisible = false;
  bool _useExistingOwnerAccount = false;
  bool _isSigningInGoogle = false;
  bool _agreedToTerms = true;

  // Accessibility features declared by owner
  bool _hasWheelchairEntrance = true;
  bool _hasRamp = true;
  bool _hasElevator = false;
  bool _hasRestroom = false;
  bool _hasParking = false;

  // Step 3: Location & hours
  String? _selectedGovernorate;
  final _cityController = TextEditingController();
  final _websiteController = TextEditingController();
  final _addressController = TextEditingController();
  final _workingHoursController = TextEditingController();
  GeoPoint? _selectedLocation;
  ll.LatLng _mapPin = const ll.LatLng(30.0444, 31.2357);
  final MapController _mapController = MapController();
  bool _fetchingGps = false;

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

  bool get _hasSignedInRealAccount {
    if (!loggedIn) return false;
    try {
      final fbUser = FirebaseAuth.instance.currentUser;
      if (fbUser != null && fbUser.isAnonymous) return false;
    } catch (_) {
      // In pure widget tests without Firebase initialized, fall back to loggedIn.
    }
    return true;
  }

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
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.15, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    if (_hasSignedInRealAccount) {
      _ownerNameController.text = AuthService.instance.currentUserDisplayName;
      _ownerEmailController.text = AuthService.instance.currentUserEmail;
      _ownerPhoneController.text = AuthService.instance.currentPhoneNumber;
    }

    AnalyticsService.instance.logBusinessRegistrationStarted();
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
    _ownerPasswordController.dispose();
    _ownerConfirmPasswordController.dispose();
    _cityController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _workingHoursController.dispose();
    super.dispose();
  }

  void _goBack() {
    if (_currentStep > 1) {
      _previousStep();
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.goNamed(
        loggedIn ? HomeDashboardWidget.routeName : AuthenticationWidget.routeName,
      );
    }
  }

  Future<void> _nextStep() async {
    if (!_validateCurrentStep()) return;

    if (_currentStep == 2) {
      final ready = await _ensureOwnerAccountAndVerifiedEmail();
      if (!ready || !mounted) return;
    }

    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } else {
      await _submitApplication();
    }
  }

  /// Ensures the Place Owner has an authenticated account AND has confirmed
  /// their email address before proceeding from Step 2 to Step 3.
  Future<bool> _ensureOwnerAccountAndVerifiedEmail() async {
    // In pure widget tests without Firebase initialized, allow advancing cleanly
    bool firebaseReady = true;
    try {
      FirebaseAuth.instance;
    } catch (_) {
      firebaseReady = false;
    }
    if (!firebaseReady) return true;

    safeSetState(() => _isLoading = true);
    try {
      if (!_hasSignedInRealAccount) {
        GoRouter.of(context).prepareAuthEvent();
        final authResult = _useExistingOwnerAccount
            ? await AuthService.instance.signInWithEmail(
                context: context,
                email: _ownerEmailController.text.trim(),
                password: _ownerPasswordController.text,
              )
            : await AuthService.instance.createAccountWithEmail(
                context: context,
                email: _ownerEmailController.text.trim(),
                password: _ownerPasswordController.text,
                displayName: _ownerNameController.text.trim(),
              );

        if (!mounted) return false;
        if (!authResult.success) {
          safeSetState(() => _isLoading = false);
          _showError(authResult.message ?? 'تعذر تسجيل حساب صاحب المكان');
          return false;
        }

        final uid = currentUserUid;
        if (uid.isNotEmpty) {
          final normalizedOwnerPhone =
              _ownerPhoneController.text.trim().isNotEmpty
                  ? ProfileOptions.normalizeEgyptianPhone(
                      _ownerPhoneController.text,
                    )
                  : '';
          try {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .update({
              if (_ownerNameController.text.trim().isNotEmpty)
                'display_name': _ownerNameController.text.trim(),
              if (normalizedOwnerPhone.isNotEmpty)
                'phone_number': normalizedOwnerPhone,
              'updated_time': FieldValue.serverTimestamp(),
            });
            currentUserDocument = await UsersRecord.getDocumentOnce(
              UsersRecord.collection.doc(uid),
            );
          } catch (e) {
            debugPrint('Business owner profile update warning: $e');
          }
        }
      }

      // Check mandatory email confirmation (applies to every registration)
      var confirmed =
          VerificationService.instance.isEmailConfirmed(currentUserDocument);
      if (!confirmed) {
        confirmed = await VerificationService.instance.checkEmailVerified();
      }
      if (!mounted) return false;
      safeSetState(() => _isLoading = false);

      if (confirmed) return true;

      // Send verification email immediately and open live confirmation modal
      final sendRes = await VerificationService.instance.sendEmailVerification();
      if (!mounted) return false;
      final verified = await _showOwnerEmailConfirmationDialog(
        initialStatusMessage: sendRes.message,
      );
      return verified == true;
    } catch (e) {
      if (mounted) {
        safeSetState(() => _isLoading = false);
        _showError('تعذر إتمام تسجيل حساب صاحب المكان: $e');
      }
      return false;
    }
  }

  Future<bool?> _showOwnerEmailConfirmationDialog({
    String? initialStatusMessage,
  }) {
    final email = AuthService.instance.currentUserEmail.isNotEmpty
        ? AuthService.instance.currentUserEmail
        : _ownerEmailController.text.trim();
    return showModalBottomSheet<bool>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _OwnerEmailVerificationSheet(
        email: email,
        initialStatusMessage: initialStatusMessage,
      ),
    );
  }

  void _previousStep() {
    if (_currentStep > 1) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 280),
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
        if (!ProfileOptions.isValidEgyptianPhone(_phoneController.text)) {
          _showError('رقم هاتف مصري غير صالح (مثال: 010xxxxxxxx)');
          return false;
        }
        return true;
      case 2:
        if ((!_useExistingOwnerAccount || _hasSignedInRealAccount) &&
            _ownerNameController.text.trim().length < 2) {
          _showError('اسم المالك مطلوب (حرفين على الأقل)');
          return false;
        }
        if ((!_useExistingOwnerAccount || _hasSignedInRealAccount) &&
            !ProfileOptions.isValidEgyptianPhone(_ownerPhoneController.text)) {
          _showError('رقم هاتف المالك غير صالح (مثال: 010xxxxxxxx)');
          return false;
        }
        if (!_hasSignedInRealAccount) {
          if (!ProfileOptions.isValidEmail(_ownerEmailController.text)) {
            _showError('أدخل بريداً إلكترونياً صالحاً لحساب صاحب المنشأة');
            return false;
          }
          if (_ownerPasswordController.text.length < 6) {
            _showError('كلمة المرور يجب أن تكون 6 أحرف على الأقل');
            return false;
          }
          if (!_useExistingOwnerAccount &&
              _ownerPasswordController.text !=
                  _ownerConfirmPasswordController.text) {
            _showError('كلمات المرور غير متطابقة');
            return false;
          }
          if (!_useExistingOwnerAccount && !_agreedToTerms) {
            _showError('يرجى الموافقة على شروط الاستخدام وسياسة الخصوصية للمتابعة');
            return false;
          }
        }
        return true;
      case 3:
        return true;
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

  Future<void> _pickMainPhoto(ImageSource source) async {
    try {
      final bytes = await PlacePhotoUploadHelper.pickImageBytes(source: source);
      if (bytes != null && mounted) {
        safeSetState(() => _mainPhotoBytes = bytes);
      }
    } catch (e) {
      if (mounted) {
        _showError('تعذر اختيار الصورة: $e');
      }
    }
  }

  Future<void> _signInOwnerWithGoogle() async {
    if (_isSigningInGoogle) return;
    safeSetState(() => _isSigningInGoogle = true);
    try {
      GoRouter.of(context).prepareAuthEvent();
      final result = await AuthService.instance.signInWithGoogle(
        context: context,
      );
      if (!mounted) return;
      if (!result.success) {
        _showError(result.message ?? 'تعذر تسجيل الدخول عبر Google');
        return;
      }

      final fbUser = FirebaseAuth.instance.currentUser;
      if (fbUser != null) {
        await maybeCreateUser(fbUser);
      }
      if (!mounted) return;

      safeSetState(() {
        if (_ownerNameController.text.trim().isEmpty) {
          _ownerNameController.text = AuthService.instance.currentUserDisplayName;
        }
        _ownerEmailController.text = AuthService.instance.currentUserEmail;
        if (_ownerPhoneController.text.trim().isEmpty &&
            AuthService.instance.currentPhoneNumber.isNotEmpty) {
          _ownerPhoneController.text = AuthService.instance.currentPhoneNumber;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم ربط حساب Google (${AuthService.instance.currentUserEmail}) بنجاح ✓',
          ),
          backgroundColor: FlutterFlowTheme.of(context).success,
        ),
      );
    } finally {
      if (mounted) safeSetState(() => _isSigningInGoogle = false);
    }
  }

  Future<void> _useCurrentGpsLocation() async {
    safeSetState(() => _fetchingGps = true);
    try {
      final pos = await EmergencyService.determineCurrentPosition();
      if (pos != null && mounted) {
        final next = ll.LatLng(pos.latitude, pos.longitude);
        safeSetState(() {
          _mapPin = next;
          _selectedLocation = GeoPoint(pos.latitude, pos.longitude);
        });
        _mapController.move(next, 15.0);
      } else if (mounted) {
        _showError('تعذر تحديد موقعك. يمكنك الضغط على الخريطة لتحديد الموقع يدوياً.');
      }
    } finally {
      if (mounted) safeSetState(() => _fetchingGps = false);
    }
  }

  Future<void> _submitApplication() async {
    safeSetState(() => _isLoading = true);

    try {
      // Pre-flight internet verification: keep all user inputs & photos intact
      // and avoid hanging forever in Firebase upload / Firestore write queues.
      final hasInternet = await ConnectivityService.instance.checkHasInternet();
      if (!mounted) return;
      if (!hasInternet) {
        safeSetState(() => _isLoading = false);
        final shouldRetry = await showOfflineUploadRetryDialog(
          context,
          title: 'لا يوجد اتصال بالإنترنت',
          message:
              'تعذر إرسال طلب تسجيل المكان لعدم وجود اتصال بالإنترنت. جميع بيانات المكان وصورك محفوظة كما هي ولن تضيع — تأكد من الشبكة واضغط «إعادة المحاولة».',
        );
        if (shouldRetry && mounted) {
          unawaited(_submitApplication());
        }
        return;
      }
      // If the business owner started from the Login screen without signing in,
      // authenticate or create their account seamlessly before submitting.
      if (!_hasSignedInRealAccount) {
        GoRouter.of(context).prepareAuthEvent();
        final authResult = _useExistingOwnerAccount
            ? await AuthService.instance.signInWithEmail(
                context: context,
                email: _ownerEmailController.text.trim(),
                password: _ownerPasswordController.text,
              )
            : await AuthService.instance.createAccountWithEmail(
                context: context,
                email: _ownerEmailController.text.trim(),
                password: _ownerPasswordController.text,
                displayName: _ownerNameController.text.trim(),
              );

        if (!mounted) return;
        if (!authResult.success) {
          safeSetState(() => _isLoading = false);
          _showError(authResult.message ?? 'تعذر تسجيل حساب صاحب المنشأة');
          return;
        }

        final uid = currentUserUid;
        if (uid.isNotEmpty && !_useExistingOwnerAccount) {
          final normalizedOwnerPhone = ProfileOptions.normalizeEgyptianPhone(
            _ownerPhoneController.text,
          );
          try {
            await FirebaseFirestore.instance.collection('users').doc(uid).update({
              'display_name': _ownerNameController.text.trim(),
              'phone_number': normalizedOwnerPhone,
              'updated_time': FieldValue.serverTimestamp(),
            });
            currentUserDocument = await UsersRecord.getDocumentOnce(
              UsersRecord.collection.doc(uid),
            );
          } catch (e) {
            debugPrint('Business owner profile update warning: $e');
          }
          // Send confirmation email automatically to new email-based business owners
          await VerificationService.instance.sendEmailVerification();
        }
      }

      // Enforce mandatory email confirmation before submitting any place request
      var emailConfirmed =
          VerificationService.instance.isEmailConfirmed(currentUserDocument);
      if (!emailConfirmed) {
        emailConfirmed =
            await VerificationService.instance.checkEmailVerified();
      }
      if (!mounted) return;
      if (!emailConfirmed) {
        final sendRes =
            await VerificationService.instance.sendEmailVerification();
        if (!mounted) return;
        safeSetState(() => _isLoading = false);
        final verified = await _showOwnerEmailConfirmationDialog(
          initialStatusMessage: sendRes.message,
        );
        if (!mounted || verified != true) {
          return;
        }
        safeSetState(() => _isLoading = true);
      }

      // Upload main photo if selected
      String? uploadedPhotoUrl;
      if (_mainPhotoBytes != null && currentUserUid.isNotEmpty) {
        try {
          uploadedPhotoUrl =
              await BusinessRegistrationService.instance.uploadBusinessMainPhoto(
            bytes: _mainPhotoBytes!,
            uid: currentUserUid,
          );
        } catch (e) {
          debugPrint('Main business photo upload failed: $e');
          final stillOnline =
              await ConnectivityService.instance.checkHasInternet();
          if (!mounted) return;
          if (!stillOnline) {
            safeSetState(() => _isLoading = false);
            final shouldRetry = await showOfflineUploadRetryDialog(
              context,
              title: 'انقطع الاتصال أثناء رفع الصورة',
              message:
                  'توقف رفع صورة المكان بسبب انقطاع الإنترنت. لم تضِع بياناتك ولا صورتك — أعد الاتصال واضغط «إعادة المحاولة» لإرسال الطلب كاملاً بالصورة.',
            );
            if (shouldRetry && mounted) {
              unawaited(_submitApplication());
            }
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'تعذر رفع الصورة الرئيسية حالياً، سيتم حفظ الطلب ويمكنك تعديلها لاحقاً: $e',
              ),
            ),
          );
        }
      }

      final normalizedBizPhone =
          ProfileOptions.normalizeEgyptianPhone(_phoneController.text);
      final normalizedOwnerPhone = _ownerPhoneController.text.trim().isNotEmpty
          ? ProfileOptions.normalizeEgyptianPhone(_ownerPhoneController.text)
          : AuthService.instance.currentPhoneNumber;
      final resolvedOwnerName = _ownerNameController.text.trim().isNotEmpty
          ? _ownerNameController.text.trim()
          : AuthService.instance.currentUserDisplayName;
      final resolvedOwnerEmail = _ownerEmailController.text.trim().isNotEmpty
          ? _ownerEmailController.text.trim()
          : AuthService.instance.currentUserEmail;

      // 1. Prevent same owner from accidentally submitting the exact same place twice
      final existingOwnBiz =
          await BusinessRegistrationService.instance.getCurrentUserBusiness();
      if (existingOwnBiz != null &&
          existingOwnBiz.businessName.trim().toLowerCase() ==
              _businessNameController.text.trim().toLowerCase()) {
        if (!mounted) return;
        safeSetState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'قمت بتسجيل «${existingOwnBiz.businessName}» مسبقاً! جاري نقلك للوحة صاحب المكان لعرضه وتعديله.',
            ),
            backgroundColor: FlutterFlowTheme.of(context).primary,
          ),
        );
        context.goNamed(BusinessAdminDashboardWidget.routeName);
        return;
      }

      // 2. Smart Duplicate & Ownership Claim Check against published places
      String? claimedPlaceId;
      DuplicatePlaceMatch? duplicateMatch;
      try {
        duplicateMatch =
            await PlaceDeduplicationService.checkDuplicateAgainstPublishedPlaces(
          candidateName: _businessNameController.text.trim(),
          candidateAddress: _addressController.text.trim(),
          candidatePhone: normalizedBizPhone,
          candidateLocation: _selectedLocation,
        );
      } catch (e) {
        debugPrint('Duplicate check skipped safely: $e');
      }

      if (duplicateMatch != null && mounted) {
        final match = duplicateMatch;
        if (match.isOwned) {
          safeSetState(() => _isLoading = false);
          await showDialog<void>(
            context: context,
            builder: (ctx) => Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: const Text('هذا المكان مسجّل بالفعل بواسطة صاحبه'),
                content: Text(
                  'المكان «${match.place.name}» مسجّل وموثّق بالفعل على ONEWAY (${match.reasonAr}).\n\n'
                  'لا يمكن رفع مكان مكرر لنفس المنشأة. إذا كان هذا فرعاً مختلفاً في منطقة أخرى، يرجى توضيح اسم الفرع في اسم المنشأة وتحديد موقعه الدقيق على الخريطة.',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              PlaceDetailPage(place: match.place),
                        ),
                      );
                    },
                    child: const Text('عرض المكان المسجّل'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('حسناً'),
                  ),
                ],
              ),
            ),
          );
          return;
        } else {
          // Place was added earlier via Community Suggestion without an official owner!
          final claimChoice = await showDialog<String>(
            context: context,
            builder: (ctx) => Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: const Text('هذا المكان مضاف مسبقاً بدون مالك رسمي!'),
                content: Text(
                  'وجدنا «${match.place.name}» مضافاً مسبقاً على الخريطة كاقتراح مجتمعي (${match.reasonAr}).\n\n'
                  'بصفتك صاحب المكان الرسمي، يمكنك استلام إدارة نفس المكان وتحديث صوره ومواعيده وتجهيزاته بدلاً من إنشاء نسخة مكررة!',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, 'cancel'),
                    child: const Text('تراجع للمراجعة'),
                  ),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, 'different_branch'),
                    child: const Text('هذا فرع آخر مختلف'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, 'claim'),
                    child: const Text('نعم، استلام إدارة مكاني'),
                  ),
                ],
              ),
            ),
          );
          if (!mounted) return;
          if (claimChoice == null || claimChoice == 'cancel') {
            safeSetState(() => _isLoading = false);
            return;
          }
          if (claimChoice == 'claim') {
            claimedPlaceId = match.place.reference.id;
          }
        }
      }

      final data = BusinessApplicationData(
        businessName: _businessNameController.text.trim(),
        category: _selectedCategory,
        phoneNumber: normalizedBizPhone,
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        governorate: _selectedGovernorate,
        city: _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
        website: _websiteController.text.trim().isEmpty
            ? null
            : _websiteController.text.trim(),
        openingHours: _workingHoursController.text.trim().isEmpty
            ? null
            : _workingHoursController.text.trim(),
        location: _selectedLocation,
        workingHours: _workingHoursController.text.trim().isEmpty
            ? null
            : _parseWorkingHours(_workingHoursController.text.trim()),
        accessibilityFeatures: {
          'wheelchairEntrance': _hasWheelchairEntrance,
          'ramp': _hasRamp,
          'suitableElevator': _hasElevator,
          'accessibleRestroom': _hasRestroom,
          'accessibleParking': _hasParking,
        },
        services: null,
        ownerName: resolvedOwnerName,
        ownerPhone: normalizedOwnerPhone,
        ownerEmail: resolvedOwnerEmail.isEmpty ? null : resolvedOwnerEmail,
        claimedExistingPlaceId: claimedPlaceId,
      );

      final result =
          await BusinessRegistrationService.instance.submitBusinessApplication(
        data: data,
        photoUrl: uploadedPhotoUrl,
      );

      if (!mounted) return;
      safeSetState(() => _isLoading = false);

      if (result.success) {
        AnalyticsService.instance.logBusinessRegistrationCompleted(
          businessType: _selectedCategory,
          isVerified: false,
        );
        context.pushNamed(
          BusinessRegistrationSuccessWidget.routeName,
          queryParameters: {
            if (result.businessId != null) 'businessId': result.businessId!,
            'businessName': _businessNameController.text.trim(),
          },
          extra: {
            'businessId': result.businessId,
            'businessName': _businessNameController.text.trim(),
          },
        );
      } else if (result.isOffline) {
        final shouldRetry = await showOfflineUploadRetryDialog(
          context,
          message: result.message ??
              'انقطع الاتصال بالإنترنت أثناء إرسال الطلب. بياناتك وصورك محفوظة — أعد الاتصال وحاول مرة أخرى.',
        );
        if (shouldRetry && mounted) {
          unawaited(_submitApplication());
        }
      } else {
        _showError(result.message ?? 'فشل تسجيل المنشأة');
      }
    } catch (e) {
      if (mounted) {
        safeSetState(() => _isLoading = false);
        _showError('حدث خطأ أثناء إرسال الطلب: $e');
      }
    }
  }

  Map<String, dynamic> _parseWorkingHours(String text) {
    return {
      'raw': text,
      'note': 'أوقات العمل كما أدخلها المستخدم',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _goBack();
      },
      child: GestureDetector(
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
            child: Column(
              children: [
                _buildHeader(theme),
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
    final isEn = S.isEn(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.navy, theme.navyLight],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: theme.navyDark.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Material(
                    color: Colors.white.withValues(alpha: 0.14),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _goBack,
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(
                          isEn
                              ? Icons.arrow_back_rounded
                              : Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          S.t(
                            context,
                            'تسجيل مكانك في ONEWAY',
                            'Register Your Venue on ONEWAY',
                          ),
                          key: const Key('business_reg_header_title'),
                          style: theme.titleLarge.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_getStepTitle()} ($_currentStep/3) — ${_getStepSubtitle()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.bodySmall.copyWith(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.82),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 3-step visual progress bar
              Row(
                children: List.generate(3, (index) {
                  final step = index + 1;
                  final isActive = step <= _currentStep;
                  return Expanded(
                    child: Container(
                      height: 5,
                      margin: EdgeInsets.only(left: step < 3 ? 6 : 0),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFF2DD4BF)
                            : Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 1:
        return 'معلومات المنشأة';
      case 2:
        return 'بيانات صاحب المكان';
      case 3:
        return 'الموقع والتفاصيل';
      default:
        return '';
    }
  }

  String _getStepSubtitle() {
    switch (_currentStep) {
      case 1:
        return 'الاسم والصورة الرئيسية والتصنيف';
      case 2:
        return 'بيانات التواصل وحساب الإدارة';
      case 3:
        return 'العنوان والموقع على الخريطة';
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
          // Main Venue Photo Picker (no raw URL field!)
          MainPhotoPickerCard(
            key: const Key('business_main_photo_picker'),
            title: 'الصورة الرئيسية للمكان',
            subtitle: 'اختر صورة واضحة لواجهة أو مدخل مكانك من جهازك',
            imageBytes: _mainPhotoBytes,
            onRemove: () => safeSetState(() => _mainPhotoBytes = null),
            onPickGallery: () => _pickMainPhoto(ImageSource.gallery),
            onPickCamera: () => _pickMainPhoto(ImageSource.camera),
          ),
          const SizedBox(height: 18),

          // Business name
          TextFormField(
            key: const Key('business_name_field'),
            controller: _businessNameController,
            textInputAction: TextInputAction.next,
            style:
                theme.bodyLarge.copyWith(fontSize: 16, color: theme.primaryText),
            decoration: InputDecoration(
              labelText: 'اسم المنشأة *',
              hintText: 'مثال: مطعم النيل أو مركز الشفاء الطبي',
              prefixIcon: Icon(Icons.storefront_outlined,
                  color: theme.primary, size: 22),
              filled: true,
              fillColor: theme.surface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              border: _inputBorder(theme),
              enabledBorder: _inputBorder(theme),
              focusedBorder: _focusedInputBorder(theme),
            ),
          ),
          const SizedBox(height: 16),

          // Category
          DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'تصنيف المنشأة *',
              prefixIcon: Icon(Icons.category_outlined,
                  color: theme.primary, size: 22),
              filled: true,
              fillColor: theme.surface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              border: _inputBorder(theme),
              enabledBorder: _inputBorder(theme),
              focusedBorder: _focusedInputBorder(theme),
            ),
            items: _categories
                .map(
                  (cat) => DropdownMenuItem(
                    value: cat,
                    child: Text(
                      cat,
                      style: theme.bodyLarge
                          .copyWith(fontSize: 16, color: theme.primaryText),
                    ),
                  ),
                )
                .toList(),
            onChanged: (val) {
              if (val != null) safeSetState(() => _selectedCategory = val);
            },
          ),
          const SizedBox(height: 16),

          // Phone
          TextFormField(
            key: const Key('business_phone_field'),
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            style:
                theme.bodyLarge.copyWith(fontSize: 16, color: theme.primaryText),
            decoration: InputDecoration(
              labelText: 'رقم هاتف التواصل *',
              hintText: '010xxxxxxxx',
              prefixIcon:
                  Icon(Icons.phone_outlined, color: theme.primary, size: 22),
              filled: true,
              fillColor: theme.surface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
            style:
                theme.bodyLarge.copyWith(fontSize: 16, color: theme.primaryText),
            decoration: InputDecoration(
              labelText: 'البريد الإلكتروني للمنشأة (اختياري)',
              hintText: 'business@example.com',
              prefixIcon:
                  Icon(Icons.email_outlined, color: theme.primary, size: 22),
              filled: true,
              fillColor: theme.surface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
            style:
                theme.bodyLarge.copyWith(fontSize: 16, color: theme.primaryText),
            decoration: InputDecoration(
              labelText: 'وصف المنشأة وتجهيزات الإتاحة (اختياري)',
              hintText: 'اذكر تجهيزات المكان مثل المنحدر، المصعد، أو الحمام المجهز...',
              prefixIcon: Icon(Icons.description_outlined,
                  color: theme.primary, size: 22),
              filled: true,
              fillColor: theme.surface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              border: _inputBorder(theme),
              enabledBorder: _inputBorder(theme),
              focusedBorder: _focusedInputBorder(theme),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'تجهيزات الإتاحة المتوفرة في مكانك:',
            style: theme.titleSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Material(
            color: theme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.outlineVariant),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  dense: true,
                  title: const Text('مدخل مستوٍ مناسب للكراسي المتحركة'),
                  value: _hasWheelchairEntrance,
                  onChanged: (v) =>
                      safeSetState(() => _hasWheelchairEntrance = v),
                ),
                SwitchListTile.adaptive(
                  dense: true,
                  title: const Text('منحدر مجهز (Ramp)'),
                  value: _hasRamp,
                  onChanged: (v) => safeSetState(() => _hasRamp = v),
                ),
                SwitchListTile.adaptive(
                  dense: true,
                  title: const Text('مصعد مناسب للكراسي المتحركة'),
                  value: _hasElevator,
                  onChanged: (v) => safeSetState(() => _hasElevator = v),
                ),
                SwitchListTile.adaptive(
                  dense: true,
                  title: const Text('دورة مياه مهيأة لذوي الإعاقة'),
                  value: _hasRestroom,
                  onChanged: (v) => safeSetState(() => _hasRestroom = v),
                ),
                SwitchListTile.adaptive(
                  dense: true,
                  title: const Text('موقف سيارات مخصص قريب من المدخل'),
                  value: _hasParking,
                  onChanged: (v) => safeSetState(() => _hasParking = v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(FlutterFlowTheme theme) {
    final needsAccount = !_hasSignedInRealAccount;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: (needsAccount ? theme.primary : theme.success)
                .withValues(alpha: 0.07),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
              side: BorderSide(
                color: (needsAccount ? theme.primary : theme.success)
                    .withValues(alpha: 0.28),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    needsAccount
                        ? Icons.info_outline_rounded
                        : Icons.verified_user_rounded,
                    color: needsAccount ? theme.primary : theme.success,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      needsAccount
                          ? 'سجّل الدخول بحساب Google أو البريد الإلكتروني لإدارة منشأتك ومتابعة حالة الطلب.'
                          : 'متصل بحساب (${AuthService.instance.currentUserEmail}) ✓ — تأكد من اسم المالك ورقم الهاتف للتواصل بشأن الطلب.',
                      style: theme.bodySmall.copyWith(
                        fontSize: 13,
                        color: theme.primaryText,
                        fontWeight:
                            needsAccount ? FontWeight.w500 : FontWeight.w700,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (!needsAccount) ...[
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton.icon(
                onPressed: _isSigningInGoogle
                    ? null
                    : () async {
                        GoRouter.of(context).prepareAuthEvent();
                        await AuthService.instance.signOut();
                        if (mounted) {
                          safeSetState(() {
                            _ownerEmailController.clear();
                          });
                        }
                      },
                icon: const Icon(Icons.switch_account_rounded, size: 18),
                label: const Text('استخدام حساب آخر أو التسجيل بـ Google'),
              ),
            ),
          ],

          if (needsAccount) ...[
            const SizedBox(height: 16),
            // Google Sign-In for Place Owner (directly on Step 2!)
            ButtonWidget(
              key: const Key('business_owner_google_signin_btn'),
              content: _isSigningInGoogle
                  ? 'جارٍ الاتصال بحساب Google...'
                  : 'التسجيل / المتابعة بحساب Google',
              variant: 'outline',
              size: 'medium',
              fullWidth: true,
              loading: _isSigningInGoogle,
              icon: const GoogleLogoIcon(size: 22),
              iconPresent: true,
              onPressed: _isSigningInGoogle ? null : _signInOwnerWithGoogle,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Divider(color: theme.outlineVariant)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'أو بالبريد الإلكتروني',
                    style: theme.bodySmall.copyWith(
                      fontSize: 12,
                      color: theme.secondaryText,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: theme.outlineVariant)),
              ],
            ),
            const SizedBox(height: 16),
            // Overflow-safe segmented toggle (prevents horizontal clipping on narrow screens)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.outlineVariant),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(11),
                      onTap: () =>
                          safeSetState(() => _useExistingOwnerAccount = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 10),
                        decoration: BoxDecoration(
                          color: !_useExistingOwnerAccount
                              ? theme.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'إنشاء حساب جديد',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                              color: !_useExistingOwnerAccount
                                  ? Colors.white
                                  : theme.primaryText,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(11),
                      onTap: () =>
                          safeSetState(() => _useExistingOwnerAccount = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 10),
                        decoration: BoxDecoration(
                          color: _useExistingOwnerAccount
                              ? theme.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'لدي حساب بالفعل',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                              color: _useExistingOwnerAccount
                                  ? Colors.white
                                  : theme.primaryText,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          if (!needsAccount || !_useExistingOwnerAccount) ...[
            TextFormField(
              controller: _ownerNameController,
              textInputAction: TextInputAction.next,
              style: theme.bodyLarge
                  .copyWith(fontSize: 16, color: theme.primaryText),
              decoration: InputDecoration(
                labelText: 'اسم المالك *',
                hintText: 'أحمد محمد علي',
                prefixIcon: Icon(Icons.person_outlined,
                    color: theme.primary, size: 22),
                filled: true,
                fillColor: theme.surface,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                border: _inputBorder(theme),
                enabledBorder: _inputBorder(theme),
                focusedBorder: _focusedInputBorder(theme),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ownerPhoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              style: theme.bodyLarge
                  .copyWith(fontSize: 16, color: theme.primaryText),
              decoration: InputDecoration(
                labelText: 'رقم هاتف المالك *',
                hintText: '010xxxxxxxx',
                prefixIcon:
                    Icon(Icons.phone_outlined, color: theme.primary, size: 22),
                filled: true,
                fillColor: theme.surface,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                border: _inputBorder(theme),
                enabledBorder: _inputBorder(theme),
                focusedBorder: _focusedInputBorder(theme),
              ),
            ),
            const SizedBox(height: 16),
          ],

          TextFormField(
            controller: _ownerEmailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction:
                needsAccount ? TextInputAction.next : TextInputAction.done,
            style:
                theme.bodyLarge.copyWith(fontSize: 16, color: theme.primaryText),
            decoration: InputDecoration(
              labelText: needsAccount
                  ? 'البريد الإلكتروني لحسابك *'
                  : 'بريد المالك الإلكتروني (اختياري)',
              hintText: 'owner@example.com',
              prefixIcon:
                  Icon(Icons.email_outlined, color: theme.primary, size: 22),
              filled: true,
              fillColor: theme.surface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              border: _inputBorder(theme),
              enabledBorder: _inputBorder(theme),
              focusedBorder: _focusedInputBorder(theme),
            ),
          ),

          if (needsAccount) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _ownerPasswordController,
              obscureText: !_ownerPasswordVisible,
              textInputAction: _useExistingOwnerAccount
                  ? TextInputAction.done
                  : TextInputAction.next,
              style: theme.bodyLarge
                  .copyWith(fontSize: 16, color: theme.primaryText),
              decoration: InputDecoration(
                labelText: 'كلمة المرور *',
                hintText: '••••••••',
                prefixIcon: Icon(Icons.lock_outline_rounded,
                    color: theme.primary, size: 22),
                suffixIcon: IconButton(
                  icon: Icon(
                    _ownerPasswordVisible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: theme.onSurfaceVariant,
                  ),
                  onPressed: () => safeSetState(
                      () => _ownerPasswordVisible = !_ownerPasswordVisible),
                ),
                filled: true,
                fillColor: theme.surface,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                border: _inputBorder(theme),
                enabledBorder: _inputBorder(theme),
                focusedBorder: _focusedInputBorder(theme),
              ),
            ),
            if (!_useExistingOwnerAccount) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _ownerConfirmPasswordController,
                obscureText: !_ownerConfirmPasswordVisible,
                textInputAction: TextInputAction.done,
                style: theme.bodyLarge
                    .copyWith(fontSize: 16, color: theme.primaryText),
                decoration: InputDecoration(
                  labelText: 'تأكيد كلمة المرور *',
                  hintText: '••••••••',
                  prefixIcon: Icon(Icons.lock_outline_rounded,
                      color: theme.primary, size: 22),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _ownerConfirmPasswordVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: theme.onSurfaceVariant,
                    ),
                    onPressed: () => safeSetState(() =>
                        _ownerConfirmPasswordVisible =
                            !_ownerConfirmPasswordVisible),
                  ),
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
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _agreedToTerms,
                activeColor: theme.primary,
                onChanged: (v) => safeSetState(() => _agreedToTerms = v ?? false),
                title: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('أوافق على ', style: theme.bodySmall),
                    InkWell(
                      onTap: () => context.pushNamed(TermsOfUsePage.routeName),
                      child: Text(
                        'شروط الاستخدام',
                        style: theme.bodySmall.copyWith(
                          color: theme.primary,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    Text(' و ', style: theme.bodySmall),
                    InkWell(
                      onTap: () =>
                          context.pushNamed(PrivacyPolicyPage.routeName),
                      child: Text(
                        'سياسة الخصوصية',
                        style: theme.bodySmall.copyWith(
                          color: theme.primary,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
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
          DropdownButtonFormField<String>(
            initialValue: _selectedGovernorate,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'المحافظة',
              prefixIcon:
                  Icon(Icons.map_outlined, color: theme.primary, size: 22),
              filled: true,
              fillColor: theme.surface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              border: _inputBorder(theme),
              enabledBorder: _inputBorder(theme),
              focusedBorder: _focusedInputBorder(theme),
            ),
            items: ProfileOptions.governorates
                .map(
                  (gov) => DropdownMenuItem(
                    value: gov,
                    child: Text(
                      gov,
                      style: theme.bodyLarge
                          .copyWith(fontSize: 16, color: theme.primaryText),
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) => safeSetState(() => _selectedGovernorate = v),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _cityController,
            textInputAction: TextInputAction.next,
            style:
                theme.bodyLarge.copyWith(fontSize: 16, color: theme.primaryText),
            decoration: InputDecoration(
              labelText: 'المدينة / الحي (اختياري)',
              hintText: 'مثال: مدينة نصر، الدقي، سموحة',
              prefixIcon: Icon(Icons.location_city_outlined,
                  color: theme.primary, size: 22),
              filled: true,
              fillColor: theme.surface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              border: _inputBorder(theme),
              enabledBorder: _inputBorder(theme),
              focusedBorder: _focusedInputBorder(theme),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _addressController,
            maxLines: 2,
            textInputAction: TextInputAction.next,
            style:
                theme.bodyLarge.copyWith(fontSize: 16, color: theme.primaryText),
            decoration: InputDecoration(
              labelText: 'العنوان التفصيلي (اختياري)',
              hintText: 'الشارع، المنطقة، المدينة، المحافظة',
              prefixIcon: Icon(Icons.location_on_outlined,
                  color: theme.primary, size: 22),
              filled: true,
              fillColor: theme.surface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              border: _inputBorder(theme),
              enabledBorder: _inputBorder(theme),
              focusedBorder: _focusedInputBorder(theme),
            ),
          ),
          const SizedBox(height: 16),

          // Interactive OpenStreetMap Pin Picker + GPS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'موقع المنشأة على الخريطة (اضغط لتحديد الدبوس):',
                  style: theme.titleSmall.copyWith(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: theme.primaryText,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _fetchingGps ? null : _useCurrentGpsLocation,
                icon: _fetchingGps
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location_rounded, size: 17),
                label: const Text('موقعي'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              height: 200,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _mapPin,
                  initialZoom: 13.5,
                  onTap: (_, point) {
                    safeSetState(() {
                      _mapPin = point;
                      _selectedLocation =
                          GeoPoint(point.latitude, point.longitude);
                    });
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: AppConstants.mapTileUrlTemplate,
                    userAgentPackageName: AppConstants.mapUserAgentPackage,
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
                ? 'تم تحديد الموقع: ${_selectedLocation!.latitude.toStringAsFixed(5)}, ${_selectedLocation!.longitude.toStringAsFixed(5)}'
                : 'اضغط على الخريطة لتحديد الموقع الدقيق لمنشأتك (اختياري)',
            textAlign: TextAlign.center,
            style: theme.bodySmall.copyWith(
              fontSize: 12,
              color: theme.secondaryText,
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _workingHoursController,
            maxLines: 2,
            textInputAction: TextInputAction.done,
            style:
                theme.bodyLarge.copyWith(fontSize: 16, color: theme.primaryText),
            decoration: InputDecoration(
              labelText: 'ساعات العمل (اختياري)',
              hintText: 'مثال: يومياً من 9 ص إلى 11 م',
              prefixIcon: Icon(Icons.access_time_outlined,
                  color: theme.primary, size: 22),
              filled: true,
              fillColor: theme.surface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              border: _inputBorder(theme),
              enabledBorder: _inputBorder(theme),
              focusedBorder: _focusedInputBorder(theme),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _websiteController,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
            style:
                theme.bodyLarge.copyWith(fontSize: 16, color: theme.primaryText),
            decoration: InputDecoration(
              labelText: 'الموقع الإلكتروني أو صفحة التواصل (اختياري)',
              hintText: 'https://example.com',
              prefixIcon:
                  Icon(Icons.language_rounded, color: theme.primary, size: 22),
              filled: true,
              fillColor: theme.surface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              border: _inputBorder(theme),
              enabledBorder: _inputBorder(theme),
              focusedBorder: _focusedInputBorder(theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(FlutterFlowTheme theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border(
          top: BorderSide(color: theme.outlineVariant, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 16,
            color: theme.shadow.withValues(alpha: 0.08),
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_currentStep > 1) ...[
              Expanded(
                child: ButtonWidget(
                  content: 'السابق',
                  variant: 'outline',
                  size: 'medium',
                  fullWidth: true,
                  onPressed: _isLoading ? null : _previousStep,
                ),
              ),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: ButtonWidget(
                content: _currentStep < 3 ? 'التالي' : 'إرسال الطلب',
                variant: 'primary',
                size: 'medium',
                fullWidth: true,
                loading: _isLoading,
                iconEnd: _currentStep < 3
                    ? const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 20)
                    : const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
                iconEndPresent: true,
                onPressed: _isLoading ? null : _nextStep,
              ),
            ),
          ],
        ),
      ),
    );
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
}

class _OwnerEmailVerificationSheet extends StatefulWidget {
  const _OwnerEmailVerificationSheet({
    required this.email,
    this.initialStatusMessage,
  });

  final String email;
  final String? initialStatusMessage;

  @override
  State<_OwnerEmailVerificationSheet> createState() =>
      _OwnerEmailVerificationSheetState();
}

class _OwnerEmailVerificationSheetState
    extends State<_OwnerEmailVerificationSheet> {
  Timer? _pollTimer;
  bool _checking = false;
  bool _resending = false;
  bool _switchingAccount = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _statusMessage = widget.initialStatusMessage;
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final ok = await VerificationService.instance.checkEmailVerified();
      if (ok && mounted) {
        _pollTimer?.cancel();
        Navigator.of(context).pop(true);
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkNow() async {
    if (_checking) return;
    setState(() => _checking = true);
    final ok = await VerificationService.instance.checkEmailVerified();
    if (!mounted) return;
    setState(() {
      _checking = false;
      if (!ok) {
        _statusMessage =
            'لم يتم الضغط على رابط التفعيل بعد — افتح الرسالة في بريدك (أو مجلد Spam) واضغط على الرابط.';
      }
    });
    if (ok) {
      _pollTimer?.cancel();
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _resend() async {
    if (_resending) return;
    setState(() => _resending = true);
    final res = await VerificationService.instance.sendEmailVerification();
    if (!mounted) return;
    setState(() {
      _resending = false;
      _statusMessage = res.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          24,
          20,
          24,
          24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: theme.outlineVariant,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Icon(
                Icons.mark_email_unread_rounded,
                size: 48,
                color: theme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                'تأكيد البريد الإلكتروني لصاحب المكان',
                textAlign: TextAlign.center,
                style: theme.titleLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'أرسلنا رسالة تأكيد إلى البريد الإلكتروني:\n${widget.email}\nافتح الرسالة واضغط على رابط التفعيل للمتابعة إلى الخطوة الأخيرة ورفع مكانك.',
                textAlign: TextAlign.center,
                style: theme.bodyMedium.copyWith(
                  color: theme.secondaryText,
                  height: 1.55,
                ),
              ),
              if (_statusMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    _statusMessage!,
                    textAlign: TextAlign.center,
                    style: theme.bodySmall.copyWith(
                      color: theme.primaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _checking ? null : _checkNow,
                icon: _checking
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.verified_rounded),
                label: const Text('ضغطت على الرابط في الإيميل — متابعة الآن'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _resending ? null : _resend,
                icon: _resending
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
                label: const Text('إعادة إرسال رسالة التأكيد'),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: _switchingAccount
                    ? null
                    : () async {
                        setState(() => _switchingAccount = true);
                        _pollTimer?.cancel();
                        try {
                          await AuthService.instance.signOut();
                        } catch (_) {}
                        if (context.mounted) {
                          Navigator.of(context).pop(false);
                        }
                      },
                child: Text(
                  _switchingAccount
                      ? 'جاري الرجوع لتعديل الحساب...'
                      : 'تعديل البريد الإلكتروني أو التسجيل بـ Google',
                  style: TextStyle(color: theme.secondaryText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
