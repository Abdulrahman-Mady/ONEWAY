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

  group('EmergencyService Default Configuration', () {
    test('default coordinates are center of Cairo', () {
      expect(EmergencyService.defaultLat, closeTo(30.0444, 0.001));
      expect(EmergencyService.defaultLng, closeTo(31.2357, 0.001));
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
