import 'dart:async';
import 'pending_email_change.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../base_auth_user_provider.dart';

export '../base_auth_user_provider.dart';

class OneWayEgyptFirebaseUser extends BaseAuthUser {
  OneWayEgyptFirebaseUser(this.user);
  User? user;

  /// Guest/anonymous sessions are strictly disallowed — only registered
  /// non-anonymous Firebase accounts count as logged in.
  @override
  bool get loggedIn => user != null && !user!.isAnonymous;

  @override
  AuthUserInfo get authUserInfo => AuthUserInfo(
        uid: user?.uid,
        email: user?.email,
        displayName: user?.displayName,
        photoUrl: user?.photoURL,
        phoneNumber: user?.phoneNumber,
      );

  @override
  Future? delete() => user?.delete();

  @override
  Future? updateEmail(String email) async {
    final targetUser = user;
    if (targetUser == null) return;
    await targetUser.verifyBeforeUpdateEmail(email);
    await rememberPendingEmailChange(targetUser.uid, email);
    unawaited(syncPendingEmailChange(targetUser));
  }

  @override
  Future? updatePassword(String newPassword) async {
    await user?.updatePassword(newPassword);
  }

  @override
  Future? sendEmailVerification() => user?.sendEmailVerification();

  @override
  bool get emailVerified {
    if (loggedIn && !user!.emailVerified) {
      refreshUser();
    }
    return user?.emailVerified ?? false;
  }

  @override
  Future refreshUser() async {
    await FirebaseAuth.instance.currentUser
        ?.reload()
        .then((_) => user = FirebaseAuth.instance.currentUser);
    unawaited(syncPendingEmailChange(user));
  }

  static BaseAuthUser fromUserCredential(UserCredential userCredential) =>
      fromFirebaseUser(userCredential.user);
  static BaseAuthUser fromFirebaseUser(User? user) =>
      OneWayEgyptFirebaseUser(user);
}

Stream<BaseAuthUser> oneWayEgyptFirebaseUserStream() =>
    FirebaseAuth.instance.authStateChanges().asyncMap<BaseAuthUser>(
      (user) async {
        // Purge any legacy anonymous guest session automatically
        if (user != null && user.isAnonymous) {
          try {
            await FirebaseAuth.instance.signOut();
          } catch (_) {}
          currentUser = OneWayEgyptFirebaseUser(null);
          return currentUser!;
        }
        currentUser = OneWayEgyptFirebaseUser(user);
        unawaited(syncPendingEmailChange(user));
        return currentUser!;
      },
    );
