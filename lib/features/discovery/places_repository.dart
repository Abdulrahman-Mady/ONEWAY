import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';

import '/backend/schema/places_record.dart';
import '/core/network/connectivity_service.dart';

/// Centralized, quota-conscious repository for reading verified accessible
/// places using:
/// 1. Geohash spatial radius queries (`geoflutterfire_plus`) for map views.
/// 2. Shared in-memory TTL caching (5 minutes) so switching between Home, Map,
///    Place Explorer, and Voice Assistant costs ZERO extra Firestore reads.
/// 3. Bounded queries (`.limit(...)`) and Firestore offline cache-first reads.
class PlacesRepository {
  PlacesRepository._();

  static final PlacesRepository instance = PlacesRepository._();

  static const Duration cacheTtl = Duration(minutes: 5);
  static const int defaultBoundedLimit = 50;

  List<PlacesRecord>? _verifiedCache;
  DateTime? _verifiedCachedAt;

  List<PlacesRecord>? _nearbyCache;
  DateTime? _nearbyCachedAt;
  double? _nearbyLat;
  double? _nearbyLng;
  double? _nearbyRadiusKm;

  /// Builds the standard `geoflutterfire_plus` `{geohash, geopoint}` map to
  /// store under the `geo` field on every new or updated place document.
  static Map<String, dynamic> buildGeoField(double latitude, double longitude) {
    return GeoFirePoint(GeoPoint(latitude, longitude)).data;
  }

  /// Clears all cached place lists (e.g. after Admin creates/edits a place).
  void invalidateCache() {
    _verifiedCache = null;
    _verifiedCachedAt = null;
    _nearbyCache = null;
    _nearbyCachedAt = null;
    _nearbyLat = null;
    _nearbyLng = null;
    _nearbyRadiusKm = null;
  }

  @visibleForTesting
  void seedCacheForTest(List<PlacesRecord> places, {DateTime? cachedAt}) {
    _verifiedCache = List<PlacesRecord>.unmodifiable(places);
    _verifiedCachedAt = cachedAt ?? DateTime.now();
  }

  bool _isFresh(DateTime? timestamp) {
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < cacheTtl;
  }

  /// Returns verified places from the shared TTL cache (or runs a single
  /// bounded query with `.limit(limit)` when expired or [forceRefresh] is true).
  Future<List<PlacesRecord>> getVerifiedPlaces({
    int limit = defaultBoundedLimit,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _verifiedCache != null &&
        _isFresh(_verifiedCachedAt)) {
      return _verifiedCache!.take(limit).toList(growable: false);
    }

    final query = PlacesRecord.collection
        .where('verification_status', isEqualTo: 'verified')
        .limit(limit);

    QuerySnapshot<Map<String, dynamic>> snapshot;
    if (ConnectivityService.instance.isOffline) {
      // Offline mode: read instantly from local 50MB disk cache without hanging.
      snapshot = await query.get(const GetOptions(source: Source.cache));
    } else {
      try {
        snapshot = await query
            .get(const GetOptions(source: Source.serverAndCache))
            .timeout(const Duration(seconds: 6));
      } catch (_) {
        // Offline / slow-network resilience: fall back cleanly to local disk cache.
        snapshot = await query.get(const GetOptions(source: Source.cache));
      }
    }

    final places = snapshot.docs
        .map(PlacesRecord.fromSnapshot)
        .toList(growable: false);

    // Only replace the shared cache if this fetch isn't smaller than existing cache
    if (_verifiedCache == null ||
        forceRefresh ||
        limit >= (_verifiedCache?.length ?? 0)) {
      _verifiedCache = places;
      _verifiedCachedAt = DateTime.now();
    }

    return places;
  }

  /// Queries verified places within [radiusKm] around ([latitude], [longitude])
  /// using Geohashing (`geoflutterfire_plus`), with a spatial TTL cache and
  /// automatic bounded fallback for legacy documents that do not yet carry a
  /// `geo.geohash` field.
  Future<List<PlacesRecord>> getNearbyVerifiedPlaces({
    required double latitude,
    required double longitude,
    double radiusKm = 30.0,
    int fallbackLimit = defaultBoundedLimit,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _nearbyCache != null &&
        _isFresh(_nearbyCachedAt) &&
        _nearbyLat != null &&
        _nearbyLng != null &&
        _nearbyRadiusKm == radiusKm &&
        haversineKm(_nearbyLat!, _nearbyLng!, latitude, longitude) < 2.0) {
      return _nearbyCache!;
    }

    List<PlacesRecord> results = const [];
    try {
      final geoRef = GeoCollectionReference<Map<String, dynamic>>(
        PlacesRecord.collection,
      );
      final geoDocs = await geoRef.fetchWithinWithDistance(
        center: GeoFirePoint(GeoPoint(latitude, longitude)),
        radiusInKm: radiusKm,
        field: 'geo',
        geopointFrom: (data) {
          final geo = data['geo'];
          if (geo is Map<String, dynamic> && geo['geopoint'] is GeoPoint) {
            return geo['geopoint'] as GeoPoint;
          }
          final loc = data['location'];
          if (loc is GeoPoint) return loc;
          return const GeoPoint(30.0444, 31.2357);
        },
        queryBuilder: (q) =>
            q.where('verification_status', isEqualTo: 'verified'),
        strictMode: true,
        isCacheFirst: !forceRefresh,
      );

      if (geoDocs.isNotEmpty) {
        geoDocs.sort((a, b) => a.distanceFromCenterInKm
            .compareTo(b.distanceFromCenterInKm));
        results = geoDocs
            .map((g) => PlacesRecord.fromSnapshot(g.documentSnapshot))
            .where((p) => p.location != null)
            .toList(growable: false);
      }
    } catch (e) {
      // Missing composite index or legacy docs without `geo`: fall through.
      debugPrint('Geohash query fallback to bounded verified list: $e');
    }

    // Fallback: bounded verified places sorted by distance from center so
    // pre-geohash documents remain seamlessly visible on the map.
    if (results.isEmpty) {
      final bounded = await getVerifiedPlaces(
        limit: fallbackLimit,
        forceRefresh: forceRefresh,
      );
      final withLoc = bounded.where((p) => p.location != null).toList();
      withLoc.sort((a, b) {
        final da = haversineKm(
            latitude, longitude, a.location!.latitude, a.location!.longitude);
        final db = haversineKm(
            latitude, longitude, b.location!.latitude, b.location!.longitude);
        return da.compareTo(db);
      });
      results = withLoc;
    }

    _nearbyCache = results;
    _nearbyCachedAt = DateTime.now();
    _nearbyLat = latitude;
    _nearbyLng = longitude;
    _nearbyRadiusKm = radiusKm;
    return results;
  }

  /// Great-circle distance in kilometers between two coordinates.
  static double haversineKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLng = _degToRad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degToRad(double deg) => deg * math.pi / 180.0;
}
