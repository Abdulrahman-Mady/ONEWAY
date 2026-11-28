import 'package:cloud_firestore/cloud_firestore.dart';

/// Shared personal profile options and validators used consistently across
/// Registration, Complete Profile, and Edit Profile screens.
class ProfileOptions {
  ProfileOptions._();

  static const List<String> genders = ['ذكر', 'أنثى', 'غير محدد'];

  static const List<String> governorates = [
    'القاهرة',
    'الجيزة',
    'الإسكندرية',
    'الدقهلية',
    'الشرقية',
    'الغربية',
    'المنوفية',
    'القليوبية',
    'البحيرة',
    'كفر الشيخ',
    'دمياط',
    'بورسعيد',
    'الإسماعيلية',
    'السويس',
    'الفيوم',
    'بني سويف',
    'المنيا',
    'أسيوط',
    'سوهاج',
    'قنا',
    'الأقصر',
    'أسوان',
    'البحر الأحمر',
    'الوادي الجديد',
    'مطروح',
    'شمال سيناء',
    'جنوب سيناء',
  ];

  /// Clean, user-centric mobility modes (replaces redundant manual/electric split).
  static const List<String> mobilityTypes = [
    'كرسي متحرك',
    'المشي بمساعدة (عكاز أو مشاية)',
    'المشي بدون مساعدة',
    'عربة أطفال',
    'تصفح عام دون تخصيص',
  ];

  /// Maps legacy stored mobility labels seamlessly to the canonical [mobilityTypes]
  /// so existing Firestore user profiles render cleanly in dropdowns.
  static String? normalizeMobilityForDropdown(String? raw) {
    final trimmed = (raw ?? '').trim();
    if (trimmed.isEmpty) return null;
    if (mobilityTypes.contains(trimmed)) return trimmed;
    final norm = trimmed.toLowerCase();
    if (norm.contains('كرسي') ||
        norm.contains('يدوي') ||
        norm.contains('كهرب') ||
        norm.contains('wheelchair')) {
      return 'كرسي متحرك';
    }
    if (norm.contains('عكاز') ||
        norm.contains('مشاي') ||
        norm.contains('كبار')) {
      return 'المشي بمساعدة (عكاز أو مشاية)';
    }
    if (norm.contains('طفل') || norm.contains('عربة') || norm.contains('عربه')) {
      return 'عربة أطفال';
    }
    if (norm.contains('مرافق') || norm.contains('أخرى') || norm.contains('عام')) {
      return 'تصفح عام دون تخصيص';
    }
    return 'المشي بدون مساعدة';
  }

  /// Normalizes Egyptian mobile numbers (`+2010...`, `002010...`, `2010...`)
  /// into the local 11-digit `01xxxxxxxxx` format.
  static String normalizeEgyptianPhone(String raw) {
    var cleaned = raw.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleaned.startsWith('+20')) {
      cleaned = '0${cleaned.substring(3)}';
    } else if (cleaned.startsWith('0020')) {
      cleaned = '0${cleaned.substring(4)}';
    } else if (cleaned.startsWith('20') && cleaned.length == 12) {
      cleaned = '0${cleaned.substring(2)}';
    }
    return cleaned;
  }

  static bool isValidEgyptianPhone(String raw) {
    return RegExp(r'^(010|011|012|015)\d{8}$')
        .hasMatch(normalizeEgyptianPhone(raw));
  }

  static bool isValidEmail(String raw) {
    return RegExp(r'^[\w.+-]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(raw.trim());
  }

  static String formatBirthDate(dynamic raw) {
    if (raw is DateTime) {
      return '${raw.day}/${raw.month}/${raw.year}';
    }
    if (raw is Timestamp) {
      final d = raw.toDate();
      return '${d.day}/${d.month}/${d.year}';
    }
    return '';
  }

  static DateTime? parseBirthDate(dynamic raw) {
    if (raw is DateTime) return raw;
    if (raw is Timestamp) return raw.toDate();
    return null;
  }
}
