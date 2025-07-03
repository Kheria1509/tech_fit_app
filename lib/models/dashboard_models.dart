import 'package:flutter/material.dart';

enum WorkoutZone { rest, warmup, fatBurn, aerobic, anaerobic, maximum }

class WorkoutStreak {
  final int currentStreak;
  final int longestStreak;
  final List<DateTime> workoutDates;
  final Map<DateTime, bool> calendarData;
  final DateTime? lastWorkoutDate;
  final Map<WorkoutZone, Duration> zoneDistribution;
  final double averageTimeToAT; // Average time to reach Anaerobic Threshold
  final int atReachedCount; // Number of times AT was reached
  final double averageATDuration; // Average duration spent in AT zone

  WorkoutStreak({
    required this.currentStreak,
    required this.longestStreak,
    required this.workoutDates,
    required this.calendarData,
    this.lastWorkoutDate,
    this.zoneDistribution = const {},
    this.averageTimeToAT = 0.0,
    this.atReachedCount = 0,
    this.averageATDuration = 0.0,
  });

  // Helper method to get percentage of time spent in each zone
  Map<WorkoutZone, double> getZonePercentages() {
    final totalDuration = zoneDistribution.values.fold<Duration>(
      Duration.zero,
      (prev, curr) => prev + curr,
    );

    if (totalDuration == Duration.zero) return {};

    return Map.fromEntries(
      zoneDistribution.entries.map(
        (entry) => MapEntry(
          entry.key,
          entry.value.inSeconds / totalDuration.inSeconds * 100,
        ),
      ),
    );
  }

  // Helper method to check if there's a workout on a specific date
  bool hasWorkoutOn(DateTime date) {
    return calendarData[DateTime(date.year, date.month, date.day)] ?? false;
  }
}

class Achievement {
  final String title;
  final String description;
  final DateTime? dateAchieved;
  final String icon;
  final double progress; // 0 to 1
  final bool isAchieved;

  Achievement({
    required this.title,
    required this.description,
    required this.dateAchieved,
    required this.icon,
    required this.progress,
    required this.isAchieved,
  });
}

class WorkoutMetrics {
  final int stepCount;
  final int activeMinutes;
  final double caloriesBurned;
  final int heartRate;
  final double distance;
  final WorkoutZone currentZone;

  WorkoutMetrics({
    required this.stepCount,
    required this.activeMinutes,
    required this.caloriesBurned,
    required this.heartRate,
    required this.distance,
    required this.currentZone,
  });
}

class HealthInsight {
  final String title;
  final String description;
  final double currentValue;
  final double previousValue;
  final double targetValue;
  final String unit;
  final bool isPositiveTrend;

  HealthInsight({
    required this.title,
    required this.description,
    required this.currentValue,
    required this.previousValue,
    required this.targetValue,
    required this.unit,
    required this.isPositiveTrend,
  });
}

class WorkoutSuggestion {
  final String title;
  final String description;
  final int recommendedDuration;
  final WorkoutZone targetZone;
  final double targetHeartRate;
  final String reason;

  WorkoutSuggestion({
    required this.title,
    required this.description,
    required this.recommendedDuration,
    required this.targetZone,
    required this.targetHeartRate,
    required this.reason,
  });
}

class ATAnalytics {
  final double atHeartRate;
  final Duration timeToReachAT;
  final Duration timeInAT;
  final double speedAtAT;
  final double recoveryRate;
  final Map<WorkoutZone, Duration> zoneDistribution;

  ATAnalytics({
    required this.atHeartRate,
    required this.timeToReachAT,
    required this.timeInAT,
    required this.speedAtAT,
    required this.recoveryRate,
    required this.zoneDistribution,
  });
}

class ScheduledWorkout {
  final DateTime scheduledTime;
  final String workoutType;
  final int estimatedDuration;
  final bool hasReminder;
  final WorkoutZone targetZone;

  ScheduledWorkout({
    required this.scheduledTime,
    required this.workoutType,
    required this.estimatedDuration,
    required this.hasReminder,
    required this.targetZone,
  });
}
