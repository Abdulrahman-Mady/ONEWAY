import 'package:flutter/material.dart' show ChangeNotifier, VoidCallback;
import 'package:shared_preferences/shared_preferences.dart';

class FFAppState extends ChangeNotifier {
  static FFAppState _instance = FFAppState._internal();

  factory FFAppState() {
    return _instance;
  }

  FFAppState._internal();

  static void reset() {
    _instance = FFAppState._internal();
  }

  static const _kFontScaleKey = 'oneway_font_scale';
  static const _kHighContrastKey = 'oneway_high_contrast';
  static const _kVoiceFeedbackKey = 'oneway_voice_feedback';
  static const _kNotificationsEnabledKey = 'oneway_notifications_enabled';
  static const _kLocaleCodeKey = 'oneway_locale_code';
  static const _kMobilityTypeKey = 'oneway_mobility_type';
  static const _kAccessNeedsKey = 'oneway_access_needs';

  SharedPreferences? _prefs;

  Future initializePersistedState() async {
    _prefs = await SharedPreferences.getInstance();
    _fontScale = (_prefs?.getDouble(_kFontScaleKey) ?? 1.0).clamp(0.9, 1.35);
    _highContrast = _prefs?.getBool(_kHighContrastKey) ?? false;
    _voiceFeedbackEnabled = _prefs?.getBool(_kVoiceFeedbackKey) ?? true;
    _notificationsEnabled = _prefs?.getBool(_kNotificationsEnabledKey) ?? true;
    final savedLocale = _prefs?.getString(_kLocaleCodeKey);
    _localeCode =
        (savedLocale == 'en' || savedLocale == 'ar') ? savedLocale! : 'ar';
    _mobilityType = _prefs?.getString(_kMobilityTypeKey) ?? '';
    _accessNeeds =
        List<String>.from(_prefs?.getStringList(_kAccessNeedsKey) ?? const []);
  }

  /// Active app language ('ar' or 'en').
  String _localeCode = 'ar';
  String get localeCode => _localeCode;
  bool get isEnglish => _localeCode == 'en';
  Future<void> setLocaleCode(String code) async {
    final normalized = code == 'en' ? 'en' : 'ar';
    if (_localeCode == normalized) return;
    _localeCode = normalized;
    notifyListeners();
    await _prefs?.setString(_kLocaleCodeKey, normalized);
  }

  /// User's selected mobility way (طريقة التنقل).
  String _mobilityType = '';
  String get mobilityType => _mobilityType;
  Future<void> setMobilityType(String value) async {
    _mobilityType = value.trim();
    notifyListeners();
    await _prefs?.setString(_kMobilityTypeKey, _mobilityType);
  }

  /// User's selected concrete venue access needs (احتياجات الوصول).
  List<String> _accessNeeds = [];
  List<String> get accessNeeds => List.unmodifiable(_accessNeeds);
  Future<void> setAccessNeeds(List<String> needs) async {
    final clean = needs
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .take(10)
        .toList();
    _accessNeeds = clean;
    notifyListeners();
    await _prefs?.setStringList(_kAccessNeedsKey, clean);
  }

  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }

  /// User-selected text scale multiplier (1.0 = normal, 1.15 = large, 1.3 = extra large).
  double _fontScale = 1.0;
  double get fontScale => _fontScale;
  Future<void> setFontScale(double value) async {
    final clamped = value.clamp(0.9, 1.35);
    _fontScale = clamped;
    notifyListeners();
    await _prefs?.setDouble(_kFontScaleKey, clamped);
  }

  /// High-contrast accessibility mode.
  bool _highContrast = false;
  bool get highContrast => _highContrast;
  Future<void> setHighContrast(bool value) async {
    _highContrast = value;
    notifyListeners();
    await _prefs?.setBool(_kHighContrastKey, value);
  }

  /// Spoken feedback (TTS) preference.
  bool _voiceFeedbackEnabled = true;
  bool get voiceFeedbackEnabled => _voiceFeedbackEnabled;
  Future<void> setVoiceFeedbackEnabled(bool value) async {
    _voiceFeedbackEnabled = value;
    notifyListeners();
    await _prefs?.setBool(_kVoiceFeedbackKey, value);
  }

  /// App notification preference.
  bool _notificationsEnabled = true;
  bool get notificationsEnabled => _notificationsEnabled;
  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    notifyListeners();
    await _prefs?.setBool(_kNotificationsEnabledKey, value);
  }

  /// App state demoReportDescriptions
  List<String> _demoReportDescriptions = [];
  List<String> get demoReportDescriptions => _demoReportDescriptions;
  set demoReportDescriptions(List<String> value) {
    _demoReportDescriptions = value;
  }

  void addToDemoReportDescriptions(String value) {
    demoReportDescriptions.add(value);
  }

  void removeFromDemoReportDescriptions(String value) {
    demoReportDescriptions.remove(value);
  }

  void removeAtIndexFromDemoReportDescriptions(int index) {
    demoReportDescriptions.removeAt(index);
  }

  void updateDemoReportDescriptionsAtIndex(
    int index,
    String Function(String) updateFn,
  ) {
    demoReportDescriptions[index] = updateFn(_demoReportDescriptions[index]);
  }

  void insertAtIndexInDemoReportDescriptions(int index, String value) {
    demoReportDescriptions.insert(index, value);
  }

  /// App state favoritePlaceIds
  List<String> _favoritePlaceIds = [];
  List<String> get favoritePlaceIds => _favoritePlaceIds;
  set favoritePlaceIds(List<String> value) {
    _favoritePlaceIds = value;
  }

  void addToFavoritePlaceIds(String value) {
    favoritePlaceIds.add(value);
  }

  void removeFromFavoritePlaceIds(String value) {
    favoritePlaceIds.remove(value);
  }

  void removeAtIndexFromFavoritePlaceIds(int index) {
    favoritePlaceIds.removeAt(index);
  }

  void updateFavoritePlaceIdsAtIndex(
    int index,
    String Function(String) updateFn,
  ) {
    favoritePlaceIds[index] = updateFn(_favoritePlaceIds[index]);
  }

  void insertAtIndexInFavoritePlaceIds(int index, String value) {
    favoritePlaceIds.insert(index, value);
  }
}
