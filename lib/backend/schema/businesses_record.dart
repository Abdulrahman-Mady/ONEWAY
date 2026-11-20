import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class BusinessesRecord extends FirestoreRecord {
  BusinessesRecord._(
    super.reference,
    super.data,
  ) {
    _initializeFields();
  }

  // "ownerId" field.
  String? _ownerId;
  String get ownerId => _ownerId ?? '';
  bool hasOwnerId() => _ownerId != null;

  // "business_name" field.
  String? _businessName;
  String get businessName => _businessName ?? '';
  bool hasBusinessName() => _businessName != null;

  // "category" field.
  String? _category;
  String get category => _category ?? '';
  bool hasCategory() => _category != null;

  // "phone_number" field.
  String? _phoneNumber;
  String get phoneNumber => _phoneNumber ?? '';
  bool hasPhoneNumber() => _phoneNumber != null;

  // "email" field.
  String? _email;
  String get email => _email ?? '';
  bool hasEmail() => _email != null;

  // "status" field.
  String? _status;
  String get status => _status ?? 'pending';
  bool hasStatus() => _status != null;

  // "subscription_tier" field.
  String? _subscriptionTier;
  String get subscriptionTier => _subscriptionTier ?? 'free';
  bool hasSubscriptionTier() => _subscriptionTier != null;

  // "branch_place_ids" field.
  List<String>? _branchPlaceIds;
  List<String> get branchPlaceIds => _branchPlaceIds ?? [];
  bool hasBranchPlaceIds() => _branchPlaceIds != null;

  // "created_at" field.
  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  bool hasCreatedAt() => _createdAt != null;

  void _initializeFields() {
    _ownerId = snapshotData['ownerId'] as String?;
    _businessName = snapshotData['business_name'] as String?;
    _category = snapshotData['category'] as String?;
    _phoneNumber = snapshotData['phone_number'] as String?;
    _email = snapshotData['email'] as String?;
    _status = snapshotData['status'] as String?;
    _subscriptionTier = snapshotData['subscription_tier'] as String?;
    _branchPlaceIds = getDataList(snapshotData['branch_place_ids']);
    _createdAt = snapshotData['created_at'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('businesses');

  static Stream<BusinessesRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => BusinessesRecord.fromSnapshot(s));

  static Future<BusinessesRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => BusinessesRecord.fromSnapshot(s));

  static BusinessesRecord fromSnapshot(DocumentSnapshot snapshot) =>
      BusinessesRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static BusinessesRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      BusinessesRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'BusinessesRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is BusinessesRecord && reference.path == other.reference.path;
}

Map<String, dynamic> createBusinessesRecordData({
  String? ownerId,
  String? businessName,
  String? category,
  String? phoneNumber,
  String? email,
  String? status,
  String? subscriptionTier,
  List<String>? branchPlaceIds,
  DateTime? createdAt,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'ownerId': ownerId,
      'business_name': businessName,
      'category': category,
      'phone_number': phoneNumber,
      'email': email,
      'status': status,
      'subscription_tier': subscriptionTier,
      'branch_place_ids': branchPlaceIds,
      'created_at': createdAt,
    }.withoutNulls,
  );

  return firestoreData;
}

class BusinessesRecordDocumentEquality implements Equality<BusinessesRecord> {
  const BusinessesRecordDocumentEquality();

  @override
  bool equals(BusinessesRecord? e1, BusinessesRecord? e2) {
    return e1?.ownerId == e2?.ownerId && e1?.status == e2?.status;
  }

  @override
  int hash(BusinessesRecord? e) =>
      const ListEquality().hash([e?.ownerId, e?.status]);

  @override
  bool isValidKey(Object? o) => o is BusinessesRecord;
}
