import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_constants.dart';
import '../services/exercise_service.dart';
import '../providers/user_provider.dart';
import '../models/user_model.dart';
import '../widgets/app_button.dart';

class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({Key? key}) : super(key: key);

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  final ExerciseService _exerciseService = ExerciseService();
  bool _isLoading = true;
  bool _isDeviceConnected = false;
  String? _errorMessage;

  // Default recommended exercise parameters
  final Map<String, dynamic> _recommendedParams = {
    'duration': 30,
    'intensity': 0.7,
    'calories': 300,
    'type': 0,
  };

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check if device is connected
      _isDeviceConnected = await _exerciseService.isDeviceConnected();

      // Get user data for personalized recommendations
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;

      if (user != null) {
        // Create basic personalized recommendation based on user data
        setState(() {
          _recommendedParams['duration'] = user.weight > 80 ? 35 : 30;
          _recommendedParams['calories'] = (user.weight * 4).round();
          _recommendedParams['type'] = user.gender == Gender.male ? 1 : 0;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error initializing: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _startDeviceConnection() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _exerciseService.connectToDevice();
      setState(() {
        _isDeviceConnected = true;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to connect: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startTrackingSession() {
    Navigator.pushNamed(context, '/device_tracking');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Start Exercise',
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_errorMessage != null) {
      return _buildErrorView();
    }

    if (!_isDeviceConnected) {
      return _buildConnectionView();
    }

    return _buildExerciseView();
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'An unknown error occurred',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 24),
          AppButton(text: 'Try Again', onPressed: _initializeScreen),
        ],
      ),
    );
  }

  Widget _buildConnectionView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Connect Your Device',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'To start tracking your exercise, please connect your TechFit device.',
          style: TextStyle(fontSize: 16, color: AppColors.textLight),
        ),
        const SizedBox(height: 32),
        Center(
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.watch, size: 80, color: Colors.grey.shade400),
          ),
        ),
        const SizedBox(height: 32),
        AppButton(
          text: 'Connect Device',
          onPressed: _startDeviceConnection,
          icon: Icons.bluetooth,
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            // Simulate a device connection
            setState(() {
              _isDeviceConnected = true;
            });
          },
          child: const Text('Skip (Simulate Connected Device)'),
        ),
      ],
    );
  }

  Widget _buildExerciseView() {
    final duration = _recommendedParams['duration'] ?? 30;
    final intensity = _recommendedParams['intensity'] ?? 0.7;
    final calories = _recommendedParams['calories'] ?? 300;
    final exerciseType = _getExerciseType(_recommendedParams['type'] ?? 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ready to Exercise',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Your personalized exercise recommendation is ready.',
          style: TextStyle(fontSize: 16, color: AppColors.textLight),
        ),

        const SizedBox(height: 32),

        // Recommended workout card
        Container(
          padding: const EdgeInsets.all(24),
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
                  Icon(
                    _getExerciseIcon(exerciseType),
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Recommended $exerciseType',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    icon: Icons.timer,
                    value: '$duration min',
                    label: 'Duration',
                  ),
                  _buildStatItem(
                    icon: Icons.local_fire_department,
                    value: '$calories kcal',
                    label: 'Target Calories',
                  ),
                  _buildStatItem(
                    icon: Icons.speed,
                    value: '${(intensity * 10).toStringAsFixed(1)}',
                    label: 'Intensity',
                  ),
                ],
              ),
            ],
          ),
        ),

        const Spacer(),

        // Action buttons
        AppButton(
          text: 'Start Tracking',
          onPressed: _startTrackingSession,
          icon: Icons.play_arrow,
        ),
        const SizedBox(height: 16),
        AppButton(
          text: 'Custom Workout',
          onPressed: () => _showCustomWorkoutDialog(context),
          isSecondary: true,
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  void _showCustomWorkoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Custom Workout'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Feature coming soon!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'In the future, you\'ll be able to create custom workout plans here.',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  String _getExerciseType(int type) {
    switch (type) {
      case 0:
        return 'Walking';
      case 1:
        return 'Running';
      case 2:
        return 'Cycling';
      case 3:
        return 'Rowing';
      default:
        return 'Walking';
    }
  }

  IconData _getExerciseIcon(String type) {
    switch (type) {
      case 'Walking':
        return Icons.directions_walk;
      case 'Running':
        return Icons.directions_run;
      case 'Cycling':
        return Icons.directions_bike;
      case 'Rowing':
        return Icons.rowing;
      default:
        return Icons.directions_walk;
    }
  }
}
