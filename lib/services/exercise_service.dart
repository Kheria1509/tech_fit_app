import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;

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
    // For now, we'll simulate data since we don't have a real Raspberry Pi
    _simulateDataPoints();
  }

  // Stop collecting data
  void stopDataCollection() {
    _dataTimer?.cancel();
    _dataTimer = null;
  }

  // Check if device is connected
  Future<bool> isDeviceConnected() async {
    // Simulate connection
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  // Simulate exercise data points for testing
  void _simulateDataPoints() {
    if (_dataTimer != null) return;

    final random = Random();
    double speed = 5.0 + random.nextDouble() * 2.0;
    double heartRate = 80.0 + random.nextDouble() * 10.0;
    int tick = 0;

    _dataTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      tick++;

      // Gradually increase values over time to simulate increased exercise intensity
      final exerciseTime = tick / 60.0; // Exercise time in minutes

      // Simulate natural variations
      speed += (random.nextDouble() - 0.5) * 0.3;
      if (speed < 4.0) speed = 4.0;
      if (speed > 12.0) speed = 12.0;

      // Heart rate increases with exercise time
      heartRate =
          80.0 + (exerciseTime * 5.0) + (random.nextDouble() - 0.5) * 5.0;
      if (heartRate < 80.0) heartRate = 80.0;
      if (heartRate > 180.0) heartRate = 180.0;

      // Calculate incline - occasionally changing
      double? incline;
      if (tick % 30 == 0) {
        // Change incline every 30 seconds
        incline = random.nextDouble() * 5.0;
      } else if (tick % 30 < 15) {
        incline = 2.0;
      } else {
        incline = 1.0;
      }

      // Calculate calories based on heart rate and speed
      // Rough estimate: calories per second = (0.1 * heart rate + 0.2 * speed)
      final calories = (0.1 * heartRate + 0.2 * speed) / 60.0;

      // Calculate VO2 based on heart rate (simple estimation)
      final vo2 = (heartRate - 60) * 0.2;

      // Calculate distance based on speed
      final distance = speed * (tick / 3600); // km based on km/h and seconds

      // Create data point
      final dataPoint = ExerciseDataPoint(
        timestamp: DateTime.now(),
        heartRate: heartRate,
        speed: speed,
        calories: calories,
        incline: incline,
        vo2: vo2,
      );

      // Add to stream
      _dataStreamController.add(dataPoint);
    });
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
