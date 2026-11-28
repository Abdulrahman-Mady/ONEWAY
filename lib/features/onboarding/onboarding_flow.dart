import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/app_state.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/schema/structs/accessibility_features_struct.dart';
import '/backend/schema/users_record.dart';
import '/core/analytics/analytics_service.dart';
import '/core/constants/app_constants.dart';
import '/core/theme/oneway_theme.dart';
import '/core/utils/a11y_utils.dart';
import '/features/accessibility/accessibility_score.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/l10n/app_strings.dart';
import '/widgets/responsive_layout.dart';

/// Supported optional device permissions introduced in Onboarding Step 1.
enum OnboardingPermissionKind { location, microphone, notifications }

/// Status of an optional permission tile during onboarding.
enum OnboardingPermissionState { unknown, granted, denied }

/// Abstraction over platform permission requests so onboarding works safely on
/// Android, iOS, Web, Desktop, and widget tests.
typedef OnboardingPermissionRequester = Future<OnboardingPermissionState>
    Function(OnboardingPermissionKind kind);

/// Opens the 3-step Accessibility & Mobility Personalization modal sheet from
/// Settings or User Profile at any time, saving directly to FFAppState and
/// Firestore (`mobility_type` + `access_needs`).
Future<void> showAccessibilityPreferencesSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _StandalonePersonalizationSheet(),
  );
}

/// Interactive onboarding experience for ONEWAY:
///   Screen 0: Native-style Device Permissions (Location, Microphone, Notifications)
///   Screen 1..3: 3-Step Needs-Based Accessibility Personalization:
///     - Step 1 of 3: طريقة التنقل (Single choice — 5 clear ways without raw %)
///     - Step 2 of 3: احتياجات الوصول (Multi-select — 6 concrete venue features)
///     - Step 3 of 3: ملخص احتياجاتك ومعاينة التقييم الذكي (Summary + Edit + Skip)
class OnewayOnboardingFlow extends StatefulWidget {
  const OnewayOnboardingFlow({
    super.key,
    required this.onFinished,
    this.permissionRequester,
    this.analytics,
  });

  /// Invoked when the user completes or skips onboarding.
  final Future<void> Function(String selectedMobilityValue) onFinished;

  /// Optional test seam for requesting runtime permissions.
  final OnboardingPermissionRequester? permissionRequester;

  /// Optional test seam for analytics.
  final AnalyticsService? analytics;

  @override
  State<OnewayOnboardingFlow> createState() => _OnewayOnboardingFlowState();
}

class _OnewayOnboardingFlowState extends State<OnewayOnboardingFlow> {
  static const int _totalScreens = 4; // 0 = Permissions, 1..3 = 3-Step Personalization

  final PageController _pageController = PageController();
  int _currentScreen = 0;

  // Screen 0: Permission states
  final Map<OnboardingPermissionKind, OnboardingPermissionState> _permStates = {
    OnboardingPermissionKind.location: OnboardingPermissionState.unknown,
    OnboardingPermissionKind.microphone: OnboardingPermissionState.unknown,
    OnboardingPermissionKind.notifications: OnboardingPermissionState.unknown,
  };
  OnboardingPermissionKind? _requestingPerm;
  bool _requestingAllPerms = false;
  bool _userInteractedWithPermissions = false;

  // Personalization Step 1: Mobility Way (Single choice)
  MobilityProfileOption _selectedMobility = MobilityProfileOption.all.first;

  // Personalization Step 2: Concrete Access Needs (Multi-select)
  Set<String> _selectedAccessNeeds =
      MobilityProfileOption.all.first.defaultAccessNeeds.toSet();

  // Personalization Step 3: Live place suitability preview toggles
  bool _previewHasRamp = true;
  bool _previewHasElevator = true;
  bool _previewHasRestroom = true;
  bool _previewHasParking = false;

  bool _completing = false;

  AnalyticsService get _analytics =>
      widget.analytics ?? AnalyticsService.instance;

  @override
  void initState() {
    super.initState();
    _analytics.logOnboardingStarted();
    _syncInitialPermissionStatuses();
  }

