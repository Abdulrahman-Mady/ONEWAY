import '/auth/firebase_auth/auth_util.dart';
import '/backend/schema/places_record.dart';
import '/features/discovery/discovery_pages.dart' show PlaceDetailPage;
import 'package:cloud_firestore/cloud_firestore.dart';
import '/components/bottom_nav/bottom_nav_widget.dart';
import '/components/bottom_nav_child/bottom_nav_child_widget.dart';
import '/components/button/button_widget.dart';
import '/components/category_chip/category_chip_widget.dart';
import '/components/place_card/place_card_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  /// Soft verification reminder: shown when the account is not fully verified.
  bool _showVerificationBanner = false;

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
    _checkVerificationStatus();
  }

  Future<void> _checkVerificationStatus() async {
    try {
      final status = await VerificationService.instance.getVerificationStatus();
      if (mounted) {
        setState(() {
          _showVerificationBanner = status != VerificationStatus.fullyVerified;
        });
      }
    } catch (_) {
      // Never block the home screen on a verification lookup failure.
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _model.dispose();
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
        key: scaffoldKey,
        backgroundColor: theme.background,
        extendBody: true,
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            // Phone-shaped column like the mockup, even on wide desktop windows.
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
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
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildQuickActions(theme),
                      const SizedBox(height: 24),
                      _buildCategoriesSection(theme),
                      const SizedBox(height: 24),
                      _buildNearbyPlacesSection(theme),
                      const SizedBox(height: 24),
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
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showVerificationBanner = false;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close_rounded,
                      color: theme.secondaryText,
                      size: 20,
                    ),
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
            // Cairo skyline band along the header's bottom edge.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Image.asset(
                'assets/images/hero_cairo_city.jpg',
                height: 110,
                fit: BoxFit.cover,
                alignment: const Alignment(0, 0.5),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 110,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.navy.withValues(alpha: 0.75),
                      theme.navy.withValues(alpha: 0.15),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 72),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Greeting + Notifications
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'أهلاً بك في ONEWAY',
                        style: theme.displaySmall.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: theme.onPrimary,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'مصر بدون عوائق',
                        style: theme.bodyMedium.copyWith(
                          fontSize: 15,
                          color: theme.onPrimary.withValues(alpha: 0.8),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _HeroActionButton(
                        icon: Icons.notifications_none_rounded,
                        onTap: () => context
                            .pushNamed(NotificationsPageWidget.routeName),
                      ),
                      const SizedBox(width: 12),
                      _HeroActionButton(
                        icon: Icons.logout_rounded,
                        onTap: () => _confirmLogout(context),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Search Bar + Voice Assistant
              Row(
                children: [
                  Expanded(
                    child: _SearchBar(
                      onTap: () => context.pushNamed(SearchFiltersWidget.routeName),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _HeroActionButton(
                    icon: Icons.mic_rounded,
                    backgroundColor: theme.gold,
                    onTap: () => context.goNamed(VoiceAssistantInterfaceWidget.routeName),
                  ),
                ],
              ),
            ],
          ),
              ),
            ),
          ]),
        ),
      );
  }

  // Mockup quick-action grid: 2x2 white cards (map, SOS, favorites, report).
  Widget _buildQuickActions(FlutterFlowTheme theme) {
    final items = <({
      String label,
      IconData icon,
      Color color,
      void Function() onTap,
    })>[
      (
        label: 'الخريطة',
        icon: Icons.map_rounded,
        color: theme.primary,
        onTap: () => context.pushNamed(ExploreMapWidget.routeName),
      ),
      (
        label: 'الطوارئ',
        icon: Icons.emergency_rounded,
        color: theme.error,
        onTap: () => context.goNamed(EmergencySOSWidget.routeName),
      ),
      (
        label: 'المفضلة',
        icon: Icons.favorite_rounded,
        color: theme.tertiary,
        onTap: () => context.pushNamed(FavoritesPageWidget.routeName),
      ),
      (
        label: 'بلّغ عن عائق',
        icon: Icons.report_problem_rounded,
        color: theme.navy,
        onTap: () => context.pushNamed(SubmitAccessibilityReportWidget.routeName),
      ),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.25,
      children: [
        for (final item in items)
          Material(
            color: theme.surface,
            borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
            elevation: 0,
            child: InkWell(
              onTap: item.onTap,
              borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
              child: Container(
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
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(item.icon, color: item.color, size: 24),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.label,
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
          ),
      ],
    );
  }

  Widget _buildCategoriesSection(FlutterFlowTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'التصنيفات الرئيسية',
              style: theme.titleLarge.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: theme.primaryText,
                height: 1.3,
              ),
            ),
            TextButton(
              onPressed: () => context.pushNamed(ExploreMapWidget.routeName),
              child: Text(
                'عرض الكل',
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
          height: 110,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              CategoryChipWidget(
                icon: const Icon(Icons.home_repair_service_rounded),
                label: 'مرافق عامة',
                onTap: () => context.pushNamed(ExploreMapWidget.routeName),
              ),
              const SizedBox(width: 12),
              CategoryChipWidget(
                icon: const Icon(Icons.local_hospital_rounded),
                label: 'مستشفيات',
                onTap: () => context.pushNamed(ExploreMapWidget.routeName),
              ),
              const SizedBox(width: 12),
              CategoryChipWidget(
                icon: const Icon(Icons.restaurant_rounded),
                label: 'مطاعم',
                onTap: () => context.pushNamed(ExploreMapWidget.routeName),
              ),
              const SizedBox(width: 12),
              CategoryChipWidget(
                icon: const Icon(Icons.shopping_bag_rounded),
                label: 'تسوق',
                onTap: () => context.pushNamed(ExploreMapWidget.routeName),
              ),
              const SizedBox(width: 12),
              CategoryChipWidget(
                icon: const Icon(Icons.hotel_rounded),
                label: 'فنادق',
                onTap: () => context.pushNamed(ExploreMapWidget.routeName),
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
            Text(
              'أماكن متاحة بالقرب منك',
              style: theme.titleLarge.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: theme.primaryText,
                height: 1.3,
              ),
            ),
            TextButton(
              onPressed: () => context.pushNamed(ExploreMapWidget.routeName),
              child: Text(
                'عرض الكل',
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
          height: 280,
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: PlacesRecord.collection
                .where('verification_status', isEqualTo: 'verified')
                .limit(10)
                .snapshots(),
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
              final places = snapshot.data!.docs
                  .map(PlacesRecord.fromSnapshot)
                  .toList();
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
                      'ساهم في مجتمعنا',
                      style: theme.titleLarge.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: theme.onPrimary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'أبلغ عن عائق أو شاركنا تجربتك لمساعدة الآخرين في الوصول للأماكن بسهولة.',
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
          ButtonWidget(
            content: 'إضافة بلاغ جديد',
            variant: 'outline',
            size: 'large',
            fullWidth: true,
            icon: Icon(
              Icons.add_circle_outline_rounded,
              color: theme.onPrimary,
              size: 24,
            ),
            iconPresent: true,
            onPressed: () =>
                context.goNamed(SubmitAccessibilityReportWidget.routeName),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(FlutterFlowTheme theme) {
    return BottomNavWidget(
      child: () => BottomNavChildWidget(
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              break; // Already on home
            case 1:
              context.pushNamed(ExploreMapWidget.routeName);
              break;
            case 2:
              context.pushNamed(SubmitAccessibilityReportWidget.routeName);
              break;
            case 3:
              context.pushNamed(UserProfileWidget.routeName);
              break;
          }
        },
      ),
    );
  }
}

class _HeroActionButton extends StatelessWidget {
  const _HeroActionButton({
    required this.icon,
    this.backgroundColor,
    required this.onTap,
  });

  final IconData icon;
  final Color? backgroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Material(
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
            borderRadius: BorderRadius.circular(theme.designToken.radius.full),
          ),
          child: Icon(
            icon,
            color: backgroundColor != null ? theme.onPrimary : theme.onPrimary,
            size: 24,
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
        splashColor: theme.primary.withValues(alpha: 0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: theme.onPrimary,
            borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
            boxShadow: [
              BoxShadow(
                blurRadius: 8,
                color: theme.shadow.withValues(alpha: 0.1),
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.search_rounded,
                color: theme.secondaryText,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'ابحث عن مكان...',
                style: theme.bodyMedium.copyWith(
                  fontSize: 15,
                  color: theme.onSurface,
                  height: 1.5,
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
                child: photoUrl.isNotEmpty
                    ? Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Image.asset(
                          fallbackAsset,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Image.asset(
                        fallbackAsset,
                        fit: BoxFit.cover,
                      ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                      const Spacer(),
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
