import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:one_way_egypt/features/emergency/emergency_service.dart';

Position _fakePosition(double lat, double lng) => Position(
      longitude: lng,
      latitude: lat,
      timestamp: DateTime(2026, 1, 1),
      accuracy: 5,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

void main() {
  group('EmergencyService.triggerSOS', () {
    late List<Map<String, dynamic>> notifications;
    late List<Uri> launched;
    late List<Uri> launchable;

    setUp(() {
      notifications = [];
      launched = [];
      launchable = [];

      EmergencyService.contactProvider =
          () async => const SosContact(name: 'مرافق', phone: '01012345678');
      EmergencyService.displayNameProvider = () => 'مستخدم اختبار';
      EmergencyService.uidProvider = () => 'test-uid';
      EmergencyService.canLaunchChecker =
          (uri) async => launchable.contains(uri);
      EmergencyService.launcher = (uri, {mode = LaunchMode.platformDefault}) async {
        launched.add(uri);
        return true;
      };
      EmergencyService.notificationWriter = (data) async {
        notifications.add(Map<String, dynamic>.from(data));
      };
    });

    tearDown(() {
      // Restore production defaults so other tests are unaffected.
      EmergencyService.positionProvider =
          EmergencyService.determineCurrentPosition;
      EmergencyService.contactProvider = () async {
        final record = await EmergencyService.getPrimaryContact();
        if (record == null) return null;
        return SosContact(name: record.name, phone: record.phoneNumber);
      };
    });

    test('permission denied / no GPS: alert has NO map link and says so',
        () async {
      EmergencyService.positionProvider = () async => null;

      final result = await EmergencyService.triggerSOS();

      expect(result.locationStatus, SosLocationStatus.unavailable);
      expect(result.mapsUrl, isNull);
      expect(result.message, isNot(contains('maps.google.com')));
      // The draft opened (wa.me was launchable? none listed, so this is the
      // failed-launch case here - assert no fake location leaked anywhere).
      for (final n in notifications) {
        expect(n['location'], isNull);
        expect(n['location_status'], 'unavailable');
      }
    });

    test('GPS available: alert carries the real coordinates labeled as gps',
        () async {
      EmergencyService.positionProvider =
          () async => _fakePosition(30.1, 31.2);
      final captured = <String>[];
      EmergencyService.contactProvider = () async {
        captured.add('contact');
        return const SosContact(name: 'مرافق', phone: '01012345678');
      };

      // Make WhatsApp launchable so we reach the success path.
      EmergencyService.canLaunchChecker = (uri) async => true;

      final result = await EmergencyService.triggerSOS();

      expect(result.success, isTrue);
      expect(result.draftOpened, isTrue);
      expect(result.locationStatus, SosLocationStatus.gps);
      expect(result.mapsUrl, 'https://maps.google.com/?q=30.1,31.2');
      // The message must say the draft was OPENED, never that it was sent.
      expect(result.message, contains('مسودة'));
      expect(result.message, isNot(contains('تم إرسال')));
      expect(launched, hasLength(1));
      expect(launched.first.toString(), contains('wa.me/201012345678'));
      expect(launched.first.toString(),
          contains(Uri.encodeComponent('موقعي الحالي على الخريطة')));
      expect(notifications, hasLength(1));
      expect(notifications.first['location_status'], 'gps');
      expect(notifications.first['title'], contains('مسودة'));
    });

    test('manual pin: coordinates are labeled as manually selected', () async {
      EmergencyService.positionProvider =
          () async => _fakePosition(1.0, 1.0); // must be ignored
      EmergencyService.canLaunchChecker = (uri) async => true;

      final result = await EmergencyService.triggerSOS(lat: 29.9, lng: 32.5);

      expect(result.locationStatus, SosLocationStatus.manual);
      expect(result.mapsUrl, 'https://maps.google.com/?q=29.9,32.5');
      expect(
        launched.first.toString(),
        contains(Uri.encodeComponent('حددته يدوياً')),
      );
    });

    test('failed launch: honest error, no notification, nothing "sent"',
        () async {
      EmergencyService.positionProvider =
          () async => _fakePosition(30.1, 31.2);
      EmergencyService.canLaunchChecker = (uri) async => false;

      final result = await EmergencyService.triggerSOS();

      expect(result.success, isFalse);
      expect(result.draftOpened, isFalse);
      expect(result.message, contains('تعذر فتح'));
      expect(result.message, contains('01012345678'));
      expect(launched, isEmpty);
      expect(notifications, isEmpty);
    });

    test('no emergency contact: fails before any launch attempt', () async {
      EmergencyService.positionProvider =
          () async => _fakePosition(30.1, 31.2);
      EmergencyService.contactProvider = () async => null;
      EmergencyService.canLaunchChecker = (uri) async => true;

      final result = await EmergencyService.triggerSOS();

      expect(result.success, isFalse);
      expect(result.message, contains('جهة اتصال'));
      expect(launched, isEmpty);
      expect(notifications, isEmpty);
    });

    test('no GPS + launchable draft: message text admits location missing',
        () async {
      EmergencyService.positionProvider = () async => null;
      EmergencyService.canLaunchChecker = (uri) async => true;

      final result = await EmergencyService.triggerSOS();

      expect(result.success, isTrue);
      expect(result.locationStatus, SosLocationStatus.unavailable);
      expect(
        launched.first.toString(),
        contains(Uri.encodeComponent('تعذر تحديد موقعي تلقائياً')),
      );
      expect(launched.first.toString(),
          isNot(contains(Uri.encodeComponent('maps.google.com'))));
    });
  });
}
