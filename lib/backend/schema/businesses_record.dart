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

  // "description" field.
  String? _description;
  String get description => _description ?? '';
  bool hasDescription() => _description != null && _description!.isNotEmpty;

  // "address" field.
  String? _address;
  String get address => _address ?? '';
  bool hasAddress() => _address != null && _address!.isNotEmpty;

  // "governorate" & "city" fields.
  String? _governorate;
  String get governorate => _governorate ?? '';
  String? _city;
  String get city => _city ?? '';

  // "opening_hours" / "workingHours" field.
  String? _openingHours;
  String get openingHours {
    if (_openingHours != null && _openingHours!.trim().isNotEmpty) {
      return _openingHours!.trim();
    }
    final wh = snapshotData['workingHours'] ?? snapshotData['working_hours'];
    if (wh is Map && wh['raw'] is String) {
      return (wh['raw'] as String).trim();
    }
    return '';
  }

  // "website" field.
  String? _website;
  String get website => _website ?? '';

  // "location" field.
  LatLng? _location;
  LatLng? get location => _location;
  bool hasLocation() => _location != null;

  // Photo fields.
  String? _photoUrl;
  String get photoUrl => _photoUrl ?? '';
  String? _entrancePhotoUrl;
  String get entrancePhotoUrl => _entrancePhotoUrl ?? '';
  String? _elevatorPhotoUrl;
  String get elevatorPhotoUrl => _elevatorPhotoUrl ?? '';
  String? _restroomPhotoUrl;
  String get restroomPhotoUrl => _restroomPhotoUrl ?? '';

  // Accessibility features & amenities.
  AccessibilityFeaturesStruct? _accessibilityFeatures;
  AccessibilityFeaturesStruct get accessibilityFeatures =>
      _accessibilityFeatures ?? AccessibilityFeaturesStruct();
  List<String>? _amenities;
  List<String> get amenities => _amenities ?? const [];

  // Edit-review workflow tracking.
  bool? _hasPendingEdits;
  bool get hasPendingEdits => _hasPendingEdits ?? false;
  String? _lastEditSummary;
  String get lastEditSummary => _lastEditSummary ?? '';

  // Admin moderation feedback.
  String? _adminNotes;
  String get adminNotes => _adminNotes ?? '';
  String? _rejectionReason;
  String get rejectionReason => _rejectionReason ?? '';

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

  // Timestamps.
  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  bool hasCreatedAt() => _createdAt != null;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _updatedAt;

  void _initializeFields() {
    _ownerId = snapshotData['ownerId'] as String?;
    _businessName = snapshotData['business_name'] as String?;
    _category = snapshotData['category'] as String?;
    _phoneNumber = snapshotData['phone_number'] as String?;
    _email = snapshotData['email'] as String?;
    _description = snapshotData['description'] as String?;
    _address = snapshotData['address'] as String?;
    _governorate = snapshotData['governorate'] as String?;
    _city = snapshotData['city'] as String?;
    _openingHours = snapshotData['opening_hours'] as String?;
    _website = snapshotData['website'] as String?;
    _location = snapshotData['location'] as LatLng?;
    _photoUrl = (snapshotData['photo_url'] as String?) ??
        (snapshotData['logoUrl'] as String?);
    _entrancePhotoUrl = snapshotData['entrance_photo_url'] as String?;
    _elevatorPhotoUrl = snapshotData['elevator_photo_url'] as String?;
    _restroomPhotoUrl = snapshotData['restroom_photo_url'] as String?;
    _accessibilityFeatures = snapshotData['accessibility_features'] is Map
        ? AccessibilityFeaturesStruct.fromMap(
            Map<String, dynamic>.from(
                snapshotData['accessibility_features'] as Map))
        : null;
    _amenities = getDataList(snapshotData['amenities']);
    _hasPendingEdits = snapshotData['has_pending_edits'] as bool?;
    _lastEditSummary = snapshotData['last_edit_summary'] as String?;
    _adminNotes = snapshotData['admin_notes'] as String?;
    _rejectionReason = snapshotData['rejection_reason'] as String?;
    _status = snapshotData['status'] as String?;
    _subscriptionTier = snapshotData['subscription_tier'] as String?;
    _branchPlaceIds = getDataList(snapshotData['branch_place_ids']);
    _createdAt = snapshotData['created_at'] as DateTime?;
    _updatedAt = snapshotData['updated_at'] as DateTime?;
  }

  static CollectionReference<Map<String, dynamic>> get collection =>
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
    return e1?.ownerId == e2?.ownerId &&
        e1?.status == e2?.status &&
        e1?.hasPendingEdits == e2?.hasPendingEdits;
  }

  @override
  int hash(BusinessesRecord? e) => const ListEquality()
      .hash([e?.ownerId, e?.status, e?.hasPendingEdits]);

  @override
  bool isValidKey(Object? o) => o is BusinessesRecord;
}
