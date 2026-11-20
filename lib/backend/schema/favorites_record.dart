import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class FavoritesRecord extends FirestoreRecord {
  FavoritesRecord._(
    super.reference,
    super.data,
  ) {
    _initializeFields();
  }

  // "userId" field.
  String? _userId;
  String get userId => _userId ?? '';
  bool hasUserId() => _userId != null;

  // "placeId" field.
  String? _placeId;
  String get placeId => _placeId ?? '';
  bool hasPlaceId() => _placeId != null;

  // "placeName" field.
  String? _placeName;
  String get placeName => _placeName ?? '';
  bool hasPlaceName() => _placeName != null;

  // "placePhoto" field.
  String? _placePhoto;
  String get placePhoto => _placePhoto ?? '';
  bool hasPlacePhoto() => _placePhoto != null;

  // "placeCategory" field.
  String? _placeCategory;
  String get placeCategory => _placeCategory ?? '';
  bool hasPlaceCategory() => _placeCategory != null;

  // "created_at" field.
  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  bool hasCreatedAt() => _createdAt != null;

  void _initializeFields() {
    _userId = snapshotData['userId'] as String?;
    _placeId = snapshotData['placeId'] as String?;
    _placeName = snapshotData['placeName'] as String?;
    _placePhoto = snapshotData['placePhoto'] as String?;
    _placeCategory = snapshotData['placeCategory'] as String?;
    _createdAt = snapshotData['created_at'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('favorites');

  static Stream<FavoritesRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => FavoritesRecord.fromSnapshot(s));

  static Future<FavoritesRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => FavoritesRecord.fromSnapshot(s));

  static FavoritesRecord fromSnapshot(DocumentSnapshot snapshot) =>
      FavoritesRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static FavoritesRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      FavoritesRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'FavoritesRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is FavoritesRecord && reference.path == other.reference.path;
}

Map<String, dynamic> createFavoritesRecordData({
  String? userId,
  String? placeId,
  String? placeName,
  String? placePhoto,
  String? placeCategory,
  DateTime? createdAt,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'userId': userId,
      'placeId': placeId,
      'placeName': placeName,
      'placePhoto': placePhoto,
      'placeCategory': placeCategory,
      'created_at': createdAt,
    }.withoutNulls,
  );

  return firestoreData;
}

class FavoritesRecordDocumentEquality implements Equality<FavoritesRecord> {
  const FavoritesRecordDocumentEquality();

  @override
  bool equals(FavoritesRecord? e1, FavoritesRecord? e2) {
    return e1?.userId == e2?.userId && e1?.placeId == e2?.placeId;
  }

  @override
  int hash(FavoritesRecord? e) =>
      const ListEquality().hash([e?.userId, e?.placeId]);

  @override
  bool isValidKey(Object? o) => o is FavoritesRecord;
}
