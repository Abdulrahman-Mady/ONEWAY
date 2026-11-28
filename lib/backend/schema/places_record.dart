import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class PlacesRecord extends FirestoreRecord {
  PlacesRecord._(
    super.reference,
    super.data,
  ) {
    _initializeFields();
  }

  // "name" field.
  String? _name;
  String get name => _name ?? '';
  bool hasName() => _name != null;

  // "category" field.
  String? _category;
  String get category => _category ?? '';
  bool hasCategory() => _category != null;

  // "description" field.
  String? _description;
  String get description => _description ?? '';
  bool hasDescription() => _description != null;

  // "photo_url" field.
  String? _photoUrl;
  String get photoUrl => _photoUrl ?? '';
  bool hasPhotoUrl() => _photoUrl != null;

  // "photos" field.
  List<String>? _photos;
  List<String> get photos => _photos ?? [];
  bool hasPhotos() => _photos != null;

  // Detailed accessibility photos: entrance/ramp, elevator, accessible restroom.
  String? _entrancePhotoUrl;
  String get entrancePhotoUrl => _entrancePhotoUrl ?? '';
  bool hasEntrancePhotoUrl() =>
      _entrancePhotoUrl != null && _entrancePhotoUrl!.trim().isNotEmpty;

  String? _elevatorPhotoUrl;
  String get elevatorPhotoUrl => _elevatorPhotoUrl ?? '';
  bool hasElevatorPhotoUrl() =>
      _elevatorPhotoUrl != null && _elevatorPhotoUrl!.trim().isNotEmpty;

  String? _restroomPhotoUrl;
  String get restroomPhotoUrl => _restroomPhotoUrl ?? '';
  bool hasRestroomPhotoUrl() =>
      _restroomPhotoUrl != null && _restroomPhotoUrl!.trim().isNotEmpty;

  // "address" field.
  String? _address;
  String get address => _address ?? '';
  bool hasAddress() => _address != null;

  // "governorate" field.
  String? _governorate;
  String get governorate => _governorate ?? '';
  bool hasGovernorate() => _governorate != null;

  // "city" field.
  String? _city;
  String get city => _city ?? '';
  bool hasCity() => _city != null;

  // "location" field.
  LatLng? _location;
  LatLng? get location => _location;
  bool hasLocation() => _location != null;

  // "phone_number" field.
  String? _phoneNumber;
  String get phoneNumber => _phoneNumber ?? '';
  bool hasPhoneNumber() => _phoneNumber != null;

  // "website" field.
  String? _website;
  String get website => _website ?? '';
  bool hasWebsite() => _website != null;

  // "opening_hours" field.
  String? _openingHours;
  String get openingHours => _openingHours ?? '';
  bool hasOpeningHours() => _openingHours != null;

  // "accessibility_features" field.
  AccessibilityFeaturesStruct? _accessibilityFeatures;
  AccessibilityFeaturesStruct get accessibilityFeatures =>
      _accessibilityFeatures ?? AccessibilityFeaturesStruct();
  bool hasAccessibilityFeatures() => _accessibilityFeatures != null;

  // "amenities" field (general & accessibility amenities: واي فاي، باركنج، توصيل، رامب...).
  List<String>? _amenities;
  List<String> get amenities => _amenities ?? const [];
  bool hasAmenities() => _amenities != null && _amenities!.isNotEmpty;

  // "data_source" field ('openstreetmap', 'google_places', 'admin', 'business_owner').
  String? _dataSource;
  String get dataSource => _dataSource ?? '';
  bool hasDataSource() => _dataSource != null && _dataSource!.isNotEmpty;

  // "external_id" field (deduplication ID from OSM/Google Places).
  String? _externalId;
  String get externalId => _externalId ?? '';
  bool hasExternalId() => _externalId != null && _externalId!.isNotEmpty;

  // "verification_status" field.
  String? _verificationStatus;
  String get verificationStatus => _verificationStatus ?? 'needsUpdate';
  bool hasVerificationStatus() => _verificationStatus != null;

  // "verified_by" field.
  String? _verifiedBy;
  String get verifiedBy => _verifiedBy ?? '';
  bool hasVerifiedBy() => _verifiedBy != null;

  // "last_verified_at" field.
  DateTime? _lastVerifiedAt;
  DateTime? get lastVerifiedAt => _lastVerifiedAt;
  bool hasLastVerifiedAt() => _lastVerifiedAt != null;

  // "verification_evidence" field: free-text evidence of a real field
  // check (who went, what was measured, photo/report links). A 'verified'
  // status without this means the place is real/published (e.g. from OpenStreetMap,
  // Google Places, or initial admin listing) but awaits an on-site field audit.
  String? _verificationEvidence;
  String get verificationEvidence => _verificationEvidence ?? '';
  bool hasVerificationEvidence() =>
      _verificationEvidence != null && _verificationEvidence!.trim().isNotEmpty;

  /// A 'verified' flag counts as field-audited only when the document carries
  /// explicit field-verification evidence.
  bool get isGenuinelyVerified =>
      verificationStatus == 'verified' && hasVerificationEvidence();

  /// Status to display to users: distinguishes field-inspected places from
  /// traditionally registered places awaiting an on-site engineering audit.
  String get effectiveVerificationStatus {
    if (verificationStatus == 'verified' && !isGenuinelyVerified) {
      return 'pendingFieldAudit';
    }
    return verificationStatus;
  }

  // "rating" field.
  double? _rating;
  double get rating => _rating ?? 0.0;
  bool hasRating() => _rating != null;

  // "review_count" field.
  int? _reviewCount;
  int get reviewCount => _reviewCount ?? 0;
  bool hasReviewCount() => _reviewCount != null;

  // "created_at" field.
  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  bool hasCreatedAt() => _createdAt != null;

  // "business_id" field.
  String? _businessId;
  String get businessId => _businessId ?? '';
  bool hasBusinessId() => _businessId != null;

  void _initializeFields() {
    _name = snapshotData['name'] as String?;
    _category = snapshotData['category'] as String?;
    _description = snapshotData['description'] as String?;
    _photoUrl = snapshotData['photo_url'] as String?;
    _photos = getDataList(snapshotData['photos']);
    _entrancePhotoUrl = snapshotData['entrance_photo_url'] as String?;
    _elevatorPhotoUrl = snapshotData['elevator_photo_url'] as String?;
    _restroomPhotoUrl = snapshotData['restroom_photo_url'] as String?;
    _address = snapshotData['address'] as String?;
    _governorate = snapshotData['governorate'] as String?;
    _city = snapshotData['city'] as String?;
    _location = snapshotData['location'] as LatLng?;
    _phoneNumber = snapshotData['phone_number'] as String?;
    _website = snapshotData['website'] as String?;
    _openingHours = snapshotData['opening_hours'] as String?;
    _accessibilityFeatures = snapshotData['accessibility_features'] is Map
        ? AccessibilityFeaturesStruct.fromMap(
            snapshotData['accessibility_features'] as Map<String, dynamic>)
        : null;
    _amenities = getDataList(snapshotData['amenities']);
    _dataSource = snapshotData['data_source'] as String?;
    _externalId = snapshotData['external_id'] as String?;
    _verificationStatus = snapshotData['verification_status'] as String?;
    _verifiedBy = snapshotData['verified_by'] as String?;
    _lastVerifiedAt = snapshotData['last_verified_at'] as DateTime?;
    _verificationEvidence = snapshotData['verification_evidence'] as String?;
    _rating = (snapshotData['rating'] as num?)?.toDouble();
    _reviewCount = (snapshotData['review_count'] as num?)?.toInt();
    _createdAt = snapshotData['created_at'] as DateTime?;
    _businessId = snapshotData['business_id'] as String?;
  }

  static CollectionReference<Map<String, dynamic>> get collection =>
      FirebaseFirestore.instance.collection('places');

  static Stream<PlacesRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => PlacesRecord.fromSnapshot(s));

  static Future<PlacesRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => PlacesRecord.fromSnapshot(s));

  static PlacesRecord fromSnapshot(DocumentSnapshot snapshot) => PlacesRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static PlacesRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      PlacesRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'PlacesRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is PlacesRecord && reference.path == other.reference.path;
}

