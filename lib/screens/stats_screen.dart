import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/dashboard_provider.dart';
import '../models/dashboard_models.dart';
import '../theme/app_colors.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detailed Stats'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<DashboardProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStreakCard(provider),
                const SizedBox(height: 24),
                _buildZoneDistributionCard(provider),
                const SizedBox(height: 24),
                _buildATMetricsCard(provider),
                const SizedBox(height: 24),
                _buildWeeklyProgressCard(provider),
                const SizedBox(height: 24),
                _buildEfficiencyCard(provider),
                const SizedBox(height: 24),
                _buildAchievementsCard(provider),
                const SizedBox(height: 24),
                _buildInsightsCard(provider),
                const SizedBox(height: 24),
                _buildSuggestionsCard(provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStreakCard(DashboardProvider provider) {
    final streak = provider.streak;
    if (streak == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Streak Tracking',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStreakItem(
                  'Current Streak',
                  '${streak.currentStreak}',
                  'days',
                  Icons.local_fire_department,
                  Colors.orange,
                ),
                _buildStreakItem(
                  'Longest Streak',
                  '${streak.longestStreak}',
                  'days',
                  Icons.emoji_events,
                  Colors.amber,
                ),
                _buildStreakItem(
                  'Last Workout',
                  streak.lastWorkoutDate
                          ?.difference(DateTime.now())
                          .inDays
                          .abs()
                          .toString() ??
                      '0',
                  'days ago',
                  Icons.calendar_today,
                  Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakItem(
    String title,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(unit, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildZoneDistributionCard(DashboardProvider provider) {
    final streak = provider.streak;
    if (streak == null) return const SizedBox.shrink();

    final zoneDistribution = streak.zoneDistribution;
    if (zoneDistribution.isEmpty) return const SizedBox.shrink();

    final totalDuration = zoneDistribution.values.fold<Duration>(
      Duration.zero,
      (prev, curr) => prev + curr,
    );

    final sections =
        zoneDistribution.entries.map((entry) {
          final percentage = entry.value.inSeconds / totalDuration.inSeconds;
          return PieChartSectionData(
            color: _getZoneColor(entry.key),
            value: percentage * 100,
            title: '${(percentage * 100).toStringAsFixed(1)}%',
            radius: 60,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Training Zone Distribution',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 1.3,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  startDegreeOffset: -90,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children:
                  zoneDistribution.entries.map((entry) {
                    return _buildZoneLegendItem(
                      entry.key.toString().split('.').last,
                      _getZoneColor(entry.key),
                      entry.value,
                      totalDuration,
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoneLegendItem(
    String zone,
    Color color,
    Duration duration,
    Duration total,
  ) {
    final percentage = (duration.inSeconds / total.inSeconds * 100)
        .toStringAsFixed(1);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text('$zone ($percentage%)', style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Color _getZoneColor(WorkoutZone zone) {
    switch (zone) {
      case WorkoutZone.rest:
        return AppColors.zoneRest;
      case WorkoutZone.warmup:
        return AppColors.zoneWarmup;
      case WorkoutZone.fatBurn:
        return AppColors.zoneFatBurn;
      case WorkoutZone.aerobic:
        return AppColors.zoneAerobic;
      case WorkoutZone.anaerobic:
        return AppColors.zoneAnaerobic;
      case WorkoutZone.maximum:
        return AppColors.zoneMaximum;
    }
  }

  Widget _buildATMetricsCard(DashboardProvider provider) {
    final streak = provider.streak;
    if (streak == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Anaerobic Threshold Metrics',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildATMetricItem(
                  'Times Reached',
                  streak.atReachedCount.toString(),
                  'times',
                  Icons.speed,
                  Colors.purple,
                ),
                _buildATMetricItem(
                  'Avg Time to AT',
                  streak.averageTimeToAT.toStringAsFixed(1),
                  'minutes',
                  Icons.timer,
                  Colors.blue,
                ),
                _buildATMetricItem(
                  'Avg Time in AT',
                  streak.averageATDuration.toStringAsFixed(1),
                  'minutes',
                  Icons.trending_up,
                  Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildATMetricItem(
    String title,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(unit, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildWeeklyProgressCard(DashboardProvider provider) {
    final trends = provider.progressTrends;
    if (trends.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weekly Progress',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            'W${value.toInt() + 1}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        trends.length,
                        (index) => FlSpot(
                          index.toDouble(),
                          trends[index]['avgSpeed'] as double,
                        ),
                      ),
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
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

  Widget _buildEfficiencyCard(DashboardProvider provider) {
    final scores = provider.weeklyEfficiencyScores;
    if (scores.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Workout Efficiency',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...scores.entries.map((entry) {
              final score = entry.value;
              final color =
                  score > 0.8
                      ? Colors.green
                      : score > 0.6
                      ? Colors.orange
                      : Colors.red;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text(
                      entry.key.day.toString(),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: score,
                        backgroundColor: Colors.grey[200],
                        color: color,
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(score * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsCard(DashboardProvider provider) {
    final achievements = provider.achievements;
    if (achievements.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Achievements',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...achievements.map((achievement) {
              return ListTile(
                leading: Text(
                  achievement.icon,
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(achievement.title),
                subtitle: Text(achievement.description),
                trailing:
                    achievement.isAchieved
                        ? const Icon(
                          Icons.check_circle,
                          color: AppColors.success,
                        )
                        : CircularProgressIndicator(
                          value: achievement.progress,
                          backgroundColor: Colors.grey[300],
                          color: AppColors.primary,
                        ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsCard(DashboardProvider provider) {
    final insights = provider.insights;
    if (insights.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Health Insights',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...insights.map((insight) {
              return ListTile(
                leading: Icon(
                  insight.isPositiveTrend
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                  color:
                      insight.isPositiveTrend
                          ? AppColors.success
                          : AppColors.error,
                ),
                title: Text(insight.title),
                subtitle: Text(insight.description),
                trailing: Text(
                  '${insight.currentValue} ${insight.unit}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsCard(DashboardProvider provider) {
    final suggestions = provider.suggestions;
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Workout Suggestions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...suggestions.map((suggestion) {
              return ListTile(
                leading: Icon(Icons.fitness_center, color: AppColors.primary),
                title: Text(suggestion.title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(suggestion.description),
                    const SizedBox(height: 4),
                    Text(
                      'Duration: ${suggestion.recommendedDuration} minutes',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      'Target Zone: ${suggestion.targetZone.toString().split('.').last}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
