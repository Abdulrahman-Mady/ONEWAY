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
            child: CustomScrollView(
              slivers: [
                // Hero Header
                SliverToBoxAdapter(
                  child: _buildHeroHeader(theme),
                ),
                // Content
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildEmergencyCard(theme),
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
        bottomNavigationBar: _buildBottomNav(theme),
      ),
    );
  }

  Widget _buildHeroHeader(FlutterFlowTheme theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primary,
            theme.primaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(32),
        ),
        boxShadow: [
          theme.designToken.shadow.primaryLg,
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
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
                  _HeroActionButton(
                    icon: Icons.notifications_none_rounded,
                    onTap: () => context.pushNamed(NotificationsPageWidget.routeName),
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
                    backgroundColor: theme.secondary,
                    onTap: () => context.goNamed(VoiceAssistantInterfaceWidget.routeName),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyCard(FlutterFlowTheme theme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.goNamed(EmergencySOSWidget.routeName),
        borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
        splashColor: theme.error.withValues(alpha: 0.1),
        highlightColor: theme.error.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
            gradient: LinearGradient(
              colors: [
                theme.error.withValues(alpha: 0.1),
                theme.error.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: theme.error.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 12,
                color: theme.error.withValues(alpha: 0.15),
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.error,
                  borderRadius: BorderRadius.circular(theme.designToken.radius.lg),
                ),
                child: Icon(
                  Icons.emergency_rounded,
                  color: theme.onError,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مساعدة طوارئ',
                      style: theme.titleMedium.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: theme.error,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'الوصول السريع لأقرب مستشفى أو صيدلية',
                      style: theme.bodyMedium.copyWith(
                        fontSize: 14,
                        color: theme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: theme.error,
                size: 18,
              ),
            ],
          ),
        ),
      ),
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
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              PlaceCardWidget(
                category: 'مركز تسوق · ٦ أكتوبر',
                distance: '١.٢ كم',
                imageDesc:
                    'https://dimg.dreamflow.cloud/v1/image/modern%20mall%20entrance%20with%20ramps',
                name: 'مول العرب',
                status: 'بيانات تجريبية',
                verificationStatus: 'incomplete',
                onTap: () => context.pushNamed(PlaceDetailsWidget.routeName),
              ),
              const SizedBox(width: 16),
              PlaceCardWidget(
                category: 'مطاعم · روض الفرج',
                distance: '٣.٥ كم',
                imageDesc:
                    'https://dimg.dreamflow.cloud/v1/image/traditional%20restaurant%20with%20wide%20entrance',
                name: 'مطعم صبحي كابر',
                status: 'بيانات تجريبية',
                verificationStatus: 'incomplete',
                onTap: () => context.pushNamed(PlaceDetailsWidget.routeName),
              ),
              const SizedBox(width: 16),
              PlaceCardWidget(
                category: 'مستشفيات · مدينة نصر',
                distance: '٤.٨ كم',
                imageDesc:
                    'https://dimg.dreamflow.cloud/v1/image/hospital%20entrance%20with%20automatic%20doors',
                name: 'مستشفى دار الفؤاد',
                status: 'بيانات تجريبية',
                verificationStatus: 'incomplete',
                onTap: () => context.pushNamed(PlaceDetailsWidget.routeName),
              ),
              const SizedBox(width: 24),
            ],
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