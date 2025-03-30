import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../models/user_model.dart';
import '../services/exercise_service.dart';
import '../utils/app_constants.dart';
import 'session_detail_screen.dart';

class PreviousSessionsScreen extends StatefulWidget {
  const PreviousSessionsScreen({Key? key}) : super(key: key);

  @override
  State<PreviousSessionsScreen> createState() => _PreviousSessionsScreenState();
}

class _PreviousSessionsScreenState extends State<PreviousSessionsScreen> {
  final ExerciseService _exerciseService = ExerciseService();
  List<SessionDetailData> _sessions = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final sessions = await _exerciseService.getSessionsWithATData();

      setState(() {
        _sessions = sessions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load sessions: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Previous Sessions',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: _loadSessions,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              )
              : _sessions.isEmpty
              ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.directions_run,
                      size: 72,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No sessions found',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Complete a workout to see your session history',
                      style: TextStyle(color: AppColors.textLight),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadSessions,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _sessions.length,
                  itemBuilder: (context, index) {
                    final session = _sessions[index];
                    return _buildSessionCard(session);
                  },
                ),
              ),
    );
  }

  Widget _buildSessionCard(SessionDetailData session) {
    // Format date
    final formattedDate = DateFormat(
      'MMM d, yyyy - h:mm a',
    ).format(session.date);

    // Format duration
    final hours = session.durationMinutes ~/ 60;
    final minutes = session.durationMinutes % 60;
    final durationText =
        hours > 0
            ? '$hours hr ${minutes.toString().padLeft(2, '0')} min'
            : '${minutes.toString().padLeft(2, '0')} min';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: InkWell(
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => SessionDetailScreen(sessionId: session.id),
              ),
            ),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppColors.textLight,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  if (session.atReached)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified,
                            size: 12,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'AT Detected',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Workout Summary',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),

              // Session stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatItem('Duration', durationText, Icons.timer),
                  _buildStatItem(
                    'Distance',
                    '${session.totalDistance.toStringAsFixed(2)} km',
                    Icons.straighten,
                  ),
                  _buildStatItem(
                    'Calories',
                    '${session.totalCalories}',
                    Icons.local_fire_department,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Heart Rate Chart
              Container(
                height: 150,
                child: SfCartesianChart(
                  primaryXAxis: NumericAxis(
                    title: AxisTitle(
                      text: 'Time (min)',
                      textStyle: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 10,
                      ),
                    ),
                    majorGridLines: const MajorGridLines(width: 0),
                  ),
                  primaryYAxis: NumericAxis(
                    title: AxisTitle(
                      text: 'Heart Rate (bpm)',
                      textStyle: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 10,
                      ),
                    ),
                    majorGridLines: const MajorGridLines(
                      width: 0.5,
                      color: Colors.grey,
                    ),
                  ),
                  plotAreaBorderWidth: 0,
                  series: <CartesianSeries<HeartRatePoint, int>>[
                    SplineSeries<HeartRatePoint, int>(
                      dataSource:
                          session.heartRateData.length > 20
                              ? _getDownsampledData(session.heartRateData)
                              : session.heartRateData,
                      xValueMapper:
                          (HeartRatePoint data, _) => data.timeInSeconds,
                      yValueMapper: (HeartRatePoint data, _) => data.heartRate,
                      color: Colors.red,
                      width: 2,
                    ),

                    // Mark AT point if reached
                    if (session.atReached &&
                        session.atReachedTimeSeconds != null)
                      ScatterSeries<HeartRatePoint, int>(
                        dataSource: [
                          HeartRatePoint(
                            timeInSeconds: session.atReachedTimeSeconds!,
                            heartRate: session.atHeartRate!,
                          ),
                        ],
                        xValueMapper:
                            (HeartRatePoint data, _) => data.timeInSeconds,
                        yValueMapper:
                            (HeartRatePoint data, _) => data.heartRate,
                        color: AppColors.primary,
                        markerSettings: const MarkerSettings(
                          height: 10,
                          width: 10,
                          shape: DataMarkerType.diamond,
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // View details button
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  SessionDetailScreen(sessionId: session.id),
                        ),
                      ),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('View Details'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to downsample heart rate data for chart display
  List<HeartRatePoint> _getDownsampledData(List<HeartRatePoint> data) {
    final int targetSize = 20;

    if (data.length <= targetSize) {
      return data;
    }

    final int step = data.length ~/ targetSize;
    List<HeartRatePoint> downsampled = [];

    for (int i = 0; i < data.length; i += step) {
      if (downsampled.length < targetSize) {
        downsampled.add(data[i]);
      }
    }

    // Always include the last point
    if (downsampled.length < targetSize) {
      downsampled.add(data.last);
    }

    return downsampled;
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textLight),
        ),
      ],
    );
  }
}
