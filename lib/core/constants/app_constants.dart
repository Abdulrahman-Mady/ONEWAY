import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// SharedPreferences keys, official support contacts, and application-wide
/// constants for ONEWAY.
class AppConstants {
  AppConstants._();

  static const String appNameAr = 'ONEWAY — مصر بدون عوائق';
  static const String appNameEn = 'ONEWAY — Barrier-Free Egypt';
  static const String taglineAr = 'اعرف المكان قبل ما تروح';
  static const String taglineEn = 'Know Before You Go';

  // Official direct support & business channels
  static const String supportEmail = 'bdalrhmnmady93@gmail.com';
  static const String businessEmail = 'bdalrhmnmady93@gmail.com';
  static const String supportWhatsAppNumber = '01023266750';
  static const String supportWhatsAppIntl = '201023266750';

  // SharedPreferences persistence keys
  static const String kOnboardingSeenKey = 'onboarding_seen_v1';
  static const String kPendingMobilityTypeKey = 'oneway_pending_mobility_type';
  static const String kPendingAccessNeedsKey = 'oneway_pending_access_needs';
  static const String kAnalyticsConsentKey = 'oneway_analytics_consent';
  static const String kReducedMotionOverrideKey = 'oneway_reduced_motion';

  // Accessibility compliance bounds (WCAG 2.2 AA 1.4.4 supports up to 200% text resize)
  static const double minTouchTargetSize = 48.0;
  static const double minFontScale = 0.85;
  static const double maxFontScale = 2.0;
  static const double wcagAAMinContrast = 4.5;
  static const double wcagAALargeTextContrast = 3.0;

  // Canonical 3-role model: Regular User, Place Owner, Platform Admin
  static const List<String> validUserRoles = [
    'user',
    'businessOwner',
    'admin',
  ];

  // Production-configurable Map Tile Server (supports MapTiler / Mapbox / Stadia via --dart-define)
  static const String mapTileUrlTemplate = String.fromEnvironment(
    'MAP_TILE_URL',
    defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  );
  static const String mapUserAgentPackage = 'com.onewayegypt.app';
  static const String mapAttributionText = '© OpenStreetMap contributors';

