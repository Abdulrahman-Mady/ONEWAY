// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart' hide Type;

import '/backend/schema/util/firestore_util.dart';

import '/flutter_flow/flutter_flow_util.dart';

/// Struct AccessibilityFeatures
class AccessibilityFeaturesStruct extends FFFirebaseStruct {
  AccessibilityFeaturesStruct({
    /// AccessibilityFeatures.wheelchairEntrance
    bool? wheelchairEntrance,

    /// AccessibilityFeatures.ramp
    bool? ramp,

    /// AccessibilityFeatures.suitableElevator
    bool? suitableElevator,

    /// AccessibilityFeatures.accessibleRestroom
    bool? accessibleRestroom,

    /// AccessibilityFeatures.accessibleParking
    bool? accessibleParking,

    /// AccessibilityFeatures.corridorWidth
    String? corridorWidth,

    /// AccessibilityFeatures.entranceObstacles
    String? entranceObstacles,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _wheelchairEntrance = wheelchairEntrance,
        _ramp = ramp,
        _suitableElevator = suitableElevator,
        _accessibleRestroom = accessibleRestroom,
        _accessibleParking = accessibleParking,
        _corridorWidth = corridorWidth,
        _entranceObstacles = entranceObstacles,
        super(firestoreUtilData);

  // "wheelchairEntrance" field.
  bool? _wheelchairEntrance;
  bool get wheelchairEntrance => _wheelchairEntrance ?? false;
  set wheelchairEntrance(bool? val) => _wheelchairEntrance = val;

  bool hasWheelchairEntrance() => _wheelchairEntrance != null;

  // "ramp" field.
  bool? _ramp;
  bool get ramp => _ramp ?? false;
  set ramp(bool? val) => _ramp = val;

  bool hasRamp() => _ramp != null;

  // "suitableElevator" field.
  bool? _suitableElevator;
  bool get suitableElevator => _suitableElevator ?? false;
  set suitableElevator(bool? val) => _suitableElevator = val;

  bool hasSuitableElevator() => _suitableElevator != null;

  // "accessibleRestroom" field.
  bool? _accessibleRestroom;
  bool get accessibleRestroom => _accessibleRestroom ?? false;
  set accessibleRestroom(bool? val) => _accessibleRestroom = val;

  bool hasAccessibleRestroom() => _accessibleRestroom != null;

  // "accessibleParking" field.
  bool? _accessibleParking;
  bool get accessibleParking => _accessibleParking ?? false;
  set accessibleParking(bool? val) => _accessibleParking = val;

  bool hasAccessibleParking() => _accessibleParking != null;

  // "corridorWidth" field.
  String? _corridorWidth;
  String get corridorWidth => _corridorWidth ?? '';
  set corridorWidth(String? val) => _corridorWidth = val;

  bool hasCorridorWidth() => _corridorWidth != null;

  // "entranceObstacles" field.
  String? _entranceObstacles;
  String get entranceObstacles => _entranceObstacles ?? '';
  set entranceObstacles(String? val) => _entranceObstacles = val;

  bool hasEntranceObstacles() => _entranceObstacles != null;

  static AccessibilityFeaturesStruct fromMap(Map<String, dynamic> data) =>
      AccessibilityFeaturesStruct(
        wheelchairEntrance: data['wheelchairEntrance'] as bool?,
        ramp: data['ramp'] as bool?,
        suitableElevator: data['suitableElevator'] as bool?,
        accessibleRestroom: data['accessibleRestroom'] as bool?,
        accessibleParking: data['accessibleParking'] as bool?,
        corridorWidth: data['corridorWidth'] as String?,
        entranceObstacles: data['entranceObstacles'] as String?,
      );

  static AccessibilityFeaturesStruct? maybeFromMap(dynamic data) => data is Map
      ? AccessibilityFeaturesStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'wheelchairEntrance': _wheelchairEntrance,
        'ramp': _ramp,
        'suitableElevator': _suitableElevator,
        'accessibleRestroom': _accessibleRestroom,
        'accessibleParking': _accessibleParking,
        'corridorWidth': _corridorWidth,
        'entranceObstacles': _entranceObstacles,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'wheelchairEntrance': serializeParam(
          _wheelchairEntrance,
          ParamType.bool,
        ),
        'ramp': serializeParam(
          _ramp,
          ParamType.bool,
        ),
        'suitableElevator': serializeParam(
          _suitableElevator,
          ParamType.bool,
        ),
        'accessibleRestroom': serializeParam(
          _accessibleRestroom,
          ParamType.bool,
        ),
        'accessibleParking': serializeParam(
          _accessibleParking,
          ParamType.bool,
        ),
        'corridorWidth': serializeParam(
          _corridorWidth,
          ParamType.String,
        ),
        'entranceObstacles': serializeParam(
          _entranceObstacles,
          ParamType.String,
        ),
      }.withoutNulls;

  static AccessibilityFeaturesStruct fromSerializableMap(
          Map<String, dynamic> data) =>
      AccessibilityFeaturesStruct(
        wheelchairEntrance: deserializeParam(
          data['wheelchairEntrance'],
          ParamType.bool,
          false,
        ),
        ramp: deserializeParam(
          data['ramp'],
          ParamType.bool,
          false,
        ),
        suitableElevator: deserializeParam(
          data['suitableElevator'],
          ParamType.bool,
          false,
        ),
        accessibleRestroom: deserializeParam(
          data['accessibleRestroom'],
          ParamType.bool,
          false,
        ),
        accessibleParking: deserializeParam(
          data['accessibleParking'],
          ParamType.bool,
          false,
        ),
        corridorWidth: deserializeParam(
          data['corridorWidth'],
          ParamType.String,
          false,
        ),
        entranceObstacles: deserializeParam(
          data['entranceObstacles'],
          ParamType.String,
          false,
        ),
      );

  @override
  String toString() => 'AccessibilityFeaturesStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is AccessibilityFeaturesStruct &&
        wheelchairEntrance == other.wheelchairEntrance &&
        ramp == other.ramp &&
        suitableElevator == other.suitableElevator &&
        accessibleRestroom == other.accessibleRestroom &&
        accessibleParking == other.accessibleParking &&
        corridorWidth == other.corridorWidth &&
        entranceObstacles == other.entranceObstacles;
  }

