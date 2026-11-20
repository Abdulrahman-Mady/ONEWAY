import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '/backend/backend.dart';
import '/backend/schema/businesses_record.dart';
import '/backend/schema/users_record.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/auth/firebase_auth/auth_util.dart';

/// Service for handling business registration and onboarding.
/// Manages the complete business application lifecycle.
class BusinessRegistrationService {
  BusinessRegistrationService._();
  static final BusinessRegistrationService instance = BusinessRegistrationService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// Collection references
  CollectionReference get _businessesCollection => BusinessesRecord.collection;
  CollectionReference get _usersCollection => UsersRecord.collection;

  /// Business categories
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

  /// Submit a new business application
  Future<BusinessRegistrationResult> submitBusinessApplication({
    required BusinessApplicationData data,
    List<String> imageUrls = const [],
    String? logoUrl,
  }) async {
    try {
      if (!loggedIn) {
        return BusinessRegistrationResult.failure(
          message: 'يجب تسجيل الدخول أولاً',
        );
      }

      // Validate required fields
      final validationError = _validateBusinessData(data);
      if (validationError != null) {
        return BusinessRegistrationResult.failure(message: validationError);
      }

      // Create business document with pending status
      final businessData = createBusinessesRecordData(
        ownerId: currentUserUid,
        businessName: data.businessName.trim(),
        category: data.category,
        phoneNumber: data.phoneNumber.trim(),
        email: data.email?.trim(),
        status: 'pending',
        subscriptionTier: 'free',
        branchPlaceIds: [],
        createdAt: DateTime.now(),
      );

      // Add additional fields
      final fullData = {
        ...businessData,
        'description': data.description?.trim(),
        'address': data.address?.trim(),
        'location': data.location,
        'workingHours': data.workingHours,
        'services': data.services ?? [],
        'ownerName': data.ownerName?.trim(),
        'ownerPhone': data.ownerPhone?.trim(),
        'ownerEmail': data.ownerEmail?.trim(),
        'logoUrl': logoUrl,
        'imageUrls': imageUrls,
        'submittedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _businessesCollection.add(fullData);

      // Update user role to businessOwner (pending) - actual role change via Cloud Function
      await _usersCollection.doc(currentUserUid).update({
        'business_application_id': docRef.id,
        'business_application_status': 'pending',
        'updated_time': FieldValue.serverTimestamp(),
      });

      // Create notification for admin review
      await _createAdminNotification(docRef.id, data.businessName);

      return BusinessRegistrationResult.success(
        businessId: docRef.id,
        message: 'تم تقديم طلب تسجيل المنشأة بنجاح وهو قيد المراجعة',
      );
    } on FirebaseException catch (e) {
      return BusinessRegistrationResult.failure(
        message: e.message ?? 'فشل تسجيل المنشأة',
      );
    } catch (e) {
      return BusinessRegistrationResult.failure(
        message: 'حدث خطأ غير متوقع: $e',
      );
    }
  }

  /// Upload business images to Firebase Storage
  Future<List<String>> uploadBusinessImages({
    required List<String> localPaths,
    required String businessId,
  }) async {
    final urls = <String>[];

    for (int i = 0; i < localPaths.length; i++) {
      try {
        final fileName = 'business_${businessId}_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final ref = _storage.ref().child('business_images/$fileName');

        // Upload file
        await ref.putFile(localPaths[i] as dynamic); // File upload

        // Get download URL
        final url = await ref.getDownloadURL();
        urls.add(url);
      } catch (e) {
        print('Error uploading image $i: $e');
      }
    }

    return urls;
  }

  /// Get current user's business application
  Future<BusinessesRecord?> getCurrentUserBusiness() async {
    if (!loggedIn) return null;

    final snapshot = await _businessesCollection
        .where('ownerId', isEqualTo: currentUserUid)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return BusinessesRecord.fromSnapshot(snapshot.docs.first);
  }

  /// Get business by ID
  Future<BusinessesRecord?> getBusiness(String businessId) async {
    try {
      final doc = await _businessesCollection.doc(businessId).get();
      if (doc.exists) {
        return BusinessesRecord.fromSnapshot(doc);
      }
      return null;
    } on FirebaseException catch (e) {
      print('Error getting business: ${e.message}');
      return null;
    }
  }

  /// Get business application status for current user
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

  /// Stream business application for real-time updates
  Stream<BusinessesRecord?> streamCurrentUserBusiness() {
    if (!loggedIn) return Stream.value(null);

    return _businessesCollection
        .where('ownerId', isEqualTo: currentUserUid)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return BusinessesRecord.fromSnapshot(snapshot.docs.first);
        });
  }

  /// Update business information (for approved businesses)
  Future<bool> updateBusiness({
    required String businessId,
    String? businessName,
    String? category,
    String? phoneNumber,
    String? email,
    String? description,
    String? address,
    GeoPoint? location,
    Map<String, dynamic>? workingHours,
    List<String>? services,
    String? logoUrl,
    List<String>? imageUrls,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (businessName != null) updates['business_name'] = businessName;
      if (category != null) updates['category'] = category;
      if (phoneNumber != null) updates['phone_number'] = phoneNumber;
      if (email != null) updates['email'] = email;
      if (description != null) updates['description'] = description;
      if (address != null) updates['address'] = address;
      if (location != null) updates['location'] = location;
      if (workingHours != null) updates['working_hours'] = workingHours;
      if (services != null) updates['services'] = services;
      if (logoUrl != null) updates['logo_url'] = logoUrl;
      if (imageUrls != null) updates['image_urls'] = imageUrls;

      await _businessesCollection.doc(businessId).update(updates);
      return true;
    } on FirebaseException catch (e) {
      print('Error updating business: ${e.message}');
      return false;
    }
  }

  /// Add branch/place to business
  Future<bool> addBranch({
    required String businessId,
    required String placeId,
  }) async {
    try {
      await _businessesCollection.doc(businessId).update({
        'branch_place_ids': FieldValue.arrayUnion([placeId]),
        'updated_at': FieldValue.serverTimestamp(),
      });
      return true;
    } on FirebaseException catch (e) {
      print('Error adding branch: ${e.message}');
      return false;
    }
  }

  /// Remove branch/place from business
  Future<bool> removeBranch({
    required String businessId,
    required String placeId,
  }) async {
    try {
      await _businessesCollection.doc(businessId).update({
        'branch_place_ids': FieldValue.arrayRemove([placeId]),
        'updated_at': FieldValue.serverTimestamp(),
      });
      return true;
    } on FirebaseException catch (e) {
      print('Error removing branch: ${e.message}');
      return false;
    }
  }

  /// Request field assessment for business
  Future<bool> requestFieldAssessment({
    required String businessId,
  }) async {
    try {
      await _firestore.collection('field_assessment_requests').add({
        'business_id': businessId,
        'owner_id': currentUserUid,
        'status': 'pending',
        'requested_at': FieldValue.serverTimestamp(),
      });

      // Notify admins
      await _createAssessmentNotification(businessId);

      return true;
    } on FirebaseException catch (e) {
      print('Error requesting field assessment: ${e.message}');
      return false;
    }
  }

  /// Get pending businesses for admin review
  Future<List<BusinessesRecord>> getPendingBusinesses({int limit = 50}) async {
    try {
      final snapshot = await _businessesCollection
          .where('status', isEqualTo: 'pending')
          .orderBy('submittedAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map(BusinessesRecord.fromSnapshot).toList();
    } on FirebaseException catch (e) {
      print('Error getting pending businesses: ${e.message}');
      return [];
    }
  }

  /// Approve business application (admin only - via Cloud Function)
  Future<bool> approveBusiness({
    required String businessId,
    String? adminNotes,
  }) async {
    try {
      await _businessesCollection.doc(businessId).update({
        'status': 'active',
        'approved_at': FieldValue.serverTimestamp(),
        'admin_notes': adminNotes,
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Update user role via Cloud Function (not directly)
      // This would be called from a Cloud Function
      return true;
    } on FirebaseException catch (e) {
      print('Error approving business: ${e.message}');
      return false;
    }
  }

  /// Reject business application (admin only - via Cloud Function)
  Future<bool> rejectBusiness({
    required String businessId,
    String? rejectionReason,
  }) async {
    try {
      await _businessesCollection.doc(businessId).update({
        'status': 'rejected',
        'rejected_at': FieldValue.serverTimestamp(),
        'rejection_reason': rejectionReason,
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Notify owner
      await _notifyBusinessOwner(businessId, 'rejected', rejectionReason);

      return true;
    } on FirebaseException catch (e) {
      print('Error rejecting business: ${e.message}');
      return false;
    }
  }

  /// Suspend business (admin only)
  Future<bool> suspendBusiness({
    required String businessId,
    String? reason,
  }) async {
    try {
      await _businessesCollection.doc(businessId).update({
        'status': 'suspended',
        'suspended_at': FieldValue.serverTimestamp(),
        'suspension_reason': reason,
        'updated_at': FieldValue.serverTimestamp(),
      });

      await _notifyBusinessOwner(businessId, 'suspended', reason);

      return true;
    } on FirebaseException catch (e) {
      print('Error suspending business: ${e.message}');
      return false;
    }
  }

  String? _validateBusinessData(BusinessApplicationData data) {
    if (data.businessName.trim().isEmpty) {
      return 'اسم المنشأة مطلوب';
    }
    if (data.category.isEmpty) {
      return 'تصنيف المنشأة مطلوب';
    }
    if (data.phoneNumber.trim().isEmpty) {
      return 'رقم هاتف التواصل مطلوب';
    }
    if (data.phoneNumber.trim().length < 8) {
      return 'رقم الهاتف غير صالح';
    }
    if (data.ownerName?.trim().isEmpty ?? true) {
      return 'اسم المالك مطلوب';
    }
    if (data.ownerPhone?.trim().isEmpty ?? true) {
      return 'رقم هاتف المالك مطلوب';
    }
    if (data.ownerPhone!.trim().length < 8) {
      return 'رقم هاتف المالك غير صالح';
    }
    return null;
  }

  Future<void> _createAdminNotification(String businessId, String businessName) async {
    try {
      await _firestore.collection('admin_notifications').add({
        'type': 'new_business_application',
        'business_id': businessId,
        'business_name': businessName,
        'title': 'طلب تسجيل منشأة جديد',
        'body': 'تم استلام طلب تسجيل منشأة "$businessName" ويحتاج للمراجعة',
        'is_read': false,
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating admin notification: $e');
    }
  }

  Future<void> _createAssessmentNotification(String businessId) async {
    try {
      await _firestore.collection('admin_notifications').add({
        'type': 'field_assessment_request',
        'business_id': businessId,
        'title': 'طلب تقييم ميداني',
        'body': 'صاحب منشأة طلب تقييم ميداني رسمي',
        'is_read': false,
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating assessment notification: $e');
    }
  }

  Future<void> _notifyBusinessOwner(
    String businessId,
    String action,
    String? reason,
  ) async {
    try {
      final business = await getBusiness(businessId);
      if (business == null) return;

      String title, body;
      switch (action) {
        case 'rejected':
          title = 'تم رفض طلب تسجيل المنشأة';
          body = 'تم رفض طلب تسجيل "${business.businessName}". السبب: ${reason ?? 'غير محدد'}';
          break;
        case 'suspended':
          title = 'تم تعليق المنشأة';
          body = 'تم تعليق منشأتك "${business.businessName}". السبب: ${reason ?? 'غير محدد'}';
          break;
        default:
          return;
      }

      await _firestore.collection('notifications').add({
        'userId': business.ownerId,
        'title': title,
        'body': body,
        'type': 'business_$action',
        'business_id': businessId,
        'is_read': false,
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error notifying business owner: $e');
    }
  }
}

/// Business application data model
class BusinessApplicationData {
  final String businessName;
  final String category;
  final String phoneNumber;
  final String? email;
  final String? description;
  final String? address;
  final GeoPoint? location;
  final Map<String, dynamic>? workingHours;
  final List<String>? services;
  final String? ownerName;
  final String? ownerPhone;
  final String? ownerEmail;

  BusinessApplicationData({
    required this.businessName,
    required this.category,
    required this.phoneNumber,
    this.email,
    this.description,
    this.address,
    this.location,
    this.workingHours,
    this.services,
    this.ownerName,
    this.ownerPhone,
    this.ownerEmail,
  });

  Map<String, dynamic> toMap() => {
        'business_name': businessName,
        'category': category,
        'phone_number': phoneNumber,
        'email': email,
        'description': description,
        'address': address,
        'location': location,
        'working_hours': workingHours,
        'services': services,
        'owner_name': ownerName,
        'owner_phone': ownerPhone,
        'owner_email': ownerEmail,
      };
}

/// Business registration result
class BusinessRegistrationResult {
  final bool success;
  final String? message;
  final String? businessId;

  BusinessRegistrationResult._({
    required this.success,
    this.message,
    this.businessId,
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

  factory BusinessRegistrationResult.failure({required String message}) =>
      BusinessRegistrationResult._(success: false, message: message);
}

/// Business application status enum
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
        return 'قيد المراجعة';
      case BusinessApplicationStatus.approved:
        return 'مقبول';
      case BusinessApplicationStatus.rejected:
        return 'مرفوض';
      case BusinessApplicationStatus.suspended:
        return 'معلق';
    }
  }

  String get description {
    switch (this) {
      case BusinessApplicationStatus.none:
        return 'لم تقدم طلب تسجيل منشأة بعد';
      case BusinessApplicationStatus.pending:
        return 'طلبك قيد المراجعة من قبل فريق OneWay';
      case BusinessApplicationStatus.approved:
        return 'منشأتك موثقة وتظهر للعملاء';
      case BusinessApplicationStatus.rejected:
        return 'تم رفض طلبك، تواصل مع الدعم للمزيد من التفاصيل';
      case BusinessApplicationStatus.suspended:
        return 'حساب منشأتك معلق مؤقتاً';
    }
  }
}