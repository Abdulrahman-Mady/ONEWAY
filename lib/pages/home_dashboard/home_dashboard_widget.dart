import '/auth/firebase_auth/auth_util.dart';
import '/backend/schema/places_record.dart';
import '/features/accessibility/accessibility_score.dart';
import '/features/discovery/discovery_pages.dart' show PlaceDetailPage;
import '/features/discovery/places_repository.dart';
import '/features/guide/egypt_guide_page.dart' show EgyptGuidePage;
import '/features/legal/legal_pages.dart' show SuggestPlacePage;
import '/features/onboarding/home_spotlight_tour.dart';
import '/components/bottom_nav/bottom_nav_widget.dart';
import '/components/bottom_nav_child/bottom_nav_child_widget.dart';
import '/components/category_chip/category_chip_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/l10n/app_strings.dart';
import '/widgets/responsive_layout.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'home_dashboard_model.dart';
export 'home_dashboard_model.dart';

class HomeDashboardWidget extends StatefulWidget {
  const HomeDashboardWidget({super.key});

  static String routeName = 'HomeDashboard';
  static String routePath = '/home';

  @override
  State<HomeDashboardWidget> createState() => _HomeDashboardWidgetState();
}

class _HomeDashboardWidgetState extends State<HomeDashboardWidget>
    with SingleTickerProviderStateMixin {
  late HomeDashboardModel _model;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  // Spotlight Tour target keys pointing to real Home Dashboard buttons
  final GlobalKey _searchBarKey = GlobalKey();
  final GlobalKey _mapActionKey = GlobalKey();
  final GlobalKey _reportActionKey = GlobalKey();
  final GlobalKey _emergencyActionKey = GlobalKey();
  final GlobalKey _bottomNavKey = GlobalKey();

  /// Soft verification reminder: shown when the account is not fully verified.
  bool _showVerificationBanner = false;

  /// First-time / replayed interactive Spotlight Coach-Marks tour.
  bool _showSpotlightTour = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HomeDashboardModel());
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );
    _animationController.forward();
    HomeTourController.instance.replayNonce.addListener(_onReplayTourRequested);
    _checkVerificationStatus();
    _nearbyPlacesFuture = PlacesRepository.instance.getVerifiedPlaces(limit: 10);
  }

  void _onReplayTourRequested() {
    if (!mounted) return;
    if (HomeTourController.instance.consumePendingReplay()) {
      Future<void>.delayed(const Duration(milliseconds: 350), () {
        if (mounted) {
          setState(() => _showSpotlightTour = true);
        }
      });
    }
  }

  Future<void> _maybeLaunchSpotlightTour() async {
    if (!mounted) return;
    final forcedReplay = HomeTourController.instance.consumePendingReplay();
    final uid = currentUserUid;
    final alreadySeen =
        forcedReplay ? false : await HomeTourController.instance.hasSeenTour(uid);
    if (!mounted || alreadySeen) return;

    await Future<void>.delayed(const Duration(milliseconds: 550));
    if (!mounted) return;
    setState(() => _showSpotlightTour = true);
  }

  List<SpotlightTourStep> _buildSpotlightSteps() => [
        SpotlightTourStep(
          id: 'search_voice',
          targetKey: _searchBarKey,
          icon: Icons.mic_rounded,
          highlightRadius: 30,
          titleAr: 'البحث الذكي والمساعد الصوتي',
          titleEn: 'Smart Search & Voice Assistant',
          descriptionAr:
              'ابحث عن أي مكان مهيأ بالاسم أو الفئة، أو اضغط على زر الميكروفون للتحكم في التطبيق بالكامل بالصوت فقط بدون كتابة.',
          descriptionEn:
              'Search any accessible place by name or category, or tap the mic to operate the entire app hands-free by voice.',
        ),
        SpotlightTourStep(
          id: 'map',
          targetKey: _mapActionKey,
          icon: Icons.map_rounded,
          highlightRadius: 20,
          titleAr: 'الخريطة التفاعلية للأماكن المهيأة',
          titleEn: 'Interactive Accessibility Map',
          descriptionAr:
              'شاهد الأماكن القريبة على الخريطة مع تقييم سهولة الوصول (أخضر / أصفر / أحمر) وتجهيزات المنحدرات والمصاعد والحمامات.',
          descriptionEn:
              'Explore nearby places on the map with color-coded accessibility ratings, ramps, elevators, and restroom details.',
        ),
        SpotlightTourStep(
          id: 'report',
          targetKey: _reportActionKey,
          icon: Icons.report_problem_rounded,
          highlightRadius: 20,
          titleAr: 'الإبلاغ عن العوائق لحماية غيرك',
          titleEn: 'Report Barriers',
          descriptionAr:
              'إذا واجهت مدخلاً مغلقاً أو مصعداً معطلاً في أي مكان مسجّل، أرسل بلاغاً بالصور ليراجعه فريق ONEWAY وينبّه المستخدمين.',
          descriptionEn:
              'Encountered a broken elevator or blocked ramp? Submit a quick photo report to keep accessibility info accurate.',
        ),
        SpotlightTourStep(
          id: 'emergency',
          targetKey: _emergencyActionKey,
          icon: Icons.emergency_rounded,
          highlightRadius: 20,
          titleAr: 'الطوارئ السريعة (SOS)',
          titleEn: 'Emergency SOS & Hotlines',
          descriptionAr:
              'اتصال مباشر بأرقام الطوارئ الرسمية في مصر (الإسعاف 123، الشرطة 122، المجلس القومي 15044) مع إرسال موقعك الجغرافي لمرافقك بضغطة واحدة.',
          descriptionEn:
              'Instant access to official Egyptian emergency hotlines and 1-tap GPS location sharing with your trusted companion.',
        ),
        SpotlightTourStep(
          id: 'bottom_nav',
          targetKey: _bottomNavKey,
          icon: Icons.explore_rounded,
          highlightRadius: 24,
          titleAr: 'التنقل السريع والإعدادات',
          titleEn: 'Quick Navigation & Settings',
          descriptionAr:
              'تنقّل بسهولة بين ملفك الشخصي، الإشعارات، الرئيسية، المفضلة، والخريطة. ومن أيقونة الإعدادات ⚙️ بالأعلى يمكنك تخصيص احتياجات الوصول وحجم الخط أو إعادة هذه الجولة في أي وقت.',
          descriptionEn:
              'Switch easily between Profile, Notifications, Home, Favorites, and Map. Open Settings ⚙️ at the top anytime to adjust accessibility or replay this tour.',
        ),
      ];

  late Future<List<PlacesRecord>> _nearbyPlacesFuture;

  Future<void> _checkVerificationStatus() async {
    try {
      // Enforce mandatory email confirmation & complete personal profile before
      // staying on HomeDashboard (even if navigated directly via /home).
      final requiredRoute = await AuthRouter.instance.determineRoute();
      if (!mounted) return;
      if (requiredRoute.route == '/verify-account' ||
          requiredRoute.route == '/complete-profile' ||
          requiredRoute.route == '/account-suspended' ||
          requiredRoute.route == '/login') {
        await AuthRouter.instance.navigateAfterLogin(context);
        return;
      }

      final status = await VerificationService.instance.getVerificationStatus();
      if (mounted) {
        setState(() {
          _showVerificationBanner = status != VerificationStatus.fullyVerified;
        });
      }
      await _maybeLaunchSpotlightTour();
    } catch (_) {
      // Never crash the home screen on an offline verification lookup failure.
      await _maybeLaunchSpotlightTour();
    }
  }

  @override
  void dispose() {
    HomeTourController.instance.replayNonce
        .removeListener(_onReplayTourRequested);
    _animationController.dispose();
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Scaffold(
            key: scaffoldKey,
            backgroundColor: theme.background,
            extendBody: true,
            body: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: OnewayResponsive.maxContentWidth(context),
                    ),
                    child: CustomScrollView(
                      slivers: [
                        // Hero Header
                        SliverToBoxAdapter(
                          child: _buildHeroHeader(theme),
                        ),
                        // Soft verification reminder (dismissible)
                        if (_showVerificationBanner)
                          SliverToBoxAdapter(
                            child: _buildVerificationBanner(theme),
                          ),
                        // Content
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            OnewayResponsive.horizontalPadding(context),
                            20,
                            OnewayResponsive.horizontalPadding(context),
                            108,
                          ),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              _buildQuickActions(theme),
                              const SizedBox(height: 24),
                              _buildCategoriesSection(theme),
                              const SizedBox(height: 24),
                              _buildNearbyPlacesSection(theme),
                              const SizedBox(height: 20),
                              _buildEgyptGuideCard(theme),
                              const SizedBox(height: 20),
                              _buildCommunityCTA(theme),
                            ]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottomNavigationBar: _buildBottomNav(theme),
          ),
        ),
        if (_showSpotlightTour)
          Positioned.fill(
            child: HomeSpotlightTourOverlay(
              steps: _buildSpotlightSteps(),
              isEnglish: FFAppState().isEnglish,
              initialVoiceEnabled: FFAppState().voiceFeedbackEnabled,
              onFinished: () {
                HomeTourController.instance.markTourSeen(currentUserUid);
                if (mounted) {
                  setState(() => _showSpotlightTour = false);
                }
              },
            ),
          ),
      ],
    );
  }

  Widget _buildVerificationBanner(FlutterFlowTheme theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Material(
        color: theme.tertiaryLight,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.pushNamed(VerifyAccountWidget.routeName),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  color: theme.tertiaryDark,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'وثّق حسابك بالإيميل أو التليفون عشان تستفيد بكل المزايا',
                    style: theme.bodyMedium.copyWith(
                      color: theme.primaryText,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_back_ios_rounded,
                  color: theme.tertiaryDark,
                  size: 16,
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: S.t(context, 'إخفاء التنبيه', 'Dismiss'),
                  constraints:
                      const BoxConstraints(minWidth: 48, minHeight: 48),
                  onPressed: () {
                    setState(() {
                      _showVerificationBanner = false;
                    });
                  },
                  icon: Icon(
                    Icons.close_rounded,
                    color: theme.secondaryText,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content:
            const Text('هل أنت متأكد أنك تريد تسجيل الخروج من حسابك؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    GoRouter.of(context).prepareAuthEvent();
    await authManager.signOut();
    if (context.mounted) {
      context.goNamedAuth(AuthenticationWidget.routeName, context.mounted);
    }
  }

  Widget _buildHeroHeader(FlutterFlowTheme theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.navy,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(32),
        ),
        boxShadow: [
          theme.designToken.shadow.primaryLg,
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(32),
        ),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // Illustrated Cairo skyline band (mockup art) filling the header.
            Positioned.fill(
              child: Image.asset(
                'assets/images/home_skyline_band.jpg',
                fit: BoxFit.cover,
                alignment: Alignment.bottomCenter,
              ),
            ),
            // Navy veil for legibility: strong on top, soft over the art.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.navy.withValues(alpha: 0.88),
                      theme.navy.withValues(alpha: 0.25),
                      theme.navy.withValues(alpha: 0.10),
                      theme.navy.withValues(alpha: 0.35),
                    ],
                    stops: const [0.0, 0.35, 0.7, 1.0],
                  ),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  OnewayResponsive.horizontalPadding(context),
                  14,
                  OnewayResponsive.horizontalPadding(context),
                  20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: Brand lockup + Notifications & Settings (overflow-safe)
                    Row(
                      children: [
                        const Expanded(
                          child: OnewayBrandLockup(
                            iconSize: 38,
                            fontSize: 20,
                            lightText: true,
                          ),
                        ),
                        _HeroActionButton(
                          icon: Icons.notifications_none_rounded,
                          tooltip: S.t(context, 'الإشعارات', 'Notifications'),
                          onTap: () => context
                              .pushNamed(NotificationsPageWidget.routeName),
                        ),
                        const SizedBox(width: 8),
                        _HeroActionButton(
                          icon: Icons.settings_outlined,
                          tooltip: S.t(context, 'الإعدادات', 'Settings'),
                          onTap: () =>
                              context.pushNamed(SettingsPageWidget.routeName),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: OnewayResponsive.boundedHeight(
                        context,
                        fraction: 0.045,
                        min: 18,
                        max: 44,
                      ),
                    ),
                    // Tagline over the skyline art
                    Text(
                      S.t(context, 'اعرف المكان قبل ما تروح',
                          'Know Before You Go'),
                      style: theme.titleLarge.copyWith(
                        fontSize: OnewayResponsive.isCompact(context) ? 19 : 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.35,
                        shadows: [
                          Shadow(
                            color: theme.navyDark.withValues(alpha: 0.7),
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      S.t(context, 'مصر بدون عوائق — دليلك الذكي للأماكن المهيأة',
                          'Barrier-Free Egypt — Your Smart Accessibility Guide'),
                      style: theme.bodyMedium.copyWith(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.4,
                        shadows: [
                          Shadow(
                            color: theme.navyDark.withValues(alpha: 0.6),
                            blurRadius: 8,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Search pill: arrow, hint text, teal mic circle
                    KeyedSubtree(
                      key: _searchBarKey,
                      child: _SearchBar(
                        onTap: () =>
                            context.pushNamed(SearchFiltersWidget.routeName),
                        onMicTap: () => context.pushNamed(
                            VoiceAssistantInterfaceWidget.routeName),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ]),
        ),
      );
  }

  // Mockup quick-action grid: 2x2 white cards with colorful custom icons.
  Widget _buildQuickActions(FlutterFlowTheme theme) {
    final items = <({
      String label,
      String iconKey,
      void Function() onTap,
    })>[
      (
        label: S.t(context, 'الخريطة', 'Map'),
        iconKey: 'map',
        onTap: () => context.pushNamed(ExploreMapWidget.routeName),
      ),
      (
        label: S.t(context, 'بلّغ عن عائق', 'Report Barrier'),
        iconKey: 'report',
        onTap: () => context.pushNamed(SubmitAccessibilityReportWidget.routeName),
      ),
      (
        label: S.t(context, 'المساعد الصوتي', 'Voice Assistant'),
        iconKey: 'voice',
        onTap: () =>
            context.pushNamed(VoiceAssistantInterfaceWidget.routeName),
      ),
      (
        label: S.t(context, 'الطوارئ', 'Emergency SOS'),
        iconKey: 'emergency',
        onTap: () => context.pushNamed(EmergencySOSWidget.routeName),
      ),
    ];
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final cols = OnewayResponsive.gridColumns(context, phone: 2, tablet: 4);
    final tileHeight = (112.0 * textScale.clamp(1.0, 1.5)).ceilToDouble();

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: tileHeight,
      ),
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final item = items[index];
        final GlobalKey? tourKey = item.iconKey == 'map'
            ? _mapActionKey
            : item.iconKey == 'report'
                ? _reportActionKey
                : item.iconKey == 'emergency'
                    ? _emergencyActionKey
                    : null;
        return Material(
          key: tourKey,
          color: theme.surface,
          borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
          elevation: 0,
          child: InkWell(
            onTap: item.onTap,
            borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(theme.designToken.radius.xl),
                border: Border.all(color: theme.divider),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 14,
                    color: theme.shadow.withValues(alpha: 0.06),
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _quickActionIcon(item.iconKey, theme),
                  const SizedBox(height: 8),
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.titleSmall.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: theme.primaryText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoriesSection(FlutterFlowTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                S.t(context, 'التصنيفات الرئيسية', 'Categories'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.titleLarge.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: theme.primaryText,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => context.pushNamed(SearchFiltersWidget.routeName),
              child: Text(
                S.t(context, 'عرض الكل', 'See All'),
                style: theme.labelLarge.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 126 * MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.5),
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              CategoryChipWidget(
                icon: const Icon(Icons.local_hospital_rounded),
                label: S.t(context, 'مستشفيات', 'Hospitals'),
                onTap: () => context.pushNamed(
                  SearchFiltersWidget.routeName,
                  queryParameters: {'category': 'مستشف'},
                ),
              ),
              const SizedBox(width: 12),
              CategoryChipWidget(
                icon: const Icon(Icons.shopping_bag_rounded),
                label: S.t(context, 'تسوق', 'Malls'),
                onTap: () => context.pushNamed(
                  SearchFiltersWidget.routeName,
                  queryParameters: {'category': 'تسوق'},
                ),
              ),
              const SizedBox(width: 12),
              CategoryChipWidget(
                icon: const Icon(Icons.directions_transit_rounded),
                label: S.t(context, 'مواصلات', 'Transit'),
                onTap: () => context.pushNamed(
                  SearchFiltersWidget.routeName,
                  queryParameters: {'category': 'مواصلات'},
                ),
              ),
              const SizedBox(width: 12),
              CategoryChipWidget(
                icon: const Icon(Icons.museum_rounded),
                label: S.t(context, 'سياحة وثقافة', 'Culture'),
                onTap: () => context.pushNamed(
                  SearchFiltersWidget.routeName,
                  queryParameters: {'category': 'ثقاف'},
                ),
              ),
              const SizedBox(width: 12),
              CategoryChipWidget(
                icon: const Icon(Icons.school_rounded),
                label: S.t(context, 'تعليم', 'Education'),
                onTap: () => context.pushNamed(
                  SearchFiltersWidget.routeName,
                  queryParameters: {'category': 'تعليم'},
                ),
              ),
              const SizedBox(width: 12),
              CategoryChipWidget(
                icon: const Icon(Icons.restaurant_rounded),
                label: S.t(context, 'مطاعم', 'Dining'),
                onTap: () => context.pushNamed(
                  SearchFiltersWidget.routeName,
                  queryParameters: {'category': 'مطعم'},
                ),
              ),
              const SizedBox(width: 12),
              CategoryChipWidget(
                icon: const Icon(Icons.home_repair_service_rounded),
                label: S.t(context, 'مرافق عامة', 'Facilities'),
                onTap: () => context.pushNamed(
                  SearchFiltersWidget.routeName,
                  queryParameters: {'category': 'مرافق'},
                ),
              ),
              const SizedBox(width: 24), // Extra padding at end
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNearbyPlacesSection(FlutterFlowTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                S.t(context, 'أماكن متاحة بالقرب منك', 'Accessible Places Nearby'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.titleLarge.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: theme.primaryText,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => context.pushNamed(SearchFiltersWidget.routeName),
              child: Text(
                S.t(context, 'عرض الكل', 'See All'),
                style: theme.labelLarge.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 292 * MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.5),
          child: FutureBuilder<List<PlacesRecord>>(
            future: _nearbyPlacesFuture,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _NearbyHint(
                  theme: theme,
                  icon: Icons.cloud_off_rounded,
                  text: 'تعذر تحميل الأماكن. تحقق من الاتصال ثم أعد المحاولة.',
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final places = snapshot.data!;
              if (places.isEmpty) {
                return _NearbyHint(
                  theme: theme,
                  icon: Icons.add_location_alt_rounded,
                  text:
                      'لا توجد أماكن موثقة بعد. كن أول من يشارك مكاناً يعرفه!',
                );
              }
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: places.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, i) =>
                    _NearbyPlaceCard(place: places[i], theme: theme),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEgyptGuideCard(FlutterFlowTheme theme) {
    return Material(
      color: theme.surface,
      borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
      child: InkWell(
        borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
        onTap: () => context.pushNamed(EgyptGuidePage.routeName),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
            border: Border.all(color: theme.primary.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                blurRadius: 12,
                color: theme.shadow.withValues(alpha: 0.05),
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.navy.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.menu_book_rounded,
                    color: theme.navy, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.t(context, 'دليلك في مصر — حقوقك والخدمات',
                          'Egypt Access Guide & Rights'),
                      style: theme.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.primaryText,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      S.t(
                        context,
                        'بطاقة الخدمات المتكاملة، تخفيضات المواصلات، والأرقام الرسمية',
                        'Integrated Services Card, transit discounts & official hotlines',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.bodySmall.copyWith(
                        color: theme.secondaryText,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                S.isEn(context)
                    ? Icons.chevron_right_rounded
                    : Icons.chevron_left_rounded,
                color: theme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommunityCTA(FlutterFlowTheme theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(theme.designToken.radius.xxl),
        gradient: LinearGradient(
          colors: [theme.primary, theme.secondaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          theme.designToken.shadow.primaryMd,
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.onPrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(theme.designToken.radius.lg),
                ),
                child: Icon(
                  Icons.people_alt_rounded,
                  color: theme.onPrimary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.t(context, 'ساهم في مجتمعنا', 'Join Our Community'),
                      style: theme.titleLarge.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: theme.onPrimary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      S.t(
                        context,
                        'أبلغ عن عائق أو شاركنا تجربتك لمساعدة الآخرين في الوصول للأماكن بسهولة.',
                        'Report a barrier or suggest an accessible place to help others move freely.',
                      ),
                      style: theme.bodyMedium.copyWith(
                        fontSize: 14,
                        color: theme.onPrimary.withValues(alpha: 0.9),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: double.infinity,
              minHeight: 52,
            ),
            child: ElevatedButton.icon(
              onPressed: () =>
                  context.pushNamed(SubmitAccessibilityReportWidget.routeName),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: theme.navy,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: Icon(
                Icons.report_problem_outlined,
                color: theme.navy,
                size: 22,
              ),
              label: Text(
                S.t(context, 'إضافة بلاغ جديد', 'Report a Barrier'),
                textAlign: TextAlign.center,
                style: theme.titleSmall.copyWith(
                  color: theme.navy,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: double.infinity,
              minHeight: 52,
            ),
            child: OutlinedButton.icon(
              onPressed: () =>
                  context.pushNamed(SuggestPlacePage.routeName),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.14),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                side: const BorderSide(color: Colors.white, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(
                Icons.add_location_alt_outlined,
                color: Colors.white,
                size: 22,
              ),
              label: Text(
                S.t(context, 'اقترح مكاناً مهيأً جديداً',
                    'Suggest an Accessible Place'),
                textAlign: TextAlign.center,
                style: theme.titleSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(FlutterFlowTheme theme) {
    return KeyedSubtree(
      key: _bottomNavKey,
      child: BottomNavWidget(
      child: () => BottomNavChildWidget(
        currentIndex: 2,
        onTap: (index) {
          switch (index) {
            case 0:
              context.pushNamed(UserProfileWidget.routeName);
              break;
            case 1:
              context.pushNamed(NotificationsPageWidget.routeName);
              break;
            case 2:
              break; // Already on home
            case 3:
              context.pushNamed(FavoritesPageWidget.routeName);
              break;
            case 4:
              context.pushNamed(ExploreMapWidget.routeName);
              break;
          }
        },
      ),
    ),
    );
  }
}

// Quick-grid icons as direct Icon literals so the font tree-shaker keeps them.
Widget _quickActionIcon(String key, FlutterFlowTheme theme) {
  switch (key) {
    case 'map':
      return const _MapPinIcon(size: 44);
    case 'report':
      return const Icon(Icons.report_problem_rounded,
          color: Color(0xFFF59E0B), size: 42);
    case 'voice':
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [theme.primary, const Color(0xFF16A6A0)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: theme.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(Icons.mic_rounded, color: Colors.white, size: 26),
      );
    case 'emergency':
    default:
      return const Icon(Icons.warning_rounded,
          color: Color(0xFFE5484D), size: 44);
  }
}

// Mockup-style colorful map icon: green map with a red 3D-style pin.
class _MapPinIcon extends StatelessWidget {
  const _MapPinIcon({this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 0,
            child: Icon(Icons.map_rounded,
                color: const Color(0xFF4CAF50), size: size * 0.95),
          ),
          Positioned(
            top: 0,
            child: Icon(Icons.location_on_rounded,
                color: const Color(0xFFE5484D), size: size * 0.7),
          ),
        ],
      ),
    );
  }
}

class _HeroActionButton extends StatelessWidget {
  const _HeroActionButton({
    required this.icon,
    required this.tooltip,
    this.backgroundColor,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color? backgroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(theme.designToken.radius.full),
            splashColor: theme.onPrimary.withValues(alpha: 0.1),
            highlightColor: theme.onPrimary.withValues(alpha: 0.05),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: backgroundColor ?? theme.onPrimary.withValues(alpha: 0.1),
                borderRadius:
                    BorderRadius.circular(theme.designToken.radius.full),
              ),
              child: Icon(
                icon,
                color: theme.onPrimary,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onTap, required this.onMicTap});

  final VoidCallback onTap;
  final VoidCallback onMicTap;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        splashColor: theme.primary.withValues(alpha: 0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: theme.onPrimary,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                blurRadius: 16,
                color: theme.navyDark.withValues(alpha: 0.25),
                offset: const Offset(0, 6),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: theme.primary,
                  size: 22,
                ),
              ),
              Expanded(
                child: Text(
                  S.t(context, 'ابحث عن مكان...', 'Search for a place...'),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.bodyMedium.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.secondaryText,
                    height: 1.5,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onMicTap,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: theme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.primary.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.mic_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
/// Empty/error placeholder for the nearby-places rail.
class _NearbyHint extends StatelessWidget {
  const _NearbyHint({
    required this.theme,
    required this.icon,
    required this.text,
  });

  final FlutterFlowTheme theme;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: theme.secondaryText),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: theme.bodyMedium.copyWith(
              fontSize: 14,
              color: theme.secondaryText,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

/// Real nearby-place card backed by a verified PlacesRecord.
class _NearbyPlaceCard extends StatelessWidget {
  const _NearbyPlaceCard({required this.place, required this.theme});

  final PlacesRecord place;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    final features = place.accessibilityFeatures;
    final subtitleParts = <String>[
      if (place.category.isNotEmpty) place.category,
      if (place.city.isNotEmpty) place.city else if (place.governorate.isNotEmpty) place.governorate,
    ];
    final photoUrl = place.photoUrl;
    final fallbackAsset = _fallbackPlacePhoto(place.category);
    return Material(
      color: theme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PlaceDetailPage(place: place)),
        ),
        child: Container(
          width: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 92,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    photoUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: photoUrl,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Image.asset(
                              fallbackAsset,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Image.asset(
                            fallbackAsset,
                            fit: BoxFit.cover,
                          ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: CompatibilityBadge(
                        compact: true,
                        result: AccessibilityScorer.evaluatePlace(
                          place,
                          mobilityType: currentUserDocument
                              ?.snapshotData['mobility_type'] as String?,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              place.name.isEmpty ? 'مكان بدون اسم' : place.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.titleSmall.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: theme.primaryText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (subtitleParts.isNotEmpty)
                              Text(
                                subtitleParts.join(' · '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.bodySmall.copyWith(
                                  fontSize: 12,
                                  color: theme.secondaryText,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (features.hasRamp() && features.ramp)
                            _MiniFeatureChip(label: 'منحدر', theme: theme),
                          if (features.hasAccessibleRestroom() &&
                              features.accessibleRestroom)
                            _MiniFeatureChip(label: 'حمام مجهز', theme: theme),
                          if (features.hasSuitableElevator() &&
                              features.suitableElevator)
                            _MiniFeatureChip(label: 'مصعد', theme: theme),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Category-matched local photo used when a place has no photo URL.
String _fallbackPlacePhoto(String category) {
  final c = category.toLowerCase();
  if (c.contains('مول') || c.contains('تسوق') || c.contains('mall') || c.contains('shop')) {
    return 'assets/images/place_mall.jpg';
  }
  if (c.contains('مترو') || c.contains('محطة') || c.contains('مواصلات') ||
      c.contains('metro') || c.contains('transport')) {
    return 'assets/images/place_metro.jpg';
  }
  if (c.contains('متحف') || c.contains('ثقاف') || c.contains('museum') || c.contains('culture')) {
    return 'assets/images/place_museum.jpg';
  }
  return 'assets/images/hero_pyramids.jpg';
}

class _MiniFeatureChip extends StatelessWidget {
  const _MiniFeatureChip({required this.label, required this.theme});

  final String label;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.tertiaryLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: theme.bodySmall.copyWith(fontSize: 11, color: theme.secondaryDark),
      ),
    );
  }
}