  @override
  int get hashCode => const ListEquality().hash([
        wheelchairEntrance,
        ramp,
        suitableElevator,
        accessibleRestroom,
        accessibleParking,
        corridorWidth,
        entranceObstacles
      ]);
}

AccessibilityFeaturesStruct createAccessibilityFeaturesStruct({
  bool? wheelchairEntrance,
  bool? ramp,
  bool? suitableElevator,
  bool? accessibleRestroom,
  bool? accessibleParking,
  String? corridorWidth,
  String? entranceObstacles,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    AccessibilityFeaturesStruct(
      wheelchairEntrance: wheelchairEntrance,
      ramp: ramp,
      suitableElevator: suitableElevator,
      accessibleRestroom: accessibleRestroom,
      accessibleParking: accessibleParking,
      corridorWidth: corridorWidth,
      entranceObstacles: entranceObstacles,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

AccessibilityFeaturesStruct? updateAccessibilityFeaturesStruct(
  AccessibilityFeaturesStruct? accessibilityFeatures, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    accessibilityFeatures
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addAccessibilityFeaturesStructData(
  Map<String, dynamic> firestoreData,
  AccessibilityFeaturesStruct? accessibilityFeatures,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (accessibilityFeatures == null) {
    return;
  }
  if (accessibilityFeatures.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields = !forFieldValue &&
      accessibilityFeatures.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final accessibilityFeaturesData = getAccessibilityFeaturesFirestoreData(
      accessibilityFeatures, forFieldValue);
  final nestedData =
      accessibilityFeaturesData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields =
      accessibilityFeatures.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getAccessibilityFeaturesFirestoreData(
  AccessibilityFeaturesStruct? accessibilityFeatures, [
  bool forFieldValue = false,
]) {
  if (accessibilityFeatures == null) {
    return {};
  }
  final firestoreData = mapToFirestore(accessibilityFeatures.toMap());

  // Add any Firestore field values
  mapToFirestore(accessibilityFeatures.firestoreUtilData.fieldValues)
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getAccessibilityFeaturesListFirestoreData(
  List<AccessibilityFeaturesStruct>? accessibilityFeaturess,
) =>
    accessibilityFeaturess
        ?.map((e) => getAccessibilityFeaturesFirestoreData(e, true))
        .toList() ??
    [];
