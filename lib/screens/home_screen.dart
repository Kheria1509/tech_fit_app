import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

import '../utils/app_constants.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';
import '../services/exercise_service.dart';
import '../widgets/app_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;
  final ExerciseService _exerciseService = ExerciseService();

  @override
  void initState() {
    super.initState();
    // Load latest user data when screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshUserData();
    });
  }

  Future<void> _refreshUserData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    setState(() {
      _isLoading = true;
    });

    try {
      await userProvider.refreshUserData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error refreshing data: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshUserData,
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final UserModel? user = userProvider.user;
        if (user == null) {
          return const Center(child: Text('User data not available'));
        }

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section with greeting
              _buildHeader(user),

              const SizedBox(height: 24),

              // Progress Cards
              _buildProgressSection(user),

              const SizedBox(height: 24),

              // Today's workout section
              _buildWorkoutSection(user),

              const SizedBox(height: 24),

              // Exercise Tracking
              _buildTrackingSection(user),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(UserModel user) {
    final greeting = _getGreeting();
    final firstName = user.name.split(' ').first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting,',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  firstName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/profile');
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade200,
                  image:
                      user.profileImageUrl != null &&
                              user.profileImageUrl!.isNotEmpty
                          ? DecorationImage(
                            image: NetworkImage(user.profileImageUrl!),
                            fit: BoxFit.cover,
                          )
                          : null,
                ),
                child:
                    user.profileImageUrl == null ||
                            user.profileImageUrl!.isEmpty
                        ? Icon(Icons.person, color: Colors.grey.shade400)
                        : null,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        const Text('Dashboard', style: AppTextStyles.heading2),
      ],
    );
  }

  Widget _buildProgressSection(UserModel user) {
    // Calculate weight loss progress
    final initialWeight = user.weight;
    final targetWeight = user.targetWeight;
    final weightDifference = initialWeight - targetWeight;

    // Mock data for exercise progress - replace with real data from user model in production
    final exerciseGoalMinutes = 150; // WHO recommended weekly exercise
    final exerciseProgress =
        user.sessions == null || user.sessions!.isEmpty
            ? 0.0
            : user.sessions!
                .map((session) => session.duration.inMinutes)
                .reduce((a, b) => a + b)
                .toDouble();

    final exerciseProgressPercent = exerciseProgress / exerciseGoalMinutes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Your Progress', style: AppTextStyles.heading3),

        const SizedBox(height: 16),

        Row(
          children: [
            // Weight progress card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(
                    AppConstants.cardBorderRadius,
                  ),
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
                      'Weight',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: CircularPercentIndicator(
                        radius: 60.0,
                        lineWidth: 10.0,
                        percent:
                            weightDifference <= 0
                                ? 0.0
                                : (initialWeight - user.weight) /
                                    weightDifference,
                        center: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${user.weight.toStringAsFixed(1)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'kg',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textLight,
                              ),
                            ),
                          ],
                        ),
                        progressColor: AppColors.primary,
                        backgroundColor: Colors.grey.shade200,
                        circularStrokeCap: CircularStrokeCap.round,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Target: ${user.targetWeight.toStringAsFixed(1)} kg',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Exercise progress card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(
                    AppConstants.cardBorderRadius,
                  ),
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
                      'Exercise',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: CircularPercentIndicator(
                        radius: 60.0,
                        lineWidth: 10.0,
                        percent: exerciseProgressPercent.clamp(0.0, 1.0),
                        center: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${exerciseProgress.toInt()}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'min',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textLight,
                              ),
                            ),
                          ],
                        ),
                        progressColor: AppColors.secondary,
                        backgroundColor: Colors.grey.shade200,
                        circularStrokeCap: CircularStrokeCap.round,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Goal: 150 min/week',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWorkoutSection(UserModel user) {
    // Calculate remaining calories to burn based on user's goal
    // This is mock data - replace with real algorithm in production
    final dailyCalorieBurn = 500; // Example goal
    final caloriesBurnt =
        user.sessions == null || user.sessions!.isEmpty
            ? 0.0
            : user.sessions!.last.caloriesBurned.toDouble();
    final remainingCalories = dailyCalorieBurn - caloriesBurnt;
    final progressPercent = (caloriesBurnt / dailyCalorieBurn).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF2D63D8)],
        ),
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today\'s Goal',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Icon(Icons.fitness_center, color: Colors.white),
            ],
          ),

          const SizedBox(height: 20),

          LinearPercentIndicator(
            padding: EdgeInsets.zero,
            lineHeight: 8.0,
            percent: progressPercent,
            progressColor: Colors.white,
            backgroundColor: Colors.white.withOpacity(0.3),
            barRadius: const Radius.circular(4),
          ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${caloriesBurnt.toInt()} kcal',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'Burnt',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${remainingCalories.toInt()} kcal',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'Remaining',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          AppButton(
            text: 'Start Workout',
            onPressed: () {
              Navigator.pushNamed(context, '/exercise');
            },
            backgroundColor: Colors.white,
            textColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingSection(UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Track Your Exercise', style: AppTextStyles.heading3),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/stats');
              },
              child: const Text(
                'View All',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            _buildTrackingCard(
              title: 'Connect Device',
              icon: Icons.bluetooth,
              color: AppColors.primary,
              onTap: () => _connectRaspberryPi(),
            ),
            const SizedBox(width: 16),
            _buildTrackingCard(
              title: 'Manual Entry',
              icon: Icons.edit,
              color: AppColors.secondary,
              onTap: () => Navigator.pushNamed(context, '/manual_entry'),
            ),
          ],
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            _buildTrackingCard(
              title: 'AI Recommendations',
              icon: Icons.auto_awesome,
              color: AppColors.accent,
              onTap: () => Navigator.pushNamed(context, '/recommendations'),
            ),
            const SizedBox(width: 16),
            _buildTrackingCard(
              title: 'Previous Sessions',
              icon: Icons.history,
              color: Colors.purple,
              onTap: () => Navigator.pushNamed(context, '/history'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTrackingCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  Future<void> _connectRaspberryPi() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final result = await _exerciseService.connectToDevice();

      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully connected to device')),
        );
        Navigator.pushNamed(context, '/device_tracking');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to connect to device')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error connecting to device: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
