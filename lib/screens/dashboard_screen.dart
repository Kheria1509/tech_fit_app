import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String userName;
  final String userGender;
  final DateTime? userBirthday;
  final double userHeight;
  final double userWeight;

  const DashboardScreen({
    super.key,
    required this.userName,
    required this.userGender,
    this.userBirthday,
    required this.userHeight,
    required this.userWeight,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _selectedTimeRange = 'Day';
  List<String> timeRanges = ['Day', 'Week', 'Month'];

  // Data structures for different time ranges
  late Map<String, List<FlSpot>> heartRateData;
  late Map<String, List<FlSpot>> speedData;
  late Map<String, double> anaerobicThresholds;
  late Map<String, double> maxX;
  late Map<String, String> xAxisLabels;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    // Initialize data structures with more appropriate ranges
    heartRateData = {
      'Day': _generateDayHeartRateData(),
      'Week': _generateWeekHeartRateData(),
      'Month': _generateMonthHeartRateData(),
    };

    speedData = {
      'Day': _generateDaySpeedData(),
      'Week': _generateWeekSpeedData(),
      'Month': _generateMonthSpeedData(),
    };

    anaerobicThresholds = {
      'Day': 140.0,
      'Week': 142.0,
      'Month': 145.0,
    };

    maxX = {
      'Day': 23.0,
      'Week': 6.0,
      'Month': 29.0,
    };

    xAxisLabels = {
      'Day': 'h',
      'Week': 'd',
      'Month': 'd',
    };
  }

  // Updated data generators with more realistic variations
  List<FlSpot> _generateDayHeartRateData() {
    return List.generate(24, (i) {
      double baseHR = 75.0;
      // Simulate daily heart rate pattern
      double variation = 20 * sin((i - 6) * pi / 12); // Peak at noon, low at midnight
      return FlSpot(i.toDouble(), baseHR + variation + (_random() * 10));
    });
  }

  List<FlSpot> _generateWeekHeartRateData() {
    return List.generate(7, (i) {
      double baseHR = 130.0;
      // Higher HR on weekdays, lower on weekends
      double dayEffect = (i == 0 || i == 6) ? -10.0 : 0.0;
      return FlSpot(i.toDouble(), baseHR + dayEffect + (_random() * 20));
    });
  }

  List<FlSpot> _generateMonthHeartRateData() {
    return List.generate(30, (i) {
      double baseHR = 135.0;
      // Simulate training cycles
      double cycleEffect = 15 * sin(i * pi / 7); // Weekly training cycle
      return FlSpot(i.toDouble(), baseHR + cycleEffect + (_random() * 10));
    });
  }

  List<FlSpot> _generateDaySpeedData() {
    return List.generate(24, (i) {
      double baseSpeed = 8.0;
      // Lower speed at night, higher during day
      double timeEffect = 4 * sin((i - 4) * pi / 12);
      return FlSpot(i.toDouble(), baseSpeed + timeEffect + (_random() * 2));
    });
  }

  List<FlSpot> _generateWeekSpeedData() {
    return List.generate(7, (i) {
      double baseSpeed = 10.0;
      // Variation for different training days
      double dayEffect = (i % 2 == 0) ? 2.0 : -1.0;
      return FlSpot(i.toDouble(), baseSpeed + dayEffect + (_random() * 3));
    });
  }

  List<FlSpot> _generateMonthSpeedData() {
    return List.generate(30, (i) {
      double baseSpeed = 11.0;
      // Progressive improvement over month
      double progression = (i / 30) * 3;
      double variation = 2 * sin(i * pi / 3.5);
      return FlSpot(i.toDouble(), baseSpeed + progression + variation + (_random() * 1.5));
    });
  }

  double _random() {
    return (DateTime.now().microsecondsSinceEpoch % 100) / 100;
  }

  late ThemeData theme;
  final double borderRadius = 20.0;
  final double cardElevation = 4.0;
  final double defaultPadding = 16.0;

  Widget _buildThemeToggle(BuildContext context, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey[200],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton(
            isSelected: !isDarkMode,
            icon: Icons.wb_sunny_outlined,
            onTap: () => context.read<ThemeProvider>().toggleTheme(),
          ),
          _buildToggleButton(
            isSelected: isDarkMode,
            icon: Icons.nightlight_round,
            onTap: () => context.read<ThemeProvider>().toggleTheme(),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required bool isSelected,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected
              ? (icon == Icons.wb_sunny_outlined ? Colors.white : Colors.black)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isSelected
              ? (icon == Icons.wb_sunny_outlined ? Colors.black : Colors.white)
              : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: defaultPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: timeRanges.map((range) {
          final isSelected = range == _selectedTimeRange;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedTimeRange = range;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isSelected ? theme.primaryColor : Colors.grey[200],
                foregroundColor: isSelected ? Colors.white : Colors.black87,
                elevation: isSelected ? 2 : 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(borderRadius / 2),
                ),
                padding: EdgeInsets.symmetric(horizontal: defaultPadding),
              ),
              child: Text(range),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChart(BuildContext context) {
    final maxY = _selectedTimeRange == 'Day' ? 160.0 : 180.0;
    final minY = 0.0;
    final interval = _selectedTimeRange == 'Day' ? 20.0 : 30.0;
    final xInterval = _selectedTimeRange == 'Month' ? 5.0 : 
                     _selectedTimeRange == 'Week' ? 1.0 : 4.0;

    return AspectRatio(
      aspectRatio: 1.7,
      child: Container(
        padding: EdgeInsets.all(defaultPadding),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: LineChart(
          LineChartData(
            backgroundColor: theme.cardColor,
            minY: minY,
            maxY: maxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              horizontalInterval: interval,
              verticalInterval: xInterval,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: theme.dividerColor.withOpacity(0.2),
                  strokeWidth: 1,
                );
              },
              getDrawingVerticalLine: (value) {
                return FlLine(
                  color: theme.dividerColor.withOpacity(0.2),
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: TextStyle(
                        color: theme.textTheme.bodySmall?.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                  interval: interval,
                ),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value % xInterval != 0) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        '${value.toInt()}${xAxisLabels[_selectedTimeRange]}',
                        style: TextStyle(
                          color: theme.textTheme.bodySmall?.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  },
                  interval: 1,
                ),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(
                color: theme.dividerColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            lineBarsData: [
              // Heart Rate Line
              LineChartBarData(
                spots: heartRateData[_selectedTimeRange]!,
                isCurved: true,
                curveSmoothness: 0.35,
                color: Colors.red.shade400,
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      Colors.red.shade400.withOpacity(0.3),
                      Colors.red.shade400.withOpacity(0.05),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              // Speed Line
              LineChartBarData(
                spots: speedData[_selectedTimeRange]!,
                isCurved: true,
                curveSmoothness: 0.35,
                color: theme.primaryColor,
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      theme.primaryColor.withOpacity(0.3),
                      theme.primaryColor.withOpacity(0.05),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
            extraLinesData: ExtraLinesData(
              horizontalLines: [
                HorizontalLine(
                  y: anaerobicThresholds[_selectedTimeRange]!,
                  color: Colors.orange.shade400,
                  strokeWidth: 2,
                  dashArray: [5, 5],
                  label: HorizontalLineLabel(
                    show: true,
                    padding: const EdgeInsets.only(right: 8),
                    style: TextStyle(
                      color: Colors.orange.shade400,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    labelResolver: (line) => 'AT ${line.y.toInt()} BPM',
                    alignment: Alignment.topRight,
                  ),
                ),
              ],
            ),
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                tooltipBgColor: theme.cardColor.withOpacity(0.9),
                tooltipRoundedRadius: 10,
                tooltipPadding: const EdgeInsets.all(8),
                tooltipBorder: BorderSide(
                  color: theme.dividerColor,
                  width: 1,
                ),
                getTooltipItems: (List<LineBarSpot> touchedSpots) {
                  return touchedSpots.map((spot) {
                    final isHeartRate = spot.barIndex == 0;
                    return LineTooltipItem(
                      '${isHeartRate ? "Heart Rate: " : "Speed: "}${spot.y.toStringAsFixed(1)}${isHeartRate ? " BPM" : " km/h"}',
                      TextStyle(
                        color: isHeartRate
                            ? Colors.red.shade400
                            : theme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  }).toList();
                },
              ),
              getTouchedSpotIndicator: (barData, spotIndexes) {
                return spotIndexes.map((spotIndex) {
                  final color = barData.color ?? theme.primaryColor;
                  return TouchedSpotIndicatorData(
                    FlLine(
                      color: color.withOpacity(0.8),
                      strokeWidth: 2,
                      dashArray: [3, 3],
                    ),
                    FlDotData(
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 5,
                          color: color,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: defaultPadding / 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLegendItem('Heart Rate', Colors.red.shade400),
          SizedBox(width: defaultPadding * 1.25),
          _buildLegendItem('Speed', theme.primaryColor),
          SizedBox(width: defaultPadding * 1.25),
          _buildLegendItem('AT', Colors.orange.shade400),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: theme.textTheme.bodyMedium?.color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCardSection({
    required Widget child,
    EdgeInsetsGeometry? padding,
    double? height,
  }) {
    return Card(
      elevation: cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Container(
        width: double.infinity,
        height: height,
        padding: padding ?? EdgeInsets.all(defaultPadding),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          color: theme.cardColor,
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreeting(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.userName,
                          style: TextStyle(
                            fontSize: 16,
                            color: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Consumer<ThemeProvider>(
                          builder: (context, themeProvider, _) =>
                              _buildThemeToggle(
                                  context, themeProvider.isDarkMode),
                        ),
                        SizedBox(width: defaultPadding),
                        GestureDetector(
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProfileScreen(
                                  userName: widget.userName,
                                  userGender: widget.userGender,
                                  userBirthday: widget.userBirthday,
                                  userHeight: widget.userHeight,
                                  userWeight: widget.userWeight,
                                ),
                              ),
                            );
                            
                            if (result != null && mounted) {
                              // Update the navigation state with new user info
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DashboardScreen(
                                    userName: result['userName'],
                                    userGender: result['userGender'],
                                    userBirthday: result['userBirthday'],
                                    userHeight: result['userHeight'],
                                    userWeight: result['userWeight'],
                                  ),
                                ),
                              );
                            }
                          },
                          child: CircleAvatar(
                            backgroundColor: theme.primaryColor.withOpacity(0.1),
                            child: Icon(
                              Icons.person_outline,
                              color: theme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: defaultPadding * 1.5),
                // Training Card
                Container(
                  width: double.infinity,
                  height: screenSize.height * 0.2,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0xFF6C63FF),
                        Color(0xFF8B85FF),
                      ],
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        // Background decoration
                        Positioned(
                          right: -20,
                          bottom: -20,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                        ),
                        // Content
                        Row(
                          children: [
                            // Left side - Running Person
                            Expanded(
                              flex: 1,
                              child: TweenAnimationBuilder(
                                duration: const Duration(milliseconds: 1500),
                                tween: Tween<double>(begin: -0.1, end: 0.1),
                                builder: (context, double value, child) {
                                  return Transform.translate(
                                    offset: Offset(0, value * 8), // Bounce effect
                                    child: Transform.scale(
                                      scale: 1.0 + (value * 0.05), // Slight scaling
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 20),
                                        child: Image.asset(
                                          'assets/images/running.png',
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            // Right side - Text and Button
                            Expanded(
                              flex: 1,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 24.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Let's Start\nTraining",
                                      style: TextStyle(
                                        fontSize: 28,
                                        height: 1.2,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: () {
                                        // Handle start training
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: Color(0xFF6C63FF),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 32,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(50),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: const Text(
                                        'Start',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: defaultPadding * 1.5),
                // Gear Health Card
                _buildCardSection(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.health_and_safety,
                            color: theme.primaryColor,
                            size: 28,
                          ),
                          SizedBox(width: defaultPadding * 0.75),
                          Text(
                            "Gear Health Status",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: defaultPadding * 1.5),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: defaultPadding,
                          vertical: defaultPadding * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(borderRadius / 2),
                          border: Border.all(
                            color: Colors.green,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: defaultPadding * 0.75),
                            const Text(
                              "Healthy",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: defaultPadding),
                      Text(
                        "Last checked: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}",
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.textTheme.bodyMedium?.color
                              ?.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: defaultPadding * 1.5),
                // Performance Metrics Card
                _buildCardSection(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Performance Metrics',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      _buildTimeRangeSelector(),
                      _buildChart(context),
                      _buildLegend(),
                    ],
                  ),
                ),
                SizedBox(height: defaultPadding),
              ],
            ),
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
}
