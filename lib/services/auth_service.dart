import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_model.dart' as app;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current user
  User? get currentUser => _auth.currentUser;

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(
    String name,
    String email,
    String password,
  ) async {
    try {
      // Create user in Firebase Auth
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Create user document in Firestore
      await _createUserDocument(userCredential.user!.uid, name, email);

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Create user document in Firestore
  Future<void> _createUserDocument(
    String uid,
    String name,
    String email,
  ) async {
    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'name': name,
      'email': email,
      'profileSetupComplete': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Complete user profile setup
  Future<void> completeUserProfile({
    required DateTime birthDate,
    required app.Gender gender,
    required double height,
    required double weight,
    double? targetWeight,
  }) async {
    try {
      User? user = _auth.currentUser;

      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'birthDate': birthDate,
          'gender': gender.toString().split('.').last,
          'height': height,
          'weight': weight,
          'targetWeight': targetWeight ?? weight,
          'profileSetupComplete': true,
        });
      }
    } catch (e) {
      throw Exception('Failed to complete profile setup: $e');
    }
  }

  // Check if user has completed profile setup
  Future<bool> hasUserCompletedSetup() async {
    try {
      User? user = _auth.currentUser;

      if (user != null) {
        DocumentSnapshot doc =
            await _firestore.collection('users').doc(user.uid).get();
        return doc.exists &&
            (doc.data() as Map<String, dynamic>)['profileSetupComplete'] ==
                true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  // Get user data
  Future<app.UserModel?> getUserData() async {
    try {
      User? user = _auth.currentUser;

      if (user != null) {
        DocumentSnapshot doc =
            await _firestore.collection('users').doc(user.uid).get();

        if (doc.exists) {
          return app.UserModel.fromMap(doc.data() as Map<String, dynamic>);
        }
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  // Update user profile data
  Future<void> updateUserProfile({
    String? name,
    DateTime? birthDate,
    app.Gender? gender,
    double? height,
    double? weight,
    double? targetWeight,
  }) async {
    try {
      User? user = _auth.currentUser;

      if (user != null) {
        Map<String, dynamic> data = {};

        if (name != null) data['name'] = name;
        if (birthDate != null) data['birthDate'] = birthDate;
        if (gender != null) data['gender'] = gender.toString().split('.').last;
        if (height != null) data['height'] = height;
        if (weight != null) data['weight'] = weight;
        if (targetWeight != null) data['targetWeight'] = targetWeight;

        await _firestore.collection('users').doc(user.uid).update(data);
      }
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Upload profile image
  Future<String> uploadProfileImage(File imageFile) async {
    try {
      User? user = _auth.currentUser;

      if (user != null) {
        // Create a reference to the location where we'll store the file
        Reference ref = _storage
            .ref()
            .child('profile_images')
            .child('${user.uid}.jpg');

        // Upload file
        UploadTask uploadTask = ref.putFile(imageFile);
        TaskSnapshot taskSnapshot = await uploadTask;

        // Get download URL
        String downloadUrl = await taskSnapshot.ref.getDownloadURL();

        // Update user profile
        await _firestore.collection('users').doc(user.uid).update({
          'profileImageUrl': downloadUrl,
        });

        return downloadUrl;
      }

      throw Exception('User not authenticated');
    } catch (e) {
      throw Exception('Failed to upload profile image: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Handle Firebase Auth exceptions
  Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('No user found with this email.');
      case 'wrong-password':
        return Exception('Wrong password provided.');
      case 'email-already-in-use':
        return Exception('The email address is already in use.');
      case 'weak-password':
        return Exception('The password is too weak.');
      case 'invalid-email':
        return Exception('The email address is invalid.');
      default:
        return Exception('An error occurred: ${e.message}');
    }
  }
}
