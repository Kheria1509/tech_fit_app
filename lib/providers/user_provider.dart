import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/exercise_service.dart';
import '../models/user_model.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  AuthService _authService = AuthService();
  ExerciseService _exerciseService = ExerciseService();

  UserModel? get user => _user;
  bool get isLoading => _isLoading;

  // Update user data when auth state changes
  void update(User? firebaseUser) async {
    if (firebaseUser == null) {
      _user = null;
      notifyListeners();
      return;
    }

    // For demo purposes, create a mock user if needed
    _createMockUser();

    // Only fetch user data if we don't have it already or if the user ID changed
    if (_user == null || _user!.uid != firebaseUser.uid) {
      await refreshUserData();
    }
  }

  // Create a mock user for demonstration purposes
  void _createMockUser() {
    // Create a list of mock exercise sessions
    final List<ExerciseSession> mockSessions = [];

    // Add a few recent sessions
    final now = DateTime.now();

    // Yesterday's session
    mockSessions.add(
      ExerciseSession(
        id: '1',
        date: now.subtract(const Duration(days: 1)),
        duration: const Duration(minutes: 35),
        caloriesBurned: 320,
        avgSpeed: 5.2,
        maxSpeed: 7.8,
        avgIncline: 2.5,
        maxIncline: 5.0,
        avgHeartRate: 142,
        maxHeartRate: 165,
        vo2Max: 38.5,
      ),
    );

    // 3 days ago session
    mockSessions.add(
      ExerciseSession(
        id: '2',
        date: now.subtract(const Duration(days: 3)),
        duration: const Duration(minutes: 28),
        caloriesBurned: 250,
        avgSpeed: 4.8,
        maxSpeed: 6.5,
        avgIncline: 1.5,
        maxIncline: 3.0,
        avgHeartRate: 135,
        maxHeartRate: 155,
        vo2Max: 36.2,
      ),
    );

    // 5 days ago session
    mockSessions.add(
      ExerciseSession(
        id: '3',
        date: now.subtract(const Duration(days: 5)),
        duration: const Duration(minutes: 42),
        caloriesBurned: 380,
        avgSpeed: 5.5,
        maxSpeed: 8.2,
        avgIncline: 3.0,
        maxIncline: 6.0,
        avgHeartRate: 148,
        maxHeartRate: 172,
        vo2Max: 39.8,
      ),
    );

    // Create the mock user
    _user = UserModel(
      uid: 'mock-user-id',
      name: 'John Doe',
      email: 'john.doe@example.com',
      birthDate: DateTime(1990, 5, 15),
      gender: Gender.male,
      height: 178.0,
      weight: 75.0,
      targetWeight: 72.0,
      profileImageUrl: 'https://randomuser.me/api/portraits/men/32.jpg',
      maxHeartRate: 185,
      vo2Max: 42.5,
      anaerobicThreshold: 165.0,
      sessions: mockSessions,
    );

    notifyListeners();
  }

  // Refresh user data from Firestore
  Future<void> refreshUserData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userData = await _authService.getUserData();
      if (userData != null) {
        _user = userData;
      } else {
        // If no user data found, create mock data for demo
        _createMockUser();
      }
    } catch (e) {
      debugPrint('Error refreshing user data: $e');
      // Create mock data if there's an error
      _createMockUser();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update user profile
  Future<void> updateProfile({
    String? name,
    DateTime? birthDate,
    Gender? gender,
    double? height,
    double? weight,
    double? targetWeight,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.updateUserProfile(
        name: name,
        birthDate: birthDate,
        gender: gender,
        height: height,
        weight: weight,
        targetWeight: targetWeight,
      );

      // Refresh user data
      await refreshUserData();
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Upload profile image
  Future<void> uploadProfileImage(File imageFile) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.uploadProfileImage(imageFile);

      // Refresh user data
      await refreshUserData();
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get user exercise history
  Future<List<ExerciseSession>> getExerciseHistory() async {
    try {
      return await _exerciseService.getUserExerciseHistory();
    } catch (e) {
      debugPrint('Error getting exercise history: $e');
      return [];
    }
  }

  // Get recent exercise session
  Future<ExerciseSession?> getMostRecentSession() async {
    try {
      return await _exerciseService.getMostRecentSession();
    } catch (e) {
      debugPrint('Error getting most recent session: $e');
      return null;
    }
  }

  // Start a new exercise session
  Future<String> startExerciseSession() async {
    try {
      return await _exerciseService.startSession();
    } catch (e) {
      debugPrint('Error starting exercise session: $e');
      rethrow;
    }
  }

  // End the current exercise session
  Future<void> endExerciseSession(String sessionId) async {
    try {
      await _exerciseService.endSession(sessionId);

      // Refresh user data to include new session
      await refreshUserData();
    } catch (e) {
      debugPrint('Error ending exercise session: $e');
      rethrow;
    }
  }

  // Add a new exercise session from device tracking
  Future<void> addExerciseSession(dynamic sessionData) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Create a new exercise session
      final session = ExerciseSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: DateTime.now(),
        duration: Duration(
          minutes: sessionData.durationMinutes,
          seconds: sessionData.durationSeconds,
        ),
        caloriesBurned: sessionData.caloriesBurned.toDouble(),
        avgSpeed: sessionData.averageSpeed,
        maxSpeed: sessionData.maxSpeed,
        avgIncline:
            0.0, // Default value as it might not be available from device
        maxIncline:
            0.0, // Default value as it might not be available from device
        avgHeartRate: sessionData.averageHeartRate.round(),
        maxHeartRate: sessionData.maxHeartRate.round(),
        vo2Max: 0.0, // Default value as it might not be available from device
      );

      // Save to Firestore
      await _exerciseService.saveExerciseSession(session);

      // Refresh user data
      await refreshUserData();
    } catch (e) {
      debugPrint('Error adding exercise session: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Check if user has completed profile setup
  Future<bool> hasCompletedProfileSetup() async {
    return await _authService.hasUserCompletedSetup();
  }

  // Sign out
  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    notifyListeners();
  }
}
