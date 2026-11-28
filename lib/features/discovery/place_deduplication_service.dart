import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/places_record.dart';
import '/core/utils/arabic_normalizer.dart';
import '/features/discovery/places_repository.dart';

/// Classification of a potential duplicate match against existing places.
enum DuplicateMatchKind {
  /// Place is already registered AND linked to an official Place Owner (`business_id`).
  alreadyOwnedByBusiness,

  /// Place exists on the map (e.g. from community suggestion or admin) without an owner yet.
  existingUnownedPlace,
}

class DuplicatePlaceMatch {
  const DuplicatePlaceMatch({
    required this.place,
    required this.kind,
    required this.reasonAr,
  });

  final PlacesRecord place;
  final DuplicateMatchKind kind;
  final String reasonAr;

  bool get isOwned => kind == DuplicateMatchKind.alreadyOwnedByBusiness;
}

/// Prevents duplicate place uploads across BOTH Community Suggestions
/// (`SuggestPlacePage`) and Place Owner Registration (`BusinessRegistrationWidget`),
/// and enables official Place Owners to claim & upgrade an existing community-suggested
/// place instead of creating a duplicate document.
class PlaceDeduplicationService {
  PlaceDeduplicationService._();

  static String _normName(String raw) {
    return ArabicNormalizer.normalize(raw)
        .replaceAll(RegExp(r'[^\u0600-\u06FFa-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _normDigits(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('20') && digits.length == 12) {
      return '0${digits.substring(2)}';
    }
    return digits;
  }

  /// Pure, deterministic matcher (easily unit-tested without Firestore).
  static DuplicatePlaceMatch? findMatchInList({
    required List<PlacesRecord> existingPlaces,
    required String candidateName,
    String? candidateGovernorate,
    String? candidateAddress,
    String? candidatePhone,
    GeoPoint? candidateLocation,
  }) {
    final targetName = _normName(candidateName);
    if (targetName.length < 2) return null;

    final targetPhone = _normDigits(candidatePhone ?? '');
    final targetGov = _normName(candidateGovernorate ?? '');
    final targetAddr = _normName(candidateAddress ?? '');

    for (final place in existingPlaces) {
      final pName = _normName(place.name);
      if (pName.isEmpty) continue;

      final pPhone = _normDigits(place.phoneNumber);
      final pGov = _normName('${place.governorate} ${place.city}');
      final pAddr = _normName(place.address);

      // 1. Exact phone match + similar name
      final phoneMatches = targetPhone.length >= 8 &&
          pPhone.length >= 8 &&
          targetPhone == pPhone;

      // 2. Spatial proximity (< 150 meters)
      double? distMeters;
      if (candidateLocation != null && place.hasLocation()) {
        distMeters = PlacesRepository.haversineKm(
              candidateLocation.latitude,
              candidateLocation.longitude,
              place.location!.latitude,
              place.location!.longitude,
            ) *
            1000.0;
      }
      final isVeryClose = distMeters != null && distMeters <= 150.0;

      // 3. Name similarity (exact normalized match or strong containment)
      final exactName = pName == targetName;
      final strongContains = (pName.length >= 6 &&
              targetName.length >= 6 &&
              (pName.contains(targetName) || targetName.contains(pName)));

      // 4. Same governorate/area check (so two branches of a chain in Cairo vs Alex don't collide unless GPS is close)
      final sameRegion = targetGov.isEmpty ||
          pGov.isEmpty ||
          pGov.contains(targetGov) ||
          targetGov.contains(pGov) ||
          (targetAddr.isNotEmpty && pAddr.contains(targetAddr));

      bool isDuplicate = false;
      String reason = '';

      if (exactName && isVeryClose) {
        isDuplicate = true;
        reason = 'تطابق الاسم والموقع الجغرافي على الخريطة';
      } else if (phoneMatches && (exactName || strongContains)) {
        isDuplicate = true;
        reason = 'تطابق اسم المكان ورقم التواصل المسجّل';
      } else if (exactName && sameRegion && (distMeters == null || distMeters <= 500)) {
        isDuplicate = true;
        reason = 'نفس اسم المكان مسجّل في نفس المحافظة / المنطقة';
      } else if (strongContains && isVeryClose) {
        isDuplicate = true;
        reason = 'يوجد مكان مسجّل بنفس الاسم تقريباً في نفس النقطة الجغرافية';
      }

      if (isDuplicate) {
        final hasOwner = place.businessId.trim().isNotEmpty;
        return DuplicatePlaceMatch(
          place: place,
          kind: hasOwner
              ? DuplicateMatchKind.alreadyOwnedByBusiness
              : DuplicateMatchKind.existingUnownedPlace,
          reasonAr: reason,
        );
      }
    }

    return null;
  }

  /// Queries cached/verified places and returns a [DuplicatePlaceMatch] if found.
  static Future<DuplicatePlaceMatch?> checkDuplicateAgainstPublishedPlaces({
    required String candidateName,
    String? candidateGovernorate,
    String? candidateAddress,
    String? candidatePhone,
    GeoPoint? candidateLocation,
  }) async {
    try {
      final places =
          await PlacesRepository.instance.getVerifiedPlaces(limit: 100);
      return findMatchInList(
        existingPlaces: places,
        candidateName: candidateName,
        candidateGovernorate: candidateGovernorate,
        candidateAddress: candidateAddress,
        candidatePhone: candidatePhone,
        candidateLocation: candidateLocation,
      );
    } catch (_) {
      return null;
    }
  }
}
