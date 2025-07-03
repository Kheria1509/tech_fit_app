import 'package:flutter/material.dart';
import '../models/dashboard_models.dart';
import '../models/user_model.dart';

class MockDataService {
  // Generate mock exercise sessions for the past 30 days
  static List<ExerciseSession> generateMockSessions() {
    final List<ExerciseSession> sessions = [];
    final now = DateTime.now();

    // Create sessions for the last 30 days
    for (int i = 0; i < 30; i++) {
      // Skip some days to make it realistic (70% chance of workout)
      if (i > 0 && DateTime.now().millisecond % 10 > 3) {
        continue;
      }

      final date = now.subtract(Duration(days: i));
      final session = ExerciseSession(
        id: 'session_${date.millisecondsSinceEpoch}',
        date: date,
        duration: Duration(minutes: 30 + (date.day % 30)), // 30-60 minutes
        caloriesBurned: 300 + (date.day % 200).toDouble(), // 300-500 calories
        avgSpeed: 8.0 + (date.hour % 4), // 8-12 km/h
        maxSpeed: 12.0 + (date.minute % 4), // 12-16 km/h
        avgIncline: 1.0 + (date.second % 3), // 1-4 degrees
        maxIncline: 4.0 + (date.millisecond % 4), // 4-8 degrees
        avgHeartRate: 140 + (date.minute % 20), // 140-160 bpm
        maxHeartRate: 170 + (date.second % 15), // 170-185 bpm
        vo2Max: 45.0 + (date.day % 10), // 45-55 ml/kg/min
        anaerobicThresholdHeartRate: 160 + (date.minute % 10), // 160-170 bpm
        anaerobicThresholdVo2: 40.0 + (date.second % 5), // 40-45 ml/kg/min
        timeToReachAT: Duration(minutes: 10 + (date.minute % 10)), // 10-20 min
        timeInAT: Duration(minutes: 5 + (date.second % 10)), // 5-15 min
        zoneDistribution: _generateZoneDistribution(date),
        dataPoints: _generateDataPoints(date),
      );

      sessions.add(session);
    }

    return sessions;
  }

  // Generate mock zone distribution
  static Map<WorkoutZone, Duration> _generateZoneDistribution(DateTime seed) {
    return {
      WorkoutZone.rest: Duration(minutes: 2 + (seed.minute % 3)),
      WorkoutZone.warmup: Duration(minutes: 5 + (seed.second % 5)),
      WorkoutZone.fatBurn: Duration(minutes: 10 + (seed.millisecond % 10)),
      WorkoutZone.aerobic: Duration(minutes: 15 + (seed.second % 10)),
      WorkoutZone.anaerobic: Duration(minutes: 5 + (seed.minute % 5)),
      WorkoutZone.maximum: Duration(minutes: 1 + (seed.second % 2)),
    };
  }

  // Generate mock data points for heart rate and speed over time
  static List<ExerciseDataPoint> _generateDataPoints(DateTime sessionDate) {
    final List<ExerciseDataPoint> points = [];
    final startTime = sessionDate;

    for (int minute = 0; minute < 45; minute++) {
      final timeStamp = startTime.add(Duration(minutes: minute));
      final progress = minute / 45; // 0 to 1

      // Create a bell curve for heart rate
      final baseHeartRate = 70.0;
      final maxIncrease = 100.0;
      final heartRate =
          baseHeartRate +
          maxIncrease * (1 - (2 * progress - 1) * (2 * progress - 1));

      // Create a realistic speed progression
      final baseSpeed = 6.0;
      final maxSpeedIncrease = 6.0;
      final speed =
          baseSpeed +
          maxSpeedIncrease * (1 - (2 * progress - 1) * (2 * progress - 1));

      points.add(
        ExerciseDataPoint(
          timestamp: timeStamp,
          heartRate: heartRate,
          speed: speed,
          incline: 2.0 + (timeStamp.minute % 3),
          vo2: 35.0 + (heartRate - baseHeartRate) / 10,
          calories: (speed * 1.2) + (heartRate / 400),
        ),
      );
    }

    return points;
  }

  // Generate mock achievements
  static List<Achievement> generateMockAchievements() {
    return [
      Achievement(
        title: '7-Day Streak',
        description: 'Complete workouts for 7 consecutive days',
        dateAchieved: DateTime.now().subtract(const Duration(days: 7)),
        icon: '🔥',
        progress: 1.0,
        isAchieved: true,
      ),
      Achievement(
        title: '100km Distance',
        description: 'Run a total of 100 kilometers',
        dateAchieved: DateTime.now().subtract(const Duration(days: 14)),
        icon: '🏃',
        progress: 1.0,
        isAchieved: true,
      ),
      Achievement(
        title: '30-Day Streak',
        description: 'Complete workouts for 30 consecutive days',
        dateAchieved: null,
        icon: '⭐',
        progress: 0.6,
        isAchieved: false,
      ),
      Achievement(
        title: 'Speed Demon',
        description: 'Maintain 12 km/h for 5 minutes',
        dateAchieved: null,
        icon: '⚡',
        progress: 0.8,
        isAchieved: false,
      ),
    ];
  }

  // Generate mock insights
  static List<HealthInsight> generateMockInsights() {
    return [
      HealthInsight(
        title: 'Improving Endurance',
        description:
            'Your average workout duration has increased by 15% this week',
        currentValue: 45,
        previousValue: 39,
        targetValue: 60,
        unit: 'minutes',
        isPositiveTrend: true,
      ),
      HealthInsight(
        title: 'Heart Rate Zones',
        description: 'You\'re spending more time in the aerobic zone',
        currentValue: 25,
        previousValue: 15,
        targetValue: 30,
        unit: 'minutes',
        isPositiveTrend: true,
      ),
      HealthInsight(
        title: 'Recovery Needed',
        description:
            'Your recent workouts show high intensity. Consider a rest day.',
        currentValue: 75,
        previousValue: 65,
        targetValue: 70,
        unit: '%',
        isPositiveTrend: false,
      ),
    ];
  }

  // Generate mock workout suggestions
  static List<WorkoutSuggestion> generateMockSuggestions() {
    return [
      WorkoutSuggestion(
        title: 'Endurance Run',
        description: 'Focus on maintaining a steady pace in the aerobic zone',
        recommendedDuration: 45,
        targetZone: WorkoutZone.aerobic,
        targetHeartRate: 150,
        reason: 'Builds aerobic base',
      ),
      WorkoutSuggestion(
        title: 'Recovery Session',
        description: 'Light intensity workout to promote recovery',
        recommendedDuration: 30,
        targetZone: WorkoutZone.fatBurn,
        targetHeartRate: 120,
        reason: 'Active recovery day',
      ),
      WorkoutSuggestion(
        title: 'Speed Work',
        description: 'Intervals to improve your anaerobic threshold',
        recommendedDuration: 40,
        targetZone: WorkoutZone.anaerobic,
        targetHeartRate: 170,
        reason: 'Improve speed and power',
      ),
    ];
  }

  // Generate mock user data
  static UserModel generateMockUser() {
    return UserModel(
      uid: 'mock_user_123',
      name: 'John Doe',
      email: 'john.doe@example.com',
      birthDate: DateTime(1990, 5, 15),
      gender: Gender.male,
      height: 175.0,
      weight: 70.0,
      targetWeight: 68.0,
      maxHeartRate: 185,
      vo2Max: 48.5,
      anaerobicThreshold: 165,
      sessions: generateMockSessions(),
    );
  }
}
