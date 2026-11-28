import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/schema/places_record.dart';
import '/core/analytics/analytics_service.dart';
import '/features/admin/admin_dashboard_page.dart' show AdminDashboardPage;
import '/core/utils/arabic_normalizer.dart';
import '/features/accessibility/accessibility_score.dart';
import '/features/discovery/discovery_pages.dart' show PlaceDetailPage;
import '/features/discovery/place_categories.dart';
import '/features/discovery/places_repository.dart';
import '/features/legal/legal_pages.dart' show SuggestPlacePage;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/nav/nav.dart';
import '/index.dart';
import '/l10n/app_strings.dart';
import '/widgets/responsive_layout.dart';

enum _ExplorerSortMode {
  topAccess,
  topRated,
}

class PlaceExplorerPage extends StatefulWidget {
  const PlaceExplorerPage({
    super.key,
    this.initialCategory,
    this.placesOverride,
  });

  final String? initialCategory;

  /// Optional in-memory list used in widget tests/previews instead of live Firestore.
  final List<PlacesRecord>? placesOverride;

  @override
  State<PlaceExplorerPage> createState() => _PlaceExplorerPageState();
}

class _PlaceExplorerPageState extends State<PlaceExplorerPage> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  final Map<String, GlobalKey> _categoryPillKeys = {
    for (final spec in PlaceCategoryCatalog.presets) spec.id: GlobalKey(),
  };

  String? _selectedCategoryId;
  String? _customCategory;
  bool _rampOnly = false;
  bool _elevatorOnly = false;
  bool _restroomOnly = false;
  bool _parkingOnly = false;
  bool _verifiedOnly = false;
  _ExplorerSortMode _sortMode = _ExplorerSortMode.topAccess;
  Future<List<PlacesRecord>>? _placesFuture;

  @override
  void initState() {
    super.initState();
    _applyInitialCategory(widget.initialCategory);
    if (widget.placesOverride == null) {
      _placesFuture = PlacesRepository.instance.getVerifiedPlaces(limit: 50);
    }
    if (_selectedCategoryId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollActiveCategoryIntoView();
      });
    }
  }

  void _applyInitialCategory(String? raw) {
    final trimmed = raw?.trim() ?? '';
    if (trimmed.isEmpty) {
      _selectedCategoryId = null;
      _customCategory = null;
      return;
    }
    final resolved = PlaceCategoryCatalog.resolve(trimmed);
    if (resolved != null) {
      _selectedCategoryId = resolved.id;
      _customCategory = null;
    } else {
      _selectedCategoryId = null;
      _customCategory = trimmed;
    }
  }

  void _scrollActiveCategoryIntoView() {
    final key =
        _selectedCategoryId != null ? _categoryPillKeys[_selectedCategoryId] : null;
    final ctx = key?.currentContext;
    if (ctx != null && mounted) {
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.4,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  PlaceCategorySpec? get _activeSpec {
    if (_selectedCategoryId == null) return null;
    for (final spec in PlaceCategoryCatalog.presets) {
      if (spec.id == _selectedCategoryId) return spec;
    }
    return null;
  }

  bool get _hasActiveFilters =>
      _selectedCategoryId != null ||
      _customCategory != null ||
      _search.text.trim().isNotEmpty ||
      _rampOnly ||
      _elevatorOnly ||
      _restroomOnly ||
      _parkingOnly ||
      _verifiedOnly;

  bool get _hasFeatureFilters =>
      _rampOnly || _elevatorOnly || _restroomOnly || _parkingOnly || _verifiedOnly;

  void _resetAllFilters() {
    setState(() {
      _selectedCategoryId = null;
      _customCategory = null;
      _search.clear();
      _rampOnly = false;
      _elevatorOnly = false;
      _restroomOnly = false;
      _parkingOnly = false;
      _verifiedOnly = false;
    });
  }

  bool _matchesSelectedCategory(PlacesRecord place) {
    final spec = _activeSpec;
    if (spec != null) {
      return spec.matchesPlace(place);
    }
    if (_customCategory != null && _customCategory!.isNotEmpty) {
      final norm = ArabicNormalizer.normalize(_customCategory!);
      final searchable = ArabicNormalizer.normalize(
        '${place.name} ${place.category}',
      );
      return searchable.contains(norm);
    }
    return true;
  }

  List<PlacesRecord> _filterAndSort(
    List<PlacesRecord> places, {
    String? mobilityType,
  }) {
    final query = ArabicNormalizer.normalize(_search.text);
    final filtered = places.where((place) {
      if (!_matchesSelectedCategory(place)) return false;

      if (query.isNotEmpty) {
        final searchable = ArabicNormalizer.normalize(
          '${place.name} ${place.category} ${place.description} '
          '${place.address} ${place.city} ${place.governorate}',
        );
        if (!searchable.contains(query)) return false;
      }

      final f = place.accessibilityFeatures;
      if (_rampOnly && !(f.hasRamp() && f.ramp)) return false;
      if (_elevatorOnly && !(f.hasSuitableElevator() && f.suitableElevator)) {
        return false;
      }
      if (_restroomOnly &&
          !(f.hasAccessibleRestroom() && f.accessibleRestroom)) {
        return false;
      }
      if (_parkingOnly && !(f.hasAccessibleParking() && f.accessibleParking)) {
        return false;
      }
      if (_verifiedOnly && !place.isGenuinelyVerified) return false;
      return true;
    }).toList();

    filtered.sort((a, b) {
      if (_sortMode == _ExplorerSortMode.topRated) {
        final ratingCmp = b.rating.compareTo(a.rating);
        if (ratingCmp != 0) return ratingCmp;
      }
      final scoreA = AccessibilityScorer.evaluatePlace(
        a,
        mobilityType: mobilityType,
      ).scorePercent;
      final scoreB = AccessibilityScorer.evaluatePlace(
        b,
        mobilityType: mobilityType,
      ).scorePercent;
      final scoreCmp = scoreB.compareTo(scoreA);
      if (scoreCmp != 0) return scoreCmp;
      return b.rating.compareTo(a.rating);
    });

    return filtered;
  }

  Map<String, int> _countByPreset(List<PlacesRecord> places) {
    final counts = <String, int>{};
    for (final spec in PlaceCategoryCatalog.presets) {
      counts[spec.id] = places.where(spec.matchesPlace).length;
    }
    return counts;
  }

  List<String> _extraCustomCategories(List<PlacesRecord> places) {
    final extras = <String>{};
    for (final place in places) {
      final raw = place.category.trim();
      if (raw.isEmpty) continue;
      if (PlaceCategoryCatalog.resolve(raw) == null) {
        extras.add(raw);
      }
    }
    if (_customCategory != null &&
        _customCategory!.isNotEmpty &&
        PlaceCategoryCatalog.resolve(_customCategory) == null) {
      extras.add(_customCategory!);
    }
    final list = extras.toList()..sort();
    return list;
  }

  void _openOnMap() {
    final spec = _activeSpec;
    final params = <String, String>{};
    if (spec != null) {
      params['category'] = spec.mapQuery;
    } else if (_customCategory != null && _customCategory!.isNotEmpty) {
      params['category'] = _customCategory!;
    }
    context.pushNamed(
      ExploreMapWidget.routeName,
      queryParameters: params,
    );
  }

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.goNamed(HomeDashboardWidget.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    if (widget.placesOverride != null) {
      return _buildScaffold(
        context,
        theme,
        places: widget.placesOverride!,
        isLoading: false,
      );
    }

    return FutureBuilder<List<PlacesRecord>>(
      future: _placesFuture ??=
          PlacesRepository.instance.getVerifiedPlaces(limit: 50),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildScaffold(
            context,
            theme,
            places: const [],
            isLoading: false,
            error: snapshot.error,
          );
        }
        if (!snapshot.hasData) {
          return _buildScaffold(
            context,
            theme,
            places: const [],
            isLoading: true,
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            final refreshed = PlacesRepository.instance.getVerifiedPlaces(
              limit: 50,
              forceRefresh: true,
            );
            setState(() => _placesFuture = refreshed);
            await refreshed;
          },
          child: _buildScaffold(
            context,
            theme,
            places: snapshot.data!,
            isLoading: false,
          ),
        );
      },
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    FlutterFlowTheme theme, {
    required List<PlacesRecord> places,
    required bool isLoading,
    Object? error,
  }) {
    final mobilityType =
        (currentUserDocument?.snapshotData['mobility_type'] as String?);
    final filtered =
        isLoading ? const <PlacesRecord>[] : _filterAndSort(places, mobilityType: mobilityType);
    final presetCounts = _countByPreset(places);
    final extraCategories = _extraCustomCategories(places);
    final hPad = OnewayResponsive.horizontalPadding(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: theme.background,
        body: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: OnewayResponsive.isTablet(context)
                  ? 720
                  : double.infinity,
            ),
            child: RefreshIndicator(
              color: theme.primary,
              onRefresh: () async => setState(() {}),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  // Curved Deep Navy Header + Integrated Pill Search
                  SliverToBoxAdapter(
                    child: _ExplorerHeader(
                      theme: theme,
                      activeSpec: _activeSpec,
                      customCategory: _customCategory,
                      resultCount: isLoading ? null : filtered.length,
                      searchController: _search,
                      searchFocus: _searchFocus,
                      onBack: _goBack,
                      onMapTap: _openOnMap,
                      onSearchChanged: (_) => setState(() {}),
                      onSearchClear: () {
                        _search.clear();
                        setState(() {});
                      },
                      onSearchSubmitted: (query) {
                        if (query.trim().isNotEmpty) {
                          AnalyticsService.instance.logPlaceSearched(
                            query: query.trim(),
                            resultsCount: filtered.length,
                            categoryFilter:
                                _activeSpec?.labelAr ?? _customCategory,
                            rampOnly: _rampOnly,
                            verifiedOnly: _verifiedOnly,
                          );
                        }
                      },
                      onVoiceTap: () => context.pushNamed(
                        VoiceAssistantInterfaceWidget.routeName,
                      ),
                    ),
                  ),

                  // Horizontal Category Pill Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: _CategoryPillBar(
                        theme: theme,
                        hPad: hPad,
                        selectedCategoryId: _selectedCategoryId,
                        customCategory: _customCategory,
                        totalCount: places.length,
                        presetCounts: presetCounts,
                        extraCategories: extraCategories,
                        pillKeys: _categoryPillKeys,
                        onSelectAll: () => setState(() {
                          _selectedCategoryId = null;
                          _customCategory = null;
                        }),
                        onSelectPreset: (spec) => setState(() {
                          if (_selectedCategoryId == spec.id) {
                            _selectedCategoryId = null;
                          } else {
                            _selectedCategoryId = spec.id;
                            _customCategory = null;
                          }
                        }),
                        onSelectCustom: (cat) => setState(() {
                          if (_customCategory == cat) {
                            _customCategory = null;
                          } else {
                            _selectedCategoryId = null;
                            _customCategory = cat;
                          }
                        }),
                      ),
                    ),
                  ),

                  // Compact Accessibility Quick-Filters & Sort Strip
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: _AccessibilityFilterBar(
                        theme: theme,
                        hPad: hPad,
                        sortMode: _sortMode,
                        rampOnly: _rampOnly,
                        elevatorOnly: _elevatorOnly,
                        restroomOnly: _restroomOnly,
                        parkingOnly: _parkingOnly,
                        verifiedOnly: _verifiedOnly,
                        onToggleSort: () => setState(() {
                          _sortMode = _sortMode == _ExplorerSortMode.topAccess
                              ? _ExplorerSortMode.topRated
                              : _ExplorerSortMode.topAccess;
                        }),
                        onToggleRamp: () =>
                            setState(() => _rampOnly = !_rampOnly),
                        onToggleElevator: () =>
                            setState(() => _elevatorOnly = !_elevatorOnly),
                        onToggleRestroom: () =>
                            setState(() => _restroomOnly = !_restroomOnly),
                        onToggleParking: () =>
                            setState(() => _parkingOnly = !_parkingOnly),
                        onToggleVerified: () =>
                            setState(() => _verifiedOnly = !_verifiedOnly),
                      ),
                    ),
                  ),

                  // Results Summary & Clear Filters Row
                  if (!isLoading && error == null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 10),
                        child: _ResultsSummaryRow(
                          theme: theme,
                          count: filtered.length,
                          activeSpec: _activeSpec,
                          customCategory: _customCategory,
                          hasActiveFilters: _hasActiveFilters,
                          hasFeatureFilters: _hasFeatureFilters,
                          onReset: _resetAllFilters,
                        ),
                      ),
                    ),

                  // Main Body: Error / Loading Skeleton / Empty State / Cards
                  if (error != null)
                    SliverToBoxAdapter(
                      child: _ExplorerErrorCard(
                        theme: theme,
                        error: error,
                        hPad: hPad,
                        onRetry: () => setState(() {}),
                      ),
                    )
                  else if (isLoading)
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 32),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, __) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _ExplorerLoadingSkeleton(theme: theme),
                          ),
                          childCount: 3,
                        ),
                      ),
                    )
                  else if (filtered.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 32),
                        child: _ExplorerEmptyState(
                          theme: theme,
                          activeSpec: _activeSpec,
                          customCategory: _customCategory,
                          isDatabaseEmpty: places.isEmpty,
                          hasActiveFilters: _hasActiveFilters,
                          onResetFilters: _resetAllFilters,
                          onSuggestPlace: () =>
                              context.pushNamed(SuggestPlacePage.routeName),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(hPad, 4, hPad, 32),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final place = filtered[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _ExplorerPlaceCard(
                                place: place,
                                theme: theme,
                                mobilityType: mobilityType,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        PlaceDetailPage(place: place),
                                  ),
                                ),
                              ),
                            );
                          },
                          childCount: filtered.length,
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

