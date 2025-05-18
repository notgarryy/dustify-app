import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final String USER_COLLECTION = "users";

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Map? currentUser;

  // Buffers to accumulate PM data
  List<double> _pm25Buffer = [];
  List<double> _pm10Buffer = [];
  int _currentBatchIndex = 0;
  String? _currentBatchDate; // format: 'ddMMMyyyy'

  FirebaseService();

  Future<void> initialize() async {
    await Firebase.initializeApp();
  }

  User? get currentFirebaseUser => _auth.currentUser;

  Future<bool> checkAndLoadUserData() async {
    if (currentFirebaseUser == null) {
      await logout();
      debugPrint("No user logged in. Forced logout.");
      return false;
    }
    try {
      currentUser = await getUserData(uid: currentFirebaseUser!.uid);
      debugPrint("User data loaded successfully.");
      return true;
    } catch (e) {
      debugPrint("Failed to load user data: $e");
      await logout();
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
      String todayFormatted = DateFormat('ddMMMyyyy').format(now);
      DateTime threshold = now.subtract(Duration(days: 30));

      // Delete old data (older than 30 days)
      final oldDocs =
          await userDataCollection
              .where('timestamp', isLessThan: Timestamp.fromDate(threshold))
              .get();
      for (final doc in oldDocs.docs) {
        await doc.reference.delete();
        debugPrint("Deleted old PM data: ${doc.id}");
      }

      // Save live data (!liveData)
      await userDataCollection.doc("!liveData").set({
        "PM25": pm25,
        "PM10": pm10,
        "timestamp": Timestamp.fromDate(now),
        "isLive": true,
      });

      int currentBatchIndex = 0;

      while (true) {
        String customDocId = "${todayFormatted}_data$currentBatchIndex";
        DocumentReference batchDocRef = userDataCollection.doc(customDocId);
        DocumentSnapshot batchSnapshot = await batchDocRef.get();

        if (!batchSnapshot.exists) {
          // First entry: create document
          Timestamp initialTime = Timestamp.fromDate(now);
          await batchDocRef.set({
            "avgPM25": pm25,
            "avgPM10": pm10,
            "docCreated": initialTime,
            "timestamp": Timestamp.fromDate(now),
            "entryCount": 1,
            "isLive": false,
          });
          debugPrint("Created $customDocId with entry 1");
          break;
        } else {
          Map<String, dynamic> data =
              batchSnapshot.data() as Map<String, dynamic>;
          int entryCount = (data['entryCount'] ?? 0);
          Timestamp docCreated = data['docCreated'] ?? Timestamp.fromDate(now);
          int minutesElapsed =
              DateTime.now().difference(docCreated.toDate()).inMinutes;

          // Check both conditions
          if (entryCount >= 30 || minutesElapsed >= 30) {
            currentBatchIndex++; // Go to next batch
            continue;
          }

          // Update cumulative average
          double prevPm25 = (data['avgPM25'] ?? 0.0) * entryCount;
          double prevPm10 = (data['avgPM10'] ?? 0.0) * entryCount;
          int newEntryCount = entryCount + 1;

          double newAvgPm25 = (prevPm25 + pm25) / newEntryCount;
          double newAvgPm10 = (prevPm10 + pm10) / newEntryCount;

          await batchDocRef.set({
            "avgPM25": newAvgPm25,
            "avgPM10": newAvgPm10,
            "entryCount": newEntryCount,
            "docCreated": docCreated,
            "timestamp": Timestamp.fromDate(now),
            "isLive": false,
          });

          debugPrint("Updated $customDocId with entry $newEntryCount");
          break;
        }
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
