import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kimppakyyti/providers/database.dart';
import 'package:kimppakyyti/utilities/error.dart';

class AuthProvider extends DatabaseProvider {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int? _code;
  StreamSubscription<DatabaseEvent>? subscription;

  Future<void> _duplicateAuthChecker(String uid) async {
    final ref =
        FirebaseDatabase.instance.ref().child('users/$uid/private/code');
    subscription = await ref
        .set(ServerValue.increment(1))
        .then((_) => ref.onValue.listen((event) {
              final value = event.snapshot.value as int;
              final code = _code ??= value;
              if (value > code) signOut();
            }));
  }

  Future<void> _addUserToDatabase(User user) async {
    final data = {
      'name': user.displayName,
      'image': user.photoURL,
      'phone': user.phoneNumber
    };
    FirebaseDatabase.instance
        .ref()
        .child('users/${user.uid}/public/')
        .set(data)
        .catchError((_) => _auth.signOut());
  }

  Future<void> signInWithGoogle() async {
    try {
      final gUser = await GoogleSignIn().signIn();
      if (gUser == null) {
        return;
      }
      final gAuth = await gUser.authentication;
      final authCredential = GoogleAuthProvider.credential(
          accessToken: gAuth.accessToken, idToken: gAuth.idToken);
      final credential = await _auth.signInWithCredential(authCredential);
      if (credential.additionalUserInfo!.isNewUser) {
        _addUserToDatabase(credential.user!);
      }
    } on PlatformException catch (error) {
      if (error.code == "network_error") {
        throw SignInException(error: Errors.networkError);
      } else {
        throw SignInException();
      }
    } on FirebaseAuthException catch (error) {
      throw SignInException(message: error.message);
    }
  }

  Future<void> signOut() async {
    return _auth.signOut();
  }

  @override
  void close() {
    subscription?.cancel();
    subscription = null;
  }

  @override
  void start(String uid) {
    _duplicateAuthChecker(uid);
  }
}
