import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '/backend/backend.dart';
import 'package:stream_transform/stream_transform.dart';
import 'firebase_auth_manager.dart';

export 'firebase_auth_manager.dart';

final _authManager = FirebaseAuthManager();
FirebaseAuthManager get authManager => _authManager;

String get currentUserEmail {
  final docEmail = currentUserDocument?.email ?? '';
  if (docEmail.isNotEmpty) return docEmail;
  final cachedEmail = currentUser?.email ?? '';
  if (cachedEmail.isNotEmpty) return cachedEmail;
  try {
    final fb = FirebaseAuth.instance.currentUser;
    if (fb != null && !fb.isAnonymous) return fb.email ?? '';
  } catch (_) {}
  return '';
}

String get currentUserUid {
  final cachedUid = currentUser?.uid ?? '';
  if (cachedUid.isNotEmpty) return cachedUid;
  try {
    final fb = FirebaseAuth.instance.currentUser;
    if (fb != null && !fb.isAnonymous) return fb.uid;
  } catch (_) {}
  return '';
}

String get currentUserDisplayName {
  final docName = currentUserDocument?.displayName ?? '';
  if (docName.isNotEmpty) return docName;
  final cachedName = currentUser?.displayName ?? '';
  if (cachedName.isNotEmpty) return cachedName;
  try {
    final fb = FirebaseAuth.instance.currentUser;
    if (fb != null && !fb.isAnonymous) return fb.displayName ?? '';
  } catch (_) {}
  return '';
}

String get currentUserPhoto {
  final docPhoto = currentUserDocument?.photoUrl ?? '';
  if (docPhoto.isNotEmpty) return docPhoto;
  final cachedPhoto = currentUser?.photoUrl ?? '';
  if (cachedPhoto.isNotEmpty) return cachedPhoto;
  try {
    final fb = FirebaseAuth.instance.currentUser;
    if (fb != null && !fb.isAnonymous) return fb.photoURL ?? '';
  } catch (_) {}
  return '';
}

String get currentPhoneNumber {
  final docPhone = currentUserDocument?.phoneNumber ?? '';
  if (docPhone.isNotEmpty) return docPhone;
  final cachedPhone = currentUser?.phoneNumber ?? '';
  if (cachedPhone.isNotEmpty) return cachedPhone;
  try {
    final fb = FirebaseAuth.instance.currentUser;
    if (fb != null && !fb.isAnonymous) return fb.phoneNumber ?? '';
  } catch (_) {}
  return '';
}

String get currentJwtToken => _currentJwtToken ?? '';

bool get currentUserEmailVerified => currentUser?.emailVerified ?? false;

/// Create a Stream that listens to the current user's JWT Token, since Firebase
/// generates a new token every hour.
String? _currentJwtToken;
final jwtTokenStream = FirebaseAuth.instance
    .idTokenChanges()
    .map((user) async => _currentJwtToken = await user?.getIdToken())
    .asBroadcastStream();

DocumentReference? get currentUserReference =>
    loggedIn ? UsersRecord.collection.doc(currentUser!.uid) : null;

UsersRecord? currentUserDocument;
final authenticatedUserStream = FirebaseAuth.instance
    .authStateChanges()
    .map<String>((user) => user?.uid ?? '')
    .switchMap(
      (uid) => uid.isEmpty
          ? Stream.value(null)
          : UsersRecord.getDocument(UsersRecord.collection.doc(uid))
              .handleError((_) {}),
    )
    .map((user) {
  currentUserDocument = user;

  return currentUserDocument;
}).asBroadcastStream();

class AuthUserStreamWidget extends StatelessWidget {
  const AuthUserStreamWidget({super.key, required this.builder});

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) => StreamBuilder(
        stream: authenticatedUserStream,
        builder: (context, _) => builder(context),
      );
}

bool get currentUserIsAdmin =>
    currentUserDocument?.role == 'admin' ||
    currentUserDocument?.role == 'superAdmin';

/// Simplified 3-role model (`user`, `businessOwner`, `admin`): moderator
/// permissions map strictly to admin.
bool get currentUserIsModerator => currentUserIsAdmin;

bool get currentUserIsBusinessOwner =>
    currentUserDocument?.role == 'businessOwner' ||
    (((currentUserDocument?.snapshotData['business_application_id']
                as String?) ??
            '')
        .trim()
        .isNotEmpty);

bool get currentUserIsAnonymous {
  try {
    return FirebaseAuth.instance.currentUser?.isAnonymous ?? false;
  } catch (_) {
    return false;
  }
}

String get currentUserRole {
  final raw = currentUserDocument?.role ?? 'user';
  if (raw == 'superAdmin' || raw == 'moderator') return 'admin';
  if (raw == 'businessOwner') return 'businessOwner';
  return 'user';
}
