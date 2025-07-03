import 'package:flutter/foundation.dart';
import '../models/dashboard_models.dart';
import '../services/exercise_service.dart';
import '../models/user_model.dart';
import '../services/mock_data_service.dart';
import 'package:intl/intl.dart';

class DashboardProvider extends ChangeNotifier {
  final ExerciseService _exerciseService = ExerciseService();

  WorkoutStreak? _streak;
  List<Achievement> _achievements = [];
  WorkoutMetrics? _currentMetrics;
  List<HealthInsight> _insights = [];
  List<WorkoutSuggestion> _suggestions = [];
  ATAnalytics? _atAnalytics;
  List<ScheduledWorkout> _scheduledWorkouts = [];
  bool _isDeviceConnected = false;
  String? _lastConnectedDevice;

  // Add new fields for enhanced dashboard
  Map<DateTime, Map<WorkoutZone, Duration>> _weeklyZoneDistribution = {};
  Map<DateTime, double> _weeklyEfficiencyScores = {};
  List<Map<String, dynamic>> _progressTrends = [];

  // Getters
  WorkoutStreak? get streak => _streak;
  List<Achievement> get achievements => _achievements;
  WorkoutMetrics? get currentMetrics => _currentMetrics;
  List<HealthInsight> get insights => _insights;
  List<WorkoutSuggestion> get suggestions => _suggestions;
  ATAnalytics? get atAnalytics => _atAnalytics;
  List<ScheduledWorkout> get scheduledWorkouts => _scheduledWorkouts;
  bool get isDeviceConnected => _isDeviceConnected;
  String? get lastConnectedDevice => _lastConnectedDevice;
  Map<DateTime, Map<WorkoutZone, Duration>> get weeklyZoneDistribution =>
      _weeklyZoneDistribution;
  Map<DateTime, double> get weeklyEfficiencyScores => _weeklyEfficiencyScores;
  List<Map<String, dynamic>> get progressTrends => _progressTrends;

  // Initialize dashboard data
  Future<void> initializeDashboard() async {
    // For demo purposes, we'll use mock data
    final mockSessions = MockDataService.generateMockSessions();

    // Calculate streak
    await _calculateStreak(mockSessions);

    // Load achievements
    _achievements = MockDataService.generateMockAchievements();

    // Load insights
    _insights = MockDataService.generateMockInsights();

    // Load suggestions
    _suggestions = MockDataService.generateMockSuggestions();

    // Calculate weekly distributions
    _calculateWeeklyDistributions(mockSessions);

    // Calculate efficiency scores
    _calculateEfficiencyScores(mockSessions);

    // Generate progress trends
    _generateProgressTrends(mockSessions);

    notifyListeners();
  }

  // Calculate workout streak with enhanced tracking
  Future<void> _calculateStreak(List<ExerciseSession> sessions) async {
    try {
      if (sessions.isEmpty) {
        _streak = WorkoutStreak(
          currentStreak: 0,
          longestStreak: 0,
          workoutDates: [],
          calendarData: {},
        );
        return;
      }

      // Create calendar data for last 30 days
      final Map<DateTime, bool> calendarData = {};
      final now = DateTime.now();
      for (int i = 0; i < 30; i++) {
        final date = now.subtract(Duration(days: i));
        final dateKey = DateTime(date.year, date.month, date.day);
        final hasWorkout = sessions.any(
          (session) => _isSameDay(session.date, dateKey),
        );
        calendarData[dateKey] = hasWorkout;
      }

      // Calculate current streak
      int currentStreak = 0;
      final today = DateTime(now.year, now.month, now.day);
      final hasWorkoutToday = calendarData[today] ?? false;

      if (!hasWorkoutToday) {
        _streak = WorkoutStreak(
          currentStreak: 0,
          longestStreak: 0,
          workoutDates: [],
          calendarData: {},
        );
        return;
      }

      // Count consecutive days with sessions
      DateTime currentDate = now.subtract(const Duration(days: 1));
      DateTime dateKey = DateTime(
        currentDate.year,
        currentDate.month,
        currentDate.day,
      );

      while (calendarData[dateKey] ?? false) {
        currentStreak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
        dateKey = DateTime(
          currentDate.year,
          currentDate.month,
          currentDate.day,
        );
      }

      // Calculate zone distribution and AT metrics
      Map<WorkoutZone, Duration> zoneDistribution = {};
      int atReachedCount = 0;
      double totalTimeToAT = 0;
      double totalATDuration = 0;

      for (var session in sessions) {
        if (session.anaerobicThresholdHeartRate != null) {
          atReachedCount++;
          totalTimeToAT += session.timeToReachAT?.inSeconds ?? 0;
          totalATDuration += session.timeInAT?.inSeconds ?? 0;
        }

        if (session.zoneDistribution != null) {
          for (var entry in session.zoneDistribution!.entries) {
            zoneDistribution[entry.key] =
                (zoneDistribution[entry.key] ?? Duration.zero) + entry.value;
          }
        }
      }

      _streak = WorkoutStreak(
        currentStreak: currentStreak,
        longestStreak: currentStreak,
        workoutDates: sessions.map((s) => s.date).toList(),
        calendarData: calendarData,
        zoneDistribution: zoneDistribution,
        averageTimeToAT:
            atReachedCount > 0 ? totalTimeToAT / atReachedCount : 0,
        atReachedCount: atReachedCount,
        averageATDuration:
            atReachedCount > 0 ? totalATDuration / atReachedCount : 0,
      );
    } catch (error) {
      debugPrint('Error calculating streak: $error');
      _streak = WorkoutStreak(
        currentStreak: 0,
        longestStreak: 0,
        workoutDates: [],
        calendarData: {},
      );
    }
  }

