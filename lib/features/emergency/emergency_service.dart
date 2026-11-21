import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/schema/emergency_contacts_record.dart';

/// Where the coordinates in an SOS alert came from. We never guess: if the
/// device cannot produce a position, the alert says so instead of pointing
/// at a made-up location.
enum SosLocationStatus { gps, manual, unavailable }

/// Lightweight contact shape so the SOS flow (and its tests) never depends
/// on a Firestore snapshot.
class SosContact {
  const SosContact({required this.name, required this.phone});
  final String name;
  final String phone;
}

class EmergencyResult {
  final bool success;
  final String message;
  final String? contactName;
  final String? phone;
  final String? mapsUrl;

  /// True only when a WhatsApp/SMS draft was actually opened on the device.
  /// A draft is never reported as "sent" - the user still has to press send.
  final bool draftOpened;
  final SosLocationStatus locationStatus;

  EmergencyResult({
    required this.success,
    required this.message,
    this.contactName,
    this.phone,
    this.mapsUrl,
    this.draftOpened = false,
    this.locationStatus = SosLocationStatus.unavailable,
  });
}

class EmergencyService {
  /// Attempts to determine the device's current GPS position safely.
  static Future<Position?> determineCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
    } catch (e) {
      debugPrint('Location detection exception: $e');
      return null;
    }
  }

  /// Fetches the user's primary emergency contact, or the first available contact.
  static Future<EmergencyContactsRecord?> getPrimaryContact() async {
    final uid = uidProvider();
    if (uid.isEmpty) return null;

    try {
      final query = await EmergencyContactsRecord.collection
          .where('userId', isEqualTo: uid)
          .get();

      if (query.docs.isEmpty) return null;

      final contacts =
          query.docs.map(EmergencyContactsRecord.fromSnapshot).toList();

      // Return primary first if designated, else first contact
      return contacts.firstWhere(
        (c) => c.isPrimary,
        orElse: () => contacts.first,
      );
    } catch (e) {
      debugPrint('Error getting emergency contact: $e');
      return null;
    }
  }

  // ------------------------------------------------------------------
  // Injectable seams. Production defaults hit the real plugins; tests
  // override them to simulate denied permissions, missing GPS and failed
  // launches without touching device services or Firestore.
  // ------------------------------------------------------------------
  static Future<Position?> Function() positionProvider =
      determineCurrentPosition;

  static Future<SosContact?> Function() contactProvider = () async {
    final record = await getPrimaryContact();
    if (record == null) return null;
    return SosContact(name: record.name, phone: record.phoneNumber);
  };

  static Future<bool> Function(Uri uri) canLaunchChecker = canLaunchUrl;

  static Future<bool> Function(Uri uri, {LaunchMode mode}) launcher =
      (uri, {mode = LaunchMode.platformDefault}) =>
          launchUrl(uri, mode: mode);

  static String Function() uidProvider = () => currentUserUid;

  static String Function() displayNameProvider = () => currentUserDisplayName;

  static Future<void> Function(Map<String, dynamic> data) notificationWriter =
      (data) async {
    final uid = uidProvider();
    if (uid.isNotEmpty) {
      await FirebaseFirestore.instance.collection('notifications').add(data);
    }
  };

  /// Triggers an SOS: builds the alert message with an HONEST location
  /// statement and opens a WhatsApp/SMS draft for the companion.
  ///
  /// Location rules:
  ///  - Coordinates passed in by the caller are treated as a MANUAL pin and
  ///    labeled as such.
  ///  - Coordinates from the device GPS are labeled as the current location.
  ///  - If neither exists, the alert carries NO map link and says plainly
  ///    that the location could not be determined. We never fall back to a
  ///    default city location.
  ///
  /// Delivery rules: success means a draft was OPENED, never that a message
  /// was sent - only the user pressing send in WhatsApp/SMS delivers it.
  static Future<EmergencyResult> triggerSOS({
    double? lat,
    double? lng,
    String? customNote,
  }) async {
    double? finalLat;
    double? finalLng;
    SosLocationStatus locationStatus = SosLocationStatus.unavailable;

    if (lat != null && lng != null) {
      finalLat = lat;
      finalLng = lng;
      locationStatus = SosLocationStatus.manual;
    } else {
      final pos = await positionProvider();
      if (pos != null) {
        finalLat = pos.latitude;
        finalLng = pos.longitude;
        locationStatus = SosLocationStatus.gps;
      }
    }

    final contact = await contactProvider();

    if (contact == null) {
      return EmergencyResult(
        success: false,
        message:
            'لم يتم العثور على جهة اتصال للطوارئ. يرجى إضافة رقم مرافق موثوق أولاً من شاشة الطوارئ.',
      );
    }

    final phone = contact.phone.trim().replaceAll(RegExp(r'\s+'), '');
    final name = contact.name.isNotEmpty ? contact.name : 'المرافق';
    final displayName = displayNameProvider();
    final userLabel = displayName.isNotEmpty ? displayName : 'أنا';

    String? mapsUrl;
    String locationLine;
    switch (locationStatus) {
      case SosLocationStatus.gps:
        mapsUrl = 'https://maps.google.com/?q=$finalLat,$finalLng';
        locationLine = 'موقعي الحالي على الخريطة:\n$mapsUrl\n';
        break;
      case SosLocationStatus.manual:
        mapsUrl = 'https://maps.google.com/?q=$finalLat,$finalLng';
        locationLine = 'موقعي (حددته يدوياً على الخريطة):\n$mapsUrl\n';
        break;
      case SosLocationStatus.unavailable:
        locationLine =
            'تعذر تحديد موقعي تلقائياً - برجاء الاتصال بي فوراً لمعرفة مكاني.\n';
        break;
    }

    final alertMessage =
        '🚨 نداء استغاثة عاجل من $userLabel عبر تطبيق ONEWAY!\n'
        'أنا بحاجة إلى مساعدة عاجلة.\n'
        '$locationLine'
        '${customNote != null && customNote.isNotEmpty ? "ملاحظة: $customNote\n" : ""}'
        'الوقت: ${DateTime.now().toLocal().toString().split(".")[0]}';

    // wa.me works on phones (opens the app) and desktop (WhatsApp Web),
    // unlike the whatsapp:// scheme which dies on a blank tab in browsers.
    final whatsappCleanPhone =
        phone.startsWith('01') ? '2$phone' : phone.replaceAll('+', '');
    final whatsappUri = Uri.parse(
      'https://wa.me/$whatsappCleanPhone?text=${Uri.encodeComponent(alertMessage)}',
    );

    // Fallback SMS URI
    final smsUri = Uri(
      scheme: 'sms',
      path: phone,
      queryParameters: {'body': alertMessage},
    );

    bool launched = false;
    try {
      if (await canLaunchChecker(whatsappUri)) {
        launched = await launcher(whatsappUri,
            mode: LaunchMode.externalApplication);
      }
      if (!launched && await canLaunchChecker(smsUri)) {
        launched = await launcher(smsUri);
      }
    } catch (e) {
      debugPrint('Failed to launch WhatsApp/SMS intent: $e');
      launched = false;
    }

    if (!launched) {
      return EmergencyResult(
        success: false,
        message:
            'تعذر فتح واتساب أو الرسائل لإرسال الاستغاثة. اتصل بالمرافق ($name) مباشرة على $phone.',
        contactName: name,
        phone: phone,
        mapsUrl: mapsUrl,
        draftOpened: false,
        locationStatus: locationStatus,
      );
    }

    // Record an honest log entry: a draft was OPENED, not sent. Delivery
    // only happens when the user presses send inside WhatsApp/SMS.
    try {
      final data = <String, dynamic>{
        'userId': uidProvider(),
        'title': '🚨 تم فتح مسودة استغاثة',
        'body':
            'فُتحت مسودة رسالة استغاثة إلى $name ($phone) وهي بانتظار الضغط على إرسال من جهازك.',
        'type': 'sos_alert',
        'is_read': false,
        'created_at': FieldValue.serverTimestamp(),
        'location_status': locationStatus.name,
      };
      if (finalLat != null && finalLng != null) {
        data['location'] = GeoPoint(finalLat, finalLng);
      }
      await notificationWriter(data);
    } catch (_) {}

    return EmergencyResult(
      success: true,
      message:
          'تم فتح مسودة رسالة الاستغاثة للمرافق ($name). راجعها واضغط إرسال بنفسك - لم تُرسل بعد.',
      contactName: name,
      phone: phone,
      mapsUrl: mapsUrl,
      draftOpened: true,
      locationStatus: locationStatus,
    );
  }
}