Map<String, dynamic> createPlacesRecordData({
  String? name,
  String? category,
  String? description,
  String? photoUrl,
  List<String>? photos,
  String? address,
  String? governorate,
  String? city,
  LatLng? location,
  String? phoneNumber,
  String? website,
  String? openingHours,
  AccessibilityFeaturesStruct? accessibilityFeatures,
  List<String>? amenities,
  String? dataSource,
  String? externalId,
  String? verificationStatus,
  String? verifiedBy,
  DateTime? lastVerifiedAt,
  double? rating,
  int? reviewCount,
  DateTime? createdAt,
  String? businessId,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'name': name,
      'category': category,
      'description': description,
      'photo_url': photoUrl,
      'photos': photos,
      'address': address,
      'governorate': governorate,
      'city': city,
      'location': location,
      'phone_number': phoneNumber,
      'website': website,
      'opening_hours': openingHours,
      'accessibility_features': accessibilityFeatures?.toMap(),
      'amenities': amenities,
      'data_source': dataSource,
      'external_id': externalId,
      'verification_status': verificationStatus,
      'verified_by': verifiedBy,
      'last_verified_at': lastVerifiedAt,
      'rating': rating,
      'review_count': reviewCount,
      'created_at': createdAt,
      'business_id': businessId,
    }.withoutNulls,
  );

  return firestoreData;
}

class PlacesRecordDocumentEquality implements Equality<PlacesRecord> {
  const PlacesRecordDocumentEquality();

  @override
  bool equals(PlacesRecord? e1, PlacesRecord? e2) {
    return e1?.name == e2?.name &&
        e1?.category == e2?.category &&
        e1?.verificationStatus == e2?.verificationStatus;
  }

  @override
  int hash(PlacesRecord? e) =>
      const ListEquality().hash([e?.name, e?.category, e?.verificationStatus]);

  @override
  bool isValidKey(Object? o) => o is PlacesRecord;
}
