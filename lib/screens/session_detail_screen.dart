import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../models/user_model.dart';
import '../services/exercise_service.dart';
import '../utils/app_constants.dart';

class SessionDetailScreen extends StatefulWidget {
  final String sessionId;

  const SessionDetailScreen({Key? key, required this.sessionId})
    : super(key: key);

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  final ExerciseService _exerciseService = ExerciseService();
  SessionDetailData? _session;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSessionDetails();
  }

  Future<void> _loadSessionDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final session = await _exerciseService.getSessionDetailById(
        widget.sessionId,
      );

      setState(() {
        _session = session;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load session details: ${e.toString()}';
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
          'Session Details',
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
                      onPressed: _loadSessionDetails,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              )
              : _session == null
              ? const Center(child: Text('Session not found'))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Session header with date
                    _buildSessionHeader(_session!),

                    const SizedBox(height: 24),

                    // Summary stats
                    _buildSessionStats(_session!),

                    const SizedBox(height: 24),

                    // Heart Rate Chart
                    _buildHeartRateChart(_session!),

                    const SizedBox(height: 24),

                    // AT Details section
                    if (_session!.atReached) _buildATDetails(_session!),
                  ],
                ),
              ),
    );
  }

  Widget _buildSessionHeader(SessionDetailData session) {
    final formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(session.date);
    final formattedTime = DateFormat('h:mm a').format(session.date);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.directions_run, size: 32, color: AppColors.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Workout Session',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formattedDate,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textLight,
                ),
              ),
              Text(
                formattedTime,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
        if (session.atReached)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_activity, size: 16, color: Colors.white),
                const SizedBox(width: 4),
                const Text(
                  'AT Detected',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSessionStats(SessionDetailData session) {
    // Format duration
    final hours = session.durationMinutes ~/ 60;
    final minutes = session.durationMinutes % 60;
    final durationText =
        hours > 0
            ? '$hours hr ${minutes.toString().padLeft(2, '0')} min'
            : '${minutes.toString().padLeft(2, '0')} min';

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
          const Text(
            'Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),

          // Stats grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatTile('Duration', durationText, Icons.timer),
              _buildStatTile(
                'Distance',
                '${session.totalDistance.toStringAsFixed(2)} km',
                Icons.straighten,
              ),
              _buildStatTile(
                'Calories',
                '${session.totalCalories}',
                Icons.local_fire_department,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatTile(
                'Avg HR',
                '${session.averageHeartRate.toInt()} bpm',
                Icons.favorite,
              ),
              _buildStatTile(
                'Max HR',
                '${session.maxHeartRate.toInt()} bpm',
                Icons.favorite_border,
              ),
              _buildStatTile(
                'Avg Speed',
                '${session.averageSpeed.toStringAsFixed(1)} km/h',
                Icons.speed,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeartRateChart(SessionDetailData session) {
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
          const Text(
            'Heart Rate',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: 250,
            child: SfCartesianChart(
              primaryXAxis: NumericAxis(
                title: AxisTitle(
                  text: 'Time (minutes)',
                  textStyle: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                majorGridLines: const MajorGridLines(
                  width: 0.5,
                  color: Colors.grey,
                ),
                axisLine: const AxisLine(width: 0.5, color: Colors.grey),
                interval: session.durationMinutes > 30 ? 5 : 2,
                // Convert seconds to minutes for x-axis
                labelFormat: '{value}',
                axisBorderType: AxisBorderType.rectangle,
              ),
              primaryYAxis: NumericAxis(
                title: AxisTitle(
                  text: 'Heart Rate (bpm)',
                  textStyle: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                minimum: 60,
                maximum: session.maxHeartRate * 1.1,
                interval: 20,
                majorGridLines: const MajorGridLines(
                  width: 0.5,
                  color: Colors.grey,
                ),
                axisLine: const AxisLine(width: 0.5, color: Colors.grey),
                axisBorderType: AxisBorderType.rectangle,
              ),
              plotAreaBorderWidth: 0,
              tooltipBehavior: TooltipBehavior(enable: true),
              zoomPanBehavior: ZoomPanBehavior(
                enablePanning: true,
                enablePinching: true,
                zoomMode: ZoomMode.x,
              ),
              series: <CartesianSeries<HeartRatePoint, int>>[
                // Heart rate zones (background)
                RangeAreaSeries<HeartRatePoint, int>(
                  dataSource: session.heartRateData,
                  xValueMapper:
                      (HeartRatePoint data, _) => data.timeInSeconds ~/ 60,
                  lowValueMapper: (HeartRatePoint data, _) => 60,
                  highValueMapper: (HeartRatePoint data, _) => 130,
                  color: Colors.green.withOpacity(0.2),
                  name: 'Aerobic Zone',
                ),
                RangeAreaSeries<HeartRatePoint, int>(
                  dataSource: session.heartRateData,
                  xValueMapper:
                      (HeartRatePoint data, _) => data.timeInSeconds ~/ 60,
                  lowValueMapper: (HeartRatePoint data, _) => 130,
                  highValueMapper: (HeartRatePoint data, _) => 160,
                  color: Colors.orange.withOpacity(0.2),
                  name: 'Anaerobic Zone',
                ),
                RangeAreaSeries<HeartRatePoint, int>(
                  dataSource: session.heartRateData,
                  xValueMapper:
                      (HeartRatePoint data, _) => data.timeInSeconds ~/ 60,
                  lowValueMapper: (HeartRatePoint data, _) => 160,
                  highValueMapper: (HeartRatePoint data, _) => 200,
                  color: Colors.red.withOpacity(0.2),
                  name: 'Max Zone',
                ),

                // Main heart rate line
                SplineSeries<HeartRatePoint, int>(
                  dataSource: session.heartRateData,
                  xValueMapper:
                      (HeartRatePoint data, _) => data.timeInSeconds ~/ 60,
                  yValueMapper: (HeartRatePoint data, _) => data.heartRate,
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
                  name: 'Heart Rate',
                ),

                // AT point marker
                if (session.atReached && session.atReachedTimeSeconds != null)
                  ScatterSeries<HeartRatePoint, int>(
                    dataSource: [
                      HeartRatePoint(
                        timeInSeconds: session.atReachedTimeSeconds!,
                        heartRate: session.atHeartRate!,
                      ),
                    ],
                    xValueMapper:
                        (HeartRatePoint data, _) => data.timeInSeconds ~/ 60,
                    yValueMapper: (HeartRatePoint data, _) => data.heartRate,
                    color: AppColors.primary,
                    markerSettings: MarkerSettings(
                      height: 12,
                      width: 12,
                      shape: DataMarkerType.diamond,
                      borderColor: Colors.white,
                      borderWidth: 2,
                    ),
                    name: 'Anaerobic Threshold',
                  ),
              ],
              annotations: _getHeartRateChartAnnotations(session),
            ),
          ),

          // Legend
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildChartLegend('Aerobic', Colors.green),
              const SizedBox(width: 16),
              _buildChartLegend('Anaerobic', Colors.orange),
              const SizedBox(width: 16),
              _buildChartLegend('Max', Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  List<CartesianChartAnnotation> _getHeartRateChartAnnotations(
    SessionDetailData session,
  ) {
    List<CartesianChartAnnotation> annotations = [];

    if (session.atReached && session.atReachedTimeSeconds != null) {
      annotations.add(
        CartesianChartAnnotation(
          coordinateUnit: CoordinateUnit.point,
          x: session.atReachedTimeSeconds! ~/ 60,
          y: session.atHeartRate! + 10,
          widget: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'AT Point',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ),
      );
    }

    return annotations;
  }

  Widget _buildATDetails(SessionDetailData session) {
    if (!session.atReached || session.atReachedTimeSeconds == null) {
      return const SizedBox.shrink();
    }

    // Format AT time
    final atMinutes = session.atReachedTimeSeconds! ~/ 60;
    final atSeconds = session.atReachedTimeSeconds! % 60;
    final atTimeText =
        '${atMinutes.toString().padLeft(2, '0')}:${atSeconds.toString().padLeft(2, '0')}';

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
              Icon(Icons.verified, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Anaerobic Threshold (AT) Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'The anaerobic threshold represents the point at which your body begins to produce more lactic acid than it can eliminate. Training at or near your AT can improve your endurance and performance.',
            style: TextStyle(fontSize: 14, color: AppColors.textLight),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildATStat('AT Time', atTimeText, Icons.timer),
              _buildATStat(
                'AT Heart Rate',
                '${session.atHeartRate!.toInt()} bpm',
                Icons.favorite,
              ),
              _buildATStat(
                'AT Speed',
                '${session.atSpeed!.toStringAsFixed(1)} km/h',
                Icons.speed,
              ),
            ],
          ),
          if (session.atTargetSpeed != null) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Target Speed: ${session.atTargetSpeed!.toStringAsFixed(1)} km/h',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'After reaching your anaerobic threshold, the system calculated an optimal target speed to help you train more effectively.',
              style: TextStyle(fontSize: 14, color: AppColors.textLight),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildATStat(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textLight),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textLight),
        ),
      ],
    );
  }
}
