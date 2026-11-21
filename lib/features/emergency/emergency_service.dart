import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/schema/emergency_contacts_record.dart';

class EmergencyResult {
  final bool success;
  final String message;
  final String? contactName;
  final String? phone;
  final String? mapsUrl;

  EmergencyResult({
    required this.success,
    required this.message,
    this.contactName,
    this.phone,
    this.mapsUrl,
  });
}

class EmergencyService {
  /// Default Egyptian coordinates fallback (Cairo center) if device GPS is not granted.
  static const double defaultLat = 30.0444;
  static const double defaultLng = 31.2357;

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
    final uid = currentUserUid;
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

  /// Triggers an immediate SOS by constructing location coordinates and preparing
  /// WhatsApp / SMS message to the designated companion.
  static Future<EmergencyResult> triggerSOS({
    double? lat,
    double? lng,
    String? customNote,
  }) async {
    double finalLat = lat ?? defaultLat;
    double finalLng = lng ?? defaultLng;

    if (lat == null || lng == null) {
      final pos = await determineCurrentPosition();
      if (pos != null) {
        finalLat = pos.latitude;
        finalLng = pos.longitude;
      }
    }

    final contact = await getPrimaryContact();

    if (contact == null) {
      return EmergencyResult(
        success: false,
        message:
            'لم يتم العثور على جهة اتصال للطوارئ. يرجى إضافة رقم مرافق موثوق أولاً من شاشة الطوارئ.',
      );
    }

    final phone = contact.phoneNumber.trim().replaceAll(RegExp(r'\s+'), '');
    final name = contact.name.isNotEmpty ? contact.name : 'المرافق';
    final userLabel =
        currentUserDisplayName.isNotEmpty ? currentUserDisplayName : 'أنا';

    final mapsUrl = 'https://maps.google.com/?q=$finalLat,$finalLng';
    final alertMessage =
        '🚨 نداء استغاثة عاجل من $userLabel عبر تطبيق ONEWAY!\n'
        'أنا بحاجة إلى مساعدة عاجلة.\n'
        'موقعي الحالي على الخريطة:\n$mapsUrl\n'
        '${customNote != null && customNote.isNotEmpty ? "ملاحظة: $customNote\n" : ""}'
        'الوقت: ${DateTime.now().toLocal().toString().split(".")[0]}';

    // 1. Try launching WhatsApp directly
    final whatsappCleanPhone =
        phone.startsWith('01') ? '2$phone' : phone.replaceAll('+', '');
    // wa.me works on phones (opens the app) and desktop (WhatsApp Web),
    // unlike the whatsapp:// scheme which dies on a blank tab in browsers.
    final whatsappUri = Uri.parse(
      'https://wa.me/$whatsappCleanPhone?text=${Uri.encodeComponent(alertMessage)}',
    );

    // 2. Fallback SMS URI
    final smsUri = Uri(
      scheme: 'sms',
      path: phone,
      queryParameters: {'body': alertMessage},
    );

    bool launched = false;
    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
        launched = true;
      } else if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
        launched = true;
      }
    } catch (e) {
      debugPrint('Failed to launch WhatsApp/SMS intent: $e');
    }

    // 3. Record alert log in Firestore notifications for in-app tracking
    try {
      if (currentUserUid.isNotEmpty) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': currentUserUid,
          'title': '🚨 تم إطلاق نداء استغاثة',
          'body': 'تم إرسال موقعك واستغاثتك إلى $name ($phone).',
          'type': 'sos_alert',
          'is_read': false,
          'created_at': FieldValue.serverTimestamp(),
          'location': GeoPoint(finalLat, finalLng),
        });
      }
    } catch (_) {}

    return EmergencyResult(
      success: true,
      message: launched
          ? 'تم تجهيز وإرسال رسالة الاستغاثة وموقعك للمرافق ($name).'
          : 'تم تجهيز رسالة الاستغاثة ورابط موقعك للمرافق ($name).',
      contactName: name,
      phone: phone,
      mapsUrl: mapsUrl,
    );
  }
}
