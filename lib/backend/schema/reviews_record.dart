import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ReviewsRecord extends FirestoreRecord {
  ReviewsRecord._(
    super.reference,
    super.data,
  ) {
    _initializeFields();
  }

  // "place_id" field.
  String? _placeId;
  String get placeId => _placeId ?? '';
  bool hasPlaceId() => _placeId != null;

  // "createdBy" field.
  String? _createdBy;
  String get createdBy => _createdBy ?? '';
  bool hasCreatedBy() => _createdBy != null;

  // "user_name" field.
  String? _userName;
  String get userName => _userName ?? '';
  bool hasUserName() => _userName != null;

  // "rating" field.
  double? _rating;
  double get rating => _rating ?? 0.0;
  bool hasRating() => _rating != null;

  // "comment" field.
  String? _comment;
  String get comment => _comment ?? '';
  bool hasComment() => _comment != null;

  // "status" field.
  String? _status;
  String get status => _status ?? 'published';
  bool hasStatus() => _status != null;

  // "created_at" field.
  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  bool hasCreatedAt() => _createdAt != null;

  void _initializeFields() {
    _placeId = snapshotData['place_id'] as String?;
    _createdBy = snapshotData['createdBy'] as String?;
    _userName = snapshotData['user_name'] as String?;
    _rating = (snapshotData['rating'] as num?)?.toDouble();
    _comment = snapshotData['comment'] as String?;
    _status = snapshotData['status'] as String?;
    _createdAt = snapshotData['created_at'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('reviews');

  static Stream<ReviewsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => ReviewsRecord.fromSnapshot(s));

  static Future<ReviewsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => ReviewsRecord.fromSnapshot(s));

  static ReviewsRecord fromSnapshot(DocumentSnapshot snapshot) => ReviewsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static ReviewsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      ReviewsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'ReviewsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is ReviewsRecord && reference.path == other.reference.path;
}

Map<String, dynamic> createReviewsRecordData({
  String? placeId,
  String? createdBy,
  String? userName,
  double? rating,
  String? comment,
  String? status,
  DateTime? createdAt,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'place_id': placeId,
      'createdBy': createdBy,
      'user_name': userName,
      'rating': rating,
      'comment': comment,
      'status': status,
      'created_at': createdAt,
    }.withoutNulls,
  );

  return firestoreData;
}

class ReviewsRecordDocumentEquality implements Equality<ReviewsRecord> {
  const ReviewsRecordDocumentEquality();

  @override
  bool equals(ReviewsRecord? e1, ReviewsRecord? e2) {
    return e1?.createdBy == e2?.createdBy && e1?.placeId == e2?.placeId;
  }

  @override
  int hash(ReviewsRecord? e) =>
      const ListEquality().hash([e?.createdBy, e?.placeId]);

  @override
  bool isValidKey(Object? o) => o is ReviewsRecord;
}
