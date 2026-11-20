import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class EmergencyContactsRecord extends FirestoreRecord {
  EmergencyContactsRecord._(
    super.reference,
    super.data,
  ) {
    _initializeFields();
  }

  // "userId" field.
  String? _userId;
  String get userId => _userId ?? '';
  bool hasUserId() => _userId != null;

  // "name" field.
  String? _name;
  String get name => _name ?? '';
  bool hasName() => _name != null;

  // "relationship" field.
  String? _relationship;
  String get relationship => _relationship ?? '';
  bool hasRelationship() => _relationship != null;

  // "phone_number" field.
  String? _phoneNumber;
  String get phoneNumber => _phoneNumber ?? '';
  bool hasPhoneNumber() => _phoneNumber != null;

  // "is_primary" field.
  bool? _isPrimary;
  bool get isPrimary => _isPrimary ?? false;
  bool hasIsPrimary() => _isPrimary != null;

  // "created_at" field.
  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  bool hasCreatedAt() => _createdAt != null;

  void _initializeFields() {
    _userId = snapshotData['userId'] as String?;
    _name = snapshotData['name'] as String?;
    _relationship = snapshotData['relationship'] as String?;
    _phoneNumber = snapshotData['phone_number'] as String?;
    _isPrimary = snapshotData['is_primary'] as bool?;
    _createdAt = snapshotData['created_at'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('emergencyContacts');

  static Stream<EmergencyContactsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => EmergencyContactsRecord.fromSnapshot(s));

  static Future<EmergencyContactsRecord> getDocumentOnce(
          DocumentReference ref) =>
      ref.get().then((s) => EmergencyContactsRecord.fromSnapshot(s));

  static EmergencyContactsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      EmergencyContactsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static EmergencyContactsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      EmergencyContactsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'EmergencyContactsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is EmergencyContactsRecord &&
      reference.path == other.reference.path;
}

Map<String, dynamic> createEmergencyContactsRecordData({
  String? userId,
  String? name,
  String? relationship,
  String? phoneNumber,
  bool? isPrimary,
  DateTime? createdAt,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'userId': userId,
      'name': name,
      'relationship': relationship,
      'phone_number': phoneNumber,
      'is_primary': isPrimary,
      'created_at': createdAt,
    }.withoutNulls,
  );

  return firestoreData;
}

class EmergencyContactsRecordDocumentEquality
    implements Equality<EmergencyContactsRecord> {
  const EmergencyContactsRecordDocumentEquality();

  @override
  bool equals(EmergencyContactsRecord? e1, EmergencyContactsRecord? e2) {
    return e1?.userId == e2?.userId && e1?.phoneNumber == e2?.phoneNumber;
  }

  @override
  int hash(EmergencyContactsRecord? e) =>
      const ListEquality().hash([e?.userId, e?.phoneNumber]);

  @override
  bool isValidKey(Object? o) => o is EmergencyContactsRecord;
}
