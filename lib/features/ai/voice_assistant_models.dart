import '/backend/schema/places_record.dart';
import '/features/accessibility/accessibility_score.dart';
import '/features/emergency/emergency_service.dart';

/// High-level semantic intent detected for a user's voice or text query.
enum AIIntentType {
  emergency,
  navigation,
  placeSearch,
  placeDetails,
  placeAction,
  appControl,
  userData,
  egyptGuide,
  generalInfo,
}

/// Concrete executable action the assistant can perform on the app or device.
enum AssistantActionType {
  none,
  navigate,
  goBack,
  openPlace,
  directions,
  callPhone,
  toggleFavorite,
  triggerSos,
  openReport,
  openUrl,
  changeSetting,
  clearConversation,
}

/// Structured, executable action returned by either the local NLU engine or
/// the cloud Gemini backend.
class AssistantAction {
  const AssistantAction({
    required this.type,
    required this.labelAr,
    required this.labelEn,
    this.route,
    this.routeParams = const {},
    this.place,
    this.phoneNumber,
    this.url,
    this.settingKey,
    this.settingValue,
    this.addFavorite = true,
    this.autoExecute = false,
    this.iconName,
  });

  final AssistantActionType type;
  final String labelAr;
  final String labelEn;

  /// GoRouter named route when [type] == [AssistantActionType.navigate].
  final String? route;

  /// Optional query parameters passed to GoRouter (e.g. `{'category': 'طبي'}`).
  final Map<String, String> routeParams;

  /// Target place for [openPlace], [directions], [callPhone], [toggleFavorite],
  /// or [openReport].
  final PlacesRecord? place;

  /// Phone or Egyptian hotline number for [callPhone].
  final String? phoneNumber;

  /// External URL for [openUrl] (allowlisted trusted domains).
  final String? url;

  /// Setting key for [changeSetting]:
  /// `font_scale`, `high_contrast`, `theme_mode`, `language`,
  /// `voice_feedback`, `tts_rate`, `conversation_mode`,
  /// `notifications`, `mobility_type`.
  final String? settingKey;

  /// New value for [settingKey].
  final dynamic settingValue;

  /// True to add favorite, false to remove favorite.
  final bool addFavorite;

  /// When true, the UI executes the action automatically right after responding.
  final bool autoExecute;

  /// Optional semantic icon hint (`map`, `phone`, `directions`, `favorite`,
  /// `settings`, `guide`, `sos`, `report`, `link`, `place`, `back`).
  final String? iconName;

  String label({required bool isEnglish}) => isEnglish ? labelEn : labelAr;
}

/// Enriched place match carrying personalized compatibility and optional GPS distance.
class PlaceMatch {
  const PlaceMatch({
    required this.place,
    required this.compatibility,
    this.distanceKm,
    this.highlights = const [],
  });

  final PlacesRecord place;
  final CompatibilityResult compatibility;
  final double? distanceKm;
  final List<String> highlights;

  String? formattedDistance({required bool isEnglish}) {
    if (distanceKm == null) return null;
    if (distanceKm! < 1.0) {
      final meters = (distanceKm! * 1000).round();
      return isEnglish ? '${meters}m away' : 'يبعد $meters متر';
    }
    final km = distanceKm!.toStringAsFixed(1);
    return isEnglish ? '$km km away' : 'يبعد $km كم';
  }
}

/// Grounded response returned by [OnewayAIEngine].
class AIResponse {
  AIResponse({
    required this.intent,
    required this.replyText,
    String? spokenText,
    this.places = const [],
    this.placeMatches = const [],
    this.navigationRoute,
    this.emergencyResult,
    this.primaryAction,
    this.quickActions = const [],
    this.followUpSuggestions = const [],
    this.interactionId,
    this.source = 'local',
    this.isEnglish = false,
  }) : spokenText = spokenText ?? replyText;

  final AIIntentType intent;
  final String replyText;

