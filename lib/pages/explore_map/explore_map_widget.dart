import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:url_launcher/url_launcher.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/schema/places_record.dart';
import '/components/button/button_widget.dart';
import '/core/analytics/analytics_service.dart';
import '/core/constants/app_constants.dart';
import '/features/accessibility/accessibility_score.dart';
import '/features/discovery/discovery_pages.dart';
import '/features/discovery/places_repository.dart';
import '/features/emergency/emergency_service.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/l10n/app_strings.dart';
import 'explore_map_model.dart';
export 'explore_map_model.dart';

class ExploreMapWidget extends StatefulWidget {
  const ExploreMapWidget({super.key, this.initialCategory});

  final String? initialCategory;

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
  int _filteredCount = 0;
  final MapController _mapController = MapController();

  List<PlacesRecord> _allPlaces = const [];
  bool _loadingPlaces = true;
  Object? _loadError;
  ll.LatLng _lastQueriedCenter = const ll.LatLng(30.0444, 31.2357);
  ll.LatLng? _currentCameraCenter;
  bool _showSearchAreaBtn = false;

  static const LatLng _cairoCenter = LatLng(30.0444, 31.2357);

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ExploreMapModel());
    if (widget.initialCategory != null &&
        widget.initialCategory!.trim().isNotEmpty) {
      _selectedCategory = widget.initialCategory!.trim();
    }

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
    _loadPlacesForArea(_cairoCenter.latitude, _cairoCenter.longitude);
  }

  Future<void> _loadPlacesForArea(
    double lat,
    double lng, {
    bool forceRefresh = false,
  }) async {
    if (mounted) {
      setState(() {
        _loadingPlaces = true;
        _loadError = null;
        _showSearchAreaBtn = false;
      });
    }
    try {
      final places = await PlacesRepository.instance.getNearbyVerifiedPlaces(
        latitude: lat,
        longitude: lng,
        radiusKm: 30.0,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _allPlaces = places;
        _filteredCount = _filterPlaces(places).length;
        _lastQueriedCenter = ll.LatLng(lat, lng);
        _loadingPlaces = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e;
        _loadingPlaces = false;
      });
    }
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
        _mapController.move(
          ll.LatLng(pos.latitude, pos.longitude),
          14.5,
        );
        await _loadPlacesForArea(pos.latitude, pos.longitude);
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
    AnalyticsService.instance.logNavigationStarted(
      placeId: _selectedPlace?.reference.id ?? placeName,
      navigationMode: 'maps',
    );
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=${location.latitude},${location.longitude}&travelmode=walking';
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
      if (_verifiedOnly && !place.isGenuinelyVerified) {
        return false;
      }
      return true;
    }).toList();
  }

  void _onPlaceTap(PlacesRecord place) {
    final compat = AccessibilityScorer.evaluatePlace(
      place,
      mobilityType:
          currentUserDocument?.snapshotData['mobility_type'] as String?,
    );
    AnalyticsService.instance.logPlaceViewed(
      placeId: place.reference.id,
      category: place.category,
      scorePercent: compat.scorePercent,
      accessibilityLevel: compat.level.name,
      isPersonalized: compat.isPersonalized,
    );
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
    final filteredPlaces = _filterPlaces(_allPlaces);
    if (filteredPlaces.length != _filteredCount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _filteredCount = filteredPlaces.length);
        }
      });
    }

    final mobilityType =
        (currentUserDocument?.snapshotData['mobility_type'] as String?);
    final markers = filteredPlaces.map((place) {
      final loc = place.location!;
      final compat = AccessibilityScorer.evaluatePlace(
        place,
        mobilityType: mobilityType,
      );
      return Marker(
        point: ll.LatLng(loc.latitude, loc.longitude),
        width: 48,
        height: 48,
        child: Semantics(
          button: true,
          label: '${place.name} (${compat.scorePercent}%)',
          child: GestureDetector(
            onTap: () => _onPlaceTap(place),
            child: Tooltip(
              message: '${place.name} (${compat.scorePercent}%)',
              child: Container(
                decoration: BoxDecoration(
                  color: compat.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  compat.level == AccessibilityLevel.limited
                      ? Icons.priority_high_rounded
                      : Icons.accessible_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();

    return Scaffold(
      key: scaffoldKey,
      resizeToAvoidBottomInset: false,
      backgroundColor: theme.background,
      body: Stack(
          children: [
            // Geohash-backed, cache-first Interactive Map (zero unbounded full scans)
            if (_loadError != null && _allPlaces.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'تعذر تحميل الأماكن. تحقق من الاتصال ثم أعد المحاولة.',
                        textAlign: TextAlign.center,
                        style: theme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () => _loadPlacesForArea(
                          _lastQueriedCenter.latitude,
                          _lastQueriedCenter.longitude,
                          forceRefresh: true,
                        ),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              )
            else
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: ll.LatLng(
                    _cairoCenter.latitude,
                    _cairoCenter.longitude,
                  ),
                  initialZoom: 12.5,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                  onPositionChanged: (camera, hasGesture) {
                    if (!hasGesture) return;
                    _currentCameraCenter = camera.center;
                    final movedKm = PlacesRepository.haversineKm(
                      _lastQueriedCenter.latitude,
                      _lastQueriedCenter.longitude,
                      camera.center.latitude,
                      camera.center.longitude,
                    );
                    if (movedKm > 4.0 && !_showSearchAreaBtn && mounted) {
                      setState(() => _showSearchAreaBtn = true);
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: AppConstants.mapTileUrlTemplate,
                    userAgentPackageName: 'com.onewayegypt.app',
                  ),
                  MarkerLayer(markers: markers),
                ],
              ),

            // "Search this area" Geohash trigger pill when user pans far away
            if (_showSearchAreaBtn && !_loadingPlaces)
              Positioned(
                top: MediaQuery.paddingOf(context).top + 126,
                left: 0,
                right: 0,
                child: Center(
                  child: Material(
                    color: theme.navy,
                    elevation: 6,
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () {
                        final target =
                            _currentCameraCenter ?? _lastQueriedCenter;
                        _loadPlacesForArea(target.latitude, target.longitude);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.travel_explore_rounded,
                                color: theme.gold, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              S.t(context, 'بحث في هذه المنطقة',
                                  'Search this area'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            if (_loadingPlaces)
              Positioned(
                top: MediaQuery.paddingOf(context).top + 126,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.surface.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 8),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          S.t(context, 'جاري تحميل الأماكن القريبة...',
                              'Loading nearby places...'),
                          style: theme.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.primaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
                      onPressed: () {
                        _mapController.move(
                          ll.LatLng(
                            _cairoCenter.latitude,
                            _cairoCenter.longitude,
                          ),
                          14.0,
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
                    icon: S.isEn(context)
                        ? Icons.arrow_back_rounded
                        : Icons.arrow_forward_rounded,
                    onPressed: () => context.safePop(),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      S.t(
                        context,
                        'استكشف الأماكن المتاحة (${_getFilteredCount()})',
                        'Accessible Places (${_getFilteredCount()})',
                      ),
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
                    onSelected: (sel) {
                      setState(() => _selectedCategory = null);
                      AnalyticsService.instance.logMapFilterApplied(
                        filterType: 'category',
                        filterValue: 'all',
                      );
                    },
                    theme: theme,
                  ),
                  const SizedBox(width: 8),
                  _CategoryFilterChip(
                    label: '🏥 طبي',
                    selected: _selectedCategory == 'طبي',
                    onSelected: (sel) {
                      setState(() => _selectedCategory = sel ? 'طبي' : null);
                      AnalyticsService.instance.logMapFilterApplied(
                        filterType: 'category',
                        filterValue: sel ? 'medical' : 'all',
                      );
                    },
                    theme: theme,
                  ),
                  const SizedBox(width: 8),
                  _CategoryFilterChip(
                    label: '🛍️ تسوق',
                    selected: _selectedCategory == 'تسوق',
                    onSelected: (sel) {
                      setState(() => _selectedCategory = sel ? 'تسوق' : null);
                      AnalyticsService.instance.logMapFilterApplied(
                        filterType: 'category',
                        filterValue: sel ? 'shopping' : 'all',
                      );
                    },
                    theme: theme,
                  ),
                  const SizedBox(width: 8),
                  _CategoryFilterChip(
                    label: '🏛️ ثقافة',
                    selected: _selectedCategory == 'ثقاف',
                    onSelected: (sel) {
                      setState(() => _selectedCategory = sel ? 'ثقاف' : null);
                      AnalyticsService.instance.logMapFilterApplied(
                        filterType: 'category',
                        filterValue: sel ? 'culture' : 'all',
                      );
                    },
                    theme: theme,
                  ),
                  const SizedBox(width: 8),
                  _CategoryFilterChip(
                    label: '🚆 مواصلات',
                    selected: _selectedCategory == 'مواصلات',
                    onSelected: (sel) {
                      setState(() => _selectedCategory = sel ? 'مواصلات' : null);
                      AnalyticsService.instance.logMapFilterApplied(
                        filterType: 'category',
                        filterValue: sel ? 'transit' : 'all',
                      );
                    },
                    theme: theme,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'منحدر مجهز',
                    selected: _rampOnly,
                    onSelected: (val) {
                      setState(() => _rampOnly = val);
                      AnalyticsService.instance.logMapFilterApplied(
                        filterType: 'ramp',
                        filterValue: val.toString(),
                      );
                    },
                    theme: theme,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: S.t(context, 'تم التحقق فقط', 'Verified Only'),
                    selected: _verifiedOnly,
                    onSelected: (val) {
                      setState(() => _verifiedOnly = val);
                      AnalyticsService.instance.logMapFilterApplied(
                        filterType: 'verified',
                        filterValue: val.toString(),
                      );
                    },
                    theme: theme,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Traffic-Light Accessibility Legend (Wheelmap-inspired)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.surface.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [theme.designToken.shadow.xs],
                ),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _LegendDot(
                      color: const Color(0xFF16A34A),
                      label: S.t(context, 'مهيأ بالكامل', 'Full'),
                    ),
                    _LegendDot(
                      color: const Color(0xFFD97706),
                      label: S.t(context, 'جزئي', 'Partial'),
                    ),
                    _LegendDot(
                      color: const Color(0xFFDC2626),
                      label: S.t(context, 'محدود', 'Limited'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getFilteredCount() {
    return _filteredCount;
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

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}