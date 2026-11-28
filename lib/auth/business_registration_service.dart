import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '/backend/schema/businesses_record.dart';
import '/backend/schema/users_record.dart';
import '/core/network/connectivity_service.dart';
import '/core/utils/image_compression_service.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/auth/firebase_auth/auth_util.dart';

/// Service for handling Place Owner (صاحب مكان) traditional registration,
/// place editing, and Admin review synchronization.
class BusinessRegistrationService {
  BusinessRegistrationService._();
  static final BusinessRegistrationService instance =
      BusinessRegistrationService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _businessesCollection =>
      BusinessesRecord.collection;
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      UsersRecord.collection;

  static const List<String> businessCategories = [
    'مطاعم وكافيهات',
    'طبي ومستشفيات',
    'تسوق ومراكز تجارية',
    'فنادق وسياحة',
    'تعليم وجامعات',
    'بنوك ومصارف',
    'مكاتب حكومية',
    'أماكن ترفيهية',
    'محطات نقل',
    'أخرى',
  ];

  String get _resolvedUid {
    if (currentUserUid.isNotEmpty) return currentUserUid;
    try {
      final u = FirebaseAuth.instance.currentUser;
      if (u != null && !u.isAnonymous) return u.uid;
    } catch (_) {}
    return '';
  }

  bool get _hasActiveUser {
    try {
      final u = FirebaseAuth.instance.currentUser;
      if (u != null && !u.isAnonymous) return true;
    } catch (_) {}
    return loggedIn && currentUserUid.isNotEmpty;
  }

  /// Submit a new place registration by its owner (traditional workflow).
  Future<BusinessRegistrationResult> submitBusinessApplication({
    required BusinessApplicationData data,
    List<String> imageUrls = const [],
    String? logoUrl,
    String? photoUrl,
    String? entrancePhotoUrl,
    String? elevatorPhotoUrl,
    String? restroomPhotoUrl,
  }) async {
    try {
      final uid = _resolvedUid;
      if (!_hasActiveUser || uid.isEmpty) {
        return BusinessRegistrationResult.failure(
          message: 'يجب تسجيل الدخول بحساب مفعل أولاً',
        );
      }

      final validationError = _validateBusinessData(data);
      if (validationError != null) {
        return BusinessRegistrationResult.failure(message: validationError);
      }

      // Fast pre-flight connectivity check so Firestore offline write queue
      // never traps the user on an endless loading spinner.
      final hasInternet = await ConnectivityService.instance.checkHasInternet();
      if (!hasInternet) {
        return BusinessRegistrationResult.failure(
          message:
              'لا يوجد اتصال بالإنترنت حالياً. بياناتك وصورك محفوظة كما هي في الصفحة — تأكد من الشبكة ثم اضغط «إعادة المحاولة».',
          isOffline: true,
        );
      }

      final resolvedPhotoUrl =
          (photoUrl != null && photoUrl.trim().isNotEmpty)
              ? photoUrl.trim()
              : (logoUrl != null && logoUrl.trim().isNotEmpty
                  ? logoUrl.trim()
                  : null);
      final mergedImages = <String>[
        if (resolvedPhotoUrl != null && !imageUrls.contains(resolvedPhotoUrl))
          resolvedPhotoUrl,
        if (entrancePhotoUrl != null &&
            entrancePhotoUrl.trim().isNotEmpty &&
            !imageUrls.contains(entrancePhotoUrl.trim()))
          entrancePhotoUrl.trim(),
        if (elevatorPhotoUrl != null &&
            elevatorPhotoUrl.trim().isNotEmpty &&
            !imageUrls.contains(elevatorPhotoUrl.trim()))
          elevatorPhotoUrl.trim(),
        if (restroomPhotoUrl != null &&
            restroomPhotoUrl.trim().isNotEmpty &&
            !imageUrls.contains(restroomPhotoUrl.trim()))
          restroomPhotoUrl.trim(),
        ...imageUrls,
      ].take(20).toList();

      final businessData = createBusinessesRecordData(
        ownerId: uid,
        businessName: data.businessName.trim(),
        category: data.category,
        phoneNumber: data.phoneNumber.trim(),
        email: data.email?.trim(),
        status: 'pending',
        subscriptionTier: 'free',
        branchPlaceIds: [],
        createdAt: DateTime.now(),
      );

      final cleanLogoUrl =
          (logoUrl != null && logoUrl.trim().isNotEmpty) ? logoUrl.trim() : resolvedPhotoUrl;
      final cleanWebsite =
          (data.website != null && data.website!.trim().isNotEmpty)
              ? data.website!.trim()
              : null;

      final coreCompatibleData = <String, dynamic>{
        ...businessData,
        if (data.description != null && data.description!.trim().isNotEmpty)
          'description': data.description!.trim(),
        if (data.address != null && data.address!.trim().isNotEmpty)
          'address': data.address!.trim(),
        if (data.location != null) 'location': data.location,
        if (data.workingHours != null) 'workingHours': data.workingHours,
        'services': data.services ?? <String>[],
        if (data.accessibilityFeatures != null)
          'accessibility_features': data.accessibilityFeatures,
        if (data.ownerName != null && data.ownerName!.trim().isNotEmpty)
          'ownerName': data.ownerName!.trim(),
        if (data.ownerPhone != null && data.ownerPhone!.trim().isNotEmpty)
          'ownerPhone': data.ownerPhone!.trim(),
        if (data.ownerEmail != null && data.ownerEmail!.trim().isNotEmpty)
          'ownerEmail': data.ownerEmail!.trim(),
        if (cleanLogoUrl != null && cleanLogoUrl.isNotEmpty)
          'logoUrl': cleanLogoUrl,
        'imageUrls': mergedImages,
        'submittedAt': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      final fullData = <String, dynamic>{
        ...coreCompatibleData,
        if (data.governorate != null && data.governorate!.trim().isNotEmpty)
          'governorate': data.governorate!.trim(),
        if (data.city != null && data.city!.trim().isNotEmpty)
          'city': data.city!.trim(),
        if (data.openingHours != null && data.openingHours!.trim().isNotEmpty)
          'opening_hours': data.openingHours!.trim(),
        if (cleanWebsite != null) 'website': cleanWebsite,
        if (data.amenities != null)
          'amenities': data.amenities!.take(20).toList(),
        if (resolvedPhotoUrl != null) 'photo_url': resolvedPhotoUrl,
        if (entrancePhotoUrl != null && entrancePhotoUrl.trim().isNotEmpty)
          'entrance_photo_url': entrancePhotoUrl.trim(),
        if (elevatorPhotoUrl != null && elevatorPhotoUrl.trim().isNotEmpty)
          'elevator_photo_url': elevatorPhotoUrl.trim(),
        if (restroomPhotoUrl != null && restroomPhotoUrl.trim().isNotEmpty)
          'restroom_photo_url': restroomPhotoUrl.trim(),
        'has_pending_edits': false,
        if (data.claimedExistingPlaceId != null &&
            data.claimedExistingPlaceId!.trim().isNotEmpty)
          'claimed_existing_place_id': data.claimedExistingPlaceId!.trim(),
      };

      DocumentReference<Map<String, dynamic>> docRef;
      try {
        docRef = await _businessesCollection
            .add(fullData)
            .timeout(const Duration(seconds: 15));
      } on FirebaseException catch (e) {
        if (e.code == 'permission-denied') {
          // Graceful fallback if older deployed rules restrict newly added keys
          docRef = await _businessesCollection
              .add(coreCompatibleData)
              .timeout(const Duration(seconds: 15));
        } else {
          rethrow;
        }
      }

      try {
        final userRef = _usersCollection.doc(uid);
        final userPayload = <String, dynamic>{
          'business_application_id': docRef.id,
          'business_application_status': 'pending',
          'has_uploaded_place': true,
          'updated_time': FieldValue.serverTimestamp(),
        };
        try {
          await userRef.update(userPayload);
        } on FirebaseException catch (e) {
          if (e.code == 'not-found') {
            await userRef.set({
              'uid': uid,
              'email': data.ownerEmail ?? currentUserEmail,
              'display_name': data.ownerName ?? currentUserDisplayName,
              'role': 'user',
              'created_time': FieldValue.serverTimestamp(),
              ...userPayload,
            }, SetOptions(merge: true));
          } else {
            // Fallback without has_uploaded_place if older rules don't list it
            await userRef.update({
              'business_application_id': docRef.id,
              'business_application_status': 'pending',
              'updated_time': FieldValue.serverTimestamp(),
            });
          }
        }
      } catch (e) {
        debugPrint('Users business_application_id sync warning: $e');
      }

      final isClaim = data.claimedExistingPlaceId != null &&
          data.claimedExistingPlaceId!.trim().isNotEmpty;
      await _createAdminNotification(
        businessId: docRef.id,
        businessName: data.businessName.trim(),
        type: isClaim ? 'place_ownership_claim' : 'new_business_application',
        title: isClaim
            ? 'طلب إثبات ملكية واستلام مكان موجود'
            : 'طلب تسجيل مكان جديد من صاحبه',
        body: isClaim
            ? 'قدّم صاحب المكان طلباً رسمياً لاستلام وإدارة «${data.businessName.trim()}» الموجود مسبقاً على الخريطة.'
            : 'قام صاحب المكان بتسجيل "${data.businessName.trim()}" ويحتاج لمراجعة واعتماد الإدارة.',
      );

      return BusinessRegistrationResult.success(
        businessId: docRef.id,
        message: 'تم تقديم بيانات مكانك بنجاح وهو قيد مراجعة الإدارة',
      );
    } on TimeoutException {
      return BusinessRegistrationResult.failure(
        message:
            'انقطع الاتصال بالإنترنت أو ضعفت الشبكة أثناء إرسال الطلب. بياناتك وصورك محفوظة كما هي — تأكد من الاتصال ثم أعد المحاولة.',
        isOffline: true,
      );
    } on FirebaseException catch (e) {
      debugPrint('Business submission FirebaseException (${e.code}): ${e.message}');
      if (e.code == 'unavailable' || e.code == 'network-request-failed') {
        return BusinessRegistrationResult.failure(
          message:
              'انقطع الاتصال بالإنترنت أثناء حفظ الطلب. بياناتك محفوظة كما هي — تحقق من الشبكة وحاول مرة أخرى.',
          isOffline: true,
        );
      }
      if (e.code == 'permission-denied') {
        return BusinessRegistrationResult.failure(
          message:
              'تعذر حفظ الطلب بسبب صلاحيات قاعدة البيانات — تأكد من تسجيل الدخول بحساب مفعل وتحديث قواعد الحماية.',
        );
      }
      return BusinessRegistrationResult.failure(
        message: 'تعذر حفظ بيانات المنشأة (${e.code}). تحقق من اتصال الإنترنت وحاول مرة أخرى.',
      );
    } catch (e) {
      return BusinessRegistrationResult.failure(
        message: 'حدث خطأ غير متوقع أثناء إرسال الطلب: $e',
      );
    }
  }

  /// Saves edits made by the Place Owner to their uploaded place and dispatches
  /// a review alert directly to the Admin Dashboard (`has_pending_edits: true`
  /// + `admin_notifications`).
  Future<bool> updateOwnerPlaceAndNotifyAdmin({
    required String businessId,
    required String businessName,
    required String category,
    required String phoneNumber,
    String? email,
    String? description,
    String? address,
    String? governorate,
    String? city,
    String? openingHours,
    String? website,
    GeoPoint? location,
    String? photoUrl,
    String? entrancePhotoUrl,
    String? elevatorPhotoUrl,
    String? restroomPhotoUrl,
    Map<String, dynamic>? accessibilityFeatures,
    List<String>? amenities,
    String? editSummary,
    String? currentStatus,
  }) async {
    try {
      final summary = (editSummary != null && editSummary.trim().isNotEmpty)
          ? editSummary.trim()
          : 'قام صاحب المكان بتحديث بيانات وتجهيزات الإتاحة الخاصة بـ "$businessName".';

      final updates = <String, dynamic>{
        'business_name': businessName.trim(),
        'category': category.trim(),
        'phone_number': phoneNumber.trim(),
        if (email != null) 'email': email.trim(),
        if (description != null) 'description': description.trim(),
        if (address != null) 'address': address.trim(),
        if (governorate != null) 'governorate': governorate.trim(),
        if (city != null) 'city': city.trim(),
        if (openingHours != null) 'opening_hours': openingHours.trim(),
        if (website != null) 'website': website.trim(),
        if (location != null) 'location': location,
        if (photoUrl != null) 'photo_url': photoUrl.trim(),
        if (photoUrl != null) 'logoUrl': photoUrl.trim(),
        if (entrancePhotoUrl != null)
          'entrance_photo_url': entrancePhotoUrl.trim(),
        if (elevatorPhotoUrl != null)
          'elevator_photo_url': elevatorPhotoUrl.trim(),
        if (restroomPhotoUrl != null)
          'restroom_photo_url': restroomPhotoUrl.trim(),
        if (accessibilityFeatures != null)
          'accessibility_features': accessibilityFeatures,
        if (amenities != null)
          'amenities': amenities.where((a) => a.trim().isNotEmpty).take(20).toList(),
        if (currentStatus == 'rejected') 'status': 'pending',
        'has_pending_edits': true,
        'last_edit_summary': summary,
        'updated_at': FieldValue.serverTimestamp(),
      };

      final hasInternet = await ConnectivityService.instance.checkHasInternet();
      if (!hasInternet) return false;

      await _businessesCollection
          .doc(businessId)
          .update(updates)
          .timeout(const Duration(seconds: 15));

      await _createAdminNotification(
        businessId: businessId,
        businessName: businessName.trim(),
        type: 'business_place_updated',
        title: 'تعديل جديد من صاحب مكان',
        body: summary,
      );
      return true;
    } on FirebaseException catch (e) {
      debugPrint('Error updating owner place: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Unexpected error updating owner place: $e');
      return false;
    }
  }

  /// Uploads the main photo for a business application safely across Android,
  /// iOS, and Web under `users/{uid}/businesses/...` (permitted by storage.rules).
  Future<String> uploadBusinessMainPhoto({
    required Uint8List bytes,
    required String uid,
  }) async {
    final optimized = await ImageCompressionService.compressForUpload(bytes);
    final ts = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage.ref('users/$uid/businesses/main_$ts.jpg');
    await ref
        .putData(
          optimized,
          SettableMetadata(contentType: 'image/jpeg'),
        )
        .timeout(const Duration(seconds: 20));
    return ref.getDownloadURL().timeout(const Duration(seconds: 10));
  }

  /// Upload additional business gallery images safely under `users/{uid}/businesses/...`
  /// matching `firebase/storage.rules` (fixes blocked `business_images/` path).
  Future<List<String>> uploadBusinessImages({
    required List<Uint8List> imageBytesList,
    required String uid,
  }) async {
    final urls = <String>[];
    for (int i = 0; i < imageBytesList.length; i++) {
      try {
        final optimized =
            await ImageCompressionService.compressForUpload(imageBytesList[i]);
        final ts = DateTime.now().millisecondsSinceEpoch;
        final ref = _storage.ref('users/$uid/businesses/gallery_${ts}_$i.jpg');
        await ref
            .putData(
              optimized,
              SettableMetadata(contentType: 'image/jpeg'),
            )
            .timeout(const Duration(seconds: 20));
        urls.add(
          await ref.getDownloadURL().timeout(const Duration(seconds: 10)),
        );
      } catch (e) {
        debugPrint('Error uploading gallery image $i: $e');
      }
    }
    return urls;
  }

  /// Upload a named facility photo (e.g. entrance, elevator, restroom) under
  /// `users/{uid}/businesses/...`.
  Future<String> uploadFacilityPhoto({
    required Uint8List bytes,
    required String uid,
    required String slot,
  }) async {
    final optimized = await ImageCompressionService.compressForUpload(bytes);
    final ts = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage.ref('users/$uid/businesses/${slot}_$ts.jpg');
    await ref
        .putData(
          optimized,
          SettableMetadata(contentType: 'image/jpeg'),
        )
        .timeout(const Duration(seconds: 20));
    return ref.getDownloadURL().timeout(const Duration(seconds: 10));
  }

  Future<BusinessesRecord?> getCurrentUserBusiness() async {
    final uid = _resolvedUid;
    if (!_hasActiveUser || uid.isEmpty) return null;
    try {
      final snapshot = await _businessesCollection
          .where('ownerId', isEqualTo: uid)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        return BusinessesRecord.fromSnapshot(snapshot.docs.first);
      }
    } on FirebaseException catch (e) {
      debugPrint(
        'getCurrentUserBusiness list query fallback (${e.code}): ${e.message}',
      );
    } catch (e) {
      debugPrint('getCurrentUserBusiness error: $e');
    }

    // Safe document-by-ID fallback via users/{uid}.business_application_id
    try {
      final userDoc = await _usersCollection.doc(uid).get();
      final appId =
          (userDoc.data()?['business_application_id'] as String?)?.trim() ?? '';
      if (appId.isNotEmpty) {
        return await getBusiness(appId);
      }
    } catch (_) {}
    return null;
  }