/// Deep Navy rounded header matching HomeDashboard's design language, adapted
/// contextually to the active category with integrated pill search.
class _ExplorerHeader extends StatelessWidget {
  const _ExplorerHeader({
    required this.theme,
    required this.activeSpec,
    required this.customCategory,
    required this.resultCount,
    required this.searchController,
    required this.searchFocus,
    required this.onBack,
    required this.onMapTap,
    required this.onSearchChanged,
    required this.onSearchClear,
    required this.onSearchSubmitted,
    required this.onVoiceTap,
  });

  final FlutterFlowTheme theme;
  final PlaceCategorySpec? activeSpec;
  final String? customCategory;
  final int? resultCount;
  final TextEditingController searchController;
  final FocusNode searchFocus;
  final VoidCallback onBack;
  final VoidCallback onMapTap;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchClear;
  final ValueChanged<String> onSearchSubmitted;
  final VoidCallback onVoiceTap;

  @override
  Widget build(BuildContext context) {
    final isCompact = OnewayResponsive.isCompact(context);
    final isEn = S.isEn(context);
    final hPad = OnewayResponsive.horizontalPadding(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final String headerTitle;
    if (activeSpec != null) {
      headerTitle =
          isCompact ? activeSpec!.label(context) : activeSpec!.title(context);
    } else if (customCategory != null && customCategory!.isNotEmpty) {
      headerTitle = customCategory!;
    } else {
      headerTitle = S.t(context, 'استكشف الأماكن', 'Explore Places');
    }

    final String subtitle;
    if (resultCount == null) {
      subtitle = S.t(context, 'جارٍ تحميل الأماكن المهيأة...',
          'Loading accessible places...');
    } else if (resultCount == 0) {
      subtitle = S.t(context, 'لا توجد نتائج حالياً', 'No places found yet');
    } else if (resultCount == 1) {
      subtitle = S.t(context, 'مكان واحد مهيأ متاح', '1 accessible place');
    } else {
      subtitle = S.t(
        context,
        '$resultCount أماكن مهيأة ومتاحة',
        '$resultCount accessible places',
      );
    }

    final accentTint = activeSpec?.accentColor ?? theme.primary;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            theme.navy,
            Color.lerp(theme.navyLight, accentTint, 0.16) ?? theme.navyLight,
          ],
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.navyDark.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Navigation + Category Title + Map Shortcut
              Row(
                children: [
                  Semantics(
                    button: true,
                    label: S.t(context, 'رجوع', 'Back'),
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.14),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onBack,
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
                  ),
                  const SizedBox(width: 12),
                  if (activeSpec != null) ...[
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: activeSpec!.accentColor.withValues(alpha: 0.24),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Icon(
                        activeSpec!.icon,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          headerTitle,
                          key: const Key('explorer_header_title'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.titleLarge.copyWith(
                            fontSize: isCompact ? 17 : 19,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.bodySmall.copyWith(
                            fontSize: 12.5,
                            color: Colors.white.withValues(alpha: 0.82),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Semantics(
                    button: true,
                    label: S.t(context, 'عرض على الخريطة', 'View on Map'),
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(24),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: onMapTap,
                        child: Container(
                          height: 44,
                          padding: EdgeInsets.symmetric(
                            horizontal: isCompact ? 11 : 14,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.26),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.map_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              if (!isCompact) ...[
                                const SizedBox(width: 6),
                                Text(
                                  S.t(context, 'الخريطة', 'Map'),
                                  style: theme.labelLarge.copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Integrated Search Pill (matching HomeDashboard's search pill)
              Container(
                decoration: BoxDecoration(
                  color: isDark ? theme.surface : Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 14,
                      color: theme.navyDark.withValues(alpha: 0.22),
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Icon(
                        Icons.search_rounded,
                        color: theme.primary,
                        size: 22,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        key: const Key('explorer_search_field'),
                        controller: searchController,
                        focusNode: searchFocus,
                        onChanged: onSearchChanged,
                        onSubmitted: onSearchSubmitted,
                        textInputAction: TextInputAction.search,
                        style: theme.bodyMedium.copyWith(
                          color: theme.primaryText,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 11),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          hintText: activeSpec != null
                              ? S.t(
                                  context,
                                  'ابحث داخل ${activeSpec!.labelAr} أو بالمنطقة...',
                                  'Search in ${activeSpec!.labelEn} or area...',
                                )
                              : S.t(
                                  context,
                                  'ابحث عن مكان أو مدينة أو حي...',
                                  'Search for a place, city, or area...',
                                ),
                          hintStyle: theme.bodyMedium.copyWith(
                            color: theme.secondaryText,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    if (searchController.text.isNotEmpty)
                      Semantics(
                        button: true,
                        label: S.t(context, 'مسح البحث', 'Clear search'),
                        child: Material(
                          color: theme.surfaceVariant,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: onSearchClear,
                            child: SizedBox(
                              width: 40,
                              height: 40,
                              child: Icon(
                                Icons.close_rounded,
                                color: theme.secondaryText,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      Semantics(
                        button: true,
                        label: S.t(context, 'المساعد الصوتي', 'Voice Assistant'),
                        child: Material(
                          color: theme.primary,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: onVoiceTap,
                            child: SizedBox(
                              width: 40,
                              height: 40,
                              child: Icon(
                                Icons.mic_rounded,
                                color: theme.onPrimary,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
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
}

/// Horizontal single-row scrollable category selector with icons and counts.
class _CategoryPillBar extends StatelessWidget {
  const _CategoryPillBar({
    required this.theme,
    required this.hPad,
    required this.selectedCategoryId,
    required this.customCategory,
    required this.totalCount,
    required this.presetCounts,
    required this.extraCategories,
    required this.pillKeys,
    required this.onSelectAll,
    required this.onSelectPreset,
    required this.onSelectCustom,
  });

  final FlutterFlowTheme theme;
  final double hPad;
  final String? selectedCategoryId;
  final String? customCategory;
  final int totalCount;
  final Map<String, int> presetCounts;
  final List<String> extraCategories;
  final Map<String, GlobalKey> pillKeys;
  final VoidCallback onSelectAll;
  final ValueChanged<PlaceCategorySpec> onSelectPreset;
  final ValueChanged<String> onSelectCustom;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.5);
    final isAllSelected =
        selectedCategoryId == null && (customCategory == null || customCategory!.isEmpty);

    return SizedBox(
      height: 46 * scale,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: hPad),
        children: [
          _CategoryPill(
            key: const Key('category_pill_all'),
            theme: theme,
            label: S.t(context, 'الكل', 'All'),
            icon: Icons.grid_view_rounded,
            accentColor: theme.primary,
            count: totalCount > 0 ? totalCount : null,
            selected: isAllSelected,
            onTap: onSelectAll,
          ),
          const SizedBox(width: 8),
          for (final spec in PlaceCategoryCatalog.presets) ...[
            _CategoryPill(
              key: pillKeys[spec.id],
              theme: theme,
              label: spec.label(context),
              icon: spec.icon,
              accentColor: spec.accentColor,
              count: (presetCounts[spec.id] ?? 0) > 0
                  ? presetCounts[spec.id]
                  : null,
              selected: selectedCategoryId == spec.id,
              onTap: () => onSelectPreset(spec),
            ),
            const SizedBox(width: 8),
          ],
          for (final extra in extraCategories) ...[
            _CategoryPill(
              theme: theme,
              label: extra,
              icon: Icons.place_rounded,
              accentColor: theme.primary,
              selected: customCategory == extra,
              onTap: () => onSelectCustom(extra),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({
    super.key,
    required this.theme,
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.selected,
    required this.onTap,
    this.count,
  });

  final FlutterFlowTheme theme;
  final String label;
  final IconData icon;
  final Color accentColor;
  final bool selected;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = selected ? theme.onPrimary : theme.primaryText;
    final iconColor = selected ? theme.onPrimary : accentColor;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? theme.primary : theme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: selected ? theme.primary : theme.divider,
                width: selected ? 1.5 : 1.2,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: theme.primary.withValues(alpha: 0.28),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: theme.shadow
                            .withValues(alpha: isDark ? 0.16 : 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 17, color: iconColor),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: theme.labelLarge.copyWith(
                    fontSize: 13.5,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: fg,
                    height: 1.2,
                  ),
                ),
                if (count != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: selected
                          ? theme.onPrimary.withValues(alpha: 0.2)
                          : theme.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: theme.labelSmall.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: selected ? theme.onPrimary : theme.secondaryText,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontal single-row accessibility feature & sort toggle strip.
class _AccessibilityFilterBar extends StatelessWidget {
  const _AccessibilityFilterBar({
    required this.theme,
    required this.hPad,
    required this.sortMode,
    required this.rampOnly,
    required this.elevatorOnly,
    required this.restroomOnly,
    required this.parkingOnly,
    required this.verifiedOnly,
    required this.onToggleSort,
    required this.onToggleRamp,
    required this.onToggleElevator,
    required this.onToggleRestroom,
    required this.onToggleParking,
    required this.onToggleVerified,
  });

  final FlutterFlowTheme theme;
  final double hPad;
  final _ExplorerSortMode sortMode;
  final bool rampOnly;
  final bool elevatorOnly;
  final bool restroomOnly;
  final bool parkingOnly;
  final bool verifiedOnly;
  final VoidCallback onToggleSort;
  final VoidCallback onToggleRamp;
  final VoidCallback onToggleElevator;
  final VoidCallback onToggleRestroom;
  final VoidCallback onToggleParking;
  final VoidCallback onToggleVerified;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.5);
    return SizedBox(
      height: 40 * scale,
      child: ListView(
        key: const Key('explorer_filter_bar'),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: hPad),
        children: [
          _FilterPill(
            key: const Key('explorer_sort_pill'),
            theme: theme,
            icon: Icons.swap_vert_rounded,
            label: sortMode == _ExplorerSortMode.topAccess
                ? S.t(context, 'الأعلى إتاحة', 'Top Access')
                : S.t(context, 'الأعلى تقييماً', 'Top Rated'),
            selected: false,
            isAccentNeutral: true,
            onTap: onToggleSort,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Container(width: 1, color: theme.divider),
          ),
          _FilterPill(
            key: const Key('filter_ramp'),
            theme: theme,
            icon: Icons.accessible_forward_rounded,
            label: S.t(context, 'منحدر', 'Ramp'),
            selected: rampOnly,
            onTap: onToggleRamp,
          ),
          const SizedBox(width: 8),
          _FilterPill(
            key: const Key('filter_elevator'),
            theme: theme,
            icon: Icons.elevator_rounded,
            label: S.t(context, 'مصعد', 'Elevator'),
            selected: elevatorOnly,
            onTap: onToggleElevator,
          ),
          const SizedBox(width: 8),
          _FilterPill(
            key: const Key('filter_restroom'),
            theme: theme,
            icon: Icons.wc_rounded,
            label: S.t(context, 'حمام مجهز', 'Restroom'),
            selected: restroomOnly,
            onTap: onToggleRestroom,
          ),
          const SizedBox(width: 8),
          _FilterPill(
            key: const Key('filter_parking'),
            theme: theme,
            icon: Icons.local_parking_rounded,
            label: S.t(context, 'موقف سيارات', 'Parking'),
            selected: parkingOnly,
            onTap: onToggleParking,
          ),
          const SizedBox(width: 8),
          _FilterPill(
            key: const Key('filter_verified'),
            theme: theme,
            icon: Icons.verified_rounded,
            label: S.t(context, 'موثق ميدانياً', 'Verified'),
            selected: verifiedOnly,
            onTap: onToggleVerified,
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    super.key,
    required this.theme,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.isAccentNeutral = false,
  });

  final FlutterFlowTheme theme;
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isAccentNeutral;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = selected
        ? theme.primary.withValues(alpha: isDark ? 0.22 : 0.12)
        : isAccentNeutral
            ? theme.navy.withValues(alpha: isDark ? 0.38 : 0.08)
            : theme.surface;
    final borderColor = selected
        ? theme.primary
        : isAccentNeutral
            ? theme.navy.withValues(alpha: isDark ? 0.55 : 0.18)
            : theme.divider;
    final fg = selected
        ? theme.primary
        : isAccentNeutral
            ? (isDark ? Colors.white : theme.navy)
            : theme.secondaryText;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? Icons.check_circle_rounded : icon,
                  size: 15,
                  color: fg,
                ),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: theme.labelMedium.copyWith(
                    fontSize: 12.5,
                    fontWeight:
                        selected || isAccentNeutral ? FontWeight.w700 : FontWeight.w600,
                    color: fg,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultsSummaryRow extends StatelessWidget {
  const _ResultsSummaryRow({
    required this.theme,
    required this.count,
    required this.activeSpec,
    required this.customCategory,
    required this.hasActiveFilters,
    required this.hasFeatureFilters,
    required this.onReset,
  });

  final FlutterFlowTheme theme;
  final int count;
  final PlaceCategorySpec? activeSpec;
  final String? customCategory;
  final bool hasActiveFilters;
  final bool hasFeatureFilters;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final catName = activeSpec?.label(context) ?? customCategory;
    final summaryText = catName != null && catName.isNotEmpty
        ? S.t(context, '$count نتائج في $catName', '$count results in $catName')
        : S.t(context, 'النتائج ($count)', 'Results ($count)');

    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: activeSpec?.accentColor ?? theme.primary,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            summaryText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.titleSmall.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: theme.primaryText,
            ),
          ),
        ),
        if (hasActiveFilters)
          TextButton.icon(
            key: const Key('explorer_reset_filters_btn'),
            onPressed: onReset,
            style: TextButton.styleFrom(
              minimumSize: const Size(44, 36),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: Icon(
              hasFeatureFilters
                  ? Icons.filter_alt_off_rounded
                  : Icons.refresh_rounded,
              size: 16,
              color: theme.primary,
            ),
            label: Text(
              S.t(context, 'عرض الكل', 'Show All'),
              style: theme.labelMedium.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: theme.primary,
              ),
            ),
          ),
      ],
    );
  }
}

/// Magazine-grade accessible place card with photo banner, compatibility badge,
/// rating pill, category tag, accessibility feature pills, and quick directions.
class _ExplorerPlaceCard extends StatelessWidget {
  const _ExplorerPlaceCard({
    required this.place,
    required this.theme,
    required this.mobilityType,
    required this.onTap,
  });

  final PlacesRecord place;
  final FlutterFlowTheme theme;
  final String? mobilityType;
  final VoidCallback onTap;

  Future<void> _openDirections(BuildContext context) async {
    final loc = place.location;
    if (loc == null) return;
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${loc.latitude},${loc.longitude}',
    );
    try {
      if (await canLaunchUrl(uri)) {
        AnalyticsService.instance.logNavigationStarted(
          placeId: place.reference.id,
          navigationMode: 'maps',
        );
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              S.t(context, 'تعذر فتح تطبيق الخرائط.', 'Could not open Maps.'),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEn = S.isEn(context);
    final isCompact = OnewayResponsive.isCompact(context);
    final features = place.accessibilityFeatures;
    final compat = AccessibilityScorer.evaluatePlace(
      place,
      mobilityType: mobilityType,
    );
    final catSpec = PlaceCategoryCatalog.forPlace(place);

    final locationParts = <String>[
      if (place.address.isNotEmpty) place.address,
      if (place.city.isNotEmpty && !place.address.contains(place.city))
        place.city,
      if (place.governorate.isNotEmpty &&
          !place.address.contains(place.governorate))
        place.governorate,
    ];
    final locationText = locationParts.join('، ');

    final featurePills = <({IconData icon, String label})>[
      if (features.hasWheelchairEntrance() && features.wheelchairEntrance)
        (
          icon: Icons.accessible_rounded,
          label: S.t(context, 'مدخل مهيأ', 'Entrance'),
        ),
      if (features.hasRamp() && features.ramp)
        (
          icon: Icons.accessible_forward_rounded,
          label: S.t(context, 'منحدر', 'Ramp'),
        ),
      if (features.hasSuitableElevator() && features.suitableElevator)
        (
          icon: Icons.elevator_rounded,
          label: S.t(context, 'مصعد', 'Elevator'),
        ),
      if (features.hasAccessibleRestroom() && features.accessibleRestroom)
        (
          icon: Icons.wc_rounded,
          label: S.t(context, 'حمام مجهز', 'Restroom'),
        ),
      if (features.hasAccessibleParking() && features.accessibleParking)
        (
          icon: Icons.local_parking_rounded,
          label: S.t(context, 'موقف سيارات', 'Parking'),
        ),
    ];

    final Color tierTextColor;
    if (isDark) {
      switch (compat.level) {
        case AccessibilityLevel.full:
          tierTextColor = theme.success;
        case AccessibilityLevel.partial:
          tierTextColor = theme.warning;
        case AccessibilityLevel.limited:
          tierTextColor = theme.error;
      }
    } else {
      tierTextColor = compat.color;
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.divider),
        boxShadow: [
          BoxShadow(
            blurRadius: 16,
            color: theme.shadow.withValues(alpha: isDark ? 0.24 : 0.06),
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photo Banner with Overlaid Badges
              SizedBox(
                height: isCompact ? 148 : 168,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _PlaceCardPhoto(
                      photoUrl: place.photoUrl,
                      catSpec: catSpec,
                      theme: theme,
                    ),
                    // Subtle scrim for crisp overlay readability
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.22),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.62),
                            ],
                            stops: const [0.0, 0.42, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // Top row: Compatibility Badge + Rating Pill
                    Positioned(
                      top: 12,
                      left: 12,
                      right: 12,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: CompatibilityBadge(
                              result: compat,
                              compact: isCompact,
                            ),
                          ),
                          if (place.rating > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.62),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.16),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star_rounded,
                                    size: 15,
                                    color: theme.gold,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    place.rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Bottom row: Category Tag + Verification Pill
                    Positioned(
                      bottom: 10,
                      left: 12,
                      right: 12,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (place.category.isNotEmpty)
                            Flexible(
                              flex: 3,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.56),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.18),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      catSpec?.icon ?? Icons.place_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: Text(
                                        place.category,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            const SizedBox.shrink(),
                          const SizedBox(width: 8),
                          Flexible(
                            flex: 2,
                            child: _CompactVerificationPill(
                              status: place.effectiveVerificationStatus,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Card Content Body
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name.isEmpty
                          ? S.t(context, 'مكان بدون اسم', 'Unnamed Place')
                          : place.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.titleMedium.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: theme.primaryText,
                        height: 1.3,
                      ),
                    ),
                    if (locationText.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.location_on_rounded,
                              size: 15,
                              color: theme.primary,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              locationText,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.bodySmall.copyWith(
                                fontSize: 13,
                                color: theme.secondaryText,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (place.openingHours.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 14,
                            color: theme.secondaryText,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              place.openingHours,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.bodySmall.copyWith(
                                fontSize: 12.5,
                                color: theme.secondaryText,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),

                    // Accessibility Feature Pills
                    if (featurePills.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: featurePills
                            .map(
                              (pill) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.primary
                                      .withValues(alpha: isDark ? 0.16 : 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: theme.primary.withValues(alpha: 0.22),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      pill.icon,
                                      size: 13.5,
                                      color: theme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      pill.label,
                                      style: theme.bodySmall.copyWith(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: theme.primary,
                                        height: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: theme.surfaceVariant,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          S.t(
                            context,
                            'تفاصيل الإتاحة قيد الاستكمال',
                            'Accessibility details pending',
                          ),
                          style: theme.bodySmall.copyWith(
                            fontSize: 11.5,
                            color: theme.secondaryText,
                          ),
                        ),
                      ),

                    const SizedBox(height: 12),
                    Divider(height: 1, color: theme.divider),
                    const SizedBox(height: 10),

                    // Footer: Accessibility Tier + Quick Directions + Details CTA
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: tierTextColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${compat.levelLabel(context)} · ${compat.availableCount}/${compat.totalFeatures}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.labelMedium.copyWith(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: tierTextColor,
                            ),
                          ),
                        ),
                        if (place.hasLocation()) ...[
                          const SizedBox(width: 8),
                          Semantics(
                            button: true,
                            label: S.t(context, 'الاتجاهات', 'Directions'),
                            child: Material(
                              color: theme.surfaceVariant,
                              borderRadius: BorderRadius.circular(10),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () => _openDirections(context),
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Icon(
                                    Icons.directions_rounded,
                                    size: 18,
                                    color: theme.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: theme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                S.t(context, 'التفاصيل', 'Details'),
                                style: theme.labelMedium.copyWith(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: theme.onPrimary,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(width: 3),
                              Icon(
                                isEn
                                    ? Icons.chevron_right_rounded
                                    : Icons.chevron_left_rounded,
                                size: 16,
                                color: theme.onPrimary,
                              ),
                            ],
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
}

class _PlaceCardPhoto extends StatelessWidget {
  const _PlaceCardPhoto({
    required this.photoUrl,
    required this.catSpec,
    required this.theme,
  });

  final String photoUrl;
  final PlaceCategorySpec? catSpec;
  final FlutterFlowTheme theme;

  Widget _buildFallback() {
    final asset = catSpec?.fallbackAsset;
    if (asset != null) {
      return Image.asset(
        asset,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _CategoryGradientArt(
          catSpec: catSpec,
          theme: theme,
        ),
      );
    }
    return _CategoryGradientArt(catSpec: catSpec, theme: theme);
  }

  @override
  Widget build(BuildContext context) {
    final trimmed = photoUrl.trim();
    if (trimmed.isEmpty) {
      return _buildFallback();
    }
    return Image.network(
      trimmed,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _CategoryGradientArt(catSpec: catSpec, theme: theme);
      },
      errorBuilder: (_, __, ___) => _buildFallback(),
    );
  }
}

/// Clean branded fallback backdrop when a photo URL is empty or offline.
class _CategoryGradientArt extends StatelessWidget {
  const _CategoryGradientArt({
    required this.catSpec,
    required this.theme,
  });

  final PlaceCategorySpec? catSpec;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    final accent = catSpec?.accentColor ?? theme.primary;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            theme.navy,
            Color.lerp(theme.navyLight, accent, 0.42) ?? theme.primary,
          ],
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
          child: Icon(
            catSpec?.icon ?? Icons.location_city_rounded,
            size: 40,
            color: Colors.white.withValues(alpha: 0.88),
          ),
        ),
      ),
    );
  }
}

class _CompactVerificationPill extends StatelessWidget {
  const _CompactVerificationPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isVerified = status == 'verified';
    final label = switch (status) {
      'verified' => S.t(context, 'موثق ميدانياً', 'Verified'),
      'osmImported' => S.t(context, 'خرائط مفتوحة', 'OpenStreetMap'),
      'googleImported' => S.t(context, 'خرائط Google', 'Google Places'),
      'pendingFieldAudit' => S.t(context, 'بانتظار فحص ميداني', 'Pending Audit'),
      'needsUpdate' => S.t(context, 'يحتاج تحديث', 'Needs Update'),
      'reportUnderReview' => S.t(context, 'قيد المراجعة', 'Under Review'),
      _ => S.t(context, 'قيد المراجعة', 'Pending'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isVerified
            ? const Color(0xFF15803D)
            : Colors.black.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: isVerified ? 0.3 : 0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVerified ? Icons.verified_rounded : Icons.info_outline_rounded,
            size: 12.5,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExplorerLoadingSkeleton extends StatelessWidget {
  const _ExplorerLoadingSkeleton({required this.theme});

  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 150,
            color: theme.surfaceVariant,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 18,
                  width: 190,
                  decoration: BoxDecoration(
                    color: theme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 13,
                  width: 240,
                  decoration: BoxDecoration(
                    color: theme.surfaceVariant,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      height: 26,
                      width: 72,
                      decoration: BoxDecoration(
                        color: theme.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 26,
                      width: 84,
                      decoration: BoxDecoration(
                        color: theme.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExplorerEmptyState extends StatelessWidget {
  const _ExplorerEmptyState({
    required this.theme,
    required this.activeSpec,
    required this.customCategory,
    required this.isDatabaseEmpty,
    required this.hasActiveFilters,
    required this.onResetFilters,
    required this.onSuggestPlace,
  });

  final FlutterFlowTheme theme;
  final PlaceCategorySpec? activeSpec;
  final String? customCategory;
  final bool isDatabaseEmpty;
  final bool hasActiveFilters;
  final VoidCallback onResetFilters;
  final VoidCallback onSuggestPlace;

  @override
  Widget build(BuildContext context) {
    final accent = activeSpec?.accentColor ?? theme.primary;
    final catName = activeSpec?.label(context) ?? customCategory;

    final title = isDatabaseEmpty
        ? S.t(context, 'لا توجد أماكن مضافة بعد', 'No places added yet')
        : catName != null && catName.isNotEmpty
            ? S.t(
                context,
                'لا توجد أماكن في «$catName» حالياً',
                'No places in "$catName" yet',
              )
            : S.t(
                context,
                'لا توجد نتائج مطابقة لبحثك',
                'No matching places found',
              );

    final subtitle = isDatabaseEmpty
        ? (currentUserIsAdmin
            ? S.t(
                context,
                'افتح لوحة الإدارة لإضافة أماكن جديدة أو مراجعة واعتماد طلبات أصحاب الأماكن.',
                'Open Admin Dashboard to add places or approve place owner registrations.',
              )
            : S.t(
                context,
                'الأماكن المهيأة ستظهر هنا فور تسجيلها ومراجعتها من فريق الإدارة.',
                'Verified accessible places will appear here as soon as they are published.',
              ))
        : S.t(
            context,
            'جرّب إزالة بعض الفلاتر أو استكشف كل التصنيفات، أو اقترح مكاناً مهيأً تعرفه!',
            'Try clearing filters, browsing all categories, or suggesting an accessible place you know.',
          );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.divider),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              activeSpec?.icon ?? Icons.search_off_rounded,
              size: 36,
              color: accent,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.titleMedium.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.bodyMedium.copyWith(
              fontSize: 13.5,
              color: theme.secondaryText,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 20),
          if (hasActiveFilters && !isDatabaseEmpty) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const Key('empty_state_show_all_btn'),
                onPressed: onResetFilters,
                icon: const Icon(Icons.grid_view_rounded, size: 19),
                label: Text(
                  S.t(context, 'عرض كل الأماكن', 'Browse All Places'),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onSuggestPlace,
              icon: const Icon(Icons.add_location_alt_outlined, size: 19),
              label: Text(
                S.t(context, 'اقترح مكاناً مهيأً جديداً',
                    'Suggest an Accessible Place'),
              ),
            ),
          ),
          if (isDatabaseEmpty && currentUserIsAdmin) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () => context.pushNamed(AdminDashboardPage.routeName),
                icon: const Icon(Icons.admin_panel_settings_outlined),
                label: Text(
                  S.t(
                    context,
                    'إدارة وإضافة الأماكن (لوحة الإدارة)',
                    'Manage Places (Admin)',
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExplorerErrorCard extends StatelessWidget {
  const _ExplorerErrorCard({
    required this.theme,
    required this.error,
    required this.hPad,
    required this.onRetry,
  });

  final FlutterFlowTheme theme;
  final Object? error;
  final double hPad;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 24, hPad, 32),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.divider),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: theme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_off_rounded,
                size: 32,
                color: theme.error,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              S.t(
                context,
                'تعذر تحميل الأماكن حالياً',
                'Could not load places right now',
              ),
              textAlign: TextAlign.center,
              style: theme.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.primaryText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              S.t(
                context,
                'تحقق من اتصالك بالإنترنت ثم أعد المحاولة.',
                'Please check your connection and try again.',
              ),
              textAlign: TextAlign.center,
              style: theme.bodySmall.copyWith(
                color: theme.secondaryText,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(S.t(context, 'إعادة المحاولة', 'Try Again')),
            ),
          ],
        ),
      ),
    );
  }
}
