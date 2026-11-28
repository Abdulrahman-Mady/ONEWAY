import 'dart:math' as math;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/schema/accessibility_reports_record.dart';
import '/backend/schema/favorites_record.dart';
import '/backend/schema/notifications_record.dart';
import '/backend/schema/places_record.dart';
import '/backend/schema/structs/accessibility_features_struct.dart';
import '/core/constants/app_constants.dart';
import '/core/utils/arabic_normalizer.dart';
import '/features/accessibility/accessibility_score.dart';
import '/features/admin/admin_dashboard_page.dart';
import '/features/discovery/places_repository.dart';
import '/features/emergency/emergency_service.dart';
import '/features/guide/egypt_guide_page.dart';
import '/features/legal/legal_pages.dart';
import 'egypt_knowledge_base.dart';
import 'voice_assistant_models.dart';

export 'voice_assistant_models.dart';

/// Lightweight summary records for personal-data voice queries (keeps tests
/// decoupled from Firestore snapshots).
class UserFavoriteSummary {
  const UserFavoriteSummary({
    required this.placeId,
    required this.placeName,
    this.category = '',
  });
  final String placeId;
  final String placeName;
  final String category;
}

class UserReportSummary {
  const UserReportSummary({
    required this.placeName,
    required this.problemCategory,
    required this.status,
  });
  final String placeName;
  final String problemCategory;
  final String status;
}

class UserNotificationSummary {
  const UserNotificationSummary({
    required this.title,
    required this.body,
    required this.isRead,
  });
  final String title;
  final String body;
  final bool isRead;
}

/// Hybrid omni-capable AI & Voice Assistant Engine for ONEWAY Egypt.
///
/// Combines instant offline/local NLU, GPS-aware personalized accessibility
/// ranking, live app/accessibility controls, Egypt disability rights &
/// hotlines, personal account queries, and optional Gemini 3.8 Flash cloud
/// reasoning via Firebase Cloud Functions.
class OnewayAIEngine {
  OnewayAIEngine._();

  // ---------------------------------------------------------------------------
  // Injectable seams for 100% deterministic unit testing without Firebase.
  // ---------------------------------------------------------------------------
  static Future<List<PlacesRecord>> Function()? placesProvider;
  static Future<Position?> Function()? positionProvider;
  static Future<List<UserFavoriteSummary>> Function()? favoritesProvider;
  static Future<List<UserReportSummary>> Function()? reportsProvider;
  static Future<List<UserNotificationSummary>> Function()?
      notificationsProvider;
  static Future<EmergencyResult> Function({
    double? lat,
    double? lng,
    String? customNote,
  }) sosTrigger = EmergencyService.triggerSOS;
  static String Function() uidProvider = () => currentUserUid;
  static String? Function() mobilityProvider = () =>
      currentUserDocument?.snapshotData['mobility_type'] as String?;
  static Future<Map<String, dynamic>?> Function(Map<String, dynamic> payload)?
      remoteAssistantCaller;

  @visibleForTesting
  static void resetProvidersForTesting() {
    placesProvider = null;
    positionProvider = null;
    favoritesProvider = null;
    reportsProvider = null;
    notificationsProvider = null;
    sosTrigger = EmergencyService.triggerSOS;
    uidProvider = () => currentUserUid;
    mobilityProvider = () =>
        currentUserDocument?.snapshotData['mobility_type'] as String?;
    remoteAssistantCaller = null;
  }

  static String _normalize(String input) => ArabicNormalizer.normalize(input);

  /// Detects whether the user's query is primarily English or Arabic.
  static bool detectIsEnglish(String rawQuery, String fallbackLocale) {
    final hasArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(rawQuery);
    if (hasArabic) return false;
    final hasLatin = RegExp(r'[A-Za-z]').hasMatch(rawQuery);
    if (hasLatin) return true;
    return fallbackLocale == 'en';
  }

  /// Main entry point: evaluates any voice or text query and returns a rich,
  /// grounded [AIResponse] with optional executable [AssistantAction]s.
  static Future<AIResponse> processQuery(
    BuildContext? context,
    String rawQuery, {
    AssistantSession? session,
  }) async {
    final activeSession = session ?? AssistantSession();
    final trimmed = rawQuery.trim();
    final isEn = detectIsEnglish(trimmed, activeSession.localeCode);
    final query = _normalize(trimmed);

    // Sync mobility type from current user profile if not explicitly set.
    if ((activeSession.mobilityType ?? '').isEmpty) {
      try {
        activeSession.mobilityType = mobilityProvider();
      } catch (_) {}
    }

    if (query.isEmpty) {
      return AIResponse(
        intent: AIIntentType.generalInfo,
        replyText: isEn
            ? 'I am listening! Tell me what you need.'
            : 'سامعك يا فندم! قولّي محتاج إيه وأنا معاك.',
        isEnglish: isEn,
      );
    }

    // 0. Repeat last answer or clear chat
    final metaResp = _matchMetaCommand(query, activeSession, isEn: isEn);
    if (metaResp != null) {
      return metaResp;
    }

    // 1. Emergency / Personal SOS (highest priority, never waits on cloud)
    if (_isSosIntent(query)) {
      final resp = await _handleSos(isEn: isEn);
      activeSession.recordTurn(trimmed, resp);
      return resp;
    }

    // 2. Official Egyptian Hotlines (123, 122, 180, 16736, 16439, 16528)
    final hotlineResp =
        EgyptKnowledgeBase.matchHotlineQuery(query, isEnglish: isEn);
    if (hotlineResp != null) {
      activeSession.recordTurn(trimmed, hotlineResp);
      return hotlineResp;
    }

    // 3. Live App & Accessibility Controls (font, contrast, dark mode, language,
    //    TTS speed/mute, notifications, mobility profile)
    final controlResp = _matchAppControl(query, activeSession, isEn: isEn);
    if (controlResp != null) {
      activeSession.recordTurn(trimmed, controlResp);
      return controlResp;
    }

    // 4. Personal Account & Live GPS Queries (favorites, reports, notifications, "where am I?")
    final userDataResp =
        await _matchUserDataQuery(query, activeSession, isEn: isEn);
    if (userDataResp != null) {
      activeSession.recordTurn(trimmed, userDataResp);
      return userDataResp;
    }

    // 5. Contextual & Direct Place Actions (directions, call, favorite,
    //    place accessibility check, open details, compare places)
    final placeActionResp =
        await _matchPlaceAction(query, activeSession, isEn: isEn);
    if (placeActionResp != null) {
      activeSession.recordTurn(trimmed, placeActionResp);
      return placeActionResp;
    }

    // 6. Full App Navigation (all 18+ routes + category deep-linking + go back)
    final navResp = _matchAppNavigation(query, isEn: isEn);
    if (navResp != null) {
      activeSession.recordTurn(trimmed, navResp);
      return navResp;
    }

    // 7. Egypt Accessibility Rights & Services Guide (offline knowledge base)
    final guideResp =
        EgyptKnowledgeBase.matchGuideQuestion(query, isEnglish: isEn);
    if (guideResp != null) {
      activeSession.recordTurn(trimmed, guideResp);
      return guideResp;
    }

    // 8. Instant Conversational Small Talk, Capabilities, Time & Date
    final smallTalkResp = _matchSmallTalk(query, isEn: isEn);
    if (smallTalkResp != null) {
      activeSession.recordTurn(trimmed, smallTalkResp);
      return smallTalkResp;
    }

    // 9. Cloud Gemini 3.8 Flash Assistant (multi-turn, grounded in Firestore)
    final remote = await _tryRemoteAssistant(
      trimmed,
      activeSession,
      isEn: isEn,
    );
    if (remote != null) {
      activeSession.recordTurn(trimmed, remote);
      return remote;
    }

    // 10. Advanced Local GPS + Personalized Place Search & Fallback
    final searchResp = await _searchPlacesLocally(
      trimmed,
      query,
      activeSession,
      isEn: isEn,
    );
    activeSession.recordTurn(trimmed, searchResp);
    return searchResp;
  }

  // ===========================================================================
  // 0. META COMMANDS (Repeat / Clear)
  // ===========================================================================
  static AIResponse? _matchMetaCommand(
    String query,
    AssistantSession session, {
    required bool isEn,
  }) {
    bool any(List<String> words) => words.any(query.contains);

    if (any([
      'عيد تاني',
      'كرر',
      'قول تاني',
      'عيد الرد',
      'مسمعتش',
      'repeat',
      'say again',
      'say that again',
    ])) {
      final last = session.lastResponse;
      if (last != null) {
        return AIResponse(
          intent: last.intent,
          replyText: last.replyText,
          spokenText: last.spokenText,
          places: last.places,
          placeMatches: last.placeMatches,
          quickActions: last.quickActions,
          followUpSuggestions: last.followUpSuggestions,
          isEnglish: isEn,
        );
      }
      return AIResponse(
        intent: AIIntentType.generalInfo,
        replyText: isEn
            ? 'We have not started yet! Ask me about accessible places, your rights, or app controls.'
            : 'لسه ما بدأناش محادثة! اسألني عن أي مكان مجهز أو تحكم بالتطبيق أو حقوقك في مصر.',
        isEnglish: isEn,
      );
    }

    if (any([
      'امسح المحادثه',
      'مسح المحادثه',
      'محادثه جديده',
      'ابدا من جديد',
      'clear chat',
      'new chat',
      'reset conversation',
    ])) {
      session.clear();
      return AIResponse(
        intent: AIIntentType.appControl,
        replyText: isEn
            ? 'Conversation cleared! How can I help you now?'
            : 'تم مسح المحادثة! كيف أقدر أساعدك الآن؟',
        primaryAction: const AssistantAction(
          type: AssistantActionType.clearConversation,
          labelAr: 'محادثة جديدة',
          labelEn: 'New Chat',
          autoExecute: true,
        ),
        isEnglish: isEn,
      );
    }

    return null;
  }

  // ===========================================================================
  // 1. EMERGENCY / SOS
  // ===========================================================================
  static bool _isSosIntent(String query) {
    // Exclude "فتح صفحة الطوارئ" / "open sos page" / "أرقام الطوارئ" / hospital emergency dept
    if ((query.contains('صفحه') ||
            query.contains('شاشه') ||
            query.contains('جهات اتصال') ||
            query.contains('اضف مرافق') ||
            query.contains('اضافه مرافق') ||
            query.contains('ارقام الطوارئ') ||
            query.contains('رقم الطوارئ') ||
            query.contains('قسم طوارئ') ||
            query.contains('مستشفي طوارئ') ||
            query.contains('open ') ||
            query.contains('contacts') ||
            query.contains('numbers')) &&
        !query.contains('استغاثه') &&
        !query.contains('الحقني') &&
        !query.contains('الحقوني') &&
        !query.contains('ابعت موقعي')) {
      return false;
    }

    // Avoid triggering SOS when user asks "أنا فين / موقعي فين"
    if ((query.contains('موقعي فين') ||
            query.contains('فين موقعي') ||
            query.contains('انا فين')) &&
        !query.contains('ابعت') &&
        !query.contains('ارسل') &&
        !query.contains('استغاثه')) {
      return false;
    }

    // Avoid triggering SOS when user sets mobility profile "أنا مرافق"
    if (query.contains('مرافق') &&
        (query.contains('انا مرافق') ||
            query.contains('نوع الحركه') ||
            query.contains('ملفي') ||
            query.contains('مقدم رعايه'))) {
      return false;
    }

    // Require unmistakable personal emergency / SOS phrases (never fire on generic "ساعدني ألاقي...")
    return query.contains('استغاثه') ||
        query.contains('اغاثه') ||
        query.contains('الحقني') ||
        query.contains('الحقوني') ||
        query.contains('انجدني') ||
        query.contains('انقذوني') ||
        query.contains('انا في خطر') ||
        query.contains('ابعت موقعي') ||
        query.contains('ارسل موقعي') ||
        query.contains('ابعت لوكيشني') ||
        query.contains('نداء طوارئ') ||
        query.contains('حاله طوارئ') ||
        query.contains('محتاج نجده') ||
        (query.contains('نجده') && !query.contains('شرطه') && !query.contains('رقم')) ||
        (query.contains('مرافقي') &&
            (query.contains('كلم') ||
                query.contains('اتصل') ||
                query.contains('ابعت') ||
                query.contains('استغاثه') ||
                query.contains('طوارئ'))) ||
        RegExp(r'\bsos\b').hasMatch(query) ||
        query.contains('trigger sos') ||
        query.contains('help me now') ||
        query.contains('i am in danger') ||
        query.contains('send my location');
  }

  static Future<AIResponse> _handleSos({required bool isEn}) async {
    final emergency = await sosTrigger();
    if (emergency.success) {
      final locLineAr = emergency.mapsUrl != null
          ? '\nرابط موقعك المرفق:\n${emergency.mapsUrl}'
          : '\n(مقدرتش أحدد موقعك تلقائياً — يا ريت تبلّغ مرافقك بمكانك.)';
      final locLineEn = emergency.mapsUrl != null
          ? '\nAttached map link:\n${emergency.mapsUrl}'
          : '\n(GPS location was unavailable — please tell your companion where you are.)';

      return AIResponse(
        intent: AIIntentType.emergency,
        replyText: isEn
            ? '🚨 ${emergency.message}$locLineEn'
            : '🚨 ${emergency.message}$locLineAr',
        spokenText: isEn
            ? 'Emergency SOS draft opened for ${emergency.contactName ?? "your companion"}. Please press send to deliver the alert.'
            : 'فتحتلك رسالة الاستغاثة للمرافق ${emergency.contactName ?? ""} ومعاها موقعك. دوس إرسال دلوقتي عشان توصله فوراً.',
        emergencyResult: emergency,
        quickActions: [
          if (emergency.phone != null && emergency.phone!.isNotEmpty)
            AssistantAction(
              type: AssistantActionType.callPhone,
              labelAr: 'اتصال مباشر بـ ${emergency.contactName ?? "المرافق"}',
              labelEn: 'Call ${emergency.contactName ?? "Companion"}',
              phoneNumber: emergency.phone,
              iconName: 'phone',
            ),
          const AssistantAction(
            type: AssistantActionType.callPhone,
            labelAr: 'اتصال بالإسعاف (123)',
            labelEn: 'Call Ambulance (123)',
            phoneNumber: '123',
            iconName: 'phone',
          ),
          const AssistantAction(
            type: AssistantActionType.navigate,
            labelAr: 'إدارة جهات الطوارئ',
            labelEn: 'Manage SOS Contacts',
            route: 'EmergencySOS',
            iconName: 'sos',
          ),
        ],
        followUpSuggestions: isEn
            ? const ['Call Ambulance 123', 'Nearest hospital with ramp']
            : const ['اتصل بالإسعاف 123', 'أقرب مستشفى فيها منحدر'],
        isEnglish: isEn,
      );
    }

    return AIResponse(
      intent: AIIntentType.emergency,
      replyText: '⚠️ ${emergency.message}',
      spokenText: emergency.message,
      emergencyResult: emergency,
      quickActions: const [
        AssistantAction(
          type: AssistantActionType.navigate,
          labelAr: 'إضافة جهة اتصال للطوارئ',
          labelEn: 'Add Emergency Contact',
          route: 'EmergencySOS',
          iconName: 'sos',
        ),
        AssistantAction(
          type: AssistantActionType.callPhone,
          labelAr: 'اتصال بالإسعاف (123)',
          labelEn: 'Call Ambulance (123)',
          phoneNumber: '123',
          iconName: 'phone',
        ),
        AssistantAction(
          type: AssistantActionType.callPhone,
          labelAr: 'شرطة النجدة (122)',
          labelEn: 'Call Police (122)',
          phoneNumber: '122',
          iconName: 'phone',
        ),
      ],
      followUpSuggestions: isEn
          ? const ['Open SOS Contacts', 'Call Ambulance 123']
          : const ['افتح شاشة الطوارئ', 'اتصل بالإسعاف 123'],
      isEnglish: isEn,
    );
  }

