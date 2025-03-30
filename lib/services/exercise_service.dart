import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

import '../models/user_model.dart';

class ExerciseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Simulated device connection state
  bool _isConnected = false;

  // Stream controller for exercise data
  final _dataStreamController = StreamController<ExerciseDataPoint>.broadcast();
  Stream<ExerciseDataPoint> get dataStream => _dataStreamController.stream;

  // Timer for simulating data points
  Timer? _dataTimer;

  // Simulation parameters - private fields for simulation state
  bool _isSimulating = false;
  int _elapsedSeconds = 0;
  double _currentSpeed = 3.0;
  double _currentHeartRate = 80.0;
  double _currentIncline = 0.0;
  double _calorieRate = 0.15; // calories per second

  // AT simulation parameters
  final int _simulatedATPoint = 60; // AT kicks in around 60 seconds
  bool _isATDetected = false;
  double _targetSpeedAfterAT = 0.0;

  // Singleton pattern
  static final ExerciseService _instance = ExerciseService._internal();
  factory ExerciseService() => _instance;
  ExerciseService._internal();

  // Get user exercise history from Firestore
  Future<List<ExerciseSession>> getUserExerciseHistory() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userData = userDoc.data();

    if (userData == null) {
      return [];
    }

    final exerciseHistory =
        (userData['sessions'] as List<dynamic>?)
            ?.map(
              (data) => ExerciseSession.fromMap(data as Map<String, dynamic>),
            )
            .toList() ??
        [];

    // Sort by date, newest first
    exerciseHistory.sort((a, b) => b.date.compareTo(a.date));

    return exerciseHistory;
  }

  // Get the most recent exercise session
  Future<ExerciseSession?> getMostRecentSession() async {
    try {
      User? user = _auth.currentUser;

      if (user != null) {
        QuerySnapshot querySnapshot =
            await _firestore
                .collection('users')
                .doc(user.uid)
                .collection('sessions')
                .orderBy('date', descending: true)
                .limit(1)
                .get();

        if (querySnapshot.docs.isNotEmpty) {
          return ExerciseSession.fromMap(
            querySnapshot.docs.first.data() as Map<String, dynamic>,
          );
        }
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get most recent session: $e');
    }
  }

  // Connect to device
  Future<bool> connectToDevice() async {
    // Simulate connection process
    await Future.delayed(const Duration(seconds: 1));
    _isConnected = true;
    return true;
  }

  // Start a new exercise session
  Future<String> startSession() async {
    try {
      User? user = _auth.currentUser;

      if (user != null) {
        // Create a new session document
        DocumentReference sessionRef = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('sessions')
            .add({
              'date': FieldValue.serverTimestamp(),
              'duration': 0,
              'status': 'active',
            });

        return sessionRef.id;
      }

      throw Exception('User not authenticated');
    } catch (e) {
      throw Exception('Failed to start exercise session: $e');
    }
  }

  // End the current exercise session
  Future<void> endSession(String sessionId) async {
    try {
      User? user = _auth.currentUser;

      if (user != null) {
        // Disconnect from Raspberry Pi
        stopDataCollection();

        // Calculate session statistics from collected data points
        List<ExerciseDataPoint> dataPoints = await _getSessionDataPoints(
          sessionId,
        );

        if (dataPoints.isNotEmpty) {
          // Calculate various stats from data points
          Map<String, dynamic> stats = calculateSessionStats(dataPoints);

          // Update session document with calculated stats
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('sessions')
              .doc(sessionId)
              .update({
                'status': 'completed',
                'duration': stats['duration'],
                'caloriesBurned': stats['caloriesBurned'],
                'avgSpeed': stats['avgSpeed'],
                'maxSpeed': stats['maxSpeed'],
                'avgIncline': stats['avgIncline'],
                'maxIncline': stats['maxIncline'],
                'avgHeartRate': stats['avgHeartRate'],
                'maxHeartRate': stats['maxHeartRate'],
              });
        }
      } else {
        throw Exception('User not authenticated');
      }
    } catch (e) {
      throw Exception('Failed to end exercise session: $e');
    }
  }

  // Parse data point from WebSocket
  ExerciseDataPoint _parseDataPoint(dynamic data, String sessionId) {
    Map<String, dynamic> jsonData = json.decode(data);

    return ExerciseDataPoint(
      timestamp: DateTime.now(),
      heartRate: (jsonData['heart_rate'] as num?)?.toDouble() ?? 0.0,
      speed: jsonData['speed']?.toDouble() ?? 0.0,
      calories: jsonData['calories']?.toDouble() ?? 0.0,
      incline: jsonData['incline']?.toDouble(),
      vo2: jsonData['vo2']?.toDouble(),
    );
  }

  // Store data point in Firestore
  Future<void> _storeDataPoint(
    String sessionId,
    ExerciseDataPoint dataPoint,
  ) async {
    try {
      User? user = _auth.currentUser;

      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('sessions')
            .doc(sessionId)
            .collection('data_points')
            .add(dataPoint.toMap());
      }
    } catch (e) {
      print('Error storing data point: $e');
    }
  }

  // Get all data points for a session
  Future<List<ExerciseDataPoint>> _getSessionDataPoints(
    String sessionId,
  ) async {
    try {
      User? user = _auth.currentUser;

      if (user != null) {
        QuerySnapshot querySnapshot =
            await _firestore
                .collection('users')
                .doc(user.uid)
                .collection('sessions')
                .doc(sessionId)
                .collection('data_points')
                .orderBy('timestamp')
                .get();

        return querySnapshot.docs
            .map(
              (doc) =>
                  ExerciseDataPoint.fromMap(doc.data() as Map<String, dynamic>),
            )
            .toList();
      }

      return [];
    } catch (e) {
      print('Error getting session data points: $e');
      return [];
    }
  }

  // Calculate session statistics
  Map<String, dynamic> calculateSessionStats(
    List<ExerciseDataPoint> dataPoints,
  ) {
    if (dataPoints.isEmpty) {
      return {
        'averageSpeed': 0.0,
        'maxSpeed': 0.0,
        'averageHeartRate': 0,
        'maxHeartRate': 0,
        'totalDistance': 0.0,
        'totalCaloriesBurned': 0,
        'duration': const Duration(seconds: 0),
      };
    }

    double totalSpeed = 0;
    double maxSpeed = 0;
    double totalIncline = 0;
    double maxIncline = 0;
    int totalHeartRate = 0;
    int maxHeartRate = 0;

    // Process each data point
    for (var point in dataPoints) {
      // Speed stats
      totalSpeed += point.speed;
      if (point.speed > maxSpeed) maxSpeed = point.speed;

      // Incline stats
      if (point.incline != null) {
        totalIncline += point.incline!;
        if (point.incline! > maxIncline) maxIncline = point.incline!;
      }

      // Heart rate stats
      totalHeartRate += point.heartRate.toInt();
      if (point.heartRate > maxHeartRate)
        maxHeartRate = point.heartRate.toInt();
    }

    // Calculate averages
    final count = dataPoints.length;
    final avgSpeed = totalSpeed / count;
    final avgIncline = totalIncline / count;
    final avgHeartRate = (totalHeartRate / count);

    // Calculate duration
    final startTime = dataPoints.first.timestamp;
    final endTime = dataPoints.last.timestamp;
    final duration = endTime.difference(startTime);

    return {
      'averageSpeed': avgSpeed,
      'maxSpeed': maxSpeed,
      'averageIncline': avgIncline,
      'maxIncline': maxIncline,
      'averageHeartRate': avgHeartRate,
      'maxHeartRate': maxHeartRate,
      'duration': duration,
    };
  }

  // Dispose resources
  void dispose() {
    _dataTimer?.cancel();
    _dataStreamController.close();
  }

  // Start collecting data
  void startDataCollection() {
    // Reset simulation parameters
    _isSimulating = true;
    _elapsedSeconds = 0;
    _currentSpeed = 3.0;
    _currentHeartRate = 80.0;
    _currentIncline = 0.0;
    _isATDetected = false;

    // Start timer to simulate data
    _dataTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isSimulating) {
        timer.cancel();
        return;
      }

      _simulateDataPoint();
    });
  }

  // Stop collecting data
  void stopDataCollection() {
    _isSimulating = false;
    _dataTimer?.cancel();
    _dataTimer = null;
  }

  // Check if device is connected
  Future<bool> isDeviceConnected() async {
    // Always return true for simulation
    return true;
  }

  // Simulate a data point
  void _simulateDataPoint() {
    _elapsedSeconds++;

    // Simulate heart rate
    // Initially increase, then show a deflection pattern around AT point
    if (_elapsedSeconds < _simulatedATPoint) {
      // Before AT - heart rate increases with effort
      _currentHeartRate = _simulateHeartRateBeforeAT();
    } else if (_elapsedSeconds == _simulatedATPoint) {
      // At AT - slight deflection occurs
      _currentHeartRate = _currentHeartRate - 2;
      _isATDetected = true;

      // Calculate target speed (lower than current for recovery)
      _targetSpeedAfterAT = max(_currentSpeed * 0.8, 2.5);
    } else {
      // After AT - heart rate stabilizes or increases more slowly
      _currentHeartRate = _simulateHeartRateAfterAT();
    }

    // Simulate speed - gradually increase until AT, then decrease
    if (!_isATDetected) {
      // Before AT - speed increases gradually
      _currentSpeed = _simulateSpeedBeforeAT();
    } else {
      // After AT - speed decreases gradually toward target
      _currentSpeed = _simulateSpeedAfterAT();
    }

    // Simulate incline - varies slightly
    _currentIncline = _simulateIncline();

    // Create data point
    final dataPoint = ExerciseDataPoint(
      timestamp: DateTime.now(),
      heartRate: _currentHeartRate,
      speed: _currentSpeed,
      incline: _currentIncline,
      vo2: _simulateVO2(),
      calories:
          _calorieRate *
          _currentHeartRate /
          100, // Calories proportional to heart rate
    );

    // Send to stream
    _dataStreamController.add(dataPoint);
  }

  // Heart rate simulation before AT
  double _simulateHeartRateBeforeAT() {
    // Increase heart rate more aggressively at first, then slow down as approaching AT
    double baseIncrease = 1.5;

    // Slow down the increase as we approach AT
    if (_elapsedSeconds > 40) {
      baseIncrease = 0.8;
    }

    // Add some random variation
    double randomVariation = Random().nextDouble() * 2 - 1; // -1 to 1

    // Cap heart rate to realistic values
    return min(185, _currentHeartRate + baseIncrease + randomVariation);
  }

  // Heart rate simulation after AT
  double _simulateHeartRateAfterAT() {
    // After AT, heart rate increases more slowly or stabilizes
    double baseChange = 0.3;

    // Add more prominent random variations after AT
    double randomVariation = Random().nextDouble() * 3 - 1.5; // -1.5 to 1.5

    // Cap heart rate to realistic values
    return min(190, max(140, _currentHeartRate + baseChange + randomVariation));
  }

  // Speed simulation before AT
  double _simulateSpeedBeforeAT() {
    // Gradually increase speed before AT
    double baseIncrease = 0.1;

    // Add some random variation
    double randomVariation = Random().nextDouble() * 0.2 - 0.1; // -0.1 to 0.1

    // Cap speed to realistic values
    return min(12.0, _currentSpeed + baseIncrease + randomVariation);
  }

  // Speed simulation after AT
  double _simulateSpeedAfterAT() {
    // After AT, gradually decrease speed toward target
    double speedDiff = _currentSpeed - _targetSpeedAfterAT;
    double adjustment =
        speedDiff > 0
            ? -0.2
            : 0.1; // Decrease if above target, increase if below

    // Add some random variation
    double randomVariation = Random().nextDouble() * 0.2 - 0.1; // -0.1 to 0.1

    // Ensure we don't go below minimum speed
    return max(2.0, _currentSpeed + adjustment + randomVariation);
  }

  // Incline simulation
  double _simulateIncline() {
    // Simulate small changes in incline
    double baseChange = 0;
    if (_elapsedSeconds % 30 < 15) {
      baseChange = 0.1; // Increase for 15 seconds
    } else {
      baseChange = -0.1; // Decrease for 15 seconds
    }

    // Add some random variation
    double randomVariation = Random().nextDouble() * 0.2 - 0.1; // -0.1 to 0.1

    // Ensure incline stays within realistic range
    return min(15.0, max(0.0, _currentIncline + baseChange + randomVariation));
  }

  // VO2 simulation based on heart rate and speed
  double _simulateVO2() {
    // Simple VO2 estimation based on heart rate and speed
    double baseVO2 = 10 + (_currentHeartRate - 60) * 0.2 + _currentSpeed * 1.5;

    // Add some random variation
    double randomVariation = Random().nextDouble() * 2 - 1; // -1 to 1

    return max(10.0, baseVO2 + randomVariation);
  }

  // Save an exercise session to Firestore
  Future<void> saveExerciseSession(ExerciseSession session) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Add to user's exercise history in Firestore
    await _firestore.collection('users').doc(userId).update({
      'sessions': FieldValue.arrayUnion([session.toMap()]),
    });
  }

  // Calculate calories burned based on exercise data
  int calculateCaloriesBurned({
    required double weight, // in kg
    required int durationMinutes,
    required double intensity, // value between 0.0 and 1.0
    required Gender gender,
    required int age,
  }) {
    // Basic formula for calorie burn:
    // For men: ((-55.0969 + (0.6309 x HR) + (0.1988 x W) + (0.2017 x A))/4.184) x T
    // For women: ((-20.4022 + (0.4472 x HR) + (0.1263 x W) + (0.074 x A))/4.184) x T
    // Where:
    // HR = Heart rate (beats/minute)
    // W = Weight (kg)
    // A = Age (years)
    // T = Exercise duration (minutes)

    // Simulate average heart rate based on intensity
    final avgHeartRate = 80 + (intensity * 100);

    double caloriesPerMinute;
    if (gender == Gender.male) {
      caloriesPerMinute =
          (-55.0969 +
              (0.6309 * avgHeartRate) +
              (0.1988 * weight) +
              (0.2017 * age)) /
          4.184;
    } else {
      caloriesPerMinute =
          (-20.4022 +
              (0.4472 * avgHeartRate) +
              (0.1263 * weight) +
              (0.074 * age)) /
          4.184;
    }

    return (caloriesPerMinute * durationMinutes).round();
  }

  // Get exercise statistics for a user
  Future<ExerciseStats> getUserExerciseStats() async {
    try {
      final exerciseHistory = await getUserExerciseHistory();

      if (exerciseHistory.isEmpty) {
        return ExerciseStats(
          totalSessions: 0,
          totalDurationMinutes: 0,
          totalCaloriesBurned: 0,
          totalDistance: 0,
          averageHeartRate: 0,
          maxHeartRate: 0,
          streakDays: 0,
        );
      }

      // Calculate total stats
      final totalDurationMinutes = exerciseHistory.fold<int>(
        0,
        (sum, session) => sum + session.duration.inMinutes,
      );
      final totalCaloriesBurned = exerciseHistory.fold<int>(
        0,
        (sum, session) => sum + session.caloriesBurned.round(),
      );
      final totalDistance = exerciseHistory.fold<double>(
        0,
        (sum, session) =>
            sum + session.avgSpeed * (session.duration.inHours.toDouble()),
      );

      // Heart rate statistics
      final totalHeartRateSessions =
          exerciseHistory.where((session) => session.avgHeartRate > 0).length;

      double averageHeartRate = 0;
      if (totalHeartRateSessions > 0) {
        averageHeartRate =
            exerciseHistory
                .where((session) => session.avgHeartRate > 0)
                .fold<double>(0, (sum, session) => sum + session.avgHeartRate) /
            totalHeartRateSessions;
      }

      final maxHeartRate = exerciseHistory.fold<int>(
        0,
        (max, session) =>
            session.maxHeartRate > max ? session.maxHeartRate : max,
      );

      return ExerciseStats(
        totalSessions: exerciseHistory.length,
        totalDurationMinutes: totalDurationMinutes,
        totalCaloriesBurned: totalCaloriesBurned,
        totalDistance: totalDistance,
        averageHeartRate: averageHeartRate.round(),
        maxHeartRate: maxHeartRate,
        streakDays: _calculateStreakDays(exerciseHistory),
      );
    } catch (e) {
      print('Error getting user exercise stats: $e');
      return ExerciseStats(
        totalSessions: 0,
        totalDurationMinutes: 0,
        totalCaloriesBurned: 0,
        totalDistance: 0,
        averageHeartRate: 0,
        maxHeartRate: 0,
        streakDays: 0,
      );
    }
  }

  // Calculate streak days
  int _calculateStreakDays(List<ExerciseSession> sessions) {
    if (sessions.isEmpty) return 0;

    // Sort sessions by date (newest first)
    sessions.sort((a, b) => b.date.compareTo(a.date));

    // Check if there's a session today
    final today = DateTime.now().day;
    final hasSessionToday = sessions.any((s) => s.date.day == today);

    if (!hasSessionToday) return 0;

    // Count consecutive days with sessions
    int streak = 1;
    DateTime currentDate = DateTime.now();

    // Start from yesterday
    currentDate = currentDate.subtract(const Duration(days: 1));

    while (true) {
      final day = currentDate.day;
      final month = currentDate.month;
      final year = currentDate.year;

      bool hasDaySession = sessions.any((session) {
        return session.date.day == day &&
            session.date.month == month &&
            session.date.year == year;
      });

      if (hasDaySession) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  // Save detailed exercise session with AT data
  Future<void> saveSessionWithATData(SessionDetailData sessionData) async {
    try {
      User? user = _auth.currentUser;

      if (user != null) {
        // Save the session data to Firestore
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('sessionDetails')
            .doc(sessionData.id)
            .set(sessionData.toMap());
      } else {
        throw Exception('User not authenticated');
      }
    } catch (e) {
      print('Error saving session with AT data: $e');
      throw Exception('Failed to save exercise session: $e');
    }
  }

  // Retrieve all detailed sessions with AT data
  Future<List<SessionDetailData>> getSessionsWithATData() async {
    try {
      User? user = _auth.currentUser;

      if (user != null) {
        QuerySnapshot querySnapshot =
            await _firestore
                .collection('users')
                .doc(user.uid)
                .collection('sessionDetails')
                .orderBy('date', descending: true)
                .get();

        return querySnapshot.docs
            .map(
              (doc) =>
                  SessionDetailData.fromMap(doc.data() as Map<String, dynamic>),
            )
            .toList();
      } else {
        throw Exception('User not authenticated');
      }
    } catch (e) {
      print('Error retrieving sessions with AT data: $e');
      return [];
    }
  }

  // Get a specific session by ID
  Future<SessionDetailData?> getSessionDetailById(String sessionId) async {
    try {
      User? user = _auth.currentUser;

      if (user != null) {
        DocumentSnapshot doc =
            await _firestore
                .collection('users')
                .doc(user.uid)
                .collection('sessionDetails')
                .doc(sessionId)
                .get();

        if (doc.exists) {
          return SessionDetailData.fromMap(doc.data() as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e) {
      print('Error retrieving session detail: $e');
      return null;
    }
  }
}

// Class representing exercise statistics for a user
class ExerciseStats {
  final int totalSessions;
  final int totalDurationMinutes;
  final int totalCaloriesBurned;
  final double totalDistance;
  final int averageHeartRate;
  final int maxHeartRate;
  final int streakDays;

  ExerciseStats({
    required this.totalSessions,
    required this.totalDurationMinutes,
    required this.totalCaloriesBurned,
    required this.totalDistance,
    required this.averageHeartRate,
    required this.maxHeartRate,
    required this.streakDays,
  });
}