  Future<BusinessesRecord?> getBusiness(String businessId) async {
    try {
      final doc = await _businessesCollection.doc(businessId).get();
      if (doc.exists) {
        return BusinessesRecord.fromSnapshot(doc);
      }
      return null;
    } on FirebaseException catch (e) {
      debugPrint('Error getting business: ${e.message}');
      return null;
    }
  }

  Future<BusinessApplicationStatus> getApplicationStatus() async {
    final business = await getCurrentUserBusiness();
    if (business == null) return BusinessApplicationStatus.none;

    switch (business.status) {
      case 'pending':
        return BusinessApplicationStatus.pending;
      case 'active':
        return BusinessApplicationStatus.approved;
      case 'rejected':
        return BusinessApplicationStatus.rejected;
      case 'suspended':
        return BusinessApplicationStatus.suspended;
      default:
        return BusinessApplicationStatus.none;
    }
  }

  Stream<BusinessesRecord?> streamCurrentUserBusiness() {
    final uid = _resolvedUid;
    if (!_hasActiveUser || uid.isEmpty) return Stream.value(null);
    return _businessesCollection
        .where('ownerId', isEqualTo: uid)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return BusinessesRecord.fromSnapshot(snapshot.docs.first);
    }).handleError((Object e) {
      debugPrint('streamCurrentUserBusiness handled error: $e');
    });
  }

  Future<bool> requestFieldAssessment({
    required String businessId,
    String businessName = '',
  }) async {
    try {
      await _firestore.collection('field_assessment_requests').add({
        'business_id': businessId,
        'business_name': businessName,
        'owner_id': currentUserUid,
        'status': 'pending',
        'requested_at': FieldValue.serverTimestamp(),
        'created_at': FieldValue.serverTimestamp(),
      });
      await _createAdminNotification(
        businessId: businessId,
        businessName: businessName,
        type: 'field_assessment_request',
        title: 'طلب فحص ميداني رسمي',
        body: 'طلب صاحب المكان إجراء زيارة فحص ميداني لتوثيق الإتاحة.',
      );
      return true;
    } on FirebaseException catch (e) {
      debugPrint('Error requesting field assessment: ${e.message}');
      return false;
    }
  }

  Future<List<BusinessesRecord>> getPendingBusinesses({int limit = 50}) async {
    try {
      final snapshot = await _businessesCollection
          .where('status', isEqualTo: 'pending')
          .orderBy('submittedAt', descending: true)
          .limit(limit)
          .get();
      return snapshot.docs.map(BusinessesRecord.fromSnapshot).toList();
    } on FirebaseException catch (e) {
      debugPrint('Error getting pending businesses: ${e.message}');
      return [];
    }
  }

  String? _validateBusinessData(BusinessApplicationData data) {
    if (data.businessName.trim().isEmpty) {
      return 'اسم المكان مطلوب';
    }
    if (data.category.isEmpty) {
      return 'تصنيف المكان مطلوب';
    }
    if (data.phoneNumber.trim().length < 8) {
      return 'رقم هاتف التواصل غير صالح';
    }
    if (data.ownerName?.trim().isEmpty ?? true) {
      return 'اسم صاحب المكان مطلوب';
    }
    if ((data.ownerPhone?.trim().length ?? 0) < 8) {
      return 'رقم هاتف صاحب المكان غير صالح';
    }
    return null;
  }

  Future<void> _createAdminNotification({
    required String businessId,
    required String businessName,
    required String type,
    required String title,
    required String body,
  }) async {
    try {
      await _firestore.collection('admin_notifications').add({
        'type': type,
        'business_id': businessId,
        'business_name': businessName,
        'title': title,
        'body': body,
        'is_read': false,
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error creating admin notification: $e');
    }
  }
}

class BusinessApplicationData {
  final String businessName;
  final String category;
  final String phoneNumber;
  final String? email;
  final String? description;
  final String? address;
  final String? governorate;
  final String? city;
  final String? openingHours;
  final String? website;
  final GeoPoint? location;
  final Map<String, dynamic>? workingHours;
  final List<String>? services;
  final Map<String, dynamic>? accessibilityFeatures;
  final List<String>? amenities;
  final String? ownerName;
  final String? ownerPhone;
  final String? ownerEmail;
  final String? claimedExistingPlaceId;

  BusinessApplicationData({
    required this.businessName,
    required this.category,
    required this.phoneNumber,
    this.email,
    this.description,
    this.address,
    this.governorate,
    this.city,
    this.openingHours,
    this.website,
    this.location,
    this.workingHours,
    this.services,
    this.accessibilityFeatures,
    this.amenities,
    this.ownerName,
    this.ownerPhone,
    this.ownerEmail,
    this.claimedExistingPlaceId,
  });
}

class BusinessRegistrationResult {
  final bool success;
  final String? message;
  final String? businessId;
  final bool isOffline;

  BusinessRegistrationResult._({
    required this.success,
    this.message,
    this.businessId,
    this.isOffline = false,
  });

  factory BusinessRegistrationResult.success({
    required String businessId,
    String? message,
  }) =>
      BusinessRegistrationResult._(
        success: true,
        message: message,
        businessId: businessId,
      );

  factory BusinessRegistrationResult.failure({
    required String message,
    bool isOffline = false,
  }) =>
      BusinessRegistrationResult._(
        success: false,
        message: message,
        isOffline: isOffline,
      );
}

enum BusinessApplicationStatus {
  none,
  pending,
  approved,
  rejected,
  suspended,
}

extension BusinessApplicationStatusExtension on BusinessApplicationStatus {
  String get label {
    switch (this) {
      case BusinessApplicationStatus.none:
        return 'غير مسجل';
      case BusinessApplicationStatus.pending:
        return 'قيد مراجعة الإدارة';
      case BusinessApplicationStatus.approved:
        return 'معتمد ومنشور';
      case BusinessApplicationStatus.rejected:
        return 'يحتاج تعديل';
      case BusinessApplicationStatus.suspended:
        return 'معلق';
    }
  }

  String get description {
    switch (this) {
      case BusinessApplicationStatus.none:
        return 'لم تقم برفع بيانات مكانك بعد';
      case BusinessApplicationStatus.pending:
        return 'بيانات مكانك قيد المراجعة لدى إدارة ONEWAY ويمكنك تعديلها في أي وقت';
      case BusinessApplicationStatus.approved:
        return 'مكانك معتمد ويظهر للمستخدمين على الخريطة ودليل الأماكن';
      case BusinessApplicationStatus.rejected:
        return 'يرجى مراجعة ملاحظات الإدارة وتعديل بيانات مكانك وإعادة إرسالها';
      case BusinessApplicationStatus.suspended:
        return 'حساب المكان معلق مؤقتاً — تواصل مع الإدارة';
    }
  }
}