  // ===========================================================================
  // 3. LIVE APP & ACCESSIBILITY CONTROLS
  // ===========================================================================
  static AIResponse? _matchAppControl(
    String query,
    AssistantSession session, {
    required bool isEn,
  }) {
    bool any(List<String> words) => words.any(query.contains);

    // Font size up
    if (any([
      'كبر الخط',
      'خط اكبر',
      'تكبير الخط',
      'زود حجم الخط',
      'الخط صغير',
      'bigger font',
      'larger font',
      'bigger text',
      'larger text',
      'increase font',
      'increase text',
    ])) {
      return AIResponse(
        intent: AIIntentType.appControl,
        replyText: isEn
            ? 'Font size increased for easier reading!'
            : 'من عنيا! كبّرتلك حجم الخط في التطبيق عشان القراية تبقى أوضح وأريح.',
        primaryAction: const AssistantAction(
          type: AssistantActionType.changeSetting,
          labelAr: 'تكبير الخط',
          labelEn: 'Increase Font',
          settingKey: 'font_scale',
          settingValue: 'increase',
          autoExecute: true,
          iconName: 'settings',
        ),
        quickActions: const [
          AssistantAction(
            type: AssistantActionType.changeSetting,
            labelAr: 'تراجع (حجم طبيعي)',
            labelEn: 'Reset Font Size',
            settingKey: 'font_scale',
            settingValue: 1.0,
            iconName: 'settings',
          ),
        ],
        followUpSuggestions: isEn
            ? const ['Enable high contrast', 'Reset font size']
            : const ['شغّل التباين العالي', 'رجّع الخط طبيعي'],
        isEnglish: isEn,
      );
    }

    // Font size down
    if (any([
      'صغر الخط',
      'خط اصغر',
      'تصغير الخط',
      'قلل حجم الخط',
      'smaller font',
      'smaller text',
      'decrease font',
      'decrease text',
    ])) {
      return AIResponse(
        intent: AIIntentType.appControl,
        replyText: isEn
            ? 'Font size decreased.'
            : 'تم تصغير حجم الخط في التطبيق.',
        primaryAction: const AssistantAction(
          type: AssistantActionType.changeSetting,
          labelAr: 'تصغير الخط',
          labelEn: 'Decrease Font',
          settingKey: 'font_scale',
          settingValue: 'decrease',
          autoExecute: true,
          iconName: 'settings',
        ),
        isEnglish: isEn,
      );
    }

    // Font size reset
    if (any([
      'رجع الخط',
      'خط عادي',
      'خط طبيعي',
      'الحجم الطبيعي للخط',
      'reset font',
      'normal font',
      'default font',
    ])) {
      return AIResponse(
        intent: AIIntentType.appControl,
        replyText: isEn
            ? 'Font size reset to normal.'
            : 'تم إعادة حجم الخط إلى الوضع الطبيعي.',
        primaryAction: const AssistantAction(
          type: AssistantActionType.changeSetting,
          labelAr: 'خط طبيعي',
          labelEn: 'Normal Font',
          settingKey: 'font_scale',
          settingValue: 1.0,
          autoExecute: true,
          iconName: 'settings',
        ),
        isEnglish: isEn,
      );
    }

    // High Contrast ON / OFF
    if (any(['تباين عالي', 'التباين العالي', 'تباين', 'high contrast'])) {
      final disable = any([
        'اقفل',
        'الغاء',
        'الغي',
        'اطفي',
        'وقف',
        'عادي',
        'disable',
        'turn off',
        'off',
      ]);
      return AIResponse(
        intent: AIIntentType.appControl,
        replyText: disable
            ? (isEn
                ? 'High contrast mode disabled.'
                : 'تم إيقاف وضع التباين العالي.')
            : (isEn
                ? 'High contrast mode enabled for sharper visibility!'
                : 'تم تفعيل وضع التباين العالي لرؤية أوضح للحدود والنصوص.'),
        primaryAction: AssistantAction(
          type: AssistantActionType.changeSetting,
          labelAr: disable ? 'إيقاف التباين العالي' : 'تفعيل التباين العالي',
          labelEn: disable ? 'Disable High Contrast' : 'Enable High Contrast',
          settingKey: 'high_contrast',
          settingValue: !disable,
          autoExecute: true,
          iconName: 'settings',
        ),
        isEnglish: isEn,
      );
    }

    // Dark Mode / Light Mode
    if (any([
      'الوضع الليلي',
      'دارك مود',
      'الوضع الداكن',
      'وضع ليلي',
      'الوضع المظلم',
      'dark mode',
      'night mode',
      'dark theme',
    ])) {
      final disable = any(['اقفل', 'الغي', 'اطفي', 'off', 'disable']);
      return AIResponse(
        intent: AIIntentType.appControl,
        replyText: disable
            ? (isEn ? 'Switched to Light Mode.' : 'تم التحويل إلى الوضع النهاري الفاتح.')
            : (isEn ? 'Dark Mode enabled!' : 'تم تفعيل الوضع الليلي المريح للعين.'),
        primaryAction: AssistantAction(
          type: AssistantActionType.changeSetting,
          labelAr: disable ? 'الوضع النهاري' : 'الوضع الليلي',
          labelEn: disable ? 'Light Mode' : 'Dark Mode',
          settingKey: 'theme_mode',
          settingValue: disable ? 'light' : 'dark',
          autoExecute: true,
          iconName: 'settings',
        ),
        isEnglish: isEn,
      );
    }

    if (any([
      'الوضع النهاري',
      'الوضع الفاتح',
      'لايت مود',
      'وضع فاتح',
      'light mode',
      'day mode',
      'light theme',
    ])) {
      return AIResponse(
        intent: AIIntentType.appControl,
        replyText: isEn
            ? 'Switched to Light Mode!'
            : 'تم تفعيل الوضع النهاري الفاتح.',
        primaryAction: const AssistantAction(
          type: AssistantActionType.changeSetting,
          labelAr: 'الوضع النهاري',
          labelEn: 'Light Mode',
          settingKey: 'theme_mode',
          settingValue: 'light',
          autoExecute: true,
          iconName: 'settings',
        ),
        isEnglish: isEn,
      );
    }

    // Language switch -> English
    if (any([
      'حول للانجليزي',
      'اللغه الانجليزيه',
      'غير اللغه انجليزي',
      'اتكلم انجليزي',
      'switch to english',
      'change language to english',
      'english language',
      'speak english',
    ])) {
      session.localeCode = 'en';
      return AIResponse(
        intent: AIIntentType.appControl,
        replyText: 'Done! Switched the app and voice assistant to English.',
        primaryAction: const AssistantAction(
          type: AssistantActionType.changeSetting,
          labelAr: 'التحويل للإنجليزية',
          labelEn: 'Switch to English',
          settingKey: 'language',
          settingValue: 'en',
          autoExecute: true,
          iconName: 'settings',
        ),
        followUpSuggestions: const [
          'Nearest accessible hospital',
          'Open interactive map',
          'Switch back to Arabic',
        ],
        isEnglish: true,
      );
    }

    // Language switch -> Arabic
    if (any([
      'حول للعربي',
      'اللغه العربيه',
      'غير اللغه عربي',
      'اتكلم عربي',
      'اتكلم مصري',
      'كلمني مصري',
      'باللهجه المصريه',
      'switch to arabic',
      'switch back to arabic',
      'change language to arabic',
      'arabic language',
      'speak arabic',
    ])) {
      session.localeCode = 'ar';
      return AIResponse(
        intent: AIIntentType.appControl,
        replyText: 'أحلى مسا! حوّلتلك التطبيق والمساعد الصوتي للعربي باللهجة المصرية.',
        primaryAction: const AssistantAction(
          type: AssistantActionType.changeSetting,
          labelAr: 'التحويل للعربية',
          labelEn: 'Switch to Arabic',
          settingKey: 'language',
          settingValue: 'ar',
          autoExecute: true,
          iconName: 'settings',
        ),
        followUpSuggestions: const [
          'أقرب مستشفى فيها منحدر',
          'افتح الخريطة التفاعلية',
          'إيه حقوقي في قانون 10؟',
        ],
        isEnglish: false,
      );
    }

    // TTS Speed
    if (any(['اتكلم ابطا', 'بطا الصوت', 'صوت ابطا', 'speak slower', 'slower'])) {
      session.ttsRate = (session.ttsRate - 0.1).clamp(0.3, 0.75);
      return AIResponse(
        intent: AIIntentType.appControl,
        replyText: isEn
            ? 'Got it — I will speak a bit slower now.'
            : 'حاضر، هتكلم بشكل أبطأ وأوضح دلوقتي.',
        primaryAction: AssistantAction(
          type: AssistantActionType.changeSetting,
          labelAr: 'إبطاء سرعة الكلام',
          labelEn: 'Slower Voice',
          settingKey: 'tts_rate',
          settingValue: session.ttsRate,
          autoExecute: true,
          iconName: 'settings',
        ),
        isEnglish: isEn,
      );
    }

    if (any(['اتكلم اسرع', 'سرع الصوت', 'صوت اسرع', 'speak faster', 'faster'])) {
      session.ttsRate = (session.ttsRate + 0.1).clamp(0.3, 0.75);
      return AIResponse(
        intent: AIIntentType.appControl,
        replyText: isEn
            ? 'Got it — I will speak faster now.'
            : 'تمام، هتكلم بسرعة أكبر دلوقتي.',
        primaryAction: AssistantAction(
          type: AssistantActionType.changeSetting,
          labelAr: 'تسريع الكلام',
          labelEn: 'Faster Voice',
          settingKey: 'tts_rate',
          settingValue: session.ttsRate,
          autoExecute: true,
          iconName: 'settings',
        ),
        isEnglish: isEn,
      );
    }

    // Mute / Unmute voice feedback
    if (any([
      'اقفل الصوت',
      'اسكت',
      'كتم الصوت',
      'وضع صامت',
      'بدون صوت',
      'mute voice',
      'mute',
      'turn off voice',
      'be quiet',
    ])) {
      return AIResponse(
        intent: AIIntentType.appControl,
        replyText: isEn
            ? 'Spoken replies muted. You can still read all answers here.'
            : 'تم كتم الصوت. هتقدر تقرأ كل الردود هنا براحتك.',
        spokenText: '',
        primaryAction: const AssistantAction(
          type: AssistantActionType.changeSetting,
          labelAr: 'كتم الصوت',
          labelEn: 'Mute Voice',
          settingKey: 'voice_feedback',
          settingValue: false,
          autoExecute: true,
          iconName: 'settings',
        ),
        isEnglish: isEn,
      );
    }

    if (any([
      'شغل الصوت',
      'فعل الصوت',
      'افتح الصوت',
      'unmute',
      'turn on voice',
      'enable voice',
    ])) {
      return AIResponse(
        intent: AIIntentType.appControl,
        replyText: isEn
            ? 'Voice replies are now enabled!'
            : 'تم تشغيل الردود الصوتية مرة أخرى!',
        primaryAction: const AssistantAction(
          type: AssistantActionType.changeSetting,
          labelAr: 'تفعيل الصوت',
          labelEn: 'Enable Voice',
          settingKey: 'voice_feedback',
          settingValue: true,
          autoExecute: true,
          iconName: 'settings',
        ),
        isEnglish: isEn,
      );
    }

    // Auto-listen / hands-free conversation mode
    if (any([
      'الاستماع التلقائي',
      'المحادثه المستمره',
      'auto listen',
      'hands free',
    ])) {
      final disable = any(['اقفل', 'وقف', 'الغي', 'stop', 'disable', 'off']);
      session.conversationMode = !disable;
      return AIResponse(
        intent: AIIntentType.appControl,
        replyText: disable
            ? (isEn
                ? 'Auto-listen paused. Tap the mic whenever you want to speak.'
                : 'تم إيقاف الاستماع التلقائي. اضغط على المايك وقت ما تحب تتكلم.')
            : (isEn
                ? 'Hands-free conversation mode enabled!'
                : 'تم تفعيل وضع المحادثة المستمرة بدون استخدام اليدين!'),
        primaryAction: AssistantAction(
          type: AssistantActionType.changeSetting,
          labelAr: disable ? 'إيقاف الاستماع التلقائي' : 'تفعيل الاستماع التلقائي',
          labelEn: disable ? 'Pause Auto-Listen' : 'Enable Auto-Listen',
          settingKey: 'conversation_mode',
          settingValue: !disable,
          autoExecute: true,
          iconName: 'settings',
        ),
        isEnglish: isEn,
      );
    }

    // Notifications toggle
    if (any(['اقفل الاشعارات', 'كتم الاشعارات', 'disable notifications', 'turn off notifications'])) {
      return AIResponse(
        intent: AIIntentType.appControl,
        replyText: isEn
            ? 'App notifications disabled.'
            : 'تم إيقاف إشعارات التطبيق.',
        primaryAction: const AssistantAction(
          type: AssistantActionType.changeSetting,
          labelAr: 'إيقاف الإشعارات',
          labelEn: 'Disable Notifications',
          settingKey: 'notifications',
          settingValue: false,
          autoExecute: true,
          iconName: 'settings',
        ),
        isEnglish: isEn,
      );
    }
    if (any(['شغل الاشعارات', 'فعل الاشعارات', 'enable notifications', 'turn on notifications'])) {
      return AIResponse(
        intent: AIIntentType.appControl,
        replyText: isEn
            ? 'App notifications enabled.'
            : 'تم تفعيل إشعارات التطبيق.',
        primaryAction: const AssistantAction(
          type: AssistantActionType.changeSetting,
          labelAr: 'تفعيل الإشعارات',
          labelEn: 'Enable Notifications',
          settingKey: 'notifications',
          settingValue: true,
          autoExecute: true,
          iconName: 'settings',
        ),
        isEnglish: isEn,
      );
    }

    // Direct Support Contact via Voice (WhatsApp, Email, Phone Call — no typing needed)
    if (any([
      'واتساب الدعم',
      'كلم الدعم واتساب',
      'ابعت واتساب للدعم',
      'راسل الدعم واتساب',
      'واتس الدعم',
      'support whatsapp',
      'whatsapp support',
      'message support on whatsapp',
    ])) {
      final waUrl =
          'https://wa.me/${AppConstants.supportWhatsAppIntl}?text=${Uri.encodeComponent('مرحباً، أحتاج مساعدة في تطبيق ONEWAY')}';
      return AIResponse(
        intent: AIIntentType.appControl,
        replyText: isEn
            ? 'Opening WhatsApp support chat directly (${AppConstants.supportWhatsAppNumber})...'
            : 'جاري فتح محادثة واتساب مباشرة مع الدعم الفني (${AppConstants.supportWhatsAppNumber})...',
        primaryAction: AssistantAction(
          type: AssistantActionType.openUrl,
          labelAr: 'محادثة واتساب الدعم (${AppConstants.supportWhatsAppNumber})',
          labelEn: 'WhatsApp Support (${AppConstants.supportWhatsAppNumber})',
          url: waUrl,
          autoExecute: true,
          iconName: 'link',
        ),
        isEnglish: isEn,
      );
    }

    if (any([
      'ابعت ايميل للدعم',
      'ايميل الدعم',
      'بريد الدعم',
      'راسل الدعم بالايميل',
      'ارسل بريد للدعم',
      'email support',
      'send email to support',
      'support email',
    ])) {
      final mailUrl =
          'mailto:${AppConstants.supportEmail}?subject=${Uri.encodeComponent('دعم تطبيق ONEWAY')}';
      return AIResponse(
        intent: AIIntentType.appControl,
        replyText: isEn
            ? 'Opening your email app addressed to ${AppConstants.supportEmail}...'
            : 'جاري فتح البريد الإلكتروني لإرسال رسالة مباشرة إلى ${AppConstants.supportEmail}...',
        primaryAction: AssistantAction(
          type: AssistantActionType.openUrl,
          labelAr: 'إرسال بريد إلى ${AppConstants.supportEmail}',
          labelEn: 'Email ${AppConstants.supportEmail}',
          url: mailUrl,
          autoExecute: true,
          iconName: 'link',
        ),
        isEnglish: isEn,
      );
    }

    if (any([
      'اتصل بالدعم',
      'كلم الدعم',
      'رقم الدعم',
      'call support',
      'phone support',
    ])) {
      return AIResponse(
        intent: AIIntentType.appControl,
        replyText: isEn
            ? 'Calling ONEWAY support on ${AppConstants.supportWhatsAppNumber}...'
            : 'جاري الاتصال برقم الدعم الفني ${AppConstants.supportWhatsAppNumber}...',
        primaryAction: const AssistantAction(
          type: AssistantActionType.callPhone,
          labelAr: 'اتصال بالدعم (${AppConstants.supportWhatsAppNumber})',
          labelEn: 'Call Support (${AppConstants.supportWhatsAppNumber})',
          phoneNumber: AppConstants.supportWhatsAppNumber,
          autoExecute: true,
          iconName: 'phone',
        ),
        isEnglish: isEn,
      );
    }

    // Open 3-step Accessibility Personalization sheet by voice
    if (any([
      'خصص احتياجاتي',
      'تخصيص الاحتياجات',
      'تخصيص الاتاحه',
      'تعديل احتياجات الوصول',
      'غير تفضيلات الاتاحه',
      'customize accessibility',
      'personalize accessibility',
      'edit my access needs',
    ])) {
      return AIResponse(
        intent: AIIntentType.appControl,
        replyText: isEn
            ? 'Opening your 3-step accessibility personalization guide...'
            : 'جاري فتح شاشة تخصيص احتياجات الوصول في 3 خطوات بسيطة...',
        primaryAction: const AssistantAction(
          type: AssistantActionType.changeSetting,
          labelAr: 'تخصيص احتياجات الوصول',
          labelEn: 'Personalize Access Needs',
          settingKey: 'open_personalization',
          settingValue: true,
          autoExecute: true,
          iconName: 'settings',
        ),
        isEnglish: isEn,
      );
    }

    // Direct Access Needs Update via Voice (no typing needed)
    final wantsNeedsUpdate = any([
      'احفظ احتياجاتي',
      'احتياجاتي هي',
      'اضف لاحتياجاتي',
      'فعل احتياج',
      'محتاج في المكان',
      'انا محتاج',
      'my access needs',
      'i need a ramp',
      'i need an elevator',
      'i need accessible restroom',
    ]);
    if (wantsNeedsUpdate &&
        !any(['ابحث', 'اقرب', 'مستشفي', 'مول', 'مطعم', 'كافيه', 'find ', 'search ', 'nearest'])) {
      final pickedNeeds = <String>[];
      if (any(['مدخل', 'بدون درجات', 'بدون سلالم', 'step free', 'step-free'])) {
        pickedNeeds.add('step_free_entrance');
      }
      if (any(['منحدر', 'رامب', 'رمب', 'ramp'])) {
        pickedNeeds.add('suitable_ramp');
      }
      if (any(['مصعد', 'اسانسير', 'elevator', 'lift'])) {
        pickedNeeds.add('accessible_elevator');
      }
      if (any(['حمام', 'دوره مياه', 'تواليت', 'restroom', 'bathroom'])) {
        pickedNeeds.add('accessible_restroom');
      }
      if (any(['ممرات', 'ابواب واسعه', 'ممر واسع', 'wide corridor', 'wide passage'])) {
        pickedNeeds.add('wide_passages');
      }
      if (any(['موقف', 'انتظار', 'باركينج', 'parking'])) {
        pickedNeeds.add('accessible_parking');
      }
      if (pickedNeeds.isNotEmpty) {
        final labels = pickedNeeds
            .map((id) => AccessNeedOption.byId(id))
            .whereType<AccessNeedOption>()
            .map((o) => isEn ? o.titleEn : o.titleAr)
            .join(isEn ? ', ' : '، ');
        return AIResponse(
          intent: AIIntentType.appControl,
          replyText: isEn
              ? 'Saved your access needs: $labels. Place results will now prioritize these automatically!'
              : 'تم حفظ احتياجات الوصول الخاصة بك: $labels. ستظهر الأماكن المطابقة لها أولاً تلقائياً!',
          primaryAction: AssistantAction(
            type: AssistantActionType.changeSetting,
            labelAr: 'حفظ احتياجات الوصول',
            labelEn: 'Save Access Needs',
            settingKey: 'access_needs',
            settingValue: pickedNeeds,
            autoExecute: true,
            iconName: 'settings',
          ),
          isEnglish: isEn,
        );
      }
    }

    // Sign Out by Voice
    if (any([
      'تسجيل الخروج',
      'سجل خروج',
      'اخرج من حسابي',
      'اقفل حسابي',
      'sign out',
      'log out',
      'logout',
    ])) {
      return AIResponse(
        intent: AIIntentType.appControl,
        replyText: isEn
            ? 'Signing you out safely and returning to the login screen...'
            : 'جاري تسجيل الخروج من حسابك بأمان والعودة لشاشة تسجيل الدخول...',
        primaryAction: const AssistantAction(
          type: AssistantActionType.changeSetting,
          labelAr: 'تسجيل الخروج',
          labelEn: 'Sign Out',
          settingKey: 'sign_out',
          settingValue: true,
          autoExecute: true,
          iconName: 'settings',
        ),
        isEnglish: isEn,
      );
    }

    // Mobility Profile Update via Voice (canonical 5-option model, zero crash risk)
    final wantsMobilityUpdate = any([
      'بستخدم',
      'استخدم',
      'نوع حركتي',
      'نوع الحركه',
      'طريقه تنقلي',
      'خصصلي',
      'حالتي',
      'كرسي متحرك',
      'كرسي كهربائي',
      'كرسي يدوي',
      'عربه اطفال',
      'عكاز',
      'مشايه',
      'المشي بدون مساعده',
      'بشكل عام',
      'my mobility',
      'i use a',
      'set mobility',
      'wheelchair',
      'stroller',
      'walker',
    ]);
    if (wantsMobilityUpdate &&
        !any(['ابحث', 'عايز مكان', 'مستشفي', 'مول', 'مطعم', 'find ', 'search '])) {
      MobilityProfileOption? chosen;
      if (any(['كرسي', 'كهرب', 'يدوي', 'wheelchair', 'electric', 'manual'])) {
        chosen = MobilityProfileOption.resolveOption('wheelchair');
      } else if (any(['عكاز', 'مشاي', 'بمساعده', 'كبار', 'senior', 'walker', 'crutch', 'assisted'])) {
        chosen = MobilityProfileOption.resolveOption('assisted_walking');
      } else if (any(['بدون مساعده', 'المشي العادي', 'صعوبه في الحركه', 'without assistance', 'walking difficulty'])) {
        chosen = MobilityProfileOption.resolveOption('walking_difficulty');
      } else if (any(['طفل', 'اطفال', 'عربه', 'stroller'])) {
        chosen = MobilityProfileOption.resolveOption('stroller');
      } else if (any(['بشكل عام', 'دون تخصيص', 'انا مرافق', 'مقدم رعايه', 'general', 'caregiver', 'companion'])) {
        chosen = MobilityProfileOption.resolveOption('general');
      }

      if (chosen != null) {
        session.mobilityType = chosen.firestoreValue;
        return AIResponse(
          intent: AIIntentType.appControl,
          replyText: isEn
              ? 'Mobility profile updated to "${chosen.titleEn}".\nAll place compatibility scores are now tailored to you (${chosen.priorityHintEn}).'
              : 'تم تحديث طريقة التنقل الخاصة بك إلى «${chosen.titleAr}».\nستتخصص تقييمات الأماكن الآن حسب احتياجاتك (${chosen.priorityHintAr}).',
          primaryAction: AssistantAction(
            type: AssistantActionType.changeSetting,
            labelAr: 'تحديث طريقة التنقل: ${chosen.titleAr}',
            labelEn: 'Set Mobility: ${chosen.titleEn}',
            settingKey: 'mobility_type',
            settingValue: chosen.firestoreValue,
            autoExecute: true,
            iconName: 'settings',
          ),
          followUpSuggestions: isEn
              ? const ['Best accessible places for me', 'Personalize my access needs']
              : const ['أفضل الأماكن المناسبة لي', 'خصص احتياجات الوصول الخاصة بي'],
          isEnglish: isEn,
        );
      }
    }

    return null;
  }

