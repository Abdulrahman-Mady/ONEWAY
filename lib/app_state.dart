import 'package:flutter/material.dart'
    show ChangeNotifier, Color, Colors, VoidCallback;

class FFAppState extends ChangeNotifier {
  static FFAppState _instance = FFAppState._internal();

  factory FFAppState() {
    return _instance;
  }

  FFAppState._internal();

  static void reset() {
    _instance = FFAppState._internal();
  }

  Future initializePersistedState() async {}

  void update(VoidCallback callback) {
    callback();
    notifyListeners();
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