  // Helper method to check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // Calculate weekly zone distributions
  void _calculateWeeklyDistributions(List<ExerciseSession> sessions) {
    _weeklyZoneDistribution.clear();
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    for (var session in sessions) {
      if (session.date.isBefore(startOfWeek)) continue;

      final weekDay = DateTime(
        session.date.year,
        session.date.month,
        session.date.day,
      );
      if (session.zoneDistribution != null) {
        _weeklyZoneDistribution[weekDay] = session.zoneDistribution!;
      }
    }
  }

  // Calculate efficiency scores
  void _calculateEfficiencyScores(List<ExerciseSession> sessions) {
    _weeklyEfficiencyScores.clear();
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    for (var session in sessions) {
      if (session.date.isBefore(startOfWeek)) continue;

      final weekDay = DateTime(
        session.date.year,
        session.date.month,
        session.date.day,
      );
      final efficiencyScore =
          session.caloriesBurned /
          session.duration.inMinutes *
          (session.avgHeartRate / 150);

      _weeklyEfficiencyScores[weekDay] = efficiencyScore;
    }
  }

  // Generate progress trends
  void _generateProgressTrends(List<ExerciseSession> sessions) {
    if (sessions.isEmpty) return;

    sessions.sort((a, b) => b.date.compareTo(a.date));

    Map<int, List<ExerciseSession>> weeklyGroups = {};
    for (var session in sessions) {
      final weekNumber = _getWeekNumber(session.date);
      weeklyGroups.putIfAbsent(weekNumber, () => []).add(session);
    }

    _progressTrends =
        weeklyGroups.entries.map((entry) {
          final sessions = entry.value;
          return {
            'weekNumber': entry.key,
            'avgSpeed':
                sessions.fold<double>(0, (sum, s) => sum + s.avgSpeed) /
                sessions.length,
            'avgHeartRate':
                sessions.fold<int>(0, (sum, s) => sum + s.avgHeartRate) ~/
                sessions.length,
            'totalDistance': sessions.fold<double>(
              0,
              (sum, s) => sum + (s.avgSpeed * s.duration.inHours),
            ),
            'totalCalories': sessions.fold<double>(
              0,
              (sum, s) => sum + s.caloriesBurned,
            ),
            'atReachedCount':
                sessions
                    .where((s) => s.anaerobicThresholdHeartRate != null)
                    .length,
          };
        }).toList();
  }

  // Helper method to get week number
  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysFromStart = date.difference(firstDayOfYear).inDays;
    return (daysFromStart / 7).ceil();
  }

  // Update device connection status
  void updateDeviceConnection(bool isConnected, String? deviceName) {
    _isDeviceConnected = isConnected;
    _lastConnectedDevice = deviceName;
    notifyListeners();
  }

  // Update current metrics (called during active workout)
  void updateCurrentMetrics(WorkoutMetrics metrics) {
    _currentMetrics = metrics;
    notifyListeners();
  }
}

extension DateOnlyCompare on DateTime {
  DateTime get date => DateTime(year, month, day);
}
