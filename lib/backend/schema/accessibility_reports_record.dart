import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class AccessibilityReportsRecord extends FirestoreRecord {
  AccessibilityReportsRecord._(
    super.reference,
    super.data,
  ) {
    _initializeFields();
  }

  // "place_id" field.
  String? _placeId;
  String get placeId => _placeId ?? '';
  bool hasPlaceId() => _placeId != null;

  // "place_name" field.
  String? _placeName;
  String get placeName => _placeName ?? '';
  bool hasPlaceName() => _placeName != null;

  // "createdBy" field.
  String? _createdBy;
  String get createdBy => _createdBy ?? '';
  bool hasCreatedBy() => _createdBy != null;

  // "user_name" field.
  String? _userName;
  String get userName => _userName ?? '';
  bool hasUserName() => _userName != null;

  // "problemCategory" field.
  String? _problemCategory;
  String get problemCategory => _problemCategory ?? '';
  bool hasProblemCategory() => _problemCategory != null;

  // "description" field.
  String? _description;
  String get description => _description ?? '';
  bool hasDescription() => _description != null;

  // "photo_urls" field.
  List<String>? _photoUrls;
  List<String> get photoUrls => _photoUrls ?? [];
  bool hasPhotoUrls() => _photoUrls != null;

  // "location" field.
  LatLng? _location;
  LatLng? get location => _location;
  bool hasLocation() => _location != null;

  // "status" field.
  String? _status;
  String get status => _status ?? 'new';
  bool hasStatus() => _status != null;

  // "created_at" field.
  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  bool hasCreatedAt() => _createdAt != null;

  // "admin_notes" field (official admin reply / decision reason).
  String? _adminNotes;
  String get adminNotes => _adminNotes ?? '';
  bool hasAdminNotes() => _adminNotes != null && _adminNotes!.isNotEmpty;

  // "previous_admin_notes" field (archived admin clarification prompt after user resubmits).
  String? _previousAdminNotes;
  String get previousAdminNotes => _previousAdminNotes ?? '';
  bool hasPreviousAdminNotes() =>
      _previousAdminNotes != null && _previousAdminNotes!.isNotEmpty;

  // "user_notes" field (additional clarification notes added by the reporter).
  String? _userNotes;
  String get userNotes => _userNotes ?? '';
  bool hasUserNotes() => _userNotes != null && _userNotes!.isNotEmpty;

  // "updated_at" field.
  DateTime? _updatedAt;
  DateTime? get updatedAt => _updatedAt;
  bool hasUpdatedAt() => _updatedAt != null;

  void _initializeFields() {
    _placeId = snapshotData['place_id'] as String?;
    _placeName = snapshotData['place_name'] as String?;
    _createdBy = snapshotData['createdBy'] as String?;
    _userName = snapshotData['user_name'] as String?;
    _problemCategory = snapshotData['problemCategory'] as String?;
    _description = snapshotData['description'] as String?;
    _photoUrls = getDataList(snapshotData['photo_urls']);
    _location = snapshotData['location'] as LatLng?;
    _status = snapshotData['status'] as String?;
    _createdAt = snapshotData['created_at'] as DateTime?;
    _adminNotes = snapshotData['admin_notes'] as String?;
    _previousAdminNotes = snapshotData['previous_admin_notes'] as String?;
    _userNotes = snapshotData['user_notes'] as String?;
    _updatedAt = snapshotData['updated_at'] as DateTime?;
  }

  static CollectionReference<Map<String, dynamic>> get collection =>
      FirebaseFirestore.instance.collection('accessibilityReports');

  static Stream<AccessibilityReportsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => AccessibilityReportsRecord.fromSnapshot(s));

  static Future<AccessibilityReportsRecord> getDocumentOnce(
          DocumentReference ref) =>
      ref.get().then((s) => AccessibilityReportsRecord.fromSnapshot(s));

  static AccessibilityReportsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      AccessibilityReportsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static AccessibilityReportsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      AccessibilityReportsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'AccessibilityReportsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is AccessibilityReportsRecord &&
      reference.path == other.reference.path;
}

Map<String, dynamic> createAccessibilityReportsRecordData({
  String? placeId,
  String? placeName,
  String? createdBy,
  String? userName,
  String? problemCategory,
  String? description,
  List<String>? photoUrls,
  LatLng? location,
  String? status,
  DateTime? createdAt,
  String? adminNotes,
  String? previousAdminNotes,
  String? userNotes,
  DateTime? updatedAt,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'place_id': placeId,
      'place_name': placeName,
      'createdBy': createdBy,
      'user_name': userName,
      'problemCategory': problemCategory,
      'description': description,
      'photo_urls': photoUrls,
      'location': location,
      'status': status,
      'created_at': createdAt,
      'admin_notes': adminNotes,
      'previous_admin_notes': previousAdminNotes,
      'user_notes': userNotes,
      'updated_at': updatedAt,
    }.withoutNulls,
  );

  return firestoreData;
}

class AccessibilityReportsRecordDocumentEquality
    implements Equality<AccessibilityReportsRecord> {
  const AccessibilityReportsRecordDocumentEquality();

  @override
  bool equals(
      AccessibilityReportsRecord? e1, AccessibilityReportsRecord? e2) {
    return e1?.createdBy == e2?.createdBy &&
        e1?.status == e2?.status &&
        e1?.description == e2?.description &&
        e1?.adminNotes == e2?.adminNotes &&
        e1?.userNotes == e2?.userNotes;
  }

  @override
  int hash(AccessibilityReportsRecord? e) => const ListEquality().hash([
        e?.createdBy,
        e?.status,
        e?.description,
        e?.adminNotes,
        e?.userNotes,
      ]);

  @override
  bool isValidKey(Object? o) => o is AccessibilityReportsRecord;
}
