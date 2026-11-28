import 'package:flutter/material.dart';

import '/backend/schema/places_record.dart';
import '/core/utils/arabic_normalizer.dart';
import '/l10n/app_strings.dart';

/// Canonical definition for a ONEWAY place category so Home, Explorer, Map,
/// and AI Assistant resolve aliases (e.g., `مستشف`, `طبي`, `طبي ومستشفيات`,
/// `hospital`) to the exact same icon, accent color, localized title, and filter.
class PlaceCategorySpec {
  const PlaceCategorySpec({
    required this.id,
    required this.labelAr,
    required this.labelEn,
    required this.titleAr,
    required this.titleEn,
    required this.icon,
    required this.accentColor,
    required this.keywords,
    required this.mapQuery,
    this.fallbackAsset,
  });

  final String id;
  final String labelAr;
  final String labelEn;
  final String titleAr;
  final String titleEn;
  final IconData icon;
  final Color accentColor;
  final List<String> keywords;
  final String mapQuery;
  final String? fallbackAsset;

  String label(BuildContext context) => S.t(context, labelAr, labelEn);

  String title(BuildContext context) => S.t(context, titleAr, titleEn);

  bool matchesText(String raw) {
    final norm = ArabicNormalizer.normalize(raw);
    if (norm.isEmpty) return false;
    if (norm == id) return true;
    for (final kw in keywords) {
      final kwNorm = ArabicNormalizer.normalize(kw);
      if (kwNorm.isEmpty) continue;
      if (norm.contains(kwNorm)) return true;
      if (norm.length >= 3 && kwNorm.contains(norm)) return true;
    }
    return false;
  }

  bool matchesPlace(PlacesRecord place) {
    if (matchesText(place.category)) return true;
    final combined = ArabicNormalizer.normalize(
      '${place.name} ${place.category}',
    );
    for (final kw in keywords) {
      final kwNorm = ArabicNormalizer.normalize(kw);
      if (kwNorm.length >= 3 && combined.contains(kwNorm)) {
        return true;
      }
    }
    return false;
  }
}

class PlaceCategoryCatalog {
  PlaceCategoryCatalog._();

  static const List<PlaceCategorySpec> presets = [
    PlaceCategorySpec(
      id: 'medical',
      labelAr: 'مستشفيات',
      labelEn: 'Hospitals',
      titleAr: 'المستشفيات والمراكز الطبية',
      titleEn: 'Hospitals & Medical Centers',
      icon: Icons.local_hospital_rounded,
      accentColor: Color(0xFFD9385A),
      keywords: [
        'مستشف',
        'طبي',
        'عياد',
        'صيدل',
        'صحه',
        'صحي',
        'علاج',
        'hospital',
        'medical',
        'clinic',
        'health',
      ],
      mapQuery: 'طبي',
    ),
    PlaceCategorySpec(
      id: 'shopping',
      labelAr: 'تسوق',
      labelEn: 'Malls',
      titleAr: 'التسوق والمراكز التجارية',
      titleEn: 'Shopping & Malls',
      icon: Icons.shopping_bag_rounded,
      accentColor: Color(0xFF7C3AED),
      keywords: [
        'تسوق',
        'مول',
        'تجاري',
        'سوق',
        'mall',
        'shopping',
        'shop',
      ],
      mapQuery: 'تسوق',
      fallbackAsset: 'assets/images/place_mall.jpg',
    ),
    PlaceCategorySpec(
      id: 'transit',
      labelAr: 'مواصلات',
      labelEn: 'Transit',
      titleAr: 'المواصلات والمحطات',
      titleEn: 'Transit & Stations',
      icon: Icons.directions_transit_rounded,
      accentColor: Color(0xFF2563EB),
      keywords: [
        'مواصلات',
        'نقل',
        'مترو',
        'قطار',
        'محط',
        'transit',
        'metro',
        'train',
        'station',
        'transport',
      ],
      mapQuery: 'مواصلات',
      fallbackAsset: 'assets/images/place_metro.jpg',
    ),
    PlaceCategorySpec(
      id: 'culture',
      labelAr: 'سياحة وثقافة',
      labelEn: 'Culture',
      titleAr: 'السياحة والثقافة',
      titleEn: 'Culture & Tourism',
      icon: Icons.museum_rounded,
      accentColor: Color(0xFFD97706),
      keywords: [
        'ثقاف',
        'سياح',
        'متحف',
        'مكتب',
        'اثار',
        'culture',
        'museum',
        'tourism',
        'library',
      ],
      mapQuery: 'ثقاف',
      fallbackAsset: 'assets/images/place_museum.jpg',
    ),
    PlaceCategorySpec(
      id: 'education',
      labelAr: 'تعليم',
      labelEn: 'Education',
      titleAr: 'التعليم والجامعات',
      titleEn: 'Education & Universities',
      icon: Icons.school_rounded,
      accentColor: Color(0xFF059669),
      keywords: [
        'تعليم',
        'جامع',
        'مدرس',
        'كلي',
        'معهد',
        'education',
        'university',
        'school',
        'college',
      ],
      mapQuery: 'تعليم',
    ),
    PlaceCategorySpec(
      id: 'dining',
      labelAr: 'مطاعم',
      labelEn: 'Dining',
      titleAr: 'المطاعم والكافيهات',
      titleEn: 'Restaurants & Cafes',
      icon: Icons.restaurant_rounded,
      accentColor: Color(0xFFEA580C),
      keywords: [
        'مطعم',
        'مطاعم',
        'كافيه',
        'مقهي',
        'restaurant',
        'cafe',
        'dining',
        'food',
      ],
      mapQuery: 'مطعم',
    ),
    PlaceCategorySpec(
      id: 'facilities',
      labelAr: 'مرافق عامة',
      labelEn: 'Facilities',
      titleAr: 'المرافق والخدمات العامة',
      titleEn: 'Public Facilities & Services',
      icon: Icons.home_repair_service_rounded,
      accentColor: Color(0xFF0E7C77),
      keywords: [
        'مرافق',
        'خدم',
        'حكوم',
        'بنك',
        'حديق',
        'فندق',
        'facilities',
        'public',
        'service',
        'park',
        'bank',
        'hotel',
      ],
      mapQuery: 'مرافق',
    ),
  ];

  /// Resolves any raw query or Firestore category string to its matching
  /// canonical [PlaceCategorySpec], or `null` if none matches.
  static PlaceCategorySpec? resolve(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    for (final spec in presets) {
      if (spec.matchesText(raw)) return spec;
    }
    return null;
  }

  /// Resolves a [PlaceCategorySpec] for a specific [PlacesRecord].
  static PlaceCategorySpec? forPlace(PlacesRecord place) {
    final direct = resolve(place.category);
    if (direct != null) return direct;
    for (final spec in presets) {
      if (spec.matchesPlace(place)) return spec;
    }
    return null;
  }
}