  /// Opens the user's email client directly addressed to [supportEmail].
  static Future<bool> launchSupportEmail({
    String? subject,
    String? body,
  }) async {
    final queryParams = <String, String>{
      if (subject != null && subject.trim().isNotEmpty) 'subject': subject.trim(),
      if (body != null && body.trim().isNotEmpty) 'body': body.trim(),
    };
    final query = queryParams.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    final uri = Uri.parse(
      query.isEmpty ? 'mailto:$supportEmail' : 'mailto:$supportEmail?$query',
    );
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  /// Opens WhatsApp chat directly with [supportWhatsAppNumber] (`+201023266750`).
  static Future<bool> launchSupportWhatsApp({String? message}) async {
    final textParam = (message != null && message.trim().isNotEmpty)
        ? '?text=${Uri.encodeComponent(message.trim())}'
        : '';
    final uri = Uri.parse('https://wa.me/$supportWhatsAppIntl$textParam');
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  /// Dials [supportWhatsAppNumber] via phone dialer.
  static Future<bool> launchSupportPhoneCall() async {
    final uri = Uri(scheme: 'tel', path: supportWhatsAppNumber);
    try {
      return await launchUrl(uri);
    } catch (_) {
      return false;
    }
  }
}

/// Concrete physical access needs (Step 2 of 3 in ONEWAY's needs-based
/// personalization). Separates what the user actually needs in a venue from
/// disability labels.
class AccessNeedOption {
  const AccessNeedOption({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.subtitleAr,
    required this.subtitleEn,
    required this.icon,
  });

  final String id;
  final String titleAr;
  final String titleEn;
  final String subtitleAr;
  final String subtitleEn;
  final IconData icon;

  static const List<AccessNeedOption> all = [
    AccessNeedOption(
      id: 'step_free_entrance',
      titleAr: 'مدخل بدون درجات',
      titleEn: 'Step-free entrance',
      subtitleAr: 'مدخل مستوٍ بدون سلالم أو عوائق عند البوابة',
      subtitleEn: 'Level entry with zero steps at the main door',
      icon: Icons.sensor_door_outlined,
    ),
    AccessNeedOption(
      id: 'suitable_ramp',
      titleAr: 'منحدر مناسب',
      titleEn: 'Suitable ramp',
      subtitleAr: 'منحدر آمن بميل مريح وسهل الصعود',
      subtitleEn: 'Safe, gentle-slope ramp for smooth entry',
      icon: Icons.trending_up_rounded,
    ),
    AccessNeedOption(
      id: 'accessible_elevator',
      titleAr: 'مصعد متاح',
      titleEn: 'Accessible elevator',
      subtitleAr: 'أسانسير واسع يعمل للوصول للأدوار العليا',
      subtitleEn: 'Working spacious elevator for upper floors',
      icon: Icons.elevator_outlined,
    ),
    AccessNeedOption(
      id: 'accessible_restroom',
      titleAr: 'حمام مجهز',
      titleEn: 'Accessible restroom',
      subtitleAr: 'دورة مياه مهيأة بمساحة كافية ومقابض أمان',
      subtitleEn: 'Equipped restroom with grab bars & turning space',
      icon: Icons.wc_rounded,
    ),
    AccessNeedOption(
      id: 'wide_passages',
      titleAr: 'ممرات واسعة',
      titleEn: 'Wide corridors',
      subtitleAr: 'أبواب وممرات داخلية تسمح بالحركة والالتفاف بسهولة',
      subtitleEn: 'Wide doors and interior pathways for easy movement',
      icon: Icons.swap_horiz_rounded,
    ),
    AccessNeedOption(
      id: 'accessible_parking',
      titleAr: 'أماكن انتظار مناسبة',
      titleEn: 'Accessible parking',
      subtitleAr: 'موقف سيارات قريب ومجهز للنزول بأمان أمام المكان',
      subtitleEn: 'Dedicated parking or safe drop-off near the entrance',
      icon: Icons.local_parking_rounded,
    ),
  ];

  static AccessNeedOption? byId(String id) {
    for (final item in all) {
      if (item.id == id) return item;
    }
    return null;
  }
}

/// User Mobility Profile (Step 1 of 3 — طريقة التنقل).
/// Focuses on how the person moves rather than medical labels or raw weight %.
class MobilityProfileOption {
  const MobilityProfileOption({
    required this.id,
    required this.firestoreValue,
    required this.titleAr,
    required this.titleEn,
    required this.subtitleAr,
    required this.subtitleEn,
    required this.priorityHintAr,
    required this.priorityHintEn,
    required this.icon,
    this.defaultAccessNeeds = const [],
  });

  /// Canonical analytics identifier (`wheelchair`, `assisted_walking`,
  /// `walking_difficulty`, `stroller`, `general`).
  final String id;

  /// Canonical Arabic label persisted in Firestore `users/{uid}.mobility_type`.
  final String firestoreValue;

  final String titleAr;
  final String titleEn;
  final String subtitleAr;
  final String subtitleEn;

  /// Human-friendly summary of what ONEWAY prioritizes (never raw % numbers).
  final String priorityHintAr;
  final String priorityHintEn;
  final IconData icon;

  /// Smart default access needs pre-selected when the user picks this mobility mode.
  final List<String> defaultAccessNeeds;

  static const List<MobilityProfileOption> all = [
    MobilityProfileOption(
      id: 'wheelchair',
      firestoreValue: 'كرسي متحرك',
      titleAr: 'كرسي متحرك',
      titleEn: 'Wheelchair',
      subtitleAr: 'يدوي أو كهربائي',
      subtitleEn: 'Manual or electric wheelchair',
      priorityHintAr: 'يركّز على المدخل بدون درجات، المنحدر، الممرات الواسعة والحمام المجهز',
      priorityHintEn: 'Prioritizes step-free entry, ramps, wide corridors & restrooms',
      icon: Icons.accessible_forward_rounded,
      defaultAccessNeeds: [
        'step_free_entrance',
        'suitable_ramp',
        'wide_passages',
        'accessible_restroom',
      ],
    ),
    MobilityProfileOption(
      id: 'assisted_walking',
      firestoreValue: 'المشي بمساعدة (عكاز أو مشاية)',
      titleAr: 'المشي بمساعدة',
      titleEn: 'Walking with Assistance',
      subtitleAr: 'عكاز أو مشاية',
      subtitleEn: 'Crutches, cane, or walker',
      priorityHintAr: 'يركّز على عدم وجود درجات، توفر المصعد، وقرب أماكن الانتظار',
      priorityHintEn: 'Prioritizes step-free entry, elevators & nearby drop-off',
      icon: Icons.elderly_rounded,
      defaultAccessNeeds: [
        'step_free_entrance',
        'accessible_elevator',
        'accessible_restroom',
      ],
    ),
    MobilityProfileOption(
      id: 'walking_difficulty',
      firestoreValue: 'المشي بدون مساعدة',
      titleAr: 'المشي بدون مساعدة',
      titleEn: 'Walking without Aid',
      subtitleAr: 'مع صعوبة بسيطة في الحركة أو السلالم',
      subtitleEn: 'Preferring easy access with minimal stairs',
      priorityHintAr: 'يركّز على المصاعد والمداخل المريحة وتجنب السلالم الطويلة',
      priorityHintEn: 'Prioritizes elevators and comfortable step-free access',
      icon: Icons.directions_walk_rounded,
      defaultAccessNeeds: [
        'step_free_entrance',
        'accessible_elevator',
      ],
    ),
    MobilityProfileOption(
      id: 'stroller',
      firestoreValue: 'عربة أطفال',
      titleAr: 'أبحث عن أماكن مناسبة لعربة أطفال',
      titleEn: 'Looking for Stroller-Friendly Places',
      subtitleAr: 'سهولة الحركة بعربة أطفال',
      subtitleEn: 'Smooth movement with a baby stroller',
      priorityHintAr: 'يركّز على المنحدرات والمداخل والممرات الواسعة والمصاعد',
      priorityHintEn: 'Prioritizes ramps, wide doors/passages & elevators',
      icon: Icons.stroller_rounded,
      defaultAccessNeeds: [
        'step_free_entrance',
        'suitable_ramp',
        'accessible_elevator',
        'wide_passages',
      ],
    ),
    MobilityProfileOption(
      id: 'general',
      firestoreValue: 'تصفح عام دون تخصيص',
      titleAr: 'أبحث بشكل عام دون تخصيص',
      titleEn: 'General Browsing (No Personalization)',
      subtitleAr: 'عرض تقييم سهولة الوصول العام لكل مكان',
      subtitleEn: 'Show standard overall accessibility ratings',
      priorityHintAr: 'تقييم شامل ومتوازن لجميع معايير سهولة الوصول',
      priorityHintEn: 'Balanced overall accessibility score across all criteria',
      icon: Icons.explore_rounded,
      defaultAccessNeeds: [],
    ),
  ];

  /// Resolves a [MobilityProfileOption] from any stored Firestore string or id.
  static MobilityProfileOption resolveOption(String? raw) {
    final norm = (raw ?? '').trim().toLowerCase();
    if (norm.isEmpty || norm.contains('عام') || norm.contains('general')) {
      return all.last;
    }
    if (norm.contains('كرسي') ||
        norm.contains('كهرب') ||
        norm.contains('يدوي') ||
        norm.contains('wheelchair')) {
      return all[0];
    }
    if (norm.contains('عكاز') ||
        norm.contains('مشاي') ||
        norm.contains('كبار') ||
        norm.contains('بمساعدة') ||
        norm.contains('walker') ||
        norm.contains('senior')) {
      return all[1];
    }
    if (norm.contains('طفل') ||
        norm.contains('أطفال') ||
        norm.contains('اطفال') ||
        norm.contains('عربة') ||
        norm.contains('عربه') ||
        norm.contains('stroller')) {
      return all[3];
    }
    if (norm.contains('بدون مساعدة') ||
        norm.contains('مشي') ||
        norm.contains('walking')) {
      return all[2];
    }
    return all[0];
  }

  /// Maps any saved Arabic/English mobility string to its canonical analytics id.
  static String canonicalIdFor(String? raw) {
    final norm = (raw ?? '').trim().toLowerCase();
    if (norm.isEmpty || norm.contains('عام') || norm.contains('general')) {
      return 'general';
    }
    if (norm.contains('كهرب') || norm.contains('electric')) return 'wheelchair';
    if (norm.contains('يدوي') ||
        norm.contains('كرسي') ||
        norm.contains('manual') ||
        norm.contains('wheelchair')) {
      return 'wheelchair';
    }
    if (norm.contains('كبار') ||
        norm.contains('عكاز') ||
        norm.contains('مشاي') ||
        norm.contains('بمساعدة') ||
        norm.contains('senior') ||
        norm.contains('walker')) {
      return 'assisted_walking';
    }
    if (norm.contains('طفل') ||
        norm.contains('عربة') ||
        norm.contains('stroller')) {
      return 'stroller';
    }
    if (norm.contains('بدون مساعدة') || norm.contains('walking')) {
      return 'walking_difficulty';
    }
    return 'other';
  }
}
