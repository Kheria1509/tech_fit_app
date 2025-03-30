import 'dart:async';
import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';

import '../utils/app_constants.dart';
import '../widgets/app_button.dart';
import '../services/exercise_service.dart';
import '../providers/user_provider.dart';
import '../models/user_model.dart';

class DeviceTrackingScreen extends StatefulWidget {
  const DeviceTrackingScreen({Key? key}) : super(key: key);

  @override
  State<DeviceTrackingScreen> createState() => _DeviceTrackingScreenState();
}

class _DeviceTrackingScreenState extends State<DeviceTrackingScreen> {
  final ExerciseService _exerciseService = ExerciseService();
  Timer? _dataTimer;
  Timer? _durationTimer;

  bool _isSessionActive = false;
  int _elapsedSeconds = 0;
  double _currentSpeed = 0.0;
  double _currentHeartRate = 0.0;
  double _currentCaloriesBurned = 0.0;
  double _currentDistance = 0.0;

  List<double> _speedHistory = [];
  List<double> _heartRateHistory = [];

  StreamSubscription? _dataSubscription;

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  @override
  void dispose() {
    _dataTimer?.cancel();
    _durationTimer?.cancel();
    _dataSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkConnection() async {
    try {
      final isConnected = await _exerciseService.isDeviceConnected();
      if (!isConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Device not connected. Please connect first.'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking connection: ${e.toString()}')),
      );
      Navigator.pop(context);
    }
  }

  void _startSession() {
    setState(() {
      _isSessionActive = true;
      _elapsedSeconds = 0;
      _currentSpeed = 0.0;
      _currentHeartRate = 0.0;
      _currentCaloriesBurned = 0.0;
      _currentDistance = 0.0;
      _speedHistory = [];
      _heartRateHistory = [];
    });

    // Start timer to track session duration
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });
    });

    // Subscribe to real-time data stream from device
    _dataSubscription = _exerciseService.dataStream.listen((data) {
      setState(() {
        _currentSpeed = data.speed;
        _currentHeartRate = data.heartRate;

        // Get calories from data point
        double pointCalories = data.calories;
        _currentCaloriesBurned += pointCalories;

        // Calculate distance increment based on speed and time interval (1 second)
        // Distance = speed (km/h) * time (h) => speed * (1/3600) for 1 second
        _currentDistance += _currentSpeed * (1 / 3600);

        // Add data points to history for graphs
        _speedHistory.add(_currentSpeed);
        _heartRateHistory.add(_currentHeartRate);

        // Keep only the last 60 data points (for a 1-minute view)
        if (_speedHistory.length > 60) {
          _speedHistory.removeAt(0);
        }
        if (_heartRateHistory.length > 60) {
          _heartRateHistory.removeAt(0);
        }
      });
    });

    // Start the data collection from the device
    _exerciseService.startDataCollection();
  }

  Future<void> _endSession() async {
    // Stop timers and data stream
    _durationTimer?.cancel();
    _dataSubscription?.cancel();
    _exerciseService.stopDataCollection();

    // Prepare session data
    final sessionData = ExerciseSessionData(
      caloriesBurned: _currentCaloriesBurned.toInt(),
      distance: _currentDistance,
      durationMinutes: _elapsedSeconds ~/ 60,
      durationSeconds: _elapsedSeconds % 60,
      averageHeartRate:
          _heartRateHistory.isEmpty
              ? 0
              : _heartRateHistory.reduce((a, b) => a + b) /
                  _heartRateHistory.length,
      maxHeartRate:
          _heartRateHistory.isEmpty
              ? 0
              : _heartRateHistory.reduce((a, b) => a > b ? a : b),
      averageSpeed:
          _speedHistory.isEmpty
              ? 0
              : _speedHistory.reduce((a, b) => a + b) / _speedHistory.length,
      maxSpeed:
          _speedHistory.isEmpty
              ? 0
              : _speedHistory.reduce((a, b) => a > b ? a : b),
    );

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Saving your workout data...'),
              ],
            ),
          ),
    );

    try {
      // Save session to user's history
      await Provider.of<UserProvider>(
        context,
        listen: false,
      ).addExerciseSession(sessionData);

      // Close loading dialog
      Navigator.pop(context);

      // Show completion dialog
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Workout Complete!'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Duration: ${_formatDuration(sessionData.durationMinutes, sessionData.durationSeconds)}',
                  ),
                  const SizedBox(height: 8),
                  Text('Calories Burned: ${sessionData.caloriesBurned}'),
                  const SizedBox(height: 8),
                  Text(
                    'Distance: ${sessionData.distance.toStringAsFixed(2)} km',
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Return to previous screen
                  },
                  child: const Text('Close'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pushReplacementNamed(context, '/stats');
                  },
                  child: const Text('View Stats'),
                ),
              ],
            ),
      );
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving workout: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isSessionActive = false;
      });
    }
  }

  String _formatDuration(int minutes, int seconds) {
    final formattedMinutes = minutes.toString().padLeft(2, '0');
    final formattedSeconds = seconds.toString().padLeft(2, '0');
    return '$formattedMinutes:$formattedSeconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Device Tracking',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () {
            // Confirm before exiting if session is active
            if (_isSessionActive) {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('End Session?'),
                      content: const Text(
                        'Your current exercise session will be lost. Are you sure you want to exit?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context); // Close dialog
                            _exerciseService.stopDataCollection();
                            Navigator.pop(context); // Exit screen
                          },
                          child: const Text('Exit'),
                        ),
                      ],
                    ),
              );
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color:
                      _isSessionActive
                          ? AppColors.secondary.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadius,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 12,
                      color:
                          _isSessionActive ? AppColors.secondary : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isSessionActive
                          ? 'Session in progress'
                          : 'Ready to start',
                      style: TextStyle(
                        color:
                            _isSessionActive
                                ? AppColors.secondary
                                : Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Timer display
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Text(
                    _formatDuration(
                      _elapsedSeconds ~/ 60,
                      _elapsedSeconds % 60,
                    ),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Stats grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.3,
                  children: [
                    _buildStatCard(
                      title: 'Heart Rate',
                      value: _currentHeartRate.toStringAsFixed(0),
                      unit: 'bpm',
                      icon: Icons.favorite,
                      color: Colors.red,
                    ),
                    _buildStatCard(
                      title: 'Speed',
                      value: _currentSpeed.toStringAsFixed(1),
                      unit: 'km/h',
                      icon: Icons.speed,
                      color: AppColors.primary,
                    ),
                    _buildStatCard(
                      title: 'Calories',
                      value: _currentCaloriesBurned.toStringAsFixed(0),
                      unit: 'kcal',
                      icon: Icons.local_fire_department,
                      color: AppColors.secondary,
                    ),
                    _buildStatCard(
                      title: 'Distance',
                      value: _currentDistance.toStringAsFixed(2),
                      unit: 'km',
                      icon: Icons.straighten,
                      color: AppColors.accent,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Heart rate trend
              if (_heartRateHistory.isNotEmpty && _isSessionActive) ...[
                const Text(
                  'Heart Rate Trend',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),

                const SizedBox(height: 8),

                SizedBox(
                  height: 80,
                  child: Row(
                    children: List.generate(
                      _heartRateHistory.length,
                      (i) => Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          height:
                              _heartRateHistory[i] /
                              2, // Scale for visualization
                          decoration: BoxDecoration(
                            color: _getHeartRateColor(_heartRateHistory[i]),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],

              // Action button
              _isSessionActive
                  ? AppButton(
                    text: 'End Session',
                    onPressed: _endSession,
                    backgroundColor: Colors.red,
                  )
                  : AppButton(text: 'Start Session', onPressed: _startSession),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(fontSize: 14, color: color.withOpacity(0.7)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getHeartRateColor(double heartRate) {
    if (heartRate < 100) {
      return Colors.green;
    } else if (heartRate < 140) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}

class ExerciseSessionData {
  final int caloriesBurned;
  final double distance;
  final int durationMinutes;
  final int durationSeconds;
  final double averageHeartRate;
  final double maxHeartRate;
  final double averageSpeed;
  final double maxSpeed;

  ExerciseSessionData({
    required this.caloriesBurned,
    required this.distance,
    required this.durationMinutes,
    required this.durationSeconds,
    required this.averageHeartRate,
    required this.maxHeartRate,
    required this.averageSpeed,
    required this.maxSpeed,
  });
}
