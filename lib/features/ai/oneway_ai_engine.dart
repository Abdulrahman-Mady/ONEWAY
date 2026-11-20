import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/backend/schema/places_record.dart';
import '/features/emergency/emergency_service.dart';

enum AIIntentType {
  emergency,
  navigation,
  placeSearch,
  generalInfo,
}

class AIResponse {
  final AIIntentType intent;
  final String replyText;
  final List<PlacesRecord> places;
  final String? navigationRoute;
  final EmergencyResult? emergencyResult;

  AIResponse({
    required this.intent,
    required this.replyText,
    this.places = const [],
    this.navigationRoute,
    this.emergencyResult,
  });
}

class OnewayAIEngine {
  static String _normalize(String input) => input
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[أإآ]'), 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('ة', 'ه')
      .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');

  /// Evaluates the user query (voice or text) and returns a grounded response.
  static Future<AIResponse> processQuery(
    BuildContext context,
    String rawQuery,
  ) async {
    final query = _normalize(rawQuery);

    // 1. Check for Emergency / SOS intent
    if (query.contains('استغاثه') ||
        query.contains('طوارئ') ||
        query.contains('اغاثه') ||
        query.contains('مرافق') ||
        query.contains('الحقني') ||
        query.contains('ساعدني') ||
        query.contains('ابعت موقعي') ||
        query.contains('موقعي') ||
        query.contains('لوكيشن') ||
        query.contains('نجده') ||
        query.contains('sos')) {
      final emergency = await EmergencyService.triggerSOS();
      if (emergency.success) {
        return AIResponse(
          intent: AIIntentType.emergency,
          replyText:
              '🚨 تم تفعيل نداء الاستغاثة فوراً!\n'
              'تم تجهيز موقعك الحالي وإرساله إلى المرافق: ${emergency.contactName} (${emergency.phone}).\n'
              'رابط الخريطة المرفق:\n${emergency.mapsUrl}',
          emergencyResult: emergency,
        );
      } else {
        return AIResponse(
          intent: AIIntentType.emergency,
          replyText: '⚠️ تنبيه: ${emergency.message}',
          emergencyResult: emergency,
        );
      }
    }

    // 2. Check for App Navigation intent
    if (query.contains('خريطه') || query.contains('الخريطه')) {
      return AIResponse(
        intent: AIIntentType.navigation,
        replyText: 'بالتأكيد! جاري فتح الخريطة التفاعلية لعرض الأماكن القريبة...',
        navigationRoute: 'ExploreMap',
      );
    }
    if (query.contains('بلاغ') || query.contains('عائق') || query.contains('اشتكي')) {
      return AIResponse(
        intent: AIIntentType.navigation,
        replyText: 'جاري نقلك إلى شاشة الإبلاغ عن عائق لمشاركة التفاصيل...',
        navigationRoute: 'SubmitAccessibilityReport',
      );
    }
    if (query.contains('مفضل') || query.contains('المفضله')) {
      return AIResponse(
        intent: AIIntentType.navigation,
        replyText: 'جاري فتح قائمة الأماكن المحفوظة في المفضلة لديك...',
        navigationRoute: 'FavoritesPage',
      );
    }

    // 3. Search and Grounded Retrieval for Places
    return await _searchPlacesWithAI(rawQuery, query);
  }

