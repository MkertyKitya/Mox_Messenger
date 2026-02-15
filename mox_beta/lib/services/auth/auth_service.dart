import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  // instance of auth
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // sign in
  Future<UserCredential> signInWithEmailPassword(String email, password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // save user info if it doesn't already exist
      _firestore.collection("Users").doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
      }, SetOptions(merge: true));

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  // sign up
  Future<UserCredential> signUpWithEmailPassword(
    String email,
    password,
    String nickname,
  ) async {
    final nick = nickname.trim();
    if (nick.isEmpty) throw Exception('empty-nickname');

    // check nickname exist
    final q = await _firestore
        .collection('Users')
        .where('nickname', isEqualTo: nick)
        .limit(1)
        .get();
    if (q.docs.isNotEmpty) {
      throw Exception('nickname-already-in-use');
    }

    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // update display name on Firebase Auth user
      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(nickname);
        await userCredential.user!.reload();
      }

      // save user info in a separate doc
      _firestore.collection("Users").doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'nickname': nick,
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  // update nickname for a user (both Firestore and Auth if current)
  Future<void> updateNickname(String uid, String nickname) async {
    // update Firestore
    await _firestore.collection("Users").doc(uid).set({
      'nickname': nickname,
    }, SetOptions(merge: true));

    // if updating current user, update Auth displayName
    if (_auth.currentUser != null && _auth.currentUser!.uid == uid) {
      await _auth.currentUser!.updateDisplayName(nickname);
      await _auth.currentUser!.reload();
    }
  }

  // sign out
  Future<void> signOut() async {
    return await _auth.signOut();
  }

  // errors
}
