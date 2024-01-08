import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:firebase_database/firebase_database.dart';
import 'package:kimppakyyti/models/user.dart';

class UserProvider {
  final List<User> data = [];
  final firebase.FirebaseAuth _auth = firebase.FirebaseAuth.instance;

  UserProvider() {
    _auth.authStateChanges().listen((firebaseUser) {
      if (firebaseUser == null) return;
      final user = _userFromFirebase(firebaseUser);
      data.add(user);
    });
  }

  Future<void> addUserToDatabase(firebase.User user) async {
    final data = {'name': user.displayName, 'image': user.photoURL};
    FirebaseDatabase.instance
        .ref()
        .child('users/${user.uid}/public/')
        .set(data)
        .catchError((_) => _auth.signOut());
  }

  User _userFromFirebase(firebase.User user) => User(user.uid, user.displayName!, user.photoURL!, user.phoneNumber);
  
  User _parseUser(DataSnapshot snapshot, String id) {
    final image = snapshot.child('image').value as String;
    final name = snapshot.child('name').value as String;
    return User(id, name, image, null);
  }

  Future<User> _fetchUser(String id) async {
    final ref = FirebaseDatabase.instance.ref('users/$id/public');
    final snapshot = await ref.get();
    final user = _parseUser(snapshot, id);
    data.add(user);
    return user;
  }

  Future<User> get(String id) async {
    try {
      return data.singleWhere((user) => user.id == id);
    } on StateError {
      return _fetchUser(id);
    }
  }
}
