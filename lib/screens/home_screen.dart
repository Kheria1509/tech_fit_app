import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/dashboard_provider.dart';
import '../providers/user_provider.dart';
import '../models/dashboard_models.dart';
import '../models/user_model.dart';
import '../theme/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Consumer<DashboardProvider>(
              builder: (context, provider, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(provider),
                    const SizedBox(height: 24),
                    _buildStartWorkoutCard(),
                    const SizedBox(height: 24),
                    _buildProgressSection(),
                    const SizedBox(height: 24),
                    _buildQuickAccess(),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(DashboardProvider provider) {
    final greeting = _getGreeting();
    final userProvider = Provider.of<UserProvider>(context);
    final UserModel? user = userProvider.user;
    final String firstName = user?.name.split(' ').first ?? 'User';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: const TextStyle(
                fontSize: 20,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              firstName,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              debugPrint('Profile icon tapped'); // Debug print
              Navigator.of(context).pushNamed('/profile');
            },
            borderRadius: BorderRadius.circular(30),
            child: Ink(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[200],
              ),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: Colors.transparent,
                backgroundImage:
                    user?.profileImageUrl != null
                        ? NetworkImage(user!.profileImageUrl!)
                        : null,
                child:
                    user?.profileImageUrl == null
                        ? const Icon(Icons.person, size: 35, color: Colors.grey)
                        : null,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  Widget _buildStartWorkoutCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Start Workout',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/device_tracking');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Start',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Progress',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Workout Statistics Card
        _buildProgressCard(
          'Workout Stats',
          '4/5',
          'workouts',
          'Weekly Goal: 5 workouts',
          Icons.fitness_center,
          Colors.blue,
          details: [
            {'label': 'Duration this week', 'value': '180 min'},
            {'label': 'Avg. Intensity', 'value': 'Moderate'},
            {'label': 'Calories burned', 'value': '2,500 kcal'},
          ],
        ),
        const SizedBox(height: 16),

        // Heart Rate Metrics Card
        _buildProgressCard(
          'Heart Rate',
          '72',
          'bpm',
          'Resting Heart Rate',
          Icons.favorite,
          Colors.red,
          details: [
            {'label': 'Time in Peak Zone', 'value': '25 min'},
            {'label': 'Recovery Rate', 'value': 'Good'},
            {'label': 'Max HR Today', 'value': '165 bpm'},
          ],
        ),
        const SizedBox(height: 16),

        // Performance Metrics Card
        _buildProgressCard(
          'Performance',
          '85',
          'points',
          'Fitness Score',
          Icons.speed,
          Colors.orange,
          details: [
            {'label': 'Personal Best', 'value': '5km Run'},
            {'label': 'Endurance Level', 'value': 'Advanced'},
            {'label': 'Recovery Status', 'value': 'Optimal'},
          ],
        ),
        const SizedBox(height: 16),

        // Body Metrics Card
        _buildProgressCard(
          'Body Metrics',
          '75.0',
          'kg',
          'Target: 72.0 kg',
          Icons.monitor_weight_outlined,
          Colors.purple,
          details: [
            {'label': 'BMI', 'value': '23.5'},
            {'label': 'Body Fat', 'value': '18%'},
            {'label': 'Muscle Mass', 'value': '35.2 kg'},
          ],
        ),
        const SizedBox(height: 16),

        // Achievement Progress Card
        _buildProgressCard(
          'Achievements',
          '12',
          'earned',
          'Total: 30 badges',
          Icons.emoji_events,
          Colors.amber,
          details: [
            {'label': 'Current Streak', 'value': '8 days'},
            {'label': 'Best Streak', 'value': '15 days'},
            {'label': 'Monthly Goals', 'value': '3/5'},
          ],
        ),
        const SizedBox(height: 16),

        // Fitness Level Card
        _buildProgressCard(
          'Fitness Level',
          'Advanced',
          'level',
          'VO2 Max: 45.5',
          Icons.trending_up,
          Colors.green,
          details: [
            {'label': 'Fitness Age', 'value': '27 yrs'},
            {'label': 'Strength Level', 'value': 'Intermediate'},
            {'label': 'Overall Score', 'value': '8.5/10'},
          ],
        ),
        const SizedBox(height: 16),

        // Recovery & Wellness Card
        _buildProgressCard(
          'Wellness',
          '85',
          '%',
          'Recovery Score',
          Icons.nightlight_round,
          Colors.indigo,
          details: [
            {'label': 'Sleep Quality', 'value': 'Good'},
            {'label': 'Stress Level', 'value': 'Low'},
            {'label': 'Rest Days', 'value': '2/week'},
          ],
        ),
        const SizedBox(height: 16),

        // Comparison Metrics Card
        _buildProgressCard(
          'Progress',
          '+15',
          '%',
          'Monthly Improvement',
          Icons.compare_arrows,
          Colors.teal,
          details: [
            {'label': 'vs Last Week', 'value': '+5%'},
            {'label': 'vs Last Month', 'value': '+15%'},
            {'label': 'Goal Progress', 'value': '75%'},
          ],
        ),
        const SizedBox(height: 16),

        // Workout Balance Card
        _buildProgressCard(
          'Training Mix',
          '70',
          '%',
          'Balanced Score',
          Icons.balance,
          Colors.deepPurple,
          details: [
            {'label': 'Cardio', 'value': '40%'},
            {'label': 'Strength', 'value': '35%'},
            {'label': 'Flexibility', 'value': '25%'},
          ],
        ),
        const SizedBox(height: 16),

        // Health Impact Card
        _buildProgressCard(
          'Health Impact',
          '92',
          '%',
          'Wellness Score',
          Icons.health_and_safety,
          Colors.cyan,
          details: [
            {'label': 'Energy Level', 'value': 'High'},
            {'label': 'Mood Score', 'value': '9/10'},
            {'label': 'Recovery Rate', 'value': 'Excellent'},
          ],
        ),
      ],
    );
  }

  Widget _buildProgressCard(
    String title,
    String value,
    String unit,
    String target,
    IconData icon,
    Color color, {
    List<Map<String, String>>? details,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
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
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    unit,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
              Text(
                target,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (details != null) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            ...details
                .map(
                  (detail) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          detail['label']!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          detail['value']!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickAccess() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Quick Access',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/stats');
              },
              child: Row(
                children: [
                  Text(
                    'View Stats',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(Icons.arrow_forward, color: AppColors.primary),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickAccessCard(
                'Connect Device',
                Icons.bluetooth,
                onTap: () {
                  Navigator.pushNamed(context, '/bluetooth_device');
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildQuickAccessCard(
                'History',
                Icons.history,
                onTap: () {
                  Navigator.pushNamed(context, '/history');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAccessCard(
    String title,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
