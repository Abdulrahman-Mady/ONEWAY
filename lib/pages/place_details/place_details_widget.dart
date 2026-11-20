import '/components/accessibility_chip2/accessibility_chip2_widget.dart';
import '/components/button/button_widget.dart';
import '/components/info_row/info_row_widget.dart';
import '/components/slider/slider_widget.dart';
import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'place_details_model.dart';
export 'place_details_model.dart';

class PlaceDetailsWidget extends StatefulWidget {
  const PlaceDetailsWidget({super.key});

  static String routeName = 'PlaceDetails';
  static String routePath = '/place-details';

  @override
  State<PlaceDetailsWidget> createState() => _PlaceDetailsWidgetState();
}

class _PlaceDetailsWidgetState extends State<PlaceDetailsWidget>
    with SingleTickerProviderStateMixin {
  late PlaceDetailsModel _model;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PlaceDetailsModel());
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
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
        extendBodyBehindAppBar: true,
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: CustomScrollView(
              slivers: [
                // Hero Image with App Bar
                SliverAppBar(
                  expandedHeight: 300,
                  pinned: true,
                  stretch: true,
                  backgroundColor: theme.surface,
                  surfaceTintColor: Colors.transparent,
                  leading: Padding(
                    padding: const EdgeInsets.all(8),
                    child: _CircleButton(
                      icon: Icons.arrow_back_ios_rounded,
                      onTap: () => context.goNamed(HomeDashboardWidget.routeName),
                    ),
                  ),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _CircleButton(
                        icon: Icons.share_rounded,
                        onTap: () {
                          // TODO: Implement share
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: _CircleButton(
                        icon: Icons.favorite_border_rounded,
                        onTap: _toggleFavorite,
                      ),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    stretchModes: const [
                      StretchMode.zoomBackground,
                      StretchMode.blurBackground,
                    ],
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          fadeInDuration: const Duration(milliseconds: 200),
                          imageUrl:
                              'https://dimg.dreamflow.cloud/v1/image/Modern%20restaurant%20entrance%20with%20wide%20glass%20doors%20and%20a%20visible%20ramp',
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: theme.surfaceVariant,
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.primary,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: theme.surfaceVariant,
                            child: Icon(
                              Icons.image_not_supported_rounded,
                              color: theme.tertiaryText,
                              size: 64,
                            ),
                          ),
                        ),
                        // Gradient overlay
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                theme.background.withValues(alpha: 0.9),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: const [0.6, 1.0],
                            ),
                          ),
                        ),
                        // Place info at bottom
                        Positioned(
                          left: 24,
                          right: 24,
                          bottom: 24,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.surface,
                                      borderRadius: BorderRadius.circular(
                                        theme.designToken.radius.full,
                                      ),
                                      boxShadow: [theme.designToken.shadow.sm],
                                    ),
                                    child: Text(
                                      'مطعم',
                                      style: theme.labelMedium.copyWith(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: theme.primaryText,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.star_rounded,
                                        color: Colors.amber.shade700,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'عرض تجريبي · لا توجد تقييمات فعلية',
                                        style: theme.labelSmall.copyWith(
                                          fontSize: 11,
                                          color: theme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'مكان تجريبي: مطعم زيتون وجارليك',
                                style: theme.headlineSmall.copyWith(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: theme.onSurface,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Content
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Demo notice
                      _buildDemoNotice(theme),
                      const SizedBox(height: 24),
                      // Accessibility Overview
                      _buildAccessibilitySection(theme),
                      const SizedBox(height: 24),
                      // About
                      _buildAboutSection(theme),
                      const SizedBox(height: 24),
                      // Contact Info
                      _buildContactSection(theme),
                      const SizedBox(height: 24),
                      // Map
                      _buildMapSection(theme),
                      const SizedBox(height: 24),
                      // Actions
                      _buildActionsSection(theme),
                      const SizedBox(height: 24),
                      // Navigation Button
                      _buildNavigationButton(theme),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDemoNotice(FlutterFlowTheme theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.infoContainer,
        borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
        border: Border.all(
          color: theme.info.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: theme.info,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'معلومات تجريبية غير معتمدة',
                  style: theme.titleSmall.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: theme.onInfoContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'هذه البيانات للعرض فقط ولم يتم التحقق من الإتاحة.',
                  style: theme.bodySmall.copyWith(
                    fontSize: 12,
                    color: theme.onInfoContainer.withValues(alpha: 0.8),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessibilitySection(FlutterFlowTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'حالة معلومات الإتاحة',
              style: theme.titleLarge.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: theme.primaryText,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.warningContainer,
                borderRadius: BorderRadius.circular(theme.designToken.radius.full),
              ),
              child: Text(
                'غير مكتملة',
                style: theme.labelMedium.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.onWarningContainer,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Progress indicator
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: theme.surfaceVariant,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: 0.3,
            child: Container(
              decoration: BoxDecoration(
                color: theme.primary,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Accessibility features grid
        _buildAccessibilityGrid(theme),
      ],
    );
  }

  Widget _buildAccessibilityGrid(FlutterFlowTheme theme) {
    final features = [
      {'icon': Icons.wheelchair_pickup_rounded, 'label': 'مدخل مجهز', 'available': false, 'color': theme.success},
      {'icon': Icons.elevator_rounded, 'label': 'مصعد واسع', 'available': false, 'color': theme.info},
      {'icon': Icons.wc_rounded, 'label': 'حمام مجهز', 'available': false, 'color': theme.primary},
      {'icon': Icons.local_parking_rounded, 'label': 'ركن سيارات', 'available': false, 'color': theme.secondary},
      {'icon': Icons.stairs_rounded, 'label': 'بدون سلالم', 'available': false, 'color': theme.tertiaryText},
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: features.map((feature) {
        return _AccessibilityFeatureCard(
          icon: feature['icon'] as IconData,
          label: feature['label'] as String,
          available: feature['available'] as bool,
          color: feature['color'] as Color,
        );
      }).toList(),
    );
  }

  Widget _buildAboutSection(FlutterFlowTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'عن المكان',
          style: theme.titleLarge.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: theme.primaryText,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'وصف توضيحي تجريبي فقط. تفاصيل الإتاحة وعرض الممرات غير متوفرة ولم يتم التحقق منها.',
          style: theme.bodyMedium.copyWith(
            fontSize: 15,
            color: theme.secondaryText,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildContactSection(FlutterFlowTheme theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
        border: Border.all(color: theme.outlineVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تفاصيل العنوان والتحقق',
            style: theme.titleLarge.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 16),
          _InfoRowItem(
            icon: Icons.location_on_rounded,
            label: 'العنوان',
            value: 'عنوان تجريبي · القاهرة',
            theme: theme,
          ),
          const SizedBox(height: 12),
          _InfoRowItem(
            icon: Icons.call_rounded,
            label: 'رقم الهاتف',
            value: 'غير متاح',
            theme: theme,
          ),
          const SizedBox(height: 12),
          _InfoRowItem(
            icon: Icons.schedule_rounded,
            label: 'ساعات العمل',
            value: 'غير متاح',
            theme: theme,
          ),
          const SizedBox(height: 12),
          _InfoRowItem(
            icon: Icons.verified_rounded,
            label: 'حالة التحقق',
            value: 'معلومات غير مكتملة',
            theme: theme,
          ),
          const SizedBox(height: 12),
          _InfoRowItem(
            icon: Icons.calendar_today_rounded,
            label: 'تاريخ آخر فحص',
            value: 'غير متاح',
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection(FlutterFlowTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الموقع على الخريطة',
          style: theme.titleLarge.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: theme.primaryText,
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
              border: Border.all(color: theme.outlineVariant, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
              child: FlutterFlowGoogleMap(
                controller: _model.mapGoogleMapsController,
                onCameraIdle: (latLng) =>
                    _model.mapGoogleMapsCenter = latLng,
                initialLocation: _model.mapGoogleMapsCenter ??=
                    const LatLng(30.027, 31.491),
                markerColor: GoogleMarkerColor.violet,
                mapType: MapType.normal,
                style: GoogleMapStyle.standard,
                initialZoom: 15,
                allowInteraction: true,
                allowZoom: true,
                showZoomControls: false,
                showLocation: false,
                showCompass: false,
                showMapToolbar: false,
                showTraffic: false,
                centerMapOnMarkerTap: true,
                mapTakesGesturePreference: false,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionsSection(FlutterFlowTheme theme) {
    return Row(
      children: [
        Expanded(
          child: ButtonWidget(
            content: 'بلاغ عن عائق',
            variant: 'outline',
            size: 'medium',
            fullWidth: true,
            icon: Icon(
              Icons.report_problem_rounded,
              color: theme.primaryText,
              size: 24,
            ),
            iconPresent: true,
            onPressed: () =>
                context.goNamed(SubmitAccessibilityReportWidget.routeName),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ButtonWidget(
            content: 'الاتصال بالدعم',
            variant: 'secondary',
            size: 'medium',
            fullWidth: true,
            icon: Icon(
              Icons.support_agent_rounded,
              color: theme.primaryText,
              size: 24,
            ),
            iconPresent: true,
            onPressed: () => context.goNamed(EmergencySOSWidget.routeName),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButton(FlutterFlowTheme theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border(
          top: BorderSide(color: theme.outlineVariant, width: 1),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: ButtonWidget(
        content: 'بدء التنقل',
        variant: 'primary',
        size: 'large',
        fullWidth: true,
        icon: Icon(
          Icons.directions_rounded,
          color: theme.onPrimary,
          size: 24,
        ),
        iconPresent: true,
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'الملاحة القياسية لا تؤكد أن المسار مناسب للكراسي المتحركة.',
              ),
              duration: Duration(milliseconds: 4000),
            ),
          );
        },
      ),
    );
  }

  Future<void> _toggleFavorite() async {
    if (_model.isFavorite!) {
      FFAppState().removeFromFavoritePlaceIds(
          'مكان تجريبي: مطعم زيتون وجارليك');
      safeSetState(() {});
      _model.isFavorite = false;
      safeSetState(() {});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('أزيل المكان من المفضلة على هذا الجهاز.'),
            duration: Duration(milliseconds: 4000),
          ),
        );
      }
    } else {
      FFAppState().addToFavoritePlaceIds(
          'مكان تجريبي: مطعم زيتون وجارليك');
      safeSetState(() {});
      _model.isFavorite = true;
      safeSetState(() {});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('أضيف المكان إلى المفضلة على هذا الجهاز.'),
            duration: Duration(milliseconds: 4000),
          ),
        );
      }
    }
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(theme.designToken.radius.full),
        splashColor: theme.onSurface.withValues(alpha: 0.1),
        highlightColor: theme.onSurface.withValues(alpha: 0.05),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.surface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(theme.designToken.radius.full),
            boxShadow: [theme.designToken.shadow.sm],
          ),
          child: Icon(
            icon,
            color: theme.primaryText,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _AccessibilityFeatureCard extends StatelessWidget {
  const _AccessibilityFeatureCard({
    required this.icon,
    required this.label,
    required this.available,
    required this.color,
  });

  final IconData icon;
  final String label;
  final bool available;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: available
            ? color.withValues(alpha: 0.1)
            : theme.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
        border: Border.all(
          color: available
              ? color.withValues(alpha: 0.3)
              : theme.outlineVariant,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: available
                  ? color.withValues(alpha: 0.2)
                  : theme.onSurface.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(theme.designToken.radius.lg),
            ),
            child: Icon(
              icon,
              color: available ? color : theme.tertiaryText,
              size: 24,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.labelMedium.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: available ? color : theme.tertiaryText,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: available
                  ? color.withValues(alpha: 0.15)
                  : theme.onSurface.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(theme.designToken.radius.full),
            ),
            child: Text(
              available ? 'متاح' : 'غير متاح',
              style: theme.labelSmall.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: available ? color : theme.tertiaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRowItem extends StatelessWidget {
  const _InfoRowItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
  });

  final IconData icon;
  final String label;
  final String value;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(theme.designToken.radius.lg),
          ),
          child: Icon(
            icon,
            color: theme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.labelSmall.copyWith(
                  fontSize: 11,
                  color: theme.tertiaryText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.bodyMedium.copyWith(
                  fontSize: 14,
                  color: theme.primaryText,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}