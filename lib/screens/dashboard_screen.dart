import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dashboard_provider.dart';
import '../models/dashboard_models.dart';
import '../theme/app_colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().initializeDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Workout Dashboard'),
              background: Container(
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Consumer<DashboardProvider>(
              builder: (context, provider, child) {
                if (provider.streak == null) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                return Column(
                  children: [
                    _buildQuickStats(provider),
                    _buildZoneDistributionCard(provider),
                    _buildProgressTrendsCard(provider),
                    _buildInsightsCard(provider),
                    _buildSuggestionsCard(provider),
                    _buildAchievementsCard(provider),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(DashboardProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Current Streak',
              '${provider.streak?.currentStreak ?? 0} days',
              Icons.local_fire_department,
              AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'AT Reached',
              '${provider.streak?.atReachedCount ?? 0} times',
              Icons.speed,
              AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
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
          ],
        ),
      ),
    );
  }

  Widget _buildZoneDistributionCard(DashboardProvider provider) {
    final zoneDistribution = provider.streak?.zoneDistribution;
    if (zoneDistribution == null || zoneDistribution.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalDuration = zoneDistribution.values.fold<Duration>(
      Duration.zero,
      (prev, curr) => prev + curr,
    );

    final sections =
        zoneDistribution.entries.map((entry) {
          final percentage = entry.value.inSeconds / totalDuration.inSeconds;
          final color = _getZoneColor(entry.key);
          return PieChartSectionData(
            color: color,
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
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Training Zone Distribution',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

  Widget _buildProgressTrendsCard(DashboardProvider provider) {
    final trends = provider.progressTrends;
    if (trends.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Progress Trends',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...trends.map((trend) {
              return ListTile(
                leading: Icon(Icons.trending_up, color: AppColors.primary),
                title: Text('Week ${trend['weekNumber']}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Avg Speed: ${trend['avgSpeed'].toStringAsFixed(1)} km/h',
                    ),
                    Text('Avg Heart Rate: ${trend['avgHeartRate']} bpm'),
                    Text(
                      'Total Distance: ${trend['totalDistance'].toStringAsFixed(1)} km',
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

  Widget _buildInsightsCard(DashboardProvider provider) {
    final insights = provider.insights;
    if (insights.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Insights',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Workout Suggestions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                    Text('Duration: ${suggestion.recommendedDuration} minutes'),
                    Text(
                      'Target Zone: ${suggestion.targetZone.toString().split('.').last}',
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
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Achievements',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
}