  Future<void> _syncInitialPermissionStatuses() async {
    if (widget.permissionRequester != null) return;
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return;
    }
    try {
      final loc = await Permission.locationWhenInUse.status;
      final mic = await Permission.microphone.status;
      final notif = await Permission.notification.status;
      if (!mounted) return;
      setState(() {
        if (loc.isGranted || loc.isLimited) {
          _permStates[OnboardingPermissionKind.location] =
              OnboardingPermissionState.granted;
        }
        if (mic.isGranted || mic.isLimited) {
          _permStates[OnboardingPermissionKind.microphone] =
              OnboardingPermissionState.granted;
        }
        if (notif.isGranted || notif.isLimited) {
          _permStates[OnboardingPermissionKind.notifications] =
              OnboardingPermissionState.granted;
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<OnboardingPermissionState> _defaultRequestPermission(
    OnboardingPermissionKind kind,
  ) async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return OnboardingPermissionState.granted;
    }
    try {
      final Permission permission;
      switch (kind) {
        case OnboardingPermissionKind.location:
          permission = Permission.locationWhenInUse;
        case OnboardingPermissionKind.microphone:
          permission = Permission.microphone;
        case OnboardingPermissionKind.notifications:
          permission = Permission.notification;
      }
      final status = await permission.request();
      return status.isGranted || status.isLimited
          ? OnboardingPermissionState.granted
          : OnboardingPermissionState.denied;
    } catch (_) {
      return OnboardingPermissionState.denied;
    }
  }

  Future<void> _requestPermission(OnboardingPermissionKind kind) async {
    if (_requestingPerm != null || _requestingAllPerms) return;
    _userInteractedWithPermissions = true;
    setState(() => _requestingPerm = kind);
    try {
      final requester = widget.permissionRequester ?? _defaultRequestPermission;
      final result = await requester(kind);
      if (!mounted) return;
      setState(() => _permStates[kind] = result);
      await _analytics.logOnboardingPermissionPrompted(
        permission: kind.name,
        granted: result == OnboardingPermissionState.granted,
      );
    } finally {
      if (mounted) setState(() => _requestingPerm = null);
    }
  }

  Future<void> _requestAllPendingPermissions() async {
    if (_requestingAllPerms || _requestingPerm != null) return;
    _userInteractedWithPermissions = true;
    setState(() => _requestingAllPerms = true);
    try {
      final requester = widget.permissionRequester ?? _defaultRequestPermission;
      for (final kind in OnboardingPermissionKind.values) {
        if (_permStates[kind] == OnboardingPermissionState.granted) continue;
        if (!mounted) return;
        setState(() => _requestingPerm = kind);
        final result = await requester(kind);
        if (!mounted) return;
        setState(() => _permStates[kind] = result);
        await _analytics.logOnboardingPermissionPrompted(
          permission: kind.name,
          granted: result == OnboardingPermissionState.granted,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _requestingPerm = null;
          _requestingAllPerms = false;
        });
      }
    }
  }

  Future<void> _persistAndFinish({
    required bool skipped,
    bool skipCustomization = false,
  }) async {
    if (_completing) return;
    setState(() => _completing = true);
    try {
      final chosenOption = skipCustomization
          ? MobilityProfileOption.all.last // 'general'
          : _selectedMobility;
      final chosenNeeds = skipCustomization
          ? <String>[]
          : _selectedAccessNeeds.take(10).toList();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.kOnboardingSeenKey, true);
      if (chosenOption.firestoreValue.isNotEmpty) {
        await prefs.setString(
          AppConstants.kPendingMobilityTypeKey,
          chosenOption.firestoreValue,
        );
        await FFAppState().setMobilityType(chosenOption.firestoreValue);
        await _analytics.setMobilityType(chosenOption.firestoreValue);
      }
      await prefs.setStringList(
        AppConstants.kPendingAccessNeedsKey,
        chosenNeeds,
      );
      await FFAppState().setAccessNeeds(chosenNeeds);

      if (skipped) {
        await _analytics.logOnboardingSkipped(step: _currentScreen + 1);
      } else {
        await _analytics.logOnboardingCompleted(
          mobilityType: chosenOption.firestoreValue,
        );
      }
      if (mounted) {
        await widget.onFinished(chosenOption.firestoreValue);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  void _goToScreen(int index) {
    final target = index.clamp(0, _totalScreens - 1);
    final duration = A11yUtils.effectiveDuration(
      context,
      const Duration(milliseconds: 280),
    );
    if (duration == Duration.zero) {
      _pageController.jumpToPage(target);
    } else {
      _pageController.animateToPage(
        target,
        duration: duration,
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _handleNext() async {
    // On Screen 0 (Permissions), if the user hasn't interacted with any
    // permission card yet, trigger native OS permission dialogs automatically
    // so nobody accidentally taps "Next" and misses granting permissions!
    if (_currentScreen == 0 &&
        !_userInteractedWithPermissions &&
        _permStates.values.every((s) => s == OnboardingPermissionState.unknown)) {
      await _requestAllPendingPermissions();
      if (!mounted) return;
      _goToScreen(1);
      return;
    }

    if (_currentScreen < _totalScreens - 1) {
      _goToScreen(_currentScreen + 1);
    } else {
      await _persistAndFinish(skipped: false);
    }
  }

  void _handleBack() {
    if (_currentScreen > 0) {
      _goToScreen(_currentScreen - 1);
    }
  }

  void _selectMobilityOption(MobilityProfileOption option) {
    setState(() {
      _selectedMobility = option;
      _selectedAccessNeeds = option.defaultAccessNeeds.toSet();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final hPad = OnewayResponsive.horizontalPadding(context);
    FFAppState? appState;
    try {
      appState = Provider.of<FFAppState>(context, listen: false);
    } catch (_) {
      appState = null;
    }
    final isEn = S.isEn(context);
    final isPermissionsScreen = _currentScreen == 0;
    final personalizationStep = _currentScreen; // 1, 2, or 3

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header: Brand + Language Toggle + Skip
                Padding(
                  padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 6),
                  child: Row(
                    children: [
                      const Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: OnewayBrandLockup(
                            iconSize: 32,
                            fontSize: 18,
                            lightText: false,
                          ),
                        ),
                      ),
                      if (appState != null)
                        Semantics(
                          button: true,
                          label: S.t(context, 'تبديل لغة التطبيق',
                              'Switch app language'),
                          child: TextButton(
                            key: const Key('onboarding_lang_toggle'),
                            style: TextButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: const Size(44, 44),
                            ),
                            onPressed: () {
                              final next = isEn ? 'ar' : 'en';
                              appState!.setLocaleCode(next);
                              _analytics.setPreferredLanguage(next);
                            },
                            child: Text(
                              isEn ? 'عربي' : 'EN',
                              style: theme.labelLarge.copyWith(
                                color: theme.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      Semantics(
                        button: true,
                        label: S.t(
                            context, 'تخطي الإعداد المبدئي', 'Skip onboarding'),
                        child: TextButton(
                          key: const Key('onboarding_skip_btn'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: const Size(44, 44),
                          ),
                          onPressed: _completing
                              ? null
                              : () => _persistAndFinish(
                                    skipped: true,
                                    skipCustomization: _currentScreen >= 1,
                                  ),
                          child: Text(
                            isPermissionsScreen
                                ? S.t(context, 'لاحقاً', 'Later')
                                : S.t(context, 'تخطي التخصيص',
                                    'Skip Personalization'),
                            style: theme.labelLarge.copyWith(
                              color: theme.secondaryText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Step Progress Header
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 6),
                  child: isPermissionsScreen
                      ? Row(
                          children: [
                            Icon(Icons.shield_outlined,
                                size: 16, color: theme.primary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                S.t(
                                  context,
                                  'إعداد أذونات الهاتف الأساسية',
                                  'Essential Phone Permissions Setup',
                                ),
                                style: theme.labelMedium.copyWith(
                                  color: theme.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: List.generate(3, (i) {
                                final active = (i + 1) <= personalizationStep;
                                return Expanded(
                                  child: AnimatedContainer(
                                    duration: A11yUtils.effectiveDuration(
                                      context,
                                      const Duration(milliseconds: 220),
                                    ),
                                    height: 6,
                                    margin: EdgeInsetsDirectional.only(
                                      end: i == 2 ? 0 : 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: active
                                          ? theme.primary
                                          : theme.outlineVariant
                                              .withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              S.t(
                                context,
                                'الخطوة $personalizationStep من 3 — تخصيص سهولة الوصول',
                                'Step $personalizationStep of 3 — Personalize Access',
                              ),
                              style: theme.labelMedium.copyWith(
                                color: theme.secondaryText,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),

                // Pages
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() => _currentScreen = index);
                    },
                    children: [
                      _buildPermissionsScreen(context, theme, hPad),
                      _buildMobilityWayStep(context, theme, hPad),
                      _buildAccessNeedsStep(context, theme, hPad),
                      _buildSummaryAndPreviewStep(context, theme, hPad),
                    ],
                  ),
                ),

                // Bottom Navigation Controls
                Container(
                  padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 16),
                  decoration: BoxDecoration(
                    color: theme.surface,
                    border: Border(top: BorderSide(color: theme.divider)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          if (_currentScreen > 0) ...[
                            SizedBox(
                              height: 52,
                              child: OutlinedButton(
                                key: const Key('onboarding_back_btn'),
                                onPressed: _completing ? null : _handleBack,
                                child: Text(S.t(context, 'السابق', 'Back')),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                key: const Key('onboarding_next_btn'),
                                onPressed: (_completing || _requestingAllPerms)
                                    ? null
                                    : _handleNext,
                                child: (_completing || _requestingAllPerms)
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              _primaryButtonLabel(context),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (_currentScreen <
                                              _totalScreens - 1) ...[
                                            const SizedBox(width: 8),
                                            Icon(
                                              isEn
                                                  ? Icons.arrow_forward_rounded
                                                  : Icons.arrow_back_rounded,
                                              size: 20,
                                            ),
                                          ],
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (isPermissionsScreen &&
                          _permStates.values.any(
                              (s) => s == OnboardingPermissionState.unknown)) ...[
                        const SizedBox(height: 4),
                        TextButton(
                          key: const Key('onboarding_skip_permissions_btn'),
                          onPressed: _completing ? null : () => _goToScreen(1),
                          child: Text(
                            S.t(
                              context,
                              'المتابعة الآن وتفعيل الأذونات لاحقاً من الهاتف',
                              'Continue now and enable permissions later',
                            ),
                            style: theme.bodySmall.copyWith(
                              color: theme.secondaryText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _primaryButtonLabel(BuildContext context) {
    if (_currentScreen == 0) {
      final allHandled = _permStates.values
          .every((s) => s != OnboardingPermissionState.unknown);
      return allHandled || _userInteractedWithPermissions
          ? S.t(context, 'التالي', 'Next')
          : S.t(context, 'تفعيل أذونات الهاتف والمتابعة',
              'Enable Permissions & Continue');
    }
    if (_currentScreen == _totalScreens - 1) {
      return S.t(context, 'اعتماد التفضيلات والبدء', 'Save & Start Exploring');
    }
    return S.t(context, 'التالي', 'Next');
  }

  // =========================================================================
  // SCREEN 0: PROFESSIONAL NATIVE-STYLE PHONE PERMISSIONS
  // =========================================================================
  Widget _buildPermissionsScreen(
    BuildContext context,
    FlutterFlowTheme theme,
    double hPad,
  ) {
    final grantedCount = _permStates.values
        .where((s) => s == OnboardingPermissionState.granted)
        .length;

    return SingleChildScrollView(
      key: const Key('onboarding_step_permissions'),
      padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Native Phone System Dialog Hero Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: theme.primary.withValues(alpha: 0.28),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.navy.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [theme.navy, theme.primary],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.phonelink_lock_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  S.t(
                    context,
                    'اسمح لـ ONEWAY بتشغيل ميزات الهاتف الأساسية',
                    'Allow ONEWAY to Access Essential Phone Features',
                  ),
                  textAlign: TextAlign.center,
                  style: theme.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: theme.primaryText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  S.t(
                    context,
                    'ستظهر لك نوافذ الإذن الرسمية الخاصة بهاتفك الآن لتشغيل تحديد أقرب الأماكن، التحكم الصوتي الكامل، وتنبيهات البلاغات.',
                    'Your phone\'s native permission prompts will appear to enable nearby accessible venues, full voice control, and status alerts.',
                  ),
                  textAlign: TextAlign.center,
                  style: theme.bodySmall.copyWith(
                    color: theme.secondaryText,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    S.t(
                      context,
                      'تم تفعيل $grantedCount من 3 أذونات',
                      '$grantedCount of 3 permissions enabled',
                    ),
                    style: theme.labelSmall.copyWith(
                      color: theme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _NativePermissionSheetTile(
            key: const Key('perm_tile_location'),
            theme: theme,
            icon: Icons.location_on_rounded,
            accentColor: const Color(0xFF0EA5E9),
            title: S.t(context, 'الموقع الجغرافي أثناء استخدام التطبيق',
                'Location While Using App'),
            subtitle: S.t(
              context,
              'لعرض الأماكن المجهزة القريبة منك وإرفاق موقعك الفعلي في استغاثة الطوارئ SOS.',
              'Show nearby accessible places and attach real GPS in SOS.',
            ),
            state: _permStates[OnboardingPermissionKind.location]!,
            loading: _requestingPerm == OnboardingPermissionKind.location,
            onRequest: () =>
                _requestPermission(OnboardingPermissionKind.location),
          ),
          const SizedBox(height: 10),
          _NativePermissionSheetTile(
            key: const Key('perm_tile_microphone'),
            theme: theme,
            icon: Icons.mic_rounded,
            accentColor: theme.primary,
            title: S.t(context, 'الميكروفون والتحكم الصوتي الكامل',
                'Microphone & Voice Control'),
            subtitle: S.t(
              context,
              'لتنفيذ كل مهام التطبيق بالصوت فقط (البحث، البلاغات، اقتراح مكان، والتواصل مع الدعم) دون كتابة.',
              'Operate the entire app hands-free by voice without typing.',
            ),
            state: _permStates[OnboardingPermissionKind.microphone]!,
            loading: _requestingPerm == OnboardingPermissionKind.microphone,
            onRequest: () =>
                _requestPermission(OnboardingPermissionKind.microphone),
          ),
          const SizedBox(height: 10),
          _NativePermissionSheetTile(
            key: const Key('perm_tile_notifications'),
            theme: theme,
            icon: Icons.notifications_active_rounded,
            accentColor: const Color(0xFFF59E0B),
            title: S.t(context, 'إشعارات الهاتف الفورية', 'Push Notifications'),
            subtitle: S.t(
              context,
              'ليصلك إشعار فور اعتماد مكانك أو الرد على بلاغاتك.',
              'Receive instant alerts when your place or report is reviewed.',
            ),
            state: _permStates[OnboardingPermissionKind.notifications]!,
            loading: _requestingPerm == OnboardingPermissionKind.notifications,
            onRequest: () =>
                _requestPermission(OnboardingPermissionKind.notifications),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // PERSONALIZATION STEP 1 OF 3: طريقة التنقل (SINGLE SELECT)
  // =========================================================================
  Widget _buildMobilityWayStep(
    BuildContext context,
    FlutterFlowTheme theme,
    double hPad,
  ) {
    return SingleChildScrollView(
      key: const Key('onboarding_step_mobility'),
      padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            S.t(
              context,
              'خلّي الأماكن المناسبة ليك تظهر أولاً',
              'See Suitable Places First',
            ),
            style: theme.headlineSmall.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            S.t(
              context,
              'اختار طريقة تنقلك عادةً عشان نخصص لك نتائج البحث وتقييمات سهولة الوصول بدون أي تصنيفات معقدة.',
              'Choose how you usually get around so we tailor search results and venue suitability for you.',
            ),
            style: theme.bodyMedium.copyWith(
              color: theme.secondaryText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            S.t(context, 'إزاي بتتنقل عادةً؟ (اختيار واحد)',
                'How do you usually move around? (Pick one)'),
            style: theme.titleSmall.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.primary,
            ),
          ),
          const SizedBox(height: 10),
          for (final option in MobilityProfileOption.all) ...[
            _MobilityOptionCard(
              key: Key('mobility_option_${option.id}'),
              theme: theme,
              option: option,
              selected: _selectedMobility.id == option.id,
              onTap: () => _selectMobilityOption(option),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  // =========================================================================
  // PERSONALIZATION STEP 2 OF 3: احتياجات الوصول (MULTI-SELECT)
  // =========================================================================
  Widget _buildAccessNeedsStep(
    BuildContext context,
    FlutterFlowTheme theme,
    double hPad,
  ) {
    return SingleChildScrollView(
      key: const Key('onboarding_step_access_needs'),
      padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            S.t(
              context,
              'إيه اللي يهمك فعلياً في المكان؟',
              'What Matters Most at a Venue?',
            ),
            style: theme.headlineSmall.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            S.t(
              context,
              'بدل التصنيفات العامة، اختار التجهيزات اللي بتحتاجها قبل ما تزور أي مكان (تقدر تختار أكتر من احتياج):',
              'Select all architectural features you need before visiting a place:',
            ),
            style: theme.bodyMedium.copyWith(
              color: theme.secondaryText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          for (final need in AccessNeedOption.all) ...[
            _AccessNeedCard(
              key: Key('need_option_${need.id}'),
              theme: theme,
              need: need,
              selected: _selectedAccessNeeds.contains(need.id),
              onTap: () {
                setState(() {
                  if (_selectedAccessNeeds.contains(need.id)) {
                    _selectedAccessNeeds.remove(need.id);
                  } else {
                    _selectedAccessNeeds.add(need.id);
                  }
                });
              },
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.tune_rounded, size: 16, color: theme.secondaryText),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  S.t(
                    context,
                    'يمكنك تعديل تفضيلاتك في أي وقت من الإعدادات.',
                    'You can update your preferences anytime in Settings.',
                  ),
                  style: theme.bodySmall.copyWith(color: theme.secondaryText),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // PERSONALIZATION STEP 3 OF 3: ملخص احتياجاتك ومعاينة ذكية (SUMMARY + PREVIEW)
  // =========================================================================
  Widget _buildSummaryAndPreviewStep(
    BuildContext context,
    FlutterFlowTheme theme,
    double hPad,
  ) {
    final previewFeatures = AccessibilityFeaturesStruct(
      wheelchairEntrance: true,
      ramp: _previewHasRamp,
      suitableElevator: _previewHasElevator,
      accessibleRestroom: _previewHasRestroom,
      accessibleParking: _previewHasParking,
      corridorWidth: 'ممرات قياسية واسعة',
    );
    final compat = AccessibilityScorer.evaluateFeatures(
      previewFeatures,
      mobilityType: _selectedMobility.firestoreValue,
      accessNeeds: _selectedAccessNeeds.toList(),
    );
    final selectedNeedObjects = AccessNeedOption.all
        .where((n) => _selectedAccessNeeds.contains(n.id))
        .toList();

    return SingleChildScrollView(
      key: const Key('onboarding_step_guide'),
      padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            S.t(context, 'ملخص تخصيصك الذكي في ONEWAY',
                'Your Smart Access Summary'),
            style: theme.headlineSmall.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 21,
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            S.t(
              context,
              'سيقوم ONEWAY بترتيب الأماكن وتقييم مدى ملاءمتها لك بناءً على بيانات هندسية حقيقية للمكان.',
              'ONEWAY evaluates venue suitability using real physical criteria matched to your needs.',
            ),
            style: theme.bodySmall.copyWith(
              color: theme.secondaryText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),

          // Summary Card with Quick Edit
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.primary.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_selectedMobility.icon,
                        color: theme.primary, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            S.t(context, 'طريقة التنقل المختارة',
                                'Selected Mobility Way'),
                            style: theme.labelSmall
                                .copyWith(color: theme.secondaryText),
                          ),
                          Text(
                            S.t(context, _selectedMobility.titleAr,
                                _selectedMobility.titleEn),
                            style: theme.titleSmall.copyWith(
                              fontWeight: FontWeight.w800,
                              color: theme.primaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _goToScreen(1),
                      child: Text(S.t(context, 'تعديل', 'Edit')),
                    ),
                  ],
                ),
                Divider(height: 20, color: theme.divider),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      S.t(context, 'احتياجات الوصول المحددة:',
                          'Selected Access Needs:'),
                      style: theme.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.primaryText,
                      ),
                    ),
                    TextButton(
                      onPressed: () => _goToScreen(2),
                      child: Text(S.t(context, 'تعديل', 'Edit')),
                    ),
                  ],
                ),
                if (selectedNeedObjects.isEmpty)
                  Text(
                    S.t(context, 'تقييم عام متوازن لجميع التجهيزات',
                        'Balanced general evaluation across all features'),
                    style: theme.bodySmall.copyWith(color: theme.secondaryText),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: selectedNeedObjects
                        .map(
                          (n) => Chip(
                            visualDensity: VisualDensity.compact,
                            avatar: Icon(n.icon, size: 16, color: theme.primary),
                            label: Text(
                              S.t(context, n.titleAr, n.titleEn),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Live Interactive Compatibility Playground
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: compat.color,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          compat.level == AccessibilityLevel.limited
                              ? Icons.priority_high_rounded
                              : Icons.accessible_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              S.t(context, 'معاينة حية لتقييم مكان تجريبي',
                                  'Live Venue Suitability Preview'),
                              style: theme.titleSmall.copyWith(
                                fontWeight: FontWeight.w800,
                                color: theme.primaryText,
                              ),
                            ),
                            Text(
                              S.t(
                                context,
                                'جرّب تشغيل/إيقاف تجهيزات المكان بالأسفل:',
                                'Toggle venue features below to test:',
                              ),
                              style: theme.bodySmall.copyWith(
                                color: theme.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      CompatibilityBadge(result: compat),
                      Text(
                        compat.levelLabel(context),
                        style: theme.labelLarge.copyWith(
                          color: compat.color,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        key: const Key('guide_toggle_ramp'),
                        label: Text(S.t(context, 'منحدر مناسب', 'Ramp')),
                        selected: _previewHasRamp,
                        onSelected: (v) => setState(() => _previewHasRamp = v),
                      ),
                      FilterChip(
                        key: const Key('guide_toggle_elevator'),
                        label: Text(S.t(context, 'مصعد متاح', 'Elevator')),
                        selected: _previewHasElevator,
                        onSelected: (v) =>
                            setState(() => _previewHasElevator = v),
                      ),
                      FilterChip(
                        key: const Key('guide_toggle_restroom'),
                        label: Text(S.t(context, 'حمام مجهز', 'Restroom')),
                        selected: _previewHasRestroom,
                        onSelected: (v) =>
                            setState(() => _previewHasRestroom = v),
                      ),
                      FilterChip(
                        key: const Key('guide_toggle_parking'),
                        label: Text(
                            S.t(context, 'أماكن انتظار مناسبة', 'Parking')),
                        selected: _previewHasParking,
                        onSelected: (v) =>
                            setState(() => _previewHasParking = v),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            S.t(
              context,
              'يمكنك تعديل تفضيلاتك في أي وقت من الإعدادات أو الملف الشخصي.',
              'You can edit your preferences anytime from Settings or Profile.',
            ),
            textAlign: TextAlign.center,
            style: theme.bodySmall.copyWith(color: theme.secondaryText),
          ),
        ],
      ),
    );
  }
}

/// Standalone 3-step Personalization Sheet opened from Settings / Profile.
class _StandalonePersonalizationSheet extends StatefulWidget {
  const _StandalonePersonalizationSheet();

  @override
  State<_StandalonePersonalizationSheet> createState() =>
      _StandalonePersonalizationSheetState();
}

class _StandalonePersonalizationSheetState
    extends State<_StandalonePersonalizationSheet> {
  int _step = 1; // 1..3
  late MobilityProfileOption _selectedMobility;
  late Set<String> _selectedNeeds;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final savedMob = currentUserDocument?.snapshotData['mobility_type']
            as String? ??
        FFAppState().mobilityType;
    _selectedMobility = MobilityProfileOption.resolveOption(savedMob);
    final docNeeds = (currentUserDocument?.snapshotData['access_needs'] as List?)
            ?.map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList() ??
        FFAppState().accessNeeds;
    _selectedNeeds = docNeeds.isNotEmpty
        ? docNeeds.toSet()
        : _selectedMobility.defaultAccessNeeds.toSet();
  }

  Future<void> _savePreferences() async {
    setState(() => _saving = true);
    try {
      final needsList = _selectedNeeds.take(10).toList();
      await FFAppState().setMobilityType(_selectedMobility.firestoreValue);
      await FFAppState().setAccessNeeds(needsList);
      await AnalyticsService.instance
          .setMobilityType(_selectedMobility.firestoreValue);

      if (loggedIn && currentUserUid.isNotEmpty) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUserUid)
              .update({
            'mobility_type': _selectedMobility.firestoreValue,
            'access_needs': needsList,
            'updated_time': FieldValue.serverTimestamp(),
          });
        } catch (_) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUserUid)
              .update({
            'mobility_type': _selectedMobility.firestoreValue,
            'updated_time': FieldValue.serverTimestamp(),
          });
        }
        currentUserDocument = await UsersRecord.getDocumentOnce(
          UsersRecord.collection.doc(currentUserUid),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم تحديث تفضيلات التنقل واحتياجات الوصول بنجاح ✓'),
          backgroundColor: FlutterFlowTheme.of(context).success,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Directionality(
      textDirection: S.isEn(context) ? TextDirection.ltr : TextDirection.rtl,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: BoxDecoration(
          color: theme.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'تخصيص سهولة الوصول (الخطوة $_step من 3)',
                      style: theme.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.primaryText,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: _step == 1
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'إزاي بتتنقل عادةً؟',
                            style: theme.titleSmall.copyWith(
                              fontWeight: FontWeight.w800,
                              color: theme.primary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          for (final opt in MobilityProfileOption.all) ...[
                            _MobilityOptionCard(
                              theme: theme,
                              option: opt,
                              selected: _selectedMobility.id == opt.id,
                              onTap: () => setState(() {
                                _selectedMobility = opt;
                                _selectedNeeds = opt.defaultAccessNeeds.toSet();
                              }),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ],
                      )
                    : _step == 2
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'إيه اللي يهمك في المكان؟ (أكتر من اختيار)',
                                style: theme.titleSmall.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: theme.primary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              for (final need in AccessNeedOption.all) ...[
                                _AccessNeedCard(
                                  theme: theme,
                                  need: need,
                                  selected: _selectedNeeds.contains(need.id),
                                  onTap: () => setState(() {
                                    if (_selectedNeeds.contains(need.id)) {
                                      _selectedNeeds.remove(need.id);
                                    } else {
                                      _selectedNeeds.add(need.id);
                                    }
                                  }),
                                ),
                                const SizedBox(height: 10),
                              ],
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'ملخص احتياجاتك المختارة:',
                                style: theme.titleSmall.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: theme.primaryText,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ListTile(
                                tileColor: theme.surface,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: theme.outlineVariant),
                                ),
                                leading: Icon(_selectedMobility.icon,
                                    color: theme.primary),
                                title: Text(_selectedMobility.titleAr),
                                subtitle: Text(_selectedMobility.subtitleAr),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: AccessNeedOption.all
                                    .where((n) => _selectedNeeds.contains(n.id))
                                    .map(
                                      (n) => Chip(
                                        avatar: Icon(n.icon,
                                            size: 16, color: theme.primary),
                                        label: Text(n.titleAr),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Row(
                children: [
                  if (_step > 1) ...[
                    OutlinedButton(
                      onPressed:
                          _saving ? null : () => setState(() => _step--),
                      child: const Text('السابق'),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving
                          ? null
                          : () {
                              if (_step < 3) {
                                setState(() => _step++);
                              } else {
                                _savePreferences();
                              }
                            },
                      child: _saving
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(_step < 3 ? 'التالي' : 'حفظ التفضيلات'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NativePermissionSheetTile extends StatelessWidget {
  const _NativePermissionSheetTile({
    super.key,
    required this.theme,
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.state,
    required this.loading,
    required this.onRequest,
  });

  final FlutterFlowTheme theme;
  final IconData icon;
  final Color accentColor;
  final String title;
  final String subtitle;
  final OnboardingPermissionState state;
  final bool loading;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final granted = state == OnboardingPermissionState.granted;
    final denied = state == OnboardingPermissionState.denied;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: granted
              ? theme.success.withValues(alpha: 0.65)
              : theme.outlineVariant,
          width: granted ? 1.8 : 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: (granted ? theme.success : accentColor)
                      .withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  granted ? Icons.check_circle_rounded : icon,
                  color: granted ? theme.success : accentColor,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.bodySmall.copyWith(
                        color: theme.secondaryText,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: granted
                ? Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded,
                            size: 16, color: theme.success),
                        const SizedBox(width: 6),
                        Text(
                          S.t(context, 'مسموح من الهاتف ✓', 'Allowed ✓'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: theme.success,
                          ),
                        ),
                      ],
                    ),
                  )
                : OutlinedButton(
                    onPressed: loading ? null : onRequest,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(136, 44),
                      foregroundColor: theme.primary,
                      side: BorderSide(color: theme.primary, width: 1.4),
                    ),
                    child: loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            denied
                                ? S.t(context, 'إعادة طلب الإذن', 'Request Again')
                                : S.t(context, 'السماح من الهاتف', 'Allow Access'),
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MobilityOptionCard extends StatelessWidget {
  const _MobilityOptionCard({
    super.key,
    required this.theme,
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final FlutterFlowTheme theme;
  final MobilityProfileOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: S.t(context, option.titleAr, option.titleEn),
      child: Material(
        color: selected
            ? theme.primary.withValues(alpha: 0.08)
            : theme.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(minHeight: 68),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? theme.primary : theme.outlineVariant,
                width: selected ? 2.0 : 1.1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: selected
                        ? theme.primary
                        : theme.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    option.icon,
                    color: selected ? Colors.white : theme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        S.t(context, option.titleAr, option.titleEn),
                        style: theme.titleSmall.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.primaryText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        S.t(context, option.subtitleAr, option.subtitleEn),
                        style: theme.bodySmall.copyWith(
                          color: theme.secondaryText,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_off_rounded,
                  color: selected ? theme.primary : theme.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccessNeedCard extends StatelessWidget {
  const _AccessNeedCard({
    super.key,
    required this.theme,
    required this.need,
    required this.selected,
    required this.onTap,
  });

  final FlutterFlowTheme theme;
  final AccessNeedOption need;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: S.t(context, need.titleAr, need.titleEn),
      child: Material(
        color: selected
            ? theme.primary.withValues(alpha: 0.08)
            : theme.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? theme.primary : theme.outlineVariant,
                width: selected ? 2.0 : 1.1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: selected
                        ? theme.primary
                        : theme.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    need.icon,
                    color: selected ? Colors.white : theme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        S.t(context, need.titleAr, need.titleEn),
                        style: theme.titleSmall.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.primaryText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        S.t(context, need.subtitleAr, need.subtitleEn),
                        style: theme.bodySmall.copyWith(
                          color: theme.secondaryText,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  selected
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded,
                  color: selected ? theme.primary : theme.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
