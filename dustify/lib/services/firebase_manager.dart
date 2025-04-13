import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

final String USER_COLLECTION = "users";

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Map? currentUser;

  FirebaseService();

  // This method ensures Firebase is initialized before using Firebase services
  Future<void> initialize() async {
    await Firebase.initializeApp();
  }

  Future<bool> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      UserCredential _userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      String _userId = _userCredential.user!.uid;
      await _db.collection(USER_COLLECTION).doc(_userId).set({
        "name": name,
        "email": email,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential _userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (_userCredential.user != null) {
        currentUser = await getUserData(uid: _userCredential.user!.uid);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<Map> getUserData({required String uid}) async {
    DocumentSnapshot _doc =
        await _db.collection(USER_COLLECTION).doc(uid).get();
    return _doc.data() as Map;
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
