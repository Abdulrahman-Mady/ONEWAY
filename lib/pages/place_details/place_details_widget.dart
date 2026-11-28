import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '/backend/schema/places_record.dart';
import '/features/discovery/discovery_pages.dart' show PlaceDetailPage;
import '/flutter_flow/flutter_flow_theme.dart';
import '/index.dart';
export 'place_details_model.dart';

/// Real-data PlaceDetails route wrapper supporting both in-memory `PlacesRecord`
/// (`place` / `extra`) and deep-linked `?id=<placeId>` URLs across web & mobile.
class PlaceDetailsWidget extends StatelessWidget {
  const PlaceDetailsWidget({
    super.key,
    this.place,
    this.placeId,
  });

  final PlacesRecord? place;
  final String? placeId;

  static String routeName = 'PlaceDetails';
  static String routePath = '/place-details';

  @override
  Widget build(BuildContext context) {
    if (place != null) {
      return PlaceDetailPage(place: place!);
    }

    GoRouterState? state;
    try {
      state = GoRouterState.of(context);
    } catch (_) {
      state = null;
    }
    final extra = state?.extra;
    if (extra is PlacesRecord) {
      return PlaceDetailPage(place: extra);
    }

    final resolvedId = (placeId != null && placeId!.trim().isNotEmpty)
        ? placeId!.trim()
        : state?.uri.queryParameters['id']?.trim();

    if (resolvedId != null && resolvedId.isNotEmpty) {
      final theme = FlutterFlowTheme.of(context);
      return FutureBuilder<PlacesRecord>(
        future: PlacesRecord.getDocumentOnce(
          PlacesRecord.collection.doc(resolvedId),
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              backgroundColor: theme.background,
              appBar: AppBar(
                backgroundColor: theme.navy,
                foregroundColor: Colors.white,
                title: const Text('تفاصيل المكان'),
              ),
              body: const Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData && snapshot.data!.name.isNotEmpty) {
            return PlaceDetailPage(place: snapshot.data!);
          }
          return _buildEmptyFallback(context);
        },
      );
    }

    return _buildEmptyFallback(context);
  }

  Widget _buildEmptyFallback(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.background,
        appBar: AppBar(
          backgroundColor: theme.navy,
          foregroundColor: Colors.white,
          title: const Text('تفاصيل المكان'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.place_outlined, size: 54, color: theme.primary),
                const SizedBox(height: 14),
                Text(
                  'اختر مكاناً لعرض تفاصيل الإتاحة الخاصة به',
                  textAlign: TextAlign.center,
                  style: theme.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.primaryText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'تصفح الأماكن الموثقة على الخريطة أو قائمة الاستكشاف لعرض الصور ومميزات الوصول والتقييمات.',
                  textAlign: TextAlign.center,
                  style: theme.bodyMedium.copyWith(
                    color: theme.secondaryText,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () =>
                      context.goNamed(SearchFiltersWidget.routeName),
                  icon: const Icon(Icons.explore_outlined),
                  label: const Text('استكشاف الأماكن'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