  /// Concise, TTS-friendly version of [replyText] (without raw URLs/emojis).
  final String spokenText;

  /// Matched places (kept for backwards compatibility with existing callers).
  final List<PlacesRecord> places;

  /// Enriched place matches with personalized compatibility and distance.
  final List<PlaceMatch> placeMatches;

  /// Legacy route name shortcut (kept for backwards compatibility).
  final String? navigationRoute;

  final EmergencyResult? emergencyResult;

  /// Primary executable action (if any).
  final AssistantAction? primaryAction;

  /// Interactive follow-up action buttons rendered inside the response card.
  final List<AssistantAction> quickActions;

  /// Contextual next-question chips shown below the response.
  final List<String> followUpSuggestions;

  /// Optional Gemini Interactions API ID for stateful cloud multi-turn chaining.
  final String? interactionId;

  /// `'local'` or `'cloud'`.
  final String source;

  /// True when the reply was generated in English.
  final bool isEnglish;
}

/// A single turn in the assistant's multi-turn conversation timeline.
class ConversationTurn {
  ConversationTurn({
    required this.id,
    required this.isUser,
    required this.text,
    DateTime? timestamp,
    this.response,
  }) : timestamp = timestamp ?? DateTime.now();

  final String id;
  final bool isUser;
  final String text;
  final DateTime timestamp;
  final AIResponse? response;
}

/// Mutable session context carried across multi-turn voice/text interactions.
class AssistantSession {
  AssistantSession({
    this.localeCode = 'ar',
    this.mobilityType,
    this.userLat,
    this.userLng,
    this.ttsRate = 0.5,
    this.conversationMode = true,
  });

  String localeCode;
  String? mobilityType;
  double? userLat;
  double? userLng;
  double ttsRate;
  bool conversationMode;

  /// Last Gemini Interactions API turn ID (when cloud mode is active).
  String? lastInteractionId;

  /// Most recently returned places so the user can refer to "الأول / التاني / ده".
  List<PlacesRecord> lastPlaces = [];

  /// Most recently focused single place.
  PlacesRecord? lastFocusedPlace;

  /// Most recent assistant response (supports "عيد تاني / كرر").
  AIResponse? lastResponse;

  /// Compact history for multi-turn context (`[{'role': 'user'|'model', 'text': '...'}]`).
  final List<Map<String, String>> history = [];

  bool get isEnglish => localeCode == 'en';

  void recordTurn(String userText, AIResponse response) {
    history.add({'role': 'user', 'text': userText});
    history.add({'role': 'model', 'text': response.replyText});
    // Keep the most recent 12 entries (6 turns) to stay fast & token-efficient.
    if (history.length > 12) {
      history.removeRange(0, history.length - 12);
    }
    if (response.places.isNotEmpty) {
      if (response.intent == AIIntentType.placeSearch || lastPlaces.isEmpty) {
        lastPlaces = List<PlacesRecord>.from(response.places);
      }
      lastFocusedPlace = response.primaryAction?.place ?? response.places.first;
    } else if (response.primaryAction?.place != null) {
      lastFocusedPlace = response.primaryAction!.place;
    }
    if (response.interactionId != null && response.interactionId!.isNotEmpty) {
      lastInteractionId = response.interactionId;
    }
    lastResponse = response;
  }

  void clear() {
    history.clear();
    lastPlaces = [];
    lastFocusedPlace = null;
    lastResponse = null;
    lastInteractionId = null;
  }
}

/// Metadata for an official Egyptian emergency or accessibility hotline.
class EgyptianHotline {
  const EgyptianHotline({
    required this.id,
    required this.number,
    required this.nameAr,
    required this.nameEn,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.keywords,
    this.isEmergency = false,
  });

  final String id;
  final String number;
  final String nameAr;
  final String nameEn;
  final String descriptionAr;
  final String descriptionEn;
  final List<String> keywords;
  final bool isEmergency;
}
