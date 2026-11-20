import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/backend/backend.dart';
import '/backend/schema/users_record.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Service for managing user profiles in Firestore.
/// Handles profile creation, updates, and queries.
class UserProfileService {
  UserProfileService._();
  static final UserProfileService instance = UserProfileService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// Collection reference
  CollectionReference get _usersCollection => UsersRecord.collection;

  /// Create or update user profile after authentication
  Future<UsersRecord?> createOrUpdateProfile({
    required User firebaseUser,
    String? displayName,
    String? phoneNumber,
    String? role,
  }) async {
    final userDoc = _usersCollection.doc(firebaseUser.uid);
    final docSnapshot = await userDoc.get();

    if (docSnapshot.exists) {
      // Update existing profile with new data if provided
      final updates = <String, dynamic>{
        'updated_time': FieldValue.serverTimestamp(),
      };

      if (displayName != null && displayName.isNotEmpty) {
        updates['display_name'] = displayName;
      }
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        updates['phone_number'] = phoneNumber;
      }
      if (role != null) {
        updates['role'] = role;
      }

      // Update email if changed
      if (firebaseUser.email != null) {
        updates['email'] = firebaseUser.email;
      }

      // Update photo URL if available
      if (firebaseUser.photoURL != null) {
        updates['photo_url'] = firebaseUser.photoURL;
      }

      await userDoc.update(updates);
      return UsersRecord.fromSnapshot(await userDoc.get());
    } else {
      // Create new profile
      final userData = createUsersRecordData(
        email: firebaseUser.email,
        displayName: displayName ?? firebaseUser.displayName,
        photoUrl: firebaseUser.photoURL,
        uid: firebaseUser.uid,
        phoneNumber: phoneNumber ?? firebaseUser.phoneNumber,
        role: role ?? 'user',
        createdTime: getCurrentTimestamp,
      );

      await userDoc.set(userData);
      return UsersRecord.getDocumentFromData(userData, userDoc);
    }
  }

  /// Get user profile by UID
  Future<UsersRecord?> getProfile(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      if (doc.exists) {
        return UsersRecord.fromSnapshot(doc);
      }
      return null;
    } on FirebaseException catch (e) {
      print('Error getting user profile: ${e.message}');
      return null;
    }
  }

  /// Get current user's profile
  Future<UsersRecord?> getCurrentUserProfile() async {
    final uid = currentUserUid;
    if (uid.isEmpty) return null;
    return getProfile(uid);
  }

  /// Update user profile fields
  Future<bool> updateProfile({
    required String uid,
    String? displayName,
    String? phoneNumber,
    String? photoUrl,
    String? email,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_time': FieldValue.serverTimestamp(),
      };

      if (displayName != null) updates['display_name'] = displayName;
      if (phoneNumber != null) updates['phone_number'] = phoneNumber;
      if (photoUrl != null) updates['photo_url'] = photoUrl;
      if (email != null) updates['email'] = email;

      await _usersCollection.doc(uid).update(updates);
      return true;
    } on FirebaseException catch (e) {
      print('Error updating profile: ${e.message}');
      return false;
    }
  }

  /// Update current user's profile
  Future<bool> updateCurrentUserProfile({
    String? displayName,
    String? phoneNumber,
    String? photoUrl,
  }) async {
    final uid = currentUserUid;
    if (uid.isEmpty) return false;
    return updateProfile(
      uid: uid,
      displayName: displayName,
      phoneNumber: phoneNumber,
      photoUrl: photoUrl,
    );
  }

  /// Check if profile is complete (has required fields)
  bool isProfileComplete(UsersRecord? profile) {
    if (profile == null) return false;
    return profile.displayName.isNotEmpty &&
        profile.phoneNumber.isNotEmpty;
  }

  /// Get missing required fields for profile completion
  List<String> getMissingFields(UsersRecord? profile) {
    final missing = <String>[];
    if (profile == null) {
      return ['displayName', 'phoneNumber'];
    }
    if (profile.displayName.isEmpty) missing.add('displayName');
    if (profile.phoneNumber.isEmpty) missing.add('phoneNumber');
    return missing;
  }

  /// Search users by name or email
  Future<List<UsersRecord>> searchUsers({
    required String query,
    int limit = 20,
  }) async {
    try {
      final lowerQuery = query.toLowerCase();

      // Search by display name
      final nameResults = await _usersCollection
          .where('display_name', isGreaterThanOrEqualTo: lowerQuery)
          .where('display_name', isLessThanOrEqualTo: '$lowerQuery')
          .limit(limit)
          .get();

      // Search by email
      final emailResults = await _usersCollection
          .where('email', isGreaterThanOrEqualTo: lowerQuery)
          .where('email', isLessThanOrEqualTo: '$lowerQuery')
          .limit(limit)
          .get();

      final users = <UsersRecord>[];
      final seenUids = <String>{};

      for (final doc in [...nameResults.docs, ...emailResults.docs]) {
        final user = UsersRecord.fromSnapshot(doc);
        if (!seenUids.contains(user.uid)) {
          users.add(user);
          seenUids.add(user.uid);
        }
      }

      return users.take(limit).toList();
    } on FirebaseException catch (e) {
      print('Error searching users: ${e.message}');
      return [];
    }
  }

  /// Get users by role
  Future<List<UsersRecord>> getUsersByRole({
    required String role,
    int limit = 50,
  }) async {
    try {
      final snapshot = await _usersCollection
          .where('role', isEqualTo: role)
          .limit(limit)
          .get();

      return snapshot.docs.map(UsersRecord.fromSnapshot).toList();
    } on FirebaseException catch (e) {
      print('Error getting users by role: ${e.message}');
      return [];
    }
  }

  /// Get user count by role
  Future<int> getUserCountByRole(String role) async {
    try {
      final count = await _usersCollection
          .where('role', isEqualTo: role)
          .count()
          .get();
      return count.count ?? 0;
    } on FirebaseException catch (e) {
      print('Error getting user count: ${e.message}');
      return 0;
    }
  }

  /// Delete user profile (admin only)
  Future<bool> deleteProfile(String uid) async {
    try {
      await _usersCollection.doc(uid).delete();
      return true;
    } on FirebaseException catch (e) {
      print('Error deleting profile: ${e.message}');
      return false;
    }
  }

  /// Set user role (admin only - should be done via Cloud Function)
  Future<bool> setUserRole(String uid, String role) async {
    try {
      await _usersCollection.doc(uid).update({
        'role': role,
        'updated_time': FieldValue.serverTimestamp(),
      });
      return true;
    } on FirebaseException catch (e) {
      print('Error setting user role: ${e.message}');
      return false;
    }
  }

  /// Stream user profile for real-time updates
  Stream<UsersRecord?> streamProfile(String uid) {
    return _usersCollection.doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UsersRecord.fromSnapshot(doc);
      }
      return null;
    });
  }

  /// Stream current user profile
  Stream<UsersRecord?> streamCurrentUserProfile() {
    final uid = currentUserUid;
    if (uid.isEmpty) return Stream.value(null);
    return streamProfile(uid);
  }
}