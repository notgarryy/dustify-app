import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

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

  User? get currentFirebaseUser => _auth.currentUser;

  Future<bool> checkAndLoadUserData() async {
    if (currentFirebaseUser == null) {
      await logout(); // logout if not logged in
      debugPrint("No user logged in. Forced logout.");
      return false; // still return false to inform
    }
    try {
      currentUser = await getUserData(uid: currentFirebaseUser!.uid);
      debugPrint("User data loaded successfully.");
      return true;
    } catch (e) {
      debugPrint("Failed to load user data: $e");
      await logout(); // logout if erroAr happens when loading user
      return false;
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      return false;
    }
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
      debugPrint("Register error: $e");
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
    } on FirebaseAuthException catch (e) {
      debugPrint("Login error: ${e.message}");
      return false;
    } catch (e) {
      debugPrint("Login general error: $e");
      return false;
    }
  }

  Future<Map> getUserData({required String uid}) async {
    DocumentSnapshot _doc =
        await _db.collection(USER_COLLECTION).doc(uid).get();
    return _doc.data() as Map;
  }

  Future<void> sendPMData({required double pm25, required double pm10}) async {
    final user = _auth.currentUser;

    if (user == null) {
      debugPrint("No user logged in. Cannot send PM data.");
      return;
    }

    try {
      String uid = user.uid;
      CollectionReference userDataCollection = _db
          .collection(USER_COLLECTION)
          .doc(uid)
          .collection("pm_data");

      DateTime now = DateTime.now();
      DateTime startOfDay = DateTime(now.year, now.month, now.day);
      DateTime endOfDay = startOfDay.add(Duration(days: 1));

      QuerySnapshot todaySnapshot =
          await userDataCollection
              .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
              .where('timestamp', isLessThan: endOfDay)
              .orderBy('timestamp')
              .get();

      int todayCount = todaySnapshot.docs.length;

      if (todayCount >= 12) {
        debugPrint("Already reached 12 data points today. Skipping save.");
      } else {
        String customDocId = "${now.millisecondsSinceEpoch}_data$todayCount";
        DateTime expiry = now.add(Duration(minutes: 1));

        await userDataCollection.doc(customDocId).set({
          "pm25": pm25,
          "pm10": pm10,
          "timestamp": now,
          "expiresAt": expiry,
        });

        debugPrint(
          "PM data sent to Firestore for today. Current count: ${todayCount + 1}",
        );
      }
    } catch (e) {
      debugPrint("Failed to send PM data: $e");
    }
  }

  Stream<QuerySnapshot> getTodayPmDataStream() {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception("No user logged in");
    }

    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);
    DateTime endOfDay = startOfDay.add(Duration(days: 1));

    return _db
        .collection(USER_COLLECTION)
        .doc(user.uid)
        .collection('pm_data')
        .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
        .where('timestamp', isLessThan: endOfDay)
        .orderBy('timestamp', descending: true)
        .limit(12)
        .snapshots();
  }

  Stream<QuerySnapshot> getAllPmDataStream() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("No user logged in.");
    }
    CollectionReference userDataCollection = _db
        .collection(USER_COLLECTION)
        .doc(user.uid)
        .collection("pm_data");

    return userDataCollection
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> logout() async {
    await _auth.signOut();
    currentUser = null;
    debugPrint("User logged out.");
  }
}
