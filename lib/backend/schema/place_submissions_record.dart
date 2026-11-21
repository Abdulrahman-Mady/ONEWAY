import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class PlaceSubmissionsRecord extends FirestoreRecord {
  PlaceSubmissionsRecord._(
    super.reference,
    super.data,
  ) {
    _initializeFields();
  }

  // "place_name" field.
  String? _placeName;
  String get placeName => _placeName ?? '';
  bool hasPlaceName() => _placeName != null;

  // "category" field.
  String? _category;
  String get category => _category ?? '';
  bool hasCategory() => _category != null;

  // "description" field.
  String? _description;
  String get description => _description ?? '';
  bool hasDescription() => _description != null;

  // "address" field.
  String? _address;
  String get address => _address ?? '';
  bool hasAddress() => _address != null;

  // "submittedBy" field.
  String? _submittedBy;
  String get submittedBy => _submittedBy ?? '';
  bool hasSubmittedBy() => _submittedBy != null;

  // "status" field.
  String? _status;
  String get status => _status ?? 'new';
  bool hasStatus() => _status != null;

  // "created_at" field.
  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  bool hasCreatedAt() => _createdAt != null;

  void _initializeFields() {
    _placeName = snapshotData['place_name'] as String?;
    _category = snapshotData['category'] as String?;
    _description = snapshotData['description'] as String?;
    _address = snapshotData['address'] as String?;
    _submittedBy = snapshotData['submittedBy'] as String?;
    _status = snapshotData['status'] as String?;
    _createdAt = snapshotData['created_at'] as DateTime?;
  }

  static CollectionReference<Map<String, dynamic>> get collection =>
      FirebaseFirestore.instance.collection('placeSubmissions');

  static Stream<PlaceSubmissionsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => PlaceSubmissionsRecord.fromSnapshot(s));

  static Future<PlaceSubmissionsRecord> getDocumentOnce(
          DocumentReference ref) =>
      ref.get().then((s) => PlaceSubmissionsRecord.fromSnapshot(s));

  static PlaceSubmissionsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      PlaceSubmissionsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static PlaceSubmissionsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      PlaceSubmissionsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'PlaceSubmissionsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is PlaceSubmissionsRecord && reference.path == other.reference.path;
}

Map<String, dynamic> createPlaceSubmissionsRecordData({
  String? placeName,
  String? category,
  String? description,
  String? address,
  String? submittedBy,
  String? status,
  DateTime? createdAt,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'place_name': placeName,
      'category': category,
      'description': description,
      'address': address,
      'submittedBy': submittedBy,
      'status': status,
      'created_at': createdAt,
    }.withoutNulls,
  );

  return firestoreData;
}

class PlaceSubmissionsRecordDocumentEquality
    implements Equality<PlaceSubmissionsRecord> {
  const PlaceSubmissionsRecordDocumentEquality();

  @override
  bool equals(PlaceSubmissionsRecord? e1, PlaceSubmissionsRecord? e2) {
    return e1?.submittedBy == e2?.submittedBy && e1?.status == e2?.status;
  }

  @override
  int hash(PlaceSubmissionsRecord? e) =>
      const ListEquality().hash([e?.submittedBy, e?.status]);

  @override
  bool isValidKey(Object? o) => o is PlaceSubmissionsRecord;
}
