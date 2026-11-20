import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' hide LatLng;

import '/backend/schema/places_record.dart';
import '/components/button/button_widget.dart';
import '/features/discovery/discovery_pages.dart';
import '/features/emergency/emergency_service.dart';
import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'explore_map_model.dart';
export 'explore_map_model.dart';

class ExploreMapWidget extends StatefulWidget {
  const ExploreMapWidget({super.key});

  static String routeName = 'ExploreMap';
  static String routePath = '/map';

  @override
  State<ExploreMapWidget> createState() => _ExploreMapWidgetState();
}

class _ExploreMapWidgetState extends State<ExploreMapWidget>
    with SingleTickerProviderStateMixin {
  late ExploreMapModel _model;
  late AnimationController _animationController;
  late Animation<double> _fabAnimation;
  late Animation<double> _bottomSheetAnimation;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  String? _selectedCategory;
  PlacesRecord? _selectedPlace;
  bool _rampOnly = false;
  bool _verifiedOnly = false;
  bool _showBottomSheet = false;

  static const LatLng _cairoCenter = LatLng(30.0444, 31.2357);

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ExploreMapModel());
    _model.mapGoogleMapsCenter ??= _cairoCenter;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _bottomSheetAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _model.dispose();
    super.dispose();
  }

  Future<void> _goToMyLocation() async {
    try {
      final pos = await EmergencyService.determineCurrentPosition();
      if (pos != null && mounted) {
        final controller = await _model.mapGoogleMapsController.future;
        controller.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(pos.latitude, pos.longitude).toGoogleMaps(),
            15.0,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'تعذر تحديد موقعك بدقة. يرجى التأكد من تشغيل الـ GPS ومنح الإذن.'),
          ),
        );
      }
    } catch (e) {
      debugPrint('Location center error: $e');
    }
  }

  Future<void> _openNavigation(LatLng location, String placeName) async {
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=${location.latitude},${location.longitude}';
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchURL(url);
      }
    } catch (_) {}
  }

  List<PlacesRecord> _filterPlaces(List<PlacesRecord> places) {
    return places.where((place) {
      if (!place.hasLocation()) return false;
      if (_selectedCategory != null &&
          !place.category.contains(_selectedCategory!)) {
        return false;
      }
      final features = place.accessibilityFeatures;
      if (_rampOnly && (!features.hasRamp() || !features.ramp)) {
        return false;
      }
      if (_verifiedOnly && place.verificationStatus != 'verified') {
        return false;
      }
      return true;
    }).toList();
  }

  void _onPlaceTap(PlacesRecord place) {
    setState(() {
      _selectedPlace = place;
      _showBottomSheet = true;
    });
    _animationController.forward();
  }

  void _closeBottomSheet() {
    _animationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _selectedPlace = null;
          _showBottomSheet = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        key: scaffoldKey,
        resizeToAvoidBottomInset: false,
        backgroundColor: theme.background,
        body: Stack(
          children: [
            // Map
            StreamBuilder<QuerySnapshot>(
              stream: PlacesRecord.collection.snapshots(),
              builder: (context, snapshot) {
                final allPlaces = (snapshot.hasData)
                    ? snapshot.data!.docs
                        .map(PlacesRecord.fromSnapshot)
                        .toList()
                    : <PlacesRecord>[];

                final filteredPlaces = _filterPlaces(allPlaces);

                final markers = filteredPlaces.map((place) {
                  return FlutterFlowMarker(
                    place.reference.id,
                    place.location!,
                    () async => _onPlaceTap(place),
                  );
                }).toList();

                return FlutterFlowGoogleMap(
                  controller: _model.mapGoogleMapsController,
                  onCameraIdle: (latLng) =>
                      _model.mapGoogleMapsCenter = latLng,
                  initialLocation: _model.mapGoogleMapsCenter ?? _cairoCenter,
                  markers: markers,
                  markerColor: GoogleMarkerColor.violet,
                  mapType: MapType.normal,
                  style: GoogleMapStyle.standard,
                  initialZoom: 12.5,
                  allowInteraction: true,
                  allowZoom: true,
                  showZoomControls: false,
                  showLocation: true,
                  showCompass: false,
                  showMapToolbar: false,
                  showTraffic: false,
                  centerMapOnMarkerTap: true,
                );
              },
            ),

            // Top Header
            SafeArea(
              child: _buildTopHeader(theme),
            ),

            // Floating Action Buttons
            Positioned(
              left: 16,
              bottom: _showBottomSheet ? 280 : 100,
              child: ScaleTransition(
                scale: _fabAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Re-center to Cairo
                    _MapFAB(
                      icon: Icons.center_focus_strong_rounded,
                      tooltip: 'العودة للقاهرة',
                      onPressed: () async {
                        final controller =
                            await _model.mapGoogleMapsController.future;
                        controller.animateCamera(
                          CameraUpdate.newLatLngZoom(
                            _cairoCenter.toGoogleMaps(),
                            14.0,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    // My Location
                    _MapFAB(
                      icon: Icons.my_location_rounded,
                      tooltip: 'موقعي الحالي',
                      backgroundColor: theme.secondary,
                      onPressed: _goToMyLocation,
                    ),
                    const SizedBox(height: 12),
                    // Report Barrier
                    _MapFAB(
                      icon: Icons.warning_amber_rounded,
                      tooltip: 'إبلاغ عن عائق',
                      backgroundColor: theme.error,
                      onPressed: () {
                        context.pushNamed(
                          SubmitAccessibilityReportWidget.routeName,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    // Emergency SOS
                    _MapFAB(
                      icon: Icons.emergency_rounded,
                      tooltip: 'طوارئ',
                      backgroundColor: theme.error,
                      onPressed: () {
                        context.pushNamed(EmergencySOSWidget.routeName);
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Sheet
            AnimatedBuilder(
              animation: _bottomSheetAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _bottomSheetAnimation.value * 400),
                  child: Opacity(
                    opacity: 1 - _bottomSheetAnimation.value,
                    child: child,
                  ),
                );
              },
              child: _showBottomSheet && _selectedPlace != null
                  ? _buildBottomSheet(theme, _selectedPlace!)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader(FlutterFlowTheme theme) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search bar & Back
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: theme.surface,
                borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
                boxShadow: [theme.designToken.shadow.sm],
              ),
              child: Row(
                children: [
                  _MapActionButton(
                    icon: Icons.arrow_forward_rounded,
                    onPressed: () => context.safePop(),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'استكشف الأماكن المتاحة (${_getFilteredCount()})',
                      style: theme.titleMedium.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: theme.primaryText,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _MapActionButton(
                    tooltip: 'المساعد الذكي',
                    icon: Icons.auto_awesome_rounded,
                    iconColor: Colors.amber.shade700,
                    onPressed: () => context.pushNamed(
                      VoiceAssistantInterfaceWidget.routeName,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Category & Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _CategoryFilterChip(
                    label: 'الكل',
                    selected: _selectedCategory == null,
                    onSelected: (sel) => setState(() => _selectedCategory = null),
                    theme: theme,
                  ),
                  const SizedBox(width: 8),
                  _CategoryFilterChip(
                    label: '🏥 طبي',
                    selected: _selectedCategory == 'طبي',
                    onSelected: (sel) => setState(
                        () => _selectedCategory = sel ? 'طبي' : null),
                    theme: theme,
                  ),
                  const SizedBox(width: 8),
                  _CategoryFilterChip(
                    label: '🛍️ تسوق',
                    selected: _selectedCategory == 'تسوق',
                    onSelected: (sel) => setState(
                        () => _selectedCategory = sel ? 'تسوق' : null),
                    theme: theme,
                  ),
                  const SizedBox(width: 8),
                  _CategoryFilterChip(
                    label: '🏛️ ثقافة',
                    selected: _selectedCategory == 'ثقاف',
                    onSelected: (sel) => setState(
                        () => _selectedCategory = sel ? 'ثقاف' : null),
                    theme: theme,
                  ),
                  const SizedBox(width: 8),
                  _CategoryFilterChip(
                    label: '🚆 مواصلات',
                    selected: _selectedCategory == 'مواصلات',
                    onSelected: (sel) => setState(
                        () => _selectedCategory = sel ? 'مواصلات' : null),
                    theme: theme,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'منحدر مجهز',
                    selected: _rampOnly,
                    onSelected: (val) => setState(() => _rampOnly = val),
                    theme: theme,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'تم التحقق فقط',
                    selected: _verifiedOnly,
                    onSelected: (val) => setState(() => _verifiedOnly = val),
                    theme: theme,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getFilteredCount() {
    // This would need access to the stream data - simplified for now
    return 0;
  }

  Widget _buildBottomSheet(FlutterFlowTheme theme, PlacesRecord place) {
    final feat = place.accessibilityFeatures;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(theme.designToken.radius.xxl),
            boxShadow: [theme.designToken.shadow.xl],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: theme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                place.name,
                                style: theme.titleMedium.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: theme.primaryText,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${place.category} • ${place.city}',
                                style: theme.bodySmall.copyWith(
                                  fontSize: 12,
                                  color: theme.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded,
                              color: theme.onSurfaceVariant, size: 20),
                          onPressed: _closeBottomSheet,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Accessibility badges
                    _buildAccessibilityBadges(theme, feat),
                    const SizedBox(height: 16),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ButtonWidget(
                            content: 'تفاصيل الإتاحة',
                            variant: 'primary',
                            size: 'medium',
                            fullWidth: true,
                            icon: const Icon(Icons.info_outline_rounded, size: 18),
                            iconPresent: true,
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => PlaceDetailPage(place: place),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ButtonWidget(
                            content: 'الاتجاهات',
                            variant: 'outline',
                            size: 'medium',
                            fullWidth: true,
                            icon: const Icon(Icons.directions_rounded,
                                size: 18, color: Colors.blueAccent),
                            iconPresent: true,
                            onPressed: () {
                              if (place.hasLocation()) {
                                _openNavigation(place.location!, place.name);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccessibilityBadges(FlutterFlowTheme theme, dynamic feat) {
    final badges = <Widget>[];

    if (feat.hasRamp() && feat.ramp) {
      badges.add(_AccessibilityBadge(
        icon: Icons.check_rounded,
        label: 'منحدر متاح',
        color: theme.success,
        theme: theme,
      ));
    }
    if (feat.hasSuitableElevator() && feat.suitableElevator) {
      badges.add(_AccessibilityBadge(
        icon: Icons.check_rounded,
        label: 'مصعد مجهز',
        color: theme.info,
        theme: theme,
      ));
    }
    if (feat.hasAccessibleRestroom() && feat.accessibleRestroom) {
      badges.add(_AccessibilityBadge(
        icon: Icons.check_rounded,
        label: 'حمام مجهز',
        color: theme.primary,
        theme: theme,
      ));
    }
    if (feat.hasWheelchairEntrance() && feat.wheelchairEntrance) {
      badges.add(_AccessibilityBadge(
        icon: Icons.check_rounded,
        label: 'مدخل كراسي',
        color: theme.secondary,
        theme: theme,
      ));
    }

    if (badges.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'لا توجد معلومات إتاحة متاحة',
          style: theme.bodySmall.copyWith(
            fontSize: 12,
            color: theme.tertiaryText,
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: badges,
    );
  }
}

class _MapActionButton extends StatelessWidget {
  const _MapActionButton({
    required this.icon,
    this.iconColor,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final Color? iconColor;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(theme.designToken.radius.full),
        splashColor: theme.primary.withValues(alpha: 0.1),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.surfaceVariant,
            borderRadius: BorderRadius.circular(theme.designToken.radius.full),
          ),
          child: Icon(
            icon,
            color: iconColor ?? theme.primaryText,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _MapFAB extends StatelessWidget {
  const _MapFAB({
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final bgColor = backgroundColor ?? theme.surface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(theme.designToken.radius.full),
        splashColor: theme.primary.withValues(alpha: 0.1),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(theme.designToken.radius.full),
            boxShadow: [theme.designToken.shadow.md],
            border: bgColor == theme.surface
                ? Border.all(color: theme.outlineVariant, width: 1)
                : null,
          ),
          child: Icon(
            icon,
            color: backgroundColor != null ? theme.onPrimary : theme.primaryText,
            size: 24,
          ),
        ),
      ),
    );
  }
}

class _CategoryFilterChip extends StatelessWidget {
  const _CategoryFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    required this.theme,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(
        label,
        style: theme.labelMedium.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: selected ? theme.onPrimary : theme.primaryText,
        ),
      ),
      selected: selected,
      onSelected: onSelected,
      backgroundColor: theme.surface,
      selectedColor: theme.primary,
      checkmarkColor: theme.onPrimary,
      side: BorderSide(
        color: selected ? theme.primary : theme.outlineVariant,
        width: 1.5,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme.designToken.radius.full),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    required this.theme,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(
        label,
        style: theme.labelMedium.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: selected ? theme.onSecondary : theme.secondaryText,
        ),
      ),
      selected: selected,
      onSelected: onSelected,
      backgroundColor: theme.surface,
      selectedColor: theme.secondary,
      checkmarkColor: theme.onSecondary,
      side: BorderSide(
        color: selected ? theme.secondary : theme.outlineVariant,
        width: 1.5,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme.designToken.radius.full),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _AccessibilityBadge extends StatelessWidget {
  const _AccessibilityBadge({
    required this.icon,
    required this.label,
    required this.color,
    required this.theme,
  });

  final IconData icon;
  final String label;
  final Color color;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 14, color: color),
      label: Text(
        label,
        style: theme.labelSmall.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.3), width: 1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme.designToken.radius.full),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}