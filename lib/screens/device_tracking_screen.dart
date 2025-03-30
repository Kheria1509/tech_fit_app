import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';

import '../utils/app_constants.dart';
import '../widgets/app_button.dart';
import '../services/exercise_service.dart';
import '../providers/user_provider.dart';
import '../models/user_model.dart';

// Data class for heart rate chart
class HeartRateData {
  final int timeInSeconds;
  final double heartRate;
  final bool isATPoint;

  HeartRateData(this.timeInSeconds, this.heartRate, {this.isATPoint = false});
}

class DeviceTrackingScreen extends StatefulWidget {
  const DeviceTrackingScreen({Key? key}) : super(key: key);

  @override
  State<DeviceTrackingScreen> createState() => _DeviceTrackingScreenState();
}

class _DeviceTrackingScreenState extends State<DeviceTrackingScreen>
    with TickerProviderStateMixin {
  final ExerciseService _exerciseService = ExerciseService();
  Timer? _dataTimer;
  Timer? _durationTimer;

  bool _isSessionActive = false;
  int _elapsedSeconds = 0;
  double _currentSpeed = 0.0;
  double _currentHeartRate = 0.0;
  double _currentCaloriesBurned = 0.0;
  double _currentDistance = 0.0;

  // New variables for anaerobic threshold detection
  bool _anaerobicThresholdReached = false;
  int? _atReachedTimeSeconds;
  double? _atTargetSpeed;
  bool _isShowingATMessage = false;

  // Animation controllers
  late AnimationController _atNotificationController;

  // Chart data
  List<double> _speedHistory = [];
  List<double> _heartRateHistory = [];
  List<HeartRateData> _heartRateChartData = [];

  // Heart rate zones
  final double _restingHeartRate = 60;
  final double _maxHeartRate = 190;

  // Chart controller for live updates
  late ChartSeriesController _chartSeriesController;

  StreamSubscription? _dataSubscription;

  // AT detection data
  double _atSpeed = 0.0;
  double _atHeartRate = 0.0;

  @override
  void initState() {
    super.initState();
    _checkConnection();

    // Initialize animation controllers
    _atNotificationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _dataTimer?.cancel();
    _durationTimer?.cancel();
    _dataSubscription?.cancel();
    _atNotificationController.dispose();
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
      _heartRateChartData = [];
      _anaerobicThresholdReached = false;
      _atReachedTimeSeconds = null;
      _atTargetSpeed = null;
      _isShowingATMessage = false;
      _atSpeed = 0.0;
      _atHeartRate = 0.0;
    });

    // Start timer to track session duration
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });
    });

    // Subscribe to real-time data stream from device
    _dataSubscription = _exerciseService.dataStream.listen(_updateDataPoint);

    // Start the data collection from the device
    _exerciseService.startDataCollection();
  }

  void _detectAnaerobicThreshold() {
    // Only check if we haven't detected AT yet
    if (!_anaerobicThresholdReached && _heartRateHistory.length >= 10) {
      // Simple algorithm to detect deflection in heart rate curve
      // In a real app, this would be more sophisticated

      // Get the last several heart rate values
      List<double> recentHeartRates = _heartRateHistory.sublist(
        _heartRateHistory.length - 10,
        _heartRateHistory.length,
      );

      // Check for a deflection pattern
      // For simulation, we'll use a simple condition:
      // If heart rate is consistently above 150 and has a specific pattern of change
      bool isAboveThreshold = recentHeartRates.last > 150;
      bool hasDeflectionPattern = false;

      // Look for a pattern where HR increases, then stabilizes despite increasing effort
      if (isAboveThreshold && _elapsedSeconds > 30) {
        // Calculate rate of change
        double sumDiffs = 0;
        for (int i = 1; i < recentHeartRates.length; i++) {
          sumDiffs += (recentHeartRates[i] - recentHeartRates[i - 1]);
        }
        double avgChange = sumDiffs / (recentHeartRates.length - 1);

        // If heart rate change is slowing despite ongoing exercise, it might indicate AT
        hasDeflectionPattern = avgChange < 0.5 && avgChange > 0;
      }

      // For demo purposes, we'll also trigger AT around a specific time
      bool timeBasedTrigger =
          _elapsedSeconds > 60 && _heartRateHistory.last > 140;

      if ((isAboveThreshold && hasDeflectionPattern) || timeBasedTrigger) {
        _triggerAnaerobicThreshold();
      }
    }
  }

  void _triggerAnaerobicThreshold() {
    setState(() {
      _anaerobicThresholdReached = true;
      _atReachedTimeSeconds = _elapsedSeconds;

      // Calculate target speed based on current metrics
      // In a real app, this would use more sophisticated algorithms
      _atTargetSpeed = max(
        _currentSpeed - 1.0,
        3.0,
      ); // Target is slightly lower than current speed

      // Show notification
      _isShowingATMessage = true;
      _atNotificationController.forward(from: 0.0);

      // Auto-dismiss notification after 8 seconds
      Future.delayed(const Duration(seconds: 8), () {
        if (mounted) {
          setState(() {
            _isShowingATMessage = false;
          });
        }
      });
    });
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

    // Prepare detailed session data with AT information
    final detailedSessionData = SessionDetailData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      durationMinutes: _elapsedSeconds ~/ 60,
      totalDistance: _currentDistance,
      totalCalories: _currentCaloriesBurned.toInt(),
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
      atReached: _anaerobicThresholdReached,
      atReachedTimeSeconds: _atReachedTimeSeconds,
      atHeartRate: _anaerobicThresholdReached ? _atHeartRate : null,
      atSpeed: _anaerobicThresholdReached ? _atSpeed : null,
      atTargetSpeed: _anaerobicThresholdReached ? _atTargetSpeed : null,
      heartRateData:
          _heartRateChartData
              .map(
                (data) => HeartRatePoint(
                  timeInSeconds: data.timeInSeconds,
                  heartRate: data.heartRate,
                ),
              )
              .toList(),
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

      // Save detailed session with AT data
      await _exerciseService.saveSessionWithATData(detailedSessionData);

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
                  if (_anaerobicThresholdReached &&
                      _atReachedTimeSeconds != null) ...[
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'Anaerobic Threshold Reached!',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Time: ${_formatDuration(_atReachedTimeSeconds! ~/ 60, _atReachedTimeSeconds! % 60)}',
                    ),
                  ],
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
                    Navigator.pushReplacementNamed(
                      context,
                      '/previous_sessions',
                    );
                  },
                  child: const Text('View Sessions'),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Anaerobic threshold notification
            if (_isShowingATMessage && _atReachedTimeSeconds != null)
              AnimatedBuilder(
                animation: _atNotificationController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      0,
                      -50 * (1 - _atNotificationController.value),
                    ),
                    child: Opacity(
                      opacity: _atNotificationController.value,
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.all(12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
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
                                const Icon(
                                  Icons.notifications_active,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Anaerobic Threshold Reached!',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'A.T is reached at ${_formatDuration(_atReachedTimeSeconds! ~/ 60, _atReachedTimeSeconds! % 60)}',
                              style: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Now Target Speed is ${_atTargetSpeed?.toStringAsFixed(1)} km/h',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

            Expanded(
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
                                _isSessionActive
                                    ? AppColors.secondary
                                    : Colors.grey,
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
                          const Spacer(),
                          // Timer display
                          Text(
                            _formatDuration(
                              _elapsedSeconds ~/ 60,
                              _elapsedSeconds % 60,
                            ),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color:
                                  _isSessionActive
                                      ? AppColors.primary
                                      : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Enhanced Data Display
                    if (_isSessionActive) _buildEnhancedDataDisplay(),

                    const SizedBox(height: 16),

                    // Heart Rate Chart
                    if (_isSessionActive) ...[
                      const Text(
                        'Heart Rate',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),

                      Container(
                        height: 220,
                        margin: const EdgeInsets.symmetric(vertical: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadius,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child:
                            _heartRateChartData.length < 2
                                ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const CircularProgressIndicator(),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Collecting data...',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                : Stack(
                                  children: [
                                    SfCartesianChart(
                                      plotAreaBorderWidth: 0,
                                      margin: EdgeInsets.zero,
                                      primaryXAxis: NumericAxis(
                                        title: AxisTitle(
                                          text: 'Time (seconds)',
                                          textStyle: const TextStyle(
                                            color: AppColors.textLight,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        majorGridLines: const MajorGridLines(
                                          width: 0.5,
                                          color: Colors.grey,
                                        ),
                                        axisLine: const AxisLine(
                                          width: 0.5,
                                          color: Colors.grey,
                                        ),
                                        minimum:
                                            max(
                                              0,
                                              _elapsedSeconds - 60,
                                            ).toDouble(),
                                        maximum: max(
                                          60,
                                          _elapsedSeconds.toDouble(),
                                        ),
                                        interval: 10,
                                        labelStyle: const TextStyle(
                                          color: AppColors.textLight,
                                          fontSize: 10,
                                        ),
                                      ),
                                      primaryYAxis: NumericAxis(
                                        title: AxisTitle(
                                          text: 'Heart Rate (bpm)',
                                          textStyle: const TextStyle(
                                            color: AppColors.textLight,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        minimum: 60,
                                        maximum: 200,
                                        interval: 20,
                                        majorGridLines: const MajorGridLines(
                                          width: 0.5,
                                          color: Colors.grey,
                                        ),
                                        axisLine: const AxisLine(
                                          width: 0.5,
                                          color: Colors.grey,
                                        ),
                                        labelStyle: const TextStyle(
                                          color: AppColors.textLight,
                                          fontSize: 10,
                                        ),
                                      ),
                                      annotations: _getChartAnnotations(),
                                      tooltipBehavior: TooltipBehavior(
                                        enable: true,
                                      ),
                                      zoomPanBehavior: ZoomPanBehavior(
                                        enablePanning: true,
                                        zoomMode: ZoomMode.x,
                                      ),
                                      series: <
                                        CartesianSeries<HeartRateData, int>
                                      >[
                                        // Main heart rate line
                                        FastLineSeries<HeartRateData, int>(
                                          onRendererCreated: (
                                            ChartSeriesController controller,
                                          ) {
                                            _chartSeriesController = controller;
                                          },
                                          dataSource: _heartRateChartData,
                                          xValueMapper:
                                              (HeartRateData data, _) =>
                                                  data.timeInSeconds,
                                          yValueMapper:
                                              (HeartRateData data, _) =>
                                                  data.heartRate,
                                          color: Colors.red.shade400,
                                          width: 3,
                                          markerSettings: MarkerSettings(
                                            isVisible: true,
                                            height: 5,
                                            width: 5,
                                            shape: DataMarkerType.circle,
                                            borderWidth: 0,
                                            color: Colors.red.shade400,
                                          ),
                                          enableTooltip: true,
                                          animationDuration: 0,
                                          name: 'Heart Rate',
                                        ),

                                        // Area under the heart rate line with gradient
                                        AreaSeries<HeartRateData, int>(
                                          dataSource: _heartRateChartData,
                                          xValueMapper:
                                              (HeartRateData data, _) =>
                                                  data.timeInSeconds,
                                          yValueMapper:
                                              (HeartRateData data, _) =>
                                                  data.heartRate,
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.red.shade100.withOpacity(
                                                0.1,
                                              ),
                                              Colors.red.shade400.withOpacity(
                                                0.3,
                                              ),
                                            ],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          ),
                                          borderColor: Colors.transparent,
                                          animationDuration: 0,
                                        ),
                                      ],
                                    ),

                                    // AT Label
                                    if (_anaerobicThresholdReached &&
                                        _atReachedTimeSeconds != null)
                                      Positioned(
                                        top: 5,
                                        right: 10,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary
                                                .withOpacity(0.8),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: const Text(
                                            'Anaerobic Threshold',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                      ),
                    ],

                    // Action button
                    const Spacer(),
                    _isSessionActive
                        ? AppButton(
                          text: 'End Session',
                          onPressed: _endSession,
                          backgroundColor: Colors.red,
                        )
                        : AppButton(
                          text: 'Start Session',
                          onPressed: _startSession,
                          icon: Icons.play_arrow,
                        ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedDataDisplay() {
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                'Speed',
                '${_currentSpeed.toStringAsFixed(1)} km/h',
                Icons.speed,
                Colors.blue,
              ),
              _buildStatItem(
                'Heart Rate',
                '${_currentHeartRate.toInt()} bpm',
                Icons.favorite,
                _getHeartRateColor(_currentHeartRate),
              ),
              _buildStatItem(
                'Distance',
                '${_currentDistance.toStringAsFixed(2)} km',
                Icons.straighten,
                Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                'Calories',
                '${_currentCaloriesBurned.toInt()} kcal',
                Icons.local_fire_department,
                Colors.orange,
              ),
              _buildStatItem(
                'Duration',
                _formatDuration(_elapsedSeconds ~/ 60, _elapsedSeconds % 60),
                Icons.timer,
                Colors.indigo,
              ),
              _buildZoneIndicator(),
            ],
          ),

          // Anaerobic Threshold Notification
          if (_anaerobicThresholdReached && _atReachedTimeSeconds != null) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                border: Border.all(color: AppColors.primary, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.notifications_active,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Anaerobic Threshold Reached!',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'At ${_formatDuration(_atReachedTimeSeconds! ~/ 60, _atReachedTimeSeconds! % 60)}. Optimal training zone detected.',
                    style: TextStyle(color: Colors.grey.shade800),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'HR: ${_atHeartRate.toInt()} bpm',
                            style: TextStyle(
                              color: Colors.grey.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.speed, color: Colors.blue, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            'Speed: ${_atSpeed.toStringAsFixed(1)} km/h',
                            style: TextStyle(
                              color: Colors.grey.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  if (_atTargetSpeed != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.arrow_downward,
                          color: Colors.green,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Target Speed: ${_atTargetSpeed!.toStringAsFixed(1)} km/h',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildZoneIndicator() {
    // Calculate the heart rate zone
    String zone;
    Color zoneColor;

    double maxHR = 220 - 30; // Assuming 30 years old user for demo
    double hrPercentage = _currentHeartRate / maxHR * 100;

    if (hrPercentage < 60) {
      zone = 'Easy';
      zoneColor = Colors.green;
    } else if (hrPercentage < 70) {
      zone = 'Fat Burn';
      zoneColor = Colors.blue;
    } else if (hrPercentage < 80) {
      zone = 'Aerobic';
      zoneColor = Colors.orange;
    } else if (hrPercentage < 90) {
      zone = 'Anaerobic';
      zoneColor = Colors.deepOrange;
    } else {
      zone = 'Max';
      zoneColor = Colors.red;
    }

    return Container(
      width: MediaQuery.of(context).size.width * 0.25,
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: zoneColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              zone,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${hrPercentage.toInt()}% MHR',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'HR Zone',
            style: TextStyle(fontSize: 14, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  Color _getHeartRateColor(double heartRate) {
    // Calculate the heart rate zone
    double maxHR = 220 - 30; // Assuming 30 years old user for demo
    double hrPercentage = heartRate / maxHR * 100;

    if (hrPercentage < 60) {
      return Colors.green;
    } else if (hrPercentage < 70) {
      return Colors.blue;
    } else if (hrPercentage < 80) {
      return Colors.orange;
    } else if (hrPercentage < 90) {
      return Colors.deepOrange;
    } else {
      return Colors.red;
    }
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.25,
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  // Update the _updateDataPoint method to capture AT values
  void _updateDataPoint(ExerciseDataPoint data) {
    if (!mounted) return;

    setState(() {
      // Update current values
      _currentSpeed = data.speed;
      _currentHeartRate = data.heartRate;
      _currentCaloriesBurned += data.calories;
      _elapsedSeconds += 1;

      // Calculate distance increment based on speed (km/h) and time (1 second)
      // Convert km/h to km/s and then multiply by time
      _currentDistance +=
          (_currentSpeed / 3600); // Convert km/h to km/s then multiply by 1s

      // Update history data for charts (keep last 60 entries)
      _speedHistory.add(_currentSpeed);
      _heartRateHistory.add(_currentHeartRate);

      // Build heart rate spot for fl_chart
      _heartRateChartData.add(
        HeartRateData(
          _elapsedSeconds,
          _currentHeartRate,
          isATPoint:
              _anaerobicThresholdReached &&
              _atReachedTimeSeconds != null &&
              _elapsedSeconds == _atReachedTimeSeconds!,
        ),
      );

      if (_speedHistory.length > 60) {
        _speedHistory.removeAt(0);
      }
      if (_heartRateHistory.length > 60) {
        _heartRateHistory.removeAt(0);
      }
      if (_heartRateChartData.length > 60) {
        _heartRateChartData.removeAt(0);
      }

      // Check for anaerobic threshold
      if (!_anaerobicThresholdReached &&
          _currentHeartRate > 160 &&
          _elapsedSeconds > 45) {
        _anaerobicThresholdReached = true;
        _atReachedTimeSeconds = _elapsedSeconds;
        _atSpeed = _currentSpeed; // Capture speed at AT
        _atHeartRate = _currentHeartRate; // Capture heart rate at AT
        _atTargetSpeed = max(
          _currentSpeed - 1.0,
          3.0,
        ); // Target slightly lower speed
        _isShowingATMessage = true;
        _atNotificationController.forward(from: 0.0);

        // Auto-dismiss notification after 8 seconds
        Future.delayed(const Duration(seconds: 8), () {
          if (mounted) {
            setState(() {
              _isShowingATMessage = false;
            });
          }
        });
      }
    });
  }

  List<CartesianChartAnnotation> _getChartAnnotations() {
    if (_anaerobicThresholdReached && _atReachedTimeSeconds != null) {
      return [
        CartesianChartAnnotation(
          coordinateUnit: CoordinateUnit.point,
          x: _atReachedTimeSeconds!.toDouble(),
          y: _atHeartRate,
          widget: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'AT',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ),
      ];
    }
    return [];
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
