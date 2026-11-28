import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_way_egypt/backend/schema/places_record.dart';
import 'package:one_way_egypt/core/notifications/push_notification_service.dart';
import 'package:one_way_egypt/core/utils/image_compression_service.dart';
import 'package:one_way_egypt/features/discovery/places_repository.dart';

void main() {
  group('PlacesRepository — Geohashing & TTL Caching', () {
    setUp(() {
      PlacesRepository.instance.invalidateCache();
    });

    test('buildGeoField generates standard 9-character geohash and geopoint', () {
      final geo = PlacesRepository.buildGeoField(30.0444, 31.2357);
      expect(geo['geohash'], isA<String>());
      expect((geo['geohash'] as String).length, 9);
      expect(geo['geopoint'], isA<GeoPoint>());
      final gp = geo['geopoint'] as GeoPoint;
      expect(gp.latitude, closeTo(30.0444, 0.0001));
      expect(gp.longitude, closeTo(31.2357, 0.0001));
    });

    test('haversineKm computes accurate distance between Cairo and Mall of Egypt', () {
      final km = PlacesRepository.haversineKm(
        30.0444,
        31.2357, // Downtown Cairo
        29.9722,
        31.0163, // Mall of Egypt
      );
      expect(km, inInclusiveRange(21.0, 24.0));
      expect(PlacesRepository.haversineKm(30.0, 31.0, 30.0, 31.0), 0.0);
    });

    test('getVerifiedPlaces returns cached results without touching Firestore', () async {
      final fakeDocs = <PlacesRecord>[];
      PlacesRepository.instance.seedCacheForTest(fakeDocs);

      final result = await PlacesRepository.instance.getVerifiedPlaces(limit: 10);
      expect(result, isEmpty);
    });
  });

  group('ImageCompressionService — Safe On-Device Optimization', () {
    test('returns empty and tiny payloads safely without throwing', () async {
      final empty = await ImageCompressionService.compressForUpload(Uint8List(0));
      expect(empty, isEmpty);

      final tiny = Uint8List.fromList(List<int>.filled(1024, 42));
      final out = await ImageCompressionService.compressForUpload(tiny);
      expect(out.length, 1024);
    });
  });

  group('PushNotificationService — Deduplication', () {
    setUp(() {
      PushNotificationService.instance.resetDeduplicationForTest();
    });

    test('shouldDeliverOnce prevents duplicate OS banners from FCM + Firestore bridge', () {
      final svc = PushNotificationService.instance;
      expect(svc.shouldDeliverOnce('notif_123'), isTrue);
      expect(svc.shouldDeliverOnce('notif_123'), isFalse);
      expect(svc.shouldDeliverOnce('notif_456'), isTrue);
      expect(svc.shouldDeliverOnce(''), isTrue);
    });
  });
}