  // ===========================================================================
  // 4. PERSONAL ACCOUNT & LIVE GPS DATA QUERIES
  // ===========================================================================
  static Future<AIResponse?> _matchUserDataQuery(
    String query,
    AssistantSession session, {
    required bool isEn,
  }) async {
    bool any(List<String> words) => words.any(query.contains);

    // Where am I? (Honest GPS check)
    if (any([
      'انا فين',
      'موقعي فين',
      'فين موقعي',
      'فين انا',
      'مكاني فين',
      'where am i',
      'my current location',
      'check my location',
    ])) {
      final pos = await _getUserPosition(session);
      if (pos == null) {
        return AIResponse(
          intent: AIIntentType.userData,
          replyText: isEn
              ? 'I could not read your GPS location right now. Please enable Location Services and grant permission.'
              : 'مش قادر أحدد موقعك بالـ GPS دلوقتي. تأكد بس إنك مشغّل خدمة الموقع ومدّي الإذن للتطبيق.',
          quickActions: const [
            AssistantAction(
              type: AssistantActionType.navigate,
              labelAr: 'فتح الخريطة التفاعلية',
              labelEn: 'Open Interactive Map',
              route: 'ExploreMap',
              iconName: 'map',
            ),
          ],
          isEnglish: isEn,
        );
      }
      final lat = pos.$1.toStringAsFixed(5);
      final lng = pos.$2.toStringAsFixed(5);
      final mapsUrl = 'https://maps.google.com/?q=$lat,$lng';
      return AIResponse(
        intent: AIIntentType.userData,
        replyText: isEn
            ? 'Your current GPS coordinates are:\n$lat, $lng\nYou can open your exact pin on Maps or find accessible places nearby.'
            : 'إحداثيات موقعك دلوقتي على الـ GPS هي:\n$lat, $lng\nتقدر تفتح مكانك على الخريطة أو تقولي أدورلك على أقرب الأماكن المجهزة حواليك.',
        spokenText: isEn
            ? 'Your GPS location has been detected. You can view it on Google Maps or search for nearby accessible places.'
            : 'حددت موقعك بالجي بي إس تمام. تقدر تفتحه على الخريطة أو تقولي أشوفلك أقرب الأماكن المجهزة حواليك.',
        quickActions: [
          AssistantAction(
            type: AssistantActionType.openUrl,
            labelAr: 'عرض موقعي على خرائط جوجل',
            labelEn: 'View on Google Maps',
            url: mapsUrl,
            iconName: 'directions',
          ),
          const AssistantAction(
            type: AssistantActionType.navigate,
            labelAr: 'فتح خريطة ONEWAY',
            labelEn: 'Open ONEWAY Map',
            route: 'ExploreMap',
            iconName: 'map',
          ),
        ],
        followUpSuggestions: isEn
            ? const ['Nearest accessible hospital', 'Nearby accessible malls']
            : const ['أقرب مستشفى مجهزة مني', 'أقرب مول مجهز مني'],
        isEnglish: isEn,
      );
    }

    // Read My Personal Profile Aloud (Voice-only users who cannot read/type)
    if (any([
      'اقرا بياناتي',
      'بيانات حسابي',
      'ملفي الشخصي ايه',
      'معلومات حسابي',
      'اسمي ايه في التطبيق',
      'read my profile',
      'my account info',
      'my profile info',
    ])) {
      final doc = currentUserDocument;
      final name = (doc?.displayName ?? '').trim().isNotEmpty
          ? doc!.displayName.trim()
          : (currentUserDisplayName.isNotEmpty ? currentUserDisplayName : 'مستخدم ONEWAY');
      final email = (doc?.email ?? currentUserEmail).trim();
      final phone = (doc?.phoneNumber ?? currentPhoneNumber).trim();
      final gov = ((doc?.snapshotData['governorate'] as String?) ?? '').trim();
      final mobRaw =
          (doc?.snapshotData['mobility_type'] as String?) ?? session.mobilityType ?? '';
      final mobOpt = MobilityProfileOption.resolveOption(mobRaw);
      final rawNeeds = (doc?.snapshotData['access_needs'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[];
      final needLabels = rawNeeds
          .map((id) => AccessNeedOption.byId(id))
          .whereType<AccessNeedOption>()
          .map((o) => isEn ? o.titleEn : o.titleAr)
          .join(isEn ? ', ' : '، ');

      final arSummary = 'بيانات حسابك المسجّلة:\n'
          '• الاسم: $name\n'
          '${email.isNotEmpty ? '• البريد الإلكتروني: $email\n' : ''}'
          '${phone.isNotEmpty ? '• الهاتف: $phone\n' : ''}'
          '${gov.isNotEmpty ? '• المحافظة: $gov\n' : ''}'
          '• طريقة التنقل: ${mobOpt.titleAr}\n'
          '${needLabels.isNotEmpty ? '• احتياجات الوصول: $needLabels' : ''}';
      final enSummary = 'Your account profile:\n'
          '• Name: $name\n'
          '${email.isNotEmpty ? '• Email: $email\n' : ''}'
          '${phone.isNotEmpty ? '• Phone: $phone\n' : ''}'
          '${gov.isNotEmpty ? '• Governorate: $gov\n' : ''}'
          '• Mobility: ${mobOpt.titleEn}\n'
          '${needLabels.isNotEmpty ? '• Access needs: $needLabels' : ''}';

      return AIResponse(
        intent: AIIntentType.userData,
        replyText: isEn ? enSummary.trim() : arSummary.trim(),
        spokenText: isEn
            ? 'Your name is $name. Your mobility preference is ${mobOpt.titleEn}${needLabels.isNotEmpty ? ", with access needs: $needLabels" : ""}.'
            : 'اسمك المسجل هو $name، وطريقة تنقلك هي ${mobOpt.titleAr}${needLabels.isNotEmpty ? "، واحتياجات الوصول المختارة هي $needLabels" : ""}.',
        quickActions: const [
          AssistantAction(
            type: AssistantActionType.navigate,
            labelAr: 'تعديل الملف الشخصي',
            labelEn: 'Edit Profile',
            route: 'EditProfile',
            iconName: 'settings',
          ),
          AssistantAction(
            type: AssistantActionType.changeSetting,
            labelAr: 'تخصيص احتياجات الوصول',
            labelEn: 'Personalize Access Needs',
            settingKey: 'open_personalization',
            settingValue: true,
            iconName: 'settings',
          ),
        ],
        isEnglish: isEn,
      );
    }

    // Read My Favorites
    if (any([
      'ايه في مفضلتي',
      'اماكن مفضلتي',
      'الاماكن المحفوظه',
      'عندي ايه في المفضله',
      'كم مكان في المفضله',
      'list my favorites',
      'what are my favorites',
      'read my favorites',
      'my saved places',
    ])) {
      final favs = await _loadFavorites();
      if (favs.isEmpty) {
        return AIResponse(
          intent: AIIntentType.userData,
          replyText: isEn
              ? 'Your favorites list is currently empty. Search for a place and say "save the first one to favorites"!'
              : 'لسه ما ضفتش أي مكان في المفضلة. دوّر على أي مكان يعجبك وقولّي «احفظ الأول في المفضلة»!',
          quickActions: const [
            AssistantAction(
              type: AssistantActionType.navigate,
              labelAr: 'استكشاف الأماكن',
              labelEn: 'Explore Places',
              route: 'SearchFilters',
              iconName: 'map',
            ),
          ],
          isEnglish: isEn,
        );
      }
      final topNames = favs.take(5).map((f) => '• ${f.placeName}').join('\n');
      return AIResponse(
        intent: AIIntentType.userData,
        replyText: isEn
            ? 'You have ${favs.length} saved place(s) in Favorites:\n$topNames'
            : 'عندك ${favs.length} مكان محفوظ في المفضلة:\n$topNames',
        spokenText: isEn
            ? 'You have ${favs.length} favorites, including ${favs.take(3).map((e) => e.placeName).join(", ")}.'
            : 'عندك ${favs.length} أماكن محفوظة في المفضلة، من ضمنهم ${favs.take(3).map((e) => e.placeName).join("، ")}.',
        quickActions: const [
          AssistantAction(
            type: AssistantActionType.navigate,
            labelAr: 'فتح قائمة المفضلة',
            labelEn: 'Open Favorites',
            route: 'FavoritesPage',
            iconName: 'favorite',
          ),
        ],
        isEnglish: isEn,
      );
    }

    // Read My Reports Status
    if (any([
      'اخبار بلاغاتي',
      'حاله بلاغاتي',
      'عندي كام بلاغ',
      'بلاغاتي ايه',
      'status of my reports',
      'check my reports',
      'how many reports',
    ])) {
      final reports = await _loadReports();
      if (reports.isEmpty) {
        return AIResponse(
          intent: AIIntentType.userData,
          replyText: isEn
              ? 'You have not submitted any barrier reports yet. Say "report a barrier" anytime to help the community.'
              : 'لسه ما بعتّش أي بلاغات عوائق. لو قابلك عائق في أي مكان مسجّل في التطبيق قولّي «أبلغ عن عائق» فوراً.',
          quickActions: const [
            AssistantAction(
              type: AssistantActionType.navigate,
              labelAr: 'إرسال بلاغ عن مكان مسجّل',
              labelEn: 'Report a Barrier',
              route: 'SubmitAccessibilityReport',
              iconName: 'report',
            ),
          ],
          isEnglish: isEn,
        );
      }
      final lines = reports
          .take(4)
          .map((r) => '• ${r.placeName.isEmpty ? "مكان مسجّل" : r.placeName}: ${r.problemCategory} (${r.status})')
          .join('\n');
      return AIResponse(
        intent: AIIntentType.userData,
        replyText: isEn
            ? 'You have ${reports.length} barrier report(s):\n$lines'
            : 'عندك ${reports.length} بلاغ متسجل:\n$lines',
        spokenText: isEn
            ? 'You have ${reports.length} barrier reports submitted.'
            : 'عندك ${reports.length} بلاغات متسجلة على حسابك.',
        quickActions: const [
          AssistantAction(
            type: AssistantActionType.navigate,
            labelAr: 'عرض كل بلاغاتي',
            labelEn: 'View All My Reports',
            route: 'MyReports',
            iconName: 'report',
          ),
        ],
        isEnglish: isEn,
      );
    }

    // Read My Notifications
    if (any([
      'عندي اشعارات',
      'اخر الاشعارات',
      'اقرا الاشعارات',
      'في اشعارات جديده',
      'check notifications',
      'unread notifications',
      'read my notifications',
    ])) {
      final notifs = await _loadNotifications();
      final unread = notifs.where((n) => !n.isRead).toList();
      if (notifs.isEmpty) {
        return AIResponse(
          intent: AIIntentType.userData,
          replyText: isEn
              ? 'You have no notifications right now.'
              : 'لا توجد لديك إشعارات حالياً.',
          isEnglish: isEn,
        );
      }
      final list = (unread.isNotEmpty ? unread : notifs)
          .take(3)
          .map((n) => '• ${n.title}: ${n.body}')
          .join('\n');
      return AIResponse(
        intent: AIIntentType.userData,
        replyText: isEn
            ? 'You have ${unread.length} unread notification(s):\n$list'
            : 'لديك ${unread.length} إشعار غير مقروء:\n$list',
        spokenText: isEn
            ? 'You have ${unread.length} unread notifications.'
            : 'لديك ${unread.length} إشعارات غير مقروءة.',
        quickActions: const [
          AssistantAction(
            type: AssistantActionType.navigate,
            labelAr: 'فتح مركز الإشعارات',
            labelEn: 'Open Notifications',
            route: 'NotificationsPage',
            iconName: 'settings',
          ),
        ],
        isEnglish: isEn,
      );
    }

    return null;
  }

  // ===========================================================================
  // 5. CONTEXTUAL & DIRECT PLACE ACTIONS (Directions, Call, Favorite,
  //    Inspect Details/Features, Compare)
  // ===========================================================================
  static Future<AIResponse?> _matchPlaceAction(
    String query,
    AssistantSession session, {
    required bool isEn,
  }) async {
    bool any(List<String> words) => words.any(query.contains);

    final wantsDirections = any([
      'وديني',
      'وصلني',
      'اتجاهات',
      'ازاي اروح',
      'اروحله ازاي',
      'اروح ازاي',
      'طريق ل',
      'الطريق الى',
      'الطريق ل',
      'خذني',
      'directions',
      'navigate to',
      'take me to',
      'route to',
      'how to get to',
    ]);
    final wantsCall = any([
      'اتصل ب',
      'كلم ',
      'كلمهم',
      'رن علي',
      'رن عليهم',
      'رقم تليفون',
      'تليفون ',
      'call ',
      'phone number',
      'dial ',
    ]);
    final wantsSaveFav = any([
      'احفظ',
      'اضف للمفضله',
      'زود للمفضله',
      'حطه في المفضله',
      'حطها في المفضله',
      'save to favorites',
      'add to favorites',
      'bookmark',
    ]);
    final wantsRemoveFav = any([
      'شيل من المفضله',
      'شيله من المفضله',
      'احذف من المفضله',
      'امسح من المفضله',
      'remove from favorites',
      'unfavorite',
    ]);
    final wantsCompare = any([
      'قارن',
      'الفرق بين',
      'انهي احسن',
      'ايهم افضل',
      'مين احسن',
      'compare',
      'which is better',
    ]);
    final wantsInspect = any([
      'تفاصيل',
      'معلومات عن',
      'اعرف اكتر',
      'افتح المكان',
      'هل ',
      'ينفع ادخل',
      'مجهز للكرسي',
      'مواعيد',
      'فاتح امتي',
      'بيقفل امتي',
      'شغال لحد امتي',
      'عنوانه',
      'فين مكان',
      'عوائق',
      'details',
      'tell me about',
      'does ',
      'opening hours',
      'open the first',
      'open the second',
      'open the third',
    ]);

    if (!wantsDirections &&
        !wantsCall &&
        !wantsSaveFav &&
        !wantsRemoveFav &&
        !wantsCompare &&
        !wantsInspect) {
      return null;
    }

    // Compare places
    if (wantsCompare) {
      final placesToCompare = await _resolveMultiplePlaces(query, session);
      if (placesToCompare.length >= 2) {
        final p1 = placesToCompare[0];
        final p2 = placesToCompare[1];
        final c1 = AccessibilityScorer.evaluatePlace(
          p1,
          mobilityType: session.mobilityType,
        );
        final c2 = AccessibilityScorer.evaluatePlace(
          p2,
          mobilityType: session.mobilityType,
        );
        final winner = c1.scorePercent >= c2.scorePercent ? p1 : p2;
        final ar = 'مقارنة الإتاحة بين المكانين:\n\n'
            '1️⃣ ${p1.name} (${p1.city})\n'
            '• نسبة الملاءمة: ${c1.scorePercent}% (${c1.availableCount}/${c1.totalFeatures} معايير)\n'
            '• التقييم: ${p1.rating.toStringAsFixed(1)} ⭐\n\n'
            '2️⃣ ${p2.name} (${p2.city})\n'
            '• نسبة الملاءمة: ${c2.scorePercent}% (${c2.availableCount}/${c2.totalFeatures} معايير)\n'
            '• التقييم: ${p2.rating.toStringAsFixed(1)} ⭐\n\n'
            '✅ الأنسب لك حالياً: ${winner.name}.';
        final en = 'Accessibility Comparison:\n\n'
            '1) ${p1.name} (${p1.city}): ${c1.scorePercent}% match (${c1.availableCount}/${c1.totalFeatures} features), ${p1.rating.toStringAsFixed(1)}★\n'
            '2) ${p2.name} (${p2.city}): ${c2.scorePercent}% match (${c2.availableCount}/${c2.totalFeatures} features), ${p2.rating.toStringAsFixed(1)}★\n\n'
            'Best match for you: ${winner.name}.';
        return AIResponse(
          intent: AIIntentType.placeDetails,
          replyText: isEn ? en : ar,
          spokenText: isEn
              ? '${p1.name} scores ${c1.scorePercent} percent, while ${p2.name} scores ${c2.scorePercent} percent. ${winner.name} is the stronger match for you.'
              : '${p1.name} نسبته ${c1.scorePercent} في المية، و${p2.name} نسبته ${c2.scorePercent} في المية. الأنسب لك هو ${winner.name}.',
          places: [p1, p2],
          placeMatches: [
            PlaceMatch(place: p1, compatibility: c1),
            PlaceMatch(place: p2, compatibility: c2),
          ],
          followUpSuggestions: isEn
              ? ['Directions to ${winner.name}', 'Open ${winner.name} details']
              : ['وديني لـ ${winner.name}', 'تفاصيل ${winner.name}'],
          isEnglish: isEn,
        );
      }
      return null;
    }

    // Resolve single target place (from session ordinal OR named search)
    final target = await _resolveTargetPlace(query, session);
    if (target == null) return null;

    final compat = AccessibilityScorer.evaluatePlace(
      target,
      mobilityType: session.mobilityType,
    );

    // 5a. Directions / Navigation
    if (wantsDirections) {
      if (!target.hasLocation()) {
        return AIResponse(
          intent: AIIntentType.placeAction,
          replyText: isEn
              ? 'Coordinates for ${target.name} are not available yet. You can view its address: ${target.address}'
              : 'إحداثيات ${target.name} غير مسجلة بعد. العنوان: ${target.address}',
          places: [target],
          placeMatches: [PlaceMatch(place: target, compatibility: compat)],
          isEnglish: isEn,
        );
      }
      final action = AssistantAction(
        type: AssistantActionType.directions,
        labelAr: 'بدء الاتجاهات إلى ${target.name}',
        labelEn: 'Start Directions to ${target.name}',
        place: target,
        autoExecute: true,
        iconName: 'directions',
      );
      return AIResponse(
        intent: AIIntentType.placeAction,
        replyText: isEn
            ? 'Starting Google Maps directions to ${target.name} (${target.address}).\nNote: standard navigation is used — check entrance notes: ${target.accessibilityFeatures.entranceObstacles.isEmpty ? "none reported" : target.accessibilityFeatures.entranceObstacles}.'
            : 'جاري فتح الاتجاهات على خرائط جوجل إلى ${target.name} (${target.address}).\nملاحظة المدخل: ${target.accessibilityFeatures.entranceObstacles.isEmpty ? "لا توجد عوائق مسجلة" : target.accessibilityFeatures.entranceObstacles}.',
        spokenText: isEn
            ? 'Opening Google Maps directions to ${target.name}.'
            : 'جاري فتح الاتجاهات إلى ${target.name}.',
        places: [target],
        placeMatches: [PlaceMatch(place: target, compatibility: compat)],
        primaryAction: action,
        quickActions: [
          action,
          AssistantAction(
            type: AssistantActionType.openPlace,
            labelAr: 'فتح تفاصيل المكان',
            labelEn: 'Open Place Details',
            place: target,
            iconName: 'place',
          ),
        ],
        isEnglish: isEn,
      );
    }

    // 5b. Call Place
    if (wantsCall) {
      if (!target.hasPhoneNumber() || target.phoneNumber.trim().isEmpty) {
        return AIResponse(
          intent: AIIntentType.placeAction,
          replyText: isEn
              ? 'No phone number is currently listed for ${target.name}.'
              : 'لا يوجد رقم هاتف مسجل حالياً لـ ${target.name}.',
          places: [target],
          placeMatches: [PlaceMatch(place: target, compatibility: compat)],
          isEnglish: isEn,
        );
      }
      final callAction = AssistantAction(
        type: AssistantActionType.callPhone,
        labelAr: 'اتصال بـ ${target.name} (${target.phoneNumber})',
        labelEn: 'Call ${target.name} (${target.phoneNumber})',
        place: target,
        phoneNumber: target.phoneNumber,
        autoExecute: true,
        iconName: 'phone',
      );
      return AIResponse(
        intent: AIIntentType.placeAction,
        replyText: isEn
            ? 'Dialing ${target.name} at ${target.phoneNumber}.'
            : 'جاري الاتصال بـ ${target.name} على الرقم ${target.phoneNumber}.',
        spokenText: isEn
            ? 'Calling ${target.name}.'
            : 'جاري الاتصال بـ ${target.name}.',
        places: [target],
        placeMatches: [PlaceMatch(place: target, compatibility: compat)],
        primaryAction: callAction,
        quickActions: [callAction],
        isEnglish: isEn,
      );
    }

    // 5c. Save / Remove Favorite
    if (wantsSaveFav || wantsRemoveFav) {
      final add = !wantsRemoveFav;
      final favAction = AssistantAction(
        type: AssistantActionType.toggleFavorite,
        labelAr: add
            ? 'حفظ ${target.name} في المفضلة'
            : 'إزالة ${target.name} من المفضلة',
        labelEn: add
            ? 'Save ${target.name} to Favorites'
            : 'Remove ${target.name} from Favorites',
        place: target,
        addFavorite: add,
        autoExecute: true,
        iconName: 'favorite',
      );
      return AIResponse(
        intent: AIIntentType.placeAction,
        replyText: add
            ? (isEn
                ? 'Saving "${target.name}" to your Favorites!'
                : 'تمت إضافة «${target.name}» إلى قائمة المفضلة لديك!')
            : (isEn
                ? 'Removing "${target.name}" from your Favorites.'
                : 'تمت إزالة «${target.name}» من المفضلة.'),
        places: [target],
        placeMatches: [PlaceMatch(place: target, compatibility: compat)],
        primaryAction: favAction,
        quickActions: const [
          AssistantAction(
            type: AssistantActionType.navigate,
            labelAr: 'فتح المفضلة',
            labelEn: 'Open Favorites',
            route: 'FavoritesPage',
            iconName: 'favorite',
          ),
        ],
        isEnglish: isEn,
      );
    }

    // 5d. Inspect Specific Place Accessibility / Details
    final f = target.accessibilityFeatures;
    final statusNoteAr = target.isGenuinelyVerified
        ? 'موثق ميدانياً'
        : 'بيانات أولية غير موثقة ميدانياً بعد';
    final statusNoteEn = target.isGenuinelyVerified
        ? 'Field-verified'
        : 'Unverified seed/community data';

    String ynAr(bool has, bool val) => !has ? 'غير محدد' : (val ? 'نعم ✅' : 'لا ❌');
    String ynEn(bool has, bool val) => !has ? 'Unknown' : (val ? 'Yes ✅' : 'No ❌');

    final replyAr = 'تفاصيل الإتاحة لـ ${target.name} (${target.city}):\n'
        '• نسبة الملاءمة لك: ${compat.scorePercent}%\n'
        '• حالة التوثيق: $statusNoteAr\n'
        '• مدخل للكراسي: ${ynAr(f.hasWheelchairEntrance(), f.wheelchairEntrance)}\n'
        '• منحدر (رامب): ${ynAr(f.hasRamp(), f.ramp)}\n'
        '• مصعد مناسب: ${ynAr(f.hasSuitableElevator(), f.suitableElevator)}\n'
        '• حمام مجهز: ${ynAr(f.hasAccessibleRestroom(), f.accessibleRestroom)}\n'
        '• موقف سيارات: ${ynAr(f.hasAccessibleParking(), f.accessibleParking)}'
        '${f.corridorWidth.isNotEmpty ? "\n• عرض الممرات: ${f.corridorWidth}" : ""}'
        '${f.entranceObstacles.isNotEmpty ? "\n• ملاحظات المدخل: ${f.entranceObstacles}" : ""}'
        '${target.openingHours.isNotEmpty ? "\n• المواعيد: ${target.openingHours}" : ""}';

    final replyEn = 'Accessibility report for ${target.name} (${target.city}):\n'
        '• Compatibility score: ${compat.scorePercent}%\n'
        '• Verification: $statusNoteEn\n'
        '• Wheelchair entrance: ${ynEn(f.hasWheelchairEntrance(), f.wheelchairEntrance)}\n'
        '• Ramp: ${ynEn(f.hasRamp(), f.ramp)}\n'
        '• Suitable elevator: ${ynEn(f.hasSuitableElevator(), f.suitableElevator)}\n'
        '• Accessible restroom: ${ynEn(f.hasAccessibleRestroom(), f.accessibleRestroom)}\n'
        '• Accessible parking: ${ynEn(f.hasAccessibleParking(), f.accessibleParking)}'
        '${target.openingHours.isNotEmpty ? "\n• Hours: ${target.openingHours}" : ""}';

    String spokenFeatAr(bool has, bool val) =>
        !has ? 'لسه مش متحدد' : (val ? 'متوفر' : 'مش متوفر');
    String spokenFeatEn(bool has, bool val) =>
        !has ? 'not confirmed yet' : (val ? 'available' : 'not available');

    final asksHours = any(['مواعيد', 'فاتح امتي', 'بيقفل امتي', 'شغال لحد امتي', 'hours']);
    final spokenHoursPrefixAr = asksHours
        ? (target.openingHours.isNotEmpty
            ? 'مواعيد عمل ${target.name} هي ${target.openingHours}. '
            : 'مواعيد عمل ${target.name} لسه مش متسجلة. ')
        : '';

    final shouldAutoOpen = any(['افتح المكان', 'افتح تفاصيل', 'open place', 'open details']);
    final openAction = AssistantAction(
      type: AssistantActionType.openPlace,
      labelAr: 'فتح صفحة ${target.name}',
      labelEn: 'Open ${target.name}',
      place: target,
      autoExecute: shouldAutoOpen,
      iconName: 'place',
    );

    return AIResponse(
      intent: AIIntentType.placeDetails,
      replyText: isEn ? replyEn : replyAr,
      spokenText: isEn
          ? '${target.name} has a ${compat.scorePercent} percent accessibility match (${target.isGenuinelyVerified ? "field verified" : "awaiting field audit"}). Ramp is ${spokenFeatEn(f.hasRamp(), f.ramp)}, elevator is ${spokenFeatEn(f.hasSuitableElevator(), f.suitableElevator)}, and restroom is ${spokenFeatEn(f.hasAccessibleRestroom(), f.accessibleRestroom)}.'
          : '$spokenHoursPrefixAr${target.name} نسبة ملاءمته ليك ${compat.scorePercent} في المية، وهو ${target.isGenuinelyVerified ? "متراجع ميدانياً" : "لسه مستني فحص ميداني"}. الرامب ${spokenFeatAr(f.hasRamp(), f.ramp)}، والأسانسير ${spokenFeatAr(f.hasSuitableElevator(), f.suitableElevator)}، والحمام المجهز ${spokenFeatAr(f.hasAccessibleRestroom(), f.accessibleRestroom)}.',
      places: [target],
      placeMatches: [PlaceMatch(place: target, compatibility: compat)],
      primaryAction: shouldAutoOpen ? openAction : null,
      quickActions: [
        openAction,
        if (target.hasLocation())
          AssistantAction(
            type: AssistantActionType.directions,
            labelAr: 'الاتجاهات',
            labelEn: 'Directions',
            place: target,
            iconName: 'directions',
          ),
        if (target.hasPhoneNumber() && target.phoneNumber.isNotEmpty)
          AssistantAction(
            type: AssistantActionType.callPhone,
            labelAr: 'اتصال',
            labelEn: 'Call',
            place: target,
            phoneNumber: target.phoneNumber,
            iconName: 'phone',
          ),
        AssistantAction(
          type: AssistantActionType.toggleFavorite,
          labelAr: 'حفظ في المفضلة',
          labelEn: 'Save Favorite',
          place: target,
          addFavorite: true,
          iconName: 'favorite',
        ),
      ],
      followUpSuggestions: isEn
          ? const ['Directions to it', 'Save to favorites', 'Call this place']
          : const ['وديني للمكان ده', 'احفظه في المفضلة', 'اتصل بيه'],
      isEnglish: isEn,
    );
  }

  // ===========================================================================
  // 6. FULL APP NAVIGATION (18+ Routes + Category Deep-Linking + Go Back)
  // ===========================================================================
  static AIResponse? _matchAppNavigation(String query, {required bool isEn}) {
    bool any(List<String> words) => words.any(query.contains);

    // Go back
    if (any([
      'ارجع',
      'رجوع',
      'الصفحه السابقه',
      'الصفحه اللي فاتت',
      'اقفل المساعد',
      'go back',
      'close assistant',
    ])) {
      return AIResponse(
        intent: AIIntentType.navigation,
        replyText: isEn ? 'Going back...' : 'حاضر، جاري الرجوع للصفحة السابقة...',
        primaryAction: const AssistantAction(
          type: AssistantActionType.goBack,
          labelAr: 'رجوع',
          labelEn: 'Go Back',
          autoExecute: true,
          iconName: 'back',
        ),
        isEnglish: isEn,
      );
    }

    AIResponse nav({
      required String route,
      required String ar,
      required String en,
      Map<String, String> params = const {},
      String iconName = 'map',
    }) {
      return AIResponse(
        intent: AIIntentType.navigation,
        replyText: isEn ? en : ar,
        navigationRoute: route,
        primaryAction: AssistantAction(
          type: AssistantActionType.navigate,
          labelAr: ar,
          labelEn: en,
          route: route,
          routeParams: params,
          autoExecute: true,
          iconName: iconName,
        ),
        isEnglish: isEn,
      );
    }

    // Map (with optional category pre-filter!)
    if (any(['خريطه', 'الخريطه', 'open map', 'show map', 'interactive map'])) {
      final cat = _extractCategoryFilter(query);
      return nav(
        route: 'ExploreMap',
        params: cat != null ? {'category': cat} : const {},
        ar: cat != null
            ? 'بالتأكيد! جاري فتح الخريطة التفاعلية مصفاة على فئة «$cat»...'
            : 'بالتأكيد! جاري فتح الخريطة التفاعلية لعرض الأماكن المجهزة القريبة...',
        en: cat != null
            ? 'Opening the interactive map filtered to "$cat"...'
            : 'Opening the interactive accessibility map...',
        iconName: 'map',
      );
    }

    // Report a barrier
    if (any([
      'بلاغ جديد',
      'ابلغ عن',
      'بلغ عن',
      'عائق',
      'اشتكي',
      'تقديم بلاغ',
      'report a barrier',
      'report obstacle',
      'submit report',
    ]) &&
        !any(['بلاغاتي', 'my reports'])) {
      return nav(
        route: 'SubmitAccessibilityReport',
        ar: 'جاري نقلك إلى شاشة الإبلاغ عن عائق لمشاركة التفاصيل والصور...',
        en: 'Opening the barrier report screen so you can share details and photos...',
        iconName: 'report',
      );
    }

    // My Reports
    if (any(['بلاغاتي', 'افتح بلاغاتي', 'my reports', 'open reports'])) {
      return nav(
        route: 'MyReports',
        ar: 'جاري فتح صفحة بلاغاتك لمتابعة حالتها...',
        en: 'Opening your submitted reports...',
        iconName: 'report',
      );
    }

    // Suggest a new accessible place
    if (any([
      'اقترح مكان',
      'اضف مكان',
      'اضافه مكان',
      'مكان جديد',
      'suggest a place',
      'add a place',
      'submit a place',
    ])) {
      return nav(
        route: SuggestPlacePage.routeName,
        ar: 'رائع! جاري فتح شاشة اقتراح مكان مهيأ جديد لإضافته للمجتمع...',
        en: 'Great! Opening the Suggest an Accessible Place screen...',
        iconName: 'place',
      );
    }

    // Egypt Guide page explicitly requested
    if (any([
      'افتح الدليل',
      'دليلك في مصر',
      'دليل مصر',
      'دليل الحقوق',
      'open guide',
      'egypt guide',
      'rights guide',
    ])) {
      return nav(
        route: EgyptGuidePage.routeName,
        ar: 'جاري فتح «دليلك في مصر» للحقوق وبطاقة الخدمات المتكاملة والخطوط الساخنة...',
        en: 'Opening the Egypt Accessibility & Rights Guide...',
        iconName: 'guide',
      );
    }

    // Favorites
    if (any(['مفضله', 'المفضله', 'مفضلتي', 'open favorites', 'favorites page'])) {
      return nav(
        route: 'FavoritesPage',
        ar: 'جاري فتح قائمة الأماكن المحفوظة في المفضلة لديك...',
        en: 'Opening your saved Favorites...',
        iconName: 'favorite',
      );
    }

    // Search / Explorer screen
    if (any([
      'صفحه البحث',
      'الفلاتر',
      'تصفح الاماكن',
      'استكشف الاماكن',
      'search filters',
      'explore places',
    ])) {
      final cat = _extractCategoryFilter(query);
      return nav(
        route: 'SearchFilters',
        params: cat != null ? {'category': cat} : const {},
        ar: 'جاري فتح شاشة البحث المتقدم والفلاتر...',
        en: 'Opening advanced search & accessibility filters...',
        iconName: 'map',
      );
    }

    // Emergency SOS screen (contacts management)
    if (any([
      'شاشه الطوارئ',
      'صفحه الطوارئ',
      'جهات الطوارئ',
      'جهات اتصال الطوارئ',
      'اضف مرافق',
      'اضافه مرافق',
      'emergency contacts',
      'sos page',
      'open sos',
    ])) {
      return nav(
        route: 'EmergencySOS',
        ar: 'جاري فتح شاشة الطوارئ وإدارة جهات الاتصال الموثوقة...',
        en: 'Opening Emergency SOS & trusted contacts...',
        iconName: 'sos',
      );
    }

    // Notifications
    if (any(['الاشعارات', 'اشعاراتي', 'افتح الاشعارات', 'notifications'])) {
      return nav(
        route: 'NotificationsPage',
        ar: 'جاري فتح مركز الإشعارات...',
        en: 'Opening Notifications...',
        iconName: 'settings',
      );
    }

    // Settings
    if (any(['الاعدادات', 'اعدادات', 'settings', 'preferences'])) {
      return nav(
        route: 'SettingsPage',
        ar: 'جاري فتح شاشة الإعدادات وتخصيص إمكانية الوصول...',
        en: 'Opening App & Accessibility Settings...',
        iconName: 'settings',
      );
    }

    // Edit profile
    if (any(['تعديل الملف', 'تعديل بياناتي', 'تعديل البروفايل', 'edit profile'])) {
      return nav(
        route: 'EditProfile',
        ar: 'جاري فتح شاشة تعديل ملفك الشخصي...',
        en: 'Opening Edit Profile...',
        iconName: 'settings',
      );
    }

    // User profile
    if (any(['ملفي', 'البروفايل', 'حسابي', 'الملف الشخصي', 'my profile', 'open profile'])) {
      return nav(
        route: 'UserProfile',
        ar: 'جاري فتح ملفك الشخصي...',
        en: 'Opening your Profile...',
        iconName: 'settings',
      );
    }

    // Help & Support
    if (any(['الدعم الفني', 'تواصل معنا', 'المساعده والدعم', 'help and support', 'contact support'])) {
      return nav(
        route: 'HelpSupportPage',
        ar: 'جاري فتح صفحة المساعدة والدعم الفني...',
        en: 'Opening Help & Support...',
        iconName: 'guide',
      );
    }

    // Business Portal / Place Owner Registration & Management
    if (any([
      'تسجيل منشاه',
      'سجل منشاتك',
      'سجل مكاني',
      'ارفع مكاني',
      'تعديل مكاني',
      'اعدل مكاني',
      'صاحب مكان',
      'لوحه صاحب المكان',
      'صاحب عمل',
      'حساب اعمال',
      'بوابه الاعمال',
      'register business',
      'business portal',
      'business dashboard',
    ])) {
      final isDashboard = any([
        'لوحه',
        'بوابه',
        'تعديل مكاني',
        'اعدل مكاني',
        'dashboard',
        'portal',
      ]);
      return nav(
        route: isDashboard ? 'BusinessAdminDashboard' : 'BusinessRegistration',
        ar: isDashboard
            ? 'حاضر! بفتحلك لوحة صاحب المكان عشان تشوف مكانك وتعدّل بياناته...'
            : 'حاضر! بفتحلك صفحة تسجيل مكانك كصاحب نشاط في وان واي...',
        en: isDashboard
            ? 'Opening the Place Owner Portal...'
            : 'Opening Place Owner Registration...',
        iconName: 'place',
      );
    }

    // Admin Dashboard
    if (any(['لوحه الاداره', 'لوحه التحكم', 'admin dashboard'])) {
      return nav(
        route: AdminDashboardPage.routeName,
        ar: 'جاري فتح لوحة تحكم الإدارة...',
        en: 'Opening Admin Dashboard...',
        iconName: 'settings',
      );
    }

    // Home
    if (any(['الرئيسيه', 'الشاشه الرئيسيه', 'الصفحه الرئيسيه', 'go home', 'open home'])) {
      return nav(
        route: 'HomeDashboard',
        ar: 'جاري العودة إلى الشاشة الرئيسية...',
        en: 'Returning to the Home Dashboard...',
        iconName: 'map',
      );
    }

    // Legal pages
    if (any(['سياسه الخصوصيه', 'الخصوصيه', 'privacy policy'])) {
      return nav(
        route: PrivacyPolicyPage.routeName,
        ar: 'جاري فتح سياسة الخصوصية...',
        en: 'Opening Privacy Policy...',
        iconName: 'guide',
      );
    }
    if (any(['شروط الاستخدام', 'terms of use'])) {
      return nav(
        route: TermsOfUsePage.routeName,
        ar: 'جاري فتح شروط الاستخدام...',
        en: 'Opening Terms of Use...',
        iconName: 'guide',
      );
    }
    if (any(['عن التطبيق', 'عن oneway', 'about app', 'about oneway'])) {
      return nav(
        route: AboutAppPage.routeName,
        ar: 'جاري فتح صفحة عن تطبيق ONEWAY...',
        en: 'Opening About ONEWAY...',
        iconName: 'guide',
      );
    }

    return null;
  }

  // ===========================================================================
  // 8. SMALL TALK, CAPABILITIES, TIME & DATE
  // ===========================================================================
  static AIResponse? _matchSmallTalk(String query, {required bool isEn}) {
    bool any(List<String> words) => words.any(query.contains);

    if (any([
      'السلام عليكم',
      'صباح الخير',
      'صباح الفل',
      'صباح النور',
      'مساء الخير',
      'مساء الفل',
      'مساء النور',
      'اهلا',
      'هاي',
      'مرحبا',
      'ازيك',
      'ازاي حالك',
      'hello',
      'hi there',
      'good morning',
      'good evening',
      'hey',
    ]) &&
        query.split(' ').length <= 5) {
      return AIResponse(
        intent: AIIntentType.generalInfo,
        replyText: isEn
            ? 'Welcome! I am the ONEWAY smart voice assistant. I can find accessible places near you, start directions, call places, adjust app settings (font, contrast, dark mode, language), answer Egypt disability rights questions, or trigger SOS. What would you like to do?'
            : 'أهلاً بيك يا فندم! أنا مساعد ONEWAY الذكي باللهجة المصرية. أقدر أشوفلك أقرب الأماكن المجهزة حواليك، أفتحلك الاتجاهات أو أتصل بالمكان، أظبطلك إعدادات التطبيق بالصوت (تكبير الخط، التباين العالي، الوضع الليلي)، أجاوبك عن حقوقك وبطاقة الخدمات المتكاملة، وأساعدك في الطوارئ. تحب نبدأ بإيه؟',
        spokenText: isEn
            ? 'Welcome! I am the ONEWAY assistant. Ask me to find accessible places, navigate the app, change accessibility settings, or check your rights in Egypt.'
            : 'أهلاً بيك في مساعد وان واي! قولّي تحب أدورلك على مكان مجهز، ولا أظبطلك إعدادات التطبيق، ولا تسألني عن حقوقك في مصر؟',
        followUpSuggestions: isEn
            ? const [
                'Nearest hospital with ramp',
                'Increase font size',
                'Integrated Services Card steps',
                'What can you do?',
              ]
            : const [
                'أقرب مستشفى فيها منحدر',
                'كبّر الخط في التطبيق',
                'خطوات بطاقة الخدمات المتكاملة',
                'تقدر تعمل إيه؟',
              ],
        isEnglish: isEn,
      );
    }

    if (any([
      'عامل ايه',
      'اخبارك',
      'كيف حالك',
      'how are you',
    ])) {
      return AIResponse(
        intent: AIIntentType.generalInfo,
        replyText: isEn
            ? 'Doing great and ready to help you move barrier-free! What do you need right now?'
            : 'الحمد لله تمام وجاهز أساعدك في أي حاجة! تحب أدور لك على مكان مجهز أو أنفذ لك أمر في التطبيق؟',
        isEnglish: isEn,
      );
    }

    if (any([
      'مين انت',
      'عرفني بنفسك',
      'انت مين',
      'تقدر تعمل ايه',
      'بتعمل ايه',
      'كل القدرات',
      'مساعده',
      'what can you do',
      'who are you',
      'help',
      'capabilities',
    ]) &&
        !any(['دعم فني', 'support'])) {
      const ar = 'أنا مساعد ONEWAY الصوتي الذكي — تقدر تستخدم التطبيق بالكامل بالصوت فقط بدون أي كتابة:\n'
          '📍 البحث الذكي بالأقرب والملاءمة: «أقرب مستشفى فيها منحدر»، «قارن بين الأول والتاني»\n'
          '🧭 إجراءات فورية على الأماكن: «وديني للأول»، «اتصل بمستشفى دار الفؤاد»، «احفظه في المفضلة»، «هل مول مصر فيه حمام مجهز؟»\n'
          '🎛️ التحكم الكامل بالتطبيق والإتاحة: «كبّر الخط»، «شغّل التباين العالي»، «الوضع الليلي»، «أنا بستخدم كرسي متحرك»، «خصص احتياجاتي»\n'
          '📂 بياناتك الشخصية وإجراءاتك: «اقرأ بياناتي»، «إيه في مفضلتي؟»، «أخبار بلاغاتي؟»، «اقترح مكان»، «أبلغ عن عائق»\n'
          '💬 الدعم الفني المباشر: «واتساب الدعم»، «ابعت إيميل للدعم»، «اتصل بالدعم»\n'
          '🇪🇬 دليلك وحقوقك في مصر: بطاقة الخدمات المتكاملة، قانون 10 لسنة 2018، والخطوط الساخنة (123، 16736، 16439)\n'
          '🚨 الطوارئ: «اطلب استغاثة من مرافقي وابعث موقعي»';
      const en = 'I am the ONEWAY Smart Voice Assistant — you can operate the entire app by voice alone without typing:\n'
          '📍 GPS & Personalized Search: "Nearest hospital with ramp", "Compare the first two"\n'
          '🧭 Direct Place Actions: "Directions to the first one", "Call Mall of Egypt", "Save to favorites"\n'
          '🎛️ Voice App & Accessibility Controls: "Increase font size", "Enable high contrast", "Dark mode", "I use a wheelchair", "Personalize accessibility"\n'
          '📂 Personal Info & Actions: "Read my profile", "What are my favorites?", "Check my reports", "Suggest a place", "Report a barrier"\n'
          '💬 Direct Support: "WhatsApp support", "Email support", "Call support"\n'
          '🇪🇬 Egypt Rights Guide & Hotlines: Integrated Services Card, Law 10/2018, Metro access, hotlines (123, 16736, 16439)\n'
          '🚨 Emergency SOS: "Trigger SOS and share my location"';
      return AIResponse(
        intent: AIIntentType.generalInfo,
        replyText: isEn ? en : ar,
        spokenText: isEn
            ? 'I can search accessible places near you, start directions, call places, control font size, contrast, dark mode, and language, check your favorites and reports, answer Egypt disability rights questions, and trigger SOS.'
            : 'أقدر أبحث لك عن أقرب الأماكن المجهزة، أفتح الاتجاهات وأتصل بالأماكن وأحفظها في المفضلة، أتحكم في حجم الخط والتباين والوضع الليلي واللغة، أقرأ مفضلتك وبلاغاتك، أجاوبك عن بطاقة الخدمات المتكاملة وحقوقك في مصر، وأطلق نداء استغاثة عند الطوارئ.',
        followUpSuggestions: isEn
            ? const [
                'Nearest hospital with ramp',
                'Enable high contrast',
                'What are my favorites?',
                'Official Egyptian hotlines',
              ]
            : const [
                'أقرب مستشفى فيها منحدر',
                'شغّل التباين العالي',
                'إيه في مفضلتي؟',
                'اعرض كل الأرقام الرسمية',
              ],
        isEnglish: isEn,
      );
    }

    if (any([
      'شكرا',
      'متشكر',
      'تسلم',
      'تسلم ايدك',
      'كتر خيرك',
      'الف شكر',
      'يعطيك العافيه',
      'ربنا يخليك',
      'ربنا يباركلك',
      'thank you',
      'thanks',
    ])) {
      return AIResponse(
        intent: AIIntentType.generalInfo,
        replyText: isEn
            ? 'You are very welcome! I am always here whenever you need anything.'
            : 'العفو يا فندم، تحت أمرك في أي وقت! لو احتجت أي حاجة تانية أنا سامعك.',
        isEnglish: isEn,
      );
    }

    if (any(['مع السلامه', 'باي', 'تصبح على خير', 'سلام', 'goodbye', 'bye'])) {
      return AIResponse(
        intent: AIIntentType.generalInfo,
        replyText: isEn
            ? 'Goodbye! Wishing you a smooth, barrier-free day.'
            : 'مع ألف سلامة! يومك جميل وسهل ومن غير أي عوائق بإذن الله.',
        isEnglish: isEn,
      );
    }

    if (any(['الساعه كام', 'الوقت كام', 'الوقت دلوقتي', 'what time is it', 'current time'])) {
      final now = DateTime.now();
      final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
      final minute = now.minute.toString().padLeft(2, '0');
      final periodAr = now.hour < 12 ? 'الصبح' : 'مساءً';
      final periodEn = now.hour < 12 ? 'AM' : 'PM';
      return AIResponse(
        intent: AIIntentType.generalInfo,
        replyText: isEn
            ? 'It is currently $hour:$minute $periodEn.'
            : 'الساعة دلوقتي $hour:$minute $periodAr.',
        isEnglish: isEn,
      );
    }

    if (any(['النهارده كام', 'التاريخ', 'النهارده ايه', 'اليوم ايه', 'what date', 'today date'])) {
      final now = DateTime.now();
      const daysAr = [
        'الاثنين',
        'الثلاثاء',
        'الأربعاء',
        'الخميس',
        'الجمعة',
        'السبت',
        'الأحد',
      ];
      const daysEn = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      final dayName = isEn ? daysEn[now.weekday - 1] : daysAr[now.weekday - 1];
      return AIResponse(
        intent: AIIntentType.generalInfo,
        replyText: isEn
            ? 'Today is $dayName, ${now.day}/${now.month}/${now.year}.'
            : 'اليوم هو $dayName، الموافق ${now.day}/${now.month}/${now.year}.',
        isEnglish: isEn,
      );
    }

    return null;
  }

  // ===========================================================================
  // 9. CLOUD GEMINI 3.8 FLASH ASSISTANT (Grounded & Multi-Turn)
  // ===========================================================================
  static Future<AIResponse?> _tryRemoteAssistant(
    String rawQuery,
    AssistantSession session, {
    required bool isEn,
  }) async {
    try {
      final payload = <String, dynamic>{
        'query': rawQuery,
        'locale': isEn ? 'en' : 'ar',
        'mobilityType': session.mobilityType ?? '',
        'history': session.history.take(8).toList(),
        'lastPlaceIds': session.lastPlaces.map((p) => p.reference.id).toList(),
        if (session.lastInteractionId != null)
          'previousInteractionId': session.lastInteractionId,
        if (session.userLat != null && session.userLng != null)
          'userLocation': {
            'lat': session.userLat,
            'lng': session.userLng,
          },
      };

      Map<String, dynamic>? data;
      if (remoteAssistantCaller != null) {
        data = await remoteAssistantCaller!(payload);
      } else {
        final callable = FirebaseFunctions.instance.httpsCallable(
          'assistantQuery',
          options: HttpsCallableOptions(timeout: const Duration(seconds: 12)),
        );
        final res = await callable.call(payload);
        if (res.data is Map) {
          data = Map<String, dynamic>.from(res.data as Map);
        }
      }

      if (data == null || data['fallback'] == true) return null;

      final actionName = data['action'] as String?;
      final actionParams = data['actionParams'] is Map
          ? Map<String, dynamic>.from(data['actionParams'] as Map)
          : const <String, dynamic>{};

      if (actionName == 'SOS') {
        return await _handleSos(isEn: isEn);
      }

      final placeIds =
          (data['placeIds'] as List?)?.whereType<String>().toList() ??
              const <String>[];
      final places = <PlacesRecord>[];
      if (placeIds.isNotEmpty) {
        final allPlaces = await _loadPlaces();
        final byId = {for (final p in allPlaces) p.reference.id: p};
        for (final id in placeIds) {
          final found = byId[id];
          if (found != null) {
            places.add(found);
          } else if (placesProvider == null) {
            try {
              final doc = await PlacesRecord.collection.doc(id).get();
              if (doc.exists) places.add(PlacesRecord.fromSnapshot(doc));
            } catch (_) {}
          }
        }
      }

      final placeMatches = _buildPlaceMatches(places, session);
      final followUps = (data['followUpSuggestions'] as List?)
              ?.whereType<String>()
              .where((s) => s.trim().isNotEmpty)
              .take(4)
              .toList() ??
          const <String>[];

      final mappedAction = _mapRemoteAction(
        actionName,
        actionParams,
        places,
        isEn: isEn,
      );

      final reply = (data['reply'] as String?)?.trim().isNotEmpty == true
          ? (data['reply'] as String).trim()
          : (isEn ? 'Done!' : 'تمام، جاري التنفيذ...');

      final spoken = (data['spokenReply'] as String?)?.trim().isNotEmpty == true
          ? (data['spokenReply'] as String).trim()
          : reply;

      final intent = places.isNotEmpty
          ? AIIntentType.placeSearch
          : mappedAction != null
              ? _intentForAction(mappedAction.type)
              : AIIntentType.generalInfo;

      return AIResponse(
        intent: intent,
        replyText: reply,
        spokenText: spoken,
        places: places,
        placeMatches: placeMatches,
        navigationRoute: mappedAction?.type == AssistantActionType.navigate
            ? mappedAction?.route
            : null,
        primaryAction: mappedAction,
        quickActions: mappedAction != null ? [mappedAction] : const [],
        followUpSuggestions: followUps.isNotEmpty
            ? followUps
            : _defaultPlaceFollowUps(places, isEn: isEn),
        interactionId: data['interactionId'] as String?,
        source: 'cloud',
        isEnglish: isEn,
      );
    } catch (_) {
      return null;
    }
  }

  static AIIntentType _intentForAction(AssistantActionType type) {
    switch (type) {
      case AssistantActionType.navigate:
      case AssistantActionType.goBack:
        return AIIntentType.navigation;
      case AssistantActionType.triggerSos:
        return AIIntentType.emergency;
      case AssistantActionType.changeSetting:
      case AssistantActionType.clearConversation:
        return AIIntentType.appControl;
      case AssistantActionType.directions:
      case AssistantActionType.callPhone:
      case AssistantActionType.toggleFavorite:
      case AssistantActionType.openReport:
        return AIIntentType.placeAction;
      case AssistantActionType.openPlace:
        return AIIntentType.placeDetails;
      case AssistantActionType.openUrl:
        return AIIntentType.egyptGuide;
      case AssistantActionType.none:
        return AIIntentType.generalInfo;
    }
  }

  static AssistantAction? _mapRemoteAction(
    String? actionName,
    Map<String, dynamic> params,
    List<PlacesRecord> resolvedPlaces, {
    required bool isEn,
  }) {
    if (actionName == null || actionName.isEmpty) return null;

    // Legacy direct route names (ExploreMap, SubmitAccessibilityReport, FavoritesPage, ...)
    const directRoutes = {
      'HomeDashboard',
      'ExploreMap',
      'SearchFilters',
      'SubmitAccessibilityReport',
      'FavoritesPage',
      'EmergencySOS',
      'EgyptGuide',
      'MyReports',
      'NotificationsPage',
      'SettingsPage',
      'UserProfile',
      'EditProfile',
      'HelpSupportPage',
      'SuggestPlace',
      'BusinessRegistration',
      'BusinessAdminDashboard',
      'AdminDashboard',
      'PrivacyPolicy',
      'TermsOfUse',
      'AboutApp',
    };

    if (directRoutes.contains(actionName)) {
      final category = params['category'] as String?;
      return AssistantAction(
        type: AssistantActionType.navigate,
        labelAr: 'فتح الصفحة',
        labelEn: 'Open Screen',
        route: actionName,
        routeParams: category != null && category.isNotEmpty
            ? {'category': category}
            : const {},
        autoExecute: true,
        iconName: 'map',
      );
    }

    switch (actionName) {
      case 'navigate':
        final route = params['route'] as String?;
        if (route == null || !directRoutes.contains(route)) return null;
        final category = params['category'] as String?;
        return AssistantAction(
          type: AssistantActionType.navigate,
          labelAr: 'فتح الصفحة',
          labelEn: 'Open Screen',
          route: route,
          routeParams: category != null && category.isNotEmpty
              ? {'category': category}
              : const {},
          autoExecute: true,
          iconName: 'map',
        );
      case 'directions':
        if (resolvedPlaces.isEmpty) return null;
        return AssistantAction(
          type: AssistantActionType.directions,
          labelAr: 'الاتجاهات إلى ${resolvedPlaces.first.name}',
          labelEn: 'Directions to ${resolvedPlaces.first.name}',
          place: resolvedPlaces.first,
          autoExecute: true,
          iconName: 'directions',
        );
      case 'call_place':
        if (resolvedPlaces.isEmpty ||
            resolvedPlaces.first.phoneNumber.isEmpty) {
          return null;
        }
        return AssistantAction(
          type: AssistantActionType.callPhone,
          labelAr: 'اتصال بـ ${resolvedPlaces.first.name}',
          labelEn: 'Call ${resolvedPlaces.first.name}',
          place: resolvedPlaces.first,
          phoneNumber: resolvedPlaces.first.phoneNumber,
          autoExecute: true,
          iconName: 'phone',
        );
      case 'call_hotline':
        final num = params['phoneNumber'] as String?;
        if (num == null || num.isEmpty) return null;
        return AssistantAction(
          type: AssistantActionType.callPhone,
          labelAr: 'اتصال بالرقم $num',
          labelEn: 'Call $num',
          phoneNumber: num,
          autoExecute: params['autoExecute'] == true,
          iconName: 'phone',
        );
      case 'favorite_add':
      case 'favorite_remove':
        if (resolvedPlaces.isEmpty) return null;
        final add = actionName == 'favorite_add';
        return AssistantAction(
          type: AssistantActionType.toggleFavorite,
          labelAr: add ? 'حفظ في المفضلة' : 'إزالة من المفضلة',
          labelEn: add ? 'Save Favorite' : 'Remove Favorite',
          place: resolvedPlaces.first,
          addFavorite: add,
          autoExecute: true,
          iconName: 'favorite',
        );
      case 'open_place':
        if (resolvedPlaces.isEmpty) return null;
        return AssistantAction(
          type: AssistantActionType.openPlace,
          labelAr: 'تفاصيل ${resolvedPlaces.first.name}',
          labelEn: '${resolvedPlaces.first.name} Details',
          place: resolvedPlaces.first,
          autoExecute: true,
          iconName: 'place',
        );
      case 'setting':
        final key = params['settingKey'] as String?;
        if (key == null || key.isEmpty) return null;
        return AssistantAction(
          type: AssistantActionType.changeSetting,
          labelAr: 'تطبيق الإعداد',
          labelEn: 'Apply Setting',
          settingKey: key,
          settingValue: params['settingValue'],
          autoExecute: true,
          iconName: 'settings',
        );
      case 'open_url':
        final url = params['url'] as String?;
        if (url == null ||
            (!url.startsWith('https://') && !url.startsWith('mailto:'))) {
          return null;
        }
        return AssistantAction(
          type: AssistantActionType.openUrl,
          labelAr: 'فتح الرابط',
          labelEn: 'Open Link',
          url: url,
          iconName: 'link',
        );
      default:
        return null;
    }
  }

  // ===========================================================================
  // 10. ADVANCED LOCAL GPS + PERSONALIZED PLACE SEARCH ENGINE
  // ===========================================================================
  static Future<AIResponse> _searchPlacesLocally(
    String rawQuery,
    String normalizedQuery,
    AssistantSession session, {
    required bool isEn,
  }) async {
    try {
      final allPlaces = await _loadPlaces();
      if (allPlaces.isEmpty) {
        return AIResponse(
          intent: AIIntentType.generalInfo,
          replyText: isEn
              ? 'No places are registered yet. You can suggest an accessible place or register your own venue!'
              : 'لسه مفيش أماكن متسجلة حالياً. تقدر تقترح مكان مهيأ من الشاشة الرئيسية أو تسجّل مكانك لو إنت صاحب النشاط!',
          quickActions: const [
            AssistantAction(
              type: AssistantActionType.navigate,
              labelAr: 'اقترح مكاناً مهيأً',
              labelEn: 'Suggest a Place',
              route: SuggestPlacePage.routeName,
              iconName: 'place',
            ),
            AssistantAction(
              type: AssistantActionType.navigate,
              labelAr: 'سجّل مكانك (صاحب مكان)',
              labelEn: 'Register Venue (Owner)',
              route: 'BusinessRegistration',
              iconName: 'place',
            ),
          ],
          isEnglish: isEn,
        );
      }

      // Parse user requirements
      final wantsNearest = normalizedQuery.contains('اقرب') ||
          normalizedQuery.contains('قريب') ||
          normalizedQuery.contains('حولي') ||
          normalizedQuery.contains('جنبي') ||
          normalizedQuery.contains('near') ||
          normalizedQuery.contains('closest') ||
          normalizedQuery.contains('nearby');

      if (wantsNearest) {
        await _getUserPosition(session);
      }

      final requireRamp = normalizedQuery.contains('منحدر') ||
          normalizedQuery.contains('رمب') ||
          normalizedQuery.contains('رامب') ||
          normalizedQuery.contains('بدون سلالم') ||
          normalizedQuery.contains('ramp') ||
          normalizedQuery.contains('step-free');
      final requireElevator = normalizedQuery.contains('مصعد') ||
          normalizedQuery.contains('اسانسير') ||
          normalizedQuery.contains('elevator') ||
          normalizedQuery.contains('lift');
      final requireRestroom = normalizedQuery.contains('حمام') ||
          normalizedQuery.contains('تواليت') ||
          normalizedQuery.contains('دوره مياه') ||
          normalizedQuery.contains('restroom') ||
          normalizedQuery.contains('bathroom') ||
          normalizedQuery.contains('toilet');
      final requireParking = normalizedQuery.contains('موقف') ||
          normalizedQuery.contains('باركينج') ||
          normalizedQuery.contains('ركن') ||
          normalizedQuery.contains('parking');
      final requireEntrance = normalizedQuery.contains('مدخل') ||
          normalizedQuery.contains('كراسي') ||
          normalizedQuery.contains('entrance') ||
          normalizedQuery.contains('wheelchair');
      final requireVerified = normalizedQuery.contains('موثق ميدانيا') ||
          normalizedQuery.contains('معتمد ميدانيا') ||
          normalizedQuery.contains('verified only');

      final categoryFilter = _extractCategoryFilter(normalizedQuery);
      final cityFilter = _extractCityFilter(normalizedQuery);

      final scored = <({PlaceMatch match, double rankScore, bool strictMatch})>[];

      for (final place in allPlaces) {
        final feat = place.accessibilityFeatures;
        final placeText = _normalize(
          '${place.name} ${place.category} ${place.description} ${place.address} ${place.city} ${place.governorate}',
        );

        var strictMatch = true;
        double score = 0;

        // Category match
        if (categoryFilter != null) {
          if (placeText.contains(_normalize(categoryFilter))) {
            score += 35;
          } else {
            strictMatch = false;
          }
        }

        // City / governorate match
        if (cityFilter != null) {
          if (placeText.contains(_normalize(cityFilter))) {
            score += 30;
          } else {
            strictMatch = false;
          }
        }

        // Feature requirements
        if (requireRamp) {
          if (feat.hasRamp() && feat.ramp) {
            score += 15;
          } else {
            strictMatch = false;
          }
        }
        if (requireElevator) {
          if (feat.hasSuitableElevator() && feat.suitableElevator) {
            score += 15;
          } else {
            strictMatch = false;
          }
        }
        if (requireRestroom) {
          if (feat.hasAccessibleRestroom() && feat.accessibleRestroom) {
            score += 15;
          } else {
            strictMatch = false;
          }
        }
        if (requireParking) {
          if (feat.hasAccessibleParking() && feat.accessibleParking) {
            score += 15;
          } else {
            strictMatch = false;
          }
        }
        if (requireEntrance && !feat.wheelchairEntrance) {
          // Soft penalty if user generally said "كراسي"
          score -= 10;
        }
        if (requireVerified && !place.isGenuinelyVerified) {
          strictMatch = false;
        }

        // Free-text token overlap (excluding common stop words)
        final tokens = _meaningfulTokens(normalizedQuery);
        var tokenHits = 0;
        for (final t in tokens) {
          if (placeText.contains(t)) {
            tokenHits++;
            score += 12;
          }
        }
        if (categoryFilter == null &&
            cityFilter == null &&
            !requireRamp &&
            !requireElevator &&
            !requireRestroom &&
            !requireParking &&
            !wantsNearest &&
            tokens.isNotEmpty &&
            tokenHits == 0) {
          strictMatch = false;
        }

        // Personalized compatibility score (0..100 -> 0..25 weight)
        final compat = AccessibilityScorer.evaluatePlace(
          place,
          mobilityType: session.mobilityType,
        );
        score += compat.scorePercent * 0.25;

        // Rating boost
        score += place.rating * 2.0;

        // Distance boost when GPS available
        double? distanceKm;
        if (session.userLat != null &&
            session.userLng != null &&
            place.hasLocation()) {
          distanceKm = haversineDistanceKm(
            session.userLat!,
            session.userLng!,
            place.location!.latitude,
            place.location!.longitude,
          );
          if (wantsNearest) {
            // Closer places get strong ranking priority
            score += math.max(0, 50 - distanceKm * 1.5);
          } else {
            score += math.max(0, 12 - distanceKm * 0.3);
          }
        }

        scored.add((
          match: PlaceMatch(
            place: place,
            compatibility: compat,
            distanceKm: distanceKm,
            highlights: _featureHighlights(feat, isEn: isEn),
          ),
          rankScore: score,
          strictMatch: strictMatch,
        ));
      }

      scored.sort((a, b) {
        if (a.strictMatch != b.strictMatch) {
          return a.strictMatch ? -1 : 1;
        }
        if (wantsNearest &&
            a.match.distanceKm != null &&
            b.match.distanceKm != null &&
            (a.rankScore - b.rankScore).abs() < 12) {
          return a.match.distanceKm!.compareTo(b.match.distanceKm!);
        }
        return b.rankScore.compareTo(a.rankScore);
      });

      final exactMatches =
          scored.where((s) => s.strictMatch).map((s) => s.match).toList();
      final finalMatches = (exactMatches.isNotEmpty
              ? exactMatches
              : scored.map((s) => s.match).toList())
          .take(4)
          .toList();

      final sb = StringBuffer();
      if (exactMatches.isNotEmpty) {
        sb.writeln(
          isEn
              ? 'Found ${exactMatches.length} accessible place(s) matching your request:'
              : 'لقيتلك ${exactMatches.length} مكان مناسب لطلبك:',
        );
      } else {
        sb.writeln(
          isEn
              ? 'No exact match for all filters, so here are the best accessible places available:'
              : 'ملقيتش مكان مطابق لكل الشروط بالظبط، بس دي أحسن الأماكن المجهزة المتاحة دلوقتي:',
        );
      }

      for (final m in finalMatches.take(3)) {
        final distText = m.formattedDistance(isEnglish: isEn);
        final distSuffix = distText != null ? ' • $distText' : '';
        sb.writeln(
          '\n📍 ${m.place.name} (${m.place.city}$distSuffix)',
        );
        sb.writeln(
          isEn
              ? '  Compatibility: ${m.compatibility.scorePercent}% • ${m.highlights.join(" • ")}'
              : '  نسبة الملاءمة: ${m.compatibility.scorePercent}% • ${m.highlights.join(" • ")}',
        );
      }

      final topPlace = finalMatches.first.place;
      final topDist = finalMatches.first.formattedDistance(isEnglish: isEn);
      final spokenAr = exactMatches.isNotEmpty
          ? 'لقيتلك ${exactMatches.length} أماكن مناسبة. أحسنهم ${topPlace.name} في ${topPlace.city}${topDist != null ? "، $topDist" : ""}، ونسبة ملاءمته ليك ${finalMatches.first.compatibility.scorePercent} في المية. تحب أوديك ليه على الخريطة ولا أفتحلك تفاصيله؟'
          : 'أقرب اقتراح متاح دلوقتي هو ${topPlace.name} في ${topPlace.city} بنسبة ملاءمة ${finalMatches.first.compatibility.scorePercent} في المية.';
      final spokenEn = exactMatches.isNotEmpty
          ? 'I found ${exactMatches.length} matching places. Top match is ${topPlace.name} in ${topPlace.city}, with ${finalMatches.first.compatibility.scorePercent} percent compatibility. Would you like directions or details?'
          : 'Here are the top accessible places available, starting with ${topPlace.name} at ${finalMatches.first.compatibility.scorePercent} percent compatibility.';

      final places = finalMatches.map((m) => m.place).toList();
      return AIResponse(
        intent: AIIntentType.placeSearch,
        replyText: sb.toString().trim(),
        spokenText: isEn ? spokenEn : spokenAr,
        places: places,
        placeMatches: finalMatches,
        quickActions: [
          if (categoryFilter != null)
            AssistantAction(
              type: AssistantActionType.navigate,
              labelAr: 'عرض الكل على الخريطة',
              labelEn: 'View All on Map',
              route: 'ExploreMap',
              routeParams: {'category': categoryFilter},
              iconName: 'map',
            ),
        ],
        followUpSuggestions: _defaultPlaceFollowUps(places, isEn: isEn),
        isEnglish: isEn,
      );
    } catch (_) {
      return AIResponse(
        intent: AIIntentType.generalInfo,
        replyText: isEn
            ? 'I am the ONEWAY assistant. Ask me for accessible hospitals, malls, transit, app controls, or emergency SOS!'
            : 'أهلاً بك! أنا مساعد ONEWAY الذكي. يمكنك أن تطلب مني بالصوت أو الكتابة:\n'
                '• «أقرب مستشفى فيها منحدر»\n'
                '• «كبّر الخط» أو «شغّل الوضع الليلي»\n'
                '• «خطوات بطاقة الخدمات المتكاملة»\n'
                '• «اطلب استغاثة من مرافقي وابعث موقعي»',
        isEnglish: isEn,
      );
    }
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  static List<String> _defaultPlaceFollowUps(
    List<PlacesRecord> places, {
    required bool isEn,
  }) {
    if (places.isEmpty) {
      return isEn
          ? const ['Open map', 'What can you do?']
          : const ['افتح الخريطة', 'تقدر تعمل إيه؟'];
    }
    if (places.length >= 2) {
      return isEn
          ? const [
              'Directions to the first one',
              'Compare the first two',
              'Save the first to favorites',
              'Call the first one',
            ]
          : const [
              'وديني للمكان الأول',
              'قارن بين الأول والتاني',
              'احفظ الأول في المفضلة',
              'اتصل بالمكان الأول',
            ];
    }
    return isEn
        ? const ['Directions to it', 'Save to favorites', 'Call this place']
        : const ['وديني للمكان ده', 'احفظه في المفضلة', 'اتصل بيه'];
  }

  static List<String> _featureHighlights(
    AccessibilityFeaturesStruct f, {
    required bool isEn,
  }) {
    final list = <String>[];
    if (f.hasWheelchairEntrance() && f.wheelchairEntrance) {
      list.add(isEn ? 'Wheelchair entrance' : 'مدخل للكراسي');
    }
    if (f.hasRamp() && f.ramp) {
      list.add(isEn ? 'Ramp' : 'منحدر');
    }
    if (f.hasSuitableElevator() && f.suitableElevator) {
      list.add(isEn ? 'Elevator' : 'مصعد');
    }
    if (f.hasAccessibleRestroom() && f.accessibleRestroom) {
      list.add(isEn ? 'Restroom' : 'حمام مجهز');
    }
    if (f.hasAccessibleParking() && f.accessibleParking) {
      list.add(isEn ? 'Parking' : 'موقف سيارات');
    }
    if (list.isEmpty) {
      list.add(isEn ? 'Limited info' : 'بيانات إتاحة محدودة');
    }
    return list;
  }

  static List<PlaceMatch> _buildPlaceMatches(
    List<PlacesRecord> places,
    AssistantSession session,
  ) {
    return places.map((place) {
      final compat = AccessibilityScorer.evaluatePlace(
        place,
        mobilityType: session.mobilityType,
      );
      double? dist;
      if (session.userLat != null &&
          session.userLng != null &&
          place.hasLocation()) {
        dist = haversineDistanceKm(
          session.userLat!,
          session.userLng!,
          place.location!.latitude,
          place.location!.longitude,
        );
      }
      return PlaceMatch(
        place: place,
        compatibility: compat,
        distanceKm: dist,
        highlights: _featureHighlights(
          place.accessibilityFeatures,
          isEn: session.isEnglish,
        ),
      );
    }).toList();
  }

  static String? _extractCategoryFilter(String normalizedQuery) {
    bool any(List<String> words) => words.any(normalizedQuery.contains);
    if (any([
      'مستشفي',
      'مستشفيات',
      'طبي',
      'عياده',
      'دكتور',
      'علاج',
      'صيدليه',
      'hospital',
      'clinic',
      'medical',
      'pharmacy',
    ])) {
      return 'طبي';
    }
    if (any([
      'مول',
      'مولات',
      'تسوق',
      'تجاري',
      'محل',
      'سوق',
      'mall',
      'shopping',
    ])) {
      return 'تسوق';
    }
    if (any([
      'جامع',
      'كليه',
      'مدرسه',
      'تعليم',
      'university',
      'college',
      'school',
      'auc',
    ])) {
      return 'تعليم';
    }
    if (any([
      'متحف',
      'مكتبه',
      'ثقاف',
      'سياح',
      'اثار',
      'حديقه',
      'museum',
      'library',
      'culture',
      'park',
      'nmec',
    ])) {
      return 'ثقاف';
    }
    if (any([
      'قطار',
      'محط',
      'مواصلات',
      'مترو',
      'بشتيل',
      'station',
      'train',
      'transit',
      'metro',
    ])) {
      return 'مواصلات';
    }
    if (any(['مطعم', 'كافيه', 'قهوه', 'اكل', 'restaurant', 'cafe', 'food'])) {
      return 'مطعم';
    }
    if (any(['فندق', 'اوتيل', 'hotel'])) {
      return 'فندق';
    }
    if (any(['بنك', 'صراف', 'bank'])) {
      return 'بنك';
    }
    return null;
  }

  static String? _extractCityFilter(String normalizedQuery) {
    const cityAliases = <String, String>{
      '6 اكتوبر': '6 اكتوبر',
      'السادس من اكتوبر': '6 اكتوبر',
      'اكتوبر': '6 اكتوبر',
      'october': '6 اكتوبر',
      'الجيزه': 'الجيزه',
      'giza': 'الجيزه',
      'القاهره الجديده': 'القاهره الجديده',
      'التجمع': 'التجمع',
      'new cairo': 'القاهره الجديده',
      'مدينه نصر': 'مدينه نصر',
      'nasr city': 'مدينه نصر',
      'الزمالك': 'الزمالك',
      'zamalek': 'الزمالك',
      'المعادي': 'المعادي',
      'maadi': 'المعادي',
      'الفسطاط': 'الفسطاط',
      'منيل': 'منيل',
      'بشتيل': 'بشتيل',
      'الشيخ زايد': 'الشيخ زايد',
      'مصر الجديده': 'مصر الجديده',
      'الدقي': 'الدقي',
      'المهندسين': 'المهندسين',
      'القاهره': 'القاهره',
      'cairo': 'القاهره',
      'الاسكندريه': 'الاسكندريه',
      'اسكندريه': 'الاسكندريه',
      'alexandria': 'الاسكندريه',
      'المنصوره': 'المنصوره',
      'طنطا': 'طنطا',
      'اسيوط': 'اسيوط',
      'اسوان': 'اسوان',
      'الاقصر': 'الاقصر',
      'شرم الشيخ': 'شرم الشيخ',
      'الغردقه': 'الغردقه',
    };

    for (final entry in cityAliases.entries) {
      if (normalizedQuery.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  static List<String> _meaningfulTokens(String normalizedQuery) {
    const stopWords = {
      'عايز',
      'ابحث',
      'عن',
      'في',
      'من',
      'علي',
      'الي',
      'مكان',
      'اماكن',
      'مجهز',
      'مجهزه',
      'مهيا',
      'مهياه',
      'مناسب',
      'مناسبه',
      'قريب',
      'اقرب',
      'مني',
      'فيها',
      'فيه',
      'ممكن',
      'لو',
      'سمحت',
      'find',
      'search',
      'for',
      'the',
      'near',
      'nearest',
      'me',
      'with',
      'accessible',
      'place',
      'places',
    };
    return normalizedQuery
        .split(RegExp(r'[\s،,؟?\.]+'))
        .where((w) => w.length > 2 && !stopWords.contains(w))
        .toList();
  }

  static Future<PlacesRecord?> _resolveTargetPlace(
    String normalizedQuery,
    AssistantSession session,
  ) async {
    // 1. Ordinal reference to last results ("الأول / التاني / التالت / الرابع")
    if (session.lastPlaces.isNotEmpty) {
      if (_containsOrdinal(normalizedQuery, 0)) return session.lastPlaces[0];
      if (session.lastPlaces.length >= 2 &&
          _containsOrdinal(normalizedQuery, 1)) {
        return session.lastPlaces[1];
      }
      if (session.lastPlaces.length >= 3 &&
          _containsOrdinal(normalizedQuery, 2)) {
        return session.lastPlaces[2];
      }
      if (session.lastPlaces.length >= 4 &&
          _containsOrdinal(normalizedQuery, 3)) {
        return session.lastPlaces[3];
      }
    }

    // 2. Named match against available places
    final allPlaces = await _loadPlaces();
    PlacesRecord? bestPlace;
    int bestScore = 0;

    for (final place in allPlaces) {
      final normName = _normalize(place.name);
      if (normName.isEmpty) continue;

      if (normalizedQuery.contains(normName)) {
        return place;
      }

      final nameTokens = normName
          .split(RegExp(r'[\s\(\)\-]+'))
          .where((t) =>
              t.length >= 3 &&
              t != 'مستشفي' &&
              t != 'متحف' &&
              t != 'محطه' &&
              t != 'مكتبه' &&
              t != 'مول' &&
              t != 'الجامعه' &&
              t != 'القاهره' &&
              t != 'mall' &&
              t != 'egypt')
          .toList();

      var score = 0;
      for (final token in nameTokens) {
        if (normalizedQuery.contains(token)) {
          score += token.length;
        }
      }
      if (score > bestScore && score >= 4) {
        bestScore = score;
        bestPlace = place;
      }
    }

    if (bestPlace != null) return bestPlace;

    // 3. Pronominal reference to last focused place ("المكان ده / بيه / له / it / this")
    if (session.lastFocusedPlace != null &&
        (normalizedQuery.contains('ده') ||
            normalizedQuery.contains('دي') ||
            normalizedQuery.contains('بيه') ||
            normalizedQuery.contains('بيها') ||
            normalizedQuery.contains('له') ||
            normalizedQuery.contains('لها') ||
            normalizedQuery.contains('احفظه') ||
            normalizedQuery.contains('شيله') ||
            normalizedQuery.contains('تفاصيله') ||
            normalizedQuery.contains('this') ||
            normalizedQuery.contains(' it'))) {
      return session.lastFocusedPlace;
    }

    return null;
  }

  static Future<List<PlacesRecord>> _resolveMultiplePlaces(
    String normalizedQuery,
    AssistantSession session,
  ) async {
    final allPlaces = await _loadPlaces();
    final matched = <PlacesRecord>[];

    for (final place in allPlaces) {
      final normName = _normalize(place.name);
      final nameTokens = normName
          .split(RegExp(r'[\s\(\)\-]+'))
          .where((t) =>
              t.length >= 4 &&
              t != 'مستشفي' &&
              t != 'متحف' &&
              t != 'القاهره' &&
              t != 'الجامعه')
          .toList();
      if (nameTokens.any(normalizedQuery.contains)) {
        matched.add(place);
      }
    }

    if (matched.length >= 2) return matched.take(2).toList();
    if (session.lastPlaces.length >= 2) {
      return session.lastPlaces.take(2).toList();
    }
    return matched;
  }

  static bool _containsOrdinal(String q, int index) {
    switch (index) {
      case 0:
        return q.contains('الاول') ||
            q.contains('اول واحد') ||
            q.contains('اول مكان') ||
            q.contains('رقم 1') ||
            q.contains('first');
      case 1:
        return q.contains('التاني') ||
            q.contains('الثاني') ||
            q.contains('تاني واحد') ||
            q.contains('رقم 2') ||
            q.contains('second');
      case 2:
        return q.contains('التالت') ||
            q.contains('الثالث') ||
            q.contains('تالت واحد') ||
            q.contains('رقم 3') ||
            q.contains('third');
      case 3:
        return q.contains('الرابع') ||
            q.contains('رقم 4') ||
            q.contains('fourth');
      default:
        return false;
    }
  }

  static Future<List<PlacesRecord>> _loadPlaces() async {
    if (placesProvider != null) {
      return placesProvider!();
    }
    try {
      return await PlacesRepository.instance.getVerifiedPlaces(limit: 50);
    } catch (_) {
      return const [];
    }
  }

  static Future<(double, double)?> _getUserPosition(
    AssistantSession session,
  ) async {
    if (session.userLat != null && session.userLng != null) {
      return (session.userLat!, session.userLng!);
    }
    try {
      final pos = await (positionProvider ?? EmergencyService.positionProvider)();
      if (pos != null) {
        session.userLat = pos.latitude;
        session.userLng = pos.longitude;
        return (pos.latitude, pos.longitude);
      }
    } catch (_) {}
    return null;
  }

  static Future<List<UserFavoriteSummary>> _loadFavorites() async {
    if (favoritesProvider != null) return favoritesProvider!();
    final uid = uidProvider();
    if (uid.isEmpty) return const [];
    try {
      final snap = await FavoritesRecord.collection
          .where('userId', isEqualTo: uid)
          .limit(20)
          .get();
      return snap.docs.map((d) {
        final rec = FavoritesRecord.fromSnapshot(d);
        return UserFavoriteSummary(
          placeId: rec.placeId,
          placeName: rec.placeName,
          category: rec.placeCategory,
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<List<UserReportSummary>> _loadReports() async {
    if (reportsProvider != null) return reportsProvider!();
    final uid = uidProvider();
    if (uid.isEmpty) return const [];
    try {
      final snap = await AccessibilityReportsRecord.collection
          .where('createdBy', isEqualTo: uid)
          .limit(20)
          .get();
      return snap.docs.map((d) {
        final rec = AccessibilityReportsRecord.fromSnapshot(d);
        return UserReportSummary(
          placeName: rec.placeName,
          problemCategory: rec.problemCategory,
          status: rec.status,
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<List<UserNotificationSummary>> _loadNotifications() async {
    if (notificationsProvider != null) return notificationsProvider!();
    final uid = uidProvider();
    if (uid.isEmpty) return const [];
    try {
      final snap = await NotificationsRecord.collection
          .where('userId', isEqualTo: uid)
          .limit(20)
          .get();
      return snap.docs.map((d) {
        final rec = NotificationsRecord.fromSnapshot(d);
        return UserNotificationSummary(
          title: rec.title,
          body: rec.body,
          isRead: rec.isRead,
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  /// Great-circle Haversine distance in kilometers between two GPS coordinates.
  static double haversineDistanceKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadiusKm = 6371.0;
    double toRad(double deg) => deg * math.pi / 180.0;
    final dLat = toRad(lat2 - lat1);
    final dLng = toRad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(toRad(lat1)) *
            math.cos(toRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }
}
