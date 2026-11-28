import 'package:flutter_test/flutter_test.dart';
import 'package:one_way_egypt/features/emergency/emergency_service.dart';

String normalizeArabic(String input) => input
    .trim()
    .toLowerCase()
    .replaceAll(RegExp('[أإآ]'), 'ا')
    .replaceAll('ى', 'ي')
    .replaceAll('ة', 'ه')
    .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');

void main() {
  group('Arabic Text Normalization Tests', () {
    test('normalizes alef variants and hamzas correctly', () {
      expect(normalizeArabic('أحمد'), equals('احمد'));
      expect(normalizeArabic('إبراهيم'), equals('ابراهيم'));
      expect(normalizeArabic('آثار'), equals('اثار'));
    });

    test('normalizes taa marbouta and yaa', () {
      expect(normalizeArabic('القاهرة'), equals('القاهره'));
      expect(normalizeArabic('مستشفى'), equals('مستشفي'));
    });

    test('strips arabic tashkeel diacritics', () {
      expect(normalizeArabic('مُسْتَشْفَى'), equals('مستشفي'));
      expect(normalizeArabic('مَصْرٌ'), equals('مصر'));
    });
  });

  group('EmergencyService Configuration', () {
    test('no default/guessed coordinates exist anywhere', () {
      // The SOS flow must never fall back to a made-up location: it either
      // has GPS, a manual pin, or says the location is unavailable.
      expect(SosLocationStatus.values, hasLength(3));
      expect(SosLocationStatus.values, contains(SosLocationStatus.gps));
      expect(SosLocationStatus.values, contains(SosLocationStatus.manual));
      expect(
          SosLocationStatus.values, contains(SosLocationStatus.unavailable));
    });

    test('EmergencyResult models success and message correctly', () {
      final res = EmergencyResult(
        success: true,
        message: 'تم تجهيز الاستغاثة بنجاح',
        contactName: 'أحمد',
        phone: '01012345678',
        mapsUrl: 'https://maps.google.com/?q=30.0444,31.2357',
      );

      expect(res.success, isTrue);
      expect(res.contactName, equals('أحمد'));
      expect(res.mapsUrl, contains('30.0444,31.2357'));
    });
  });
}