  static Future<AIResponse> _searchPlacesWithAI(
    String rawQuery,
    String normalizedQuery,
  ) async {
    try {
      final snapshot = await PlacesRecord.collection.limit(25).get();
      final allPlaces = snapshot.docs.map(PlacesRecord.fromSnapshot).toList();

      if (allPlaces.isEmpty) {
        return AIResponse(
          intent: AIIntentType.generalInfo,
          replyText:
              'مرحباً بك في ONEWAY! قاعدة البيانات لا تحتوي على أماكن بعد. يمكنك استيراد الأماكن الأولية المعتمدة من الشاشة الرئيسية للبدء.',
        );
      }

      // Filter matching criteria
      final requireRamp = normalizedQuery.contains('منحدر') ||
          normalizedQuery.contains('رمب') ||
          normalizedQuery.contains('بدون سلالم');
      final requireElevator = normalizedQuery.contains('مصعد') ||
          normalizedQuery.contains('اسانسير');
      final requireRestroom = normalizedQuery.contains('حمام') ||
          normalizedQuery.contains('تواليت') ||
          normalizedQuery.contains('دوره مياه');
      final requireParking = normalizedQuery.contains('موقف') ||
          normalizedQuery.contains('باركينج') ||
          normalizedQuery.contains('سيار');

      String? categoryFilter;
      if (normalizedQuery.contains('مستشفي') ||
          normalizedQuery.contains('طبي') ||
          normalizedQuery.contains('علاج')) {
        categoryFilter = 'طبي';
      } else if (normalizedQuery.contains('مول') ||
          normalizedQuery.contains('تسوق')) {
        categoryFilter = 'تسوق';
      } else if (normalizedQuery.contains('جامع') ||
          normalizedQuery.contains('تعليم')) {
        categoryFilter = 'تعليم';
      } else if (normalizedQuery.contains('متحف') ||
          normalizedQuery.contains('مكتبه') ||
          normalizedQuery.contains('ثقاف')) {
        categoryFilter = 'ثقاف';
      } else if (normalizedQuery.contains('قطار') ||
          normalizedQuery.contains('محط') ||
          normalizedQuery.contains('مواصلات')) {
        categoryFilter = 'مواصلات';
      }

      final matched = allPlaces.where((place) {
        final feat = place.accessibilityFeatures;
        final placeText = _normalize(
            '${place.name} ${place.category} ${place.description} ${place.city} ${place.governorate}');

        // Category matching
        if (categoryFilter != null && !placeText.contains(categoryFilter)) {
          return false;
        }

        // Feature matching
        if (requireRamp && (!feat.hasRamp() || !feat.ramp)) return false;
        if (requireElevator &&
            (!feat.hasSuitableElevator() || !feat.suitableElevator)) {
          return false;
        }
        if (requireRestroom &&
            (!feat.hasAccessibleRestroom() || !feat.accessibleRestroom)) {
          return false;
        }
        if (requireParking &&
            (!feat.hasAccessibleParking() || !feat.accessibleParking)) {
          return false;
        }

        // Query keywords match
        if (categoryFilter == null) {
          final words = normalizedQuery.split(' ');
          final hasKeyword = words.any((w) => w.length > 2 && placeText.contains(w));
          if (!hasKeyword) return false;
        }

        return true;
      }).toList();

      final results = matched.isNotEmpty ? matched : allPlaces.take(3).toList();

      final StringBuffer sb = StringBuffer();
      if (matched.isNotEmpty) {
        sb.writeln('وجدت لك ${matched.length} مكان متوافق مع طلبك بدقة:');
      } else {
        sb.writeln(
            'لم أجد أماكن تطابق جميع شروطك بدقة، لكن إليك أفضل الأماكن المعتمدة المتاحة:');
      }

      for (var i = 0; i < results.take(3).length; i++) {
        final p = results[i];
        final f = p.accessibilityFeatures;
        sb.writeln('\n📍 **${p.name}** (${p.city})');
        final features = <String>[];
        if (f.hasRamp() && f.ramp) features.add('منحدر مجهز');
        if (f.hasSuitableElevator() && f.suitableElevator) features.add('مصعد');
        if (f.hasAccessibleRestroom() && f.accessibleRestroom) {
          features.add('حمام مجهز');
        }
        if (f.hasWheelchairEntrance() && f.wheelchairEntrance) {
          features.add('مدخل للكراسي');
        }
        sb.writeln('  المزايا: ${features.join(" • ")}');
      }

      return AIResponse(
        intent: AIIntentType.placeSearch,
        replyText: sb.toString().trim(),
        places: results.take(4).toList(),
      );
    } catch (e) {
      return AIResponse(
        intent: AIIntentType.generalInfo,
        replyText:
            'أهلاً بك! أنا مساعد ONEWAY الذكي. يمكنك أن تطلب مني بالصوت أو الكتابة مثل:\n'
            '• "عايز مستشفى فيها مدخل ومنحدر في القاهرة"\n'
            '• "أقرب مول مجهز للكراسي في الجيزة"\n'
            '• "اطلب استغاثة من مرافقي وابعث موقعي"',
      );
    }
  }
}
