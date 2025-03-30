import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../utils/app_constants.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App bar with back button and title
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.textDark,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Training Stats',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Empty space to balance the back button
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Month selection
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'March 2025',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Calories and training time chart
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildCaloriesChart(),
              ),
            ),

            // Heart rate chart
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildHeartRateChart(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaloriesChart() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Legend
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildLegendItem(AppColors.primary, 'Training time'),
                    const SizedBox(width: 24),
                    _buildLegendItem(AppColors.secondary, 'Calories'),
                    const SizedBox(width: 24),
                    _buildLegendItem(Colors.red, 'Heart rate'),
                  ],
                ),
              ),
            ),

            // Chart with axes
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Y-axis labels (kcal)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'kcal',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textLight,
                        ),
                      ),
                      const Spacer(),
                      ...List.generate(6, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 15.0),
                          child: Text(
                            '${(6 - index) * 100}',
                            style: const TextStyle(
                              fontSize: 8,
                              color: AppColors.textLight,
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 15),
                    ],
                  ),

                  const SizedBox(width: 4),

                  // Chart
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 15.0),
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          minX: 0,
                          maxX: 30,
                          minY: 0,
                          maxY: 600,
                          lineBarsData: [
                            // Calories line
                            LineChartBarData(
                              spots: [
                                const FlSpot(0, 200),
                                const FlSpot(5, 300),
                                const FlSpot(10, 250),
                                const FlSpot(15, 350),
                                const FlSpot(20, 400),
                                const FlSpot(25, 350),
                                const FlSpot(30, 500),
                              ],
                              isCurved: true,
                              color: AppColors.secondary,
                              barWidth: 2,
                              isStrokeCapRound: true,
                              belowBarData: BarAreaData(
                                show: true,
                                color: AppColors.secondary.withOpacity(0.2),
                              ),
                              dotData: const FlDotData(show: false),
                            ),

                            // Training time line
                            LineChartBarData(
                              spots: [
                                const FlSpot(0, 300),
                                const FlSpot(5, 350),
                                const FlSpot(10, 280),
                                const FlSpot(15, 420),
                                const FlSpot(20, 500),
                                const FlSpot(25, 450),
                                const FlSpot(30, 580),
                              ],
                              isCurved: true,
                              color: AppColors.primary,
                              barWidth: 2,
                              isStrokeCapRound: true,
                              belowBarData: BarAreaData(
                                show: true,
                                color: AppColors.primary.withOpacity(0.2),
                              ),
                              dotData: const FlDotData(show: false),
                            ),
                          ],
                          lineTouchData: const LineTouchData(enabled: false),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 4),

                  // Right Y-axis (gym)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'min',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textLight,
                        ),
                      ),
                      const Spacer(),
                      ...List.generate(6, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 15.0),
                          child: Text(
                            '${(6 - index) * 10}',
                            style: const TextStyle(
                              fontSize: 8,
                              color: AppColors.textLight,
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 15),
                    ],
                  ),
                ],
              ),
            ),

            // X-axis labels (days)
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 10, top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '0',
                    style: TextStyle(fontSize: 8, color: AppColors.textLight),
                  ),
                  const Text(
                    '5',
                    style: TextStyle(fontSize: 8, color: AppColors.textLight),
                  ),
                  const Text(
                    '10',
                    style: TextStyle(fontSize: 8, color: AppColors.textLight),
                  ),
                  const Text(
                    '15',
                    style: TextStyle(fontSize: 8, color: AppColors.textLight),
                  ),
                  const Text(
                    '20',
                    style: TextStyle(fontSize: 8, color: AppColors.textLight),
                  ),
                  const Text(
                    '25',
                    style: TextStyle(fontSize: 8, color: AppColors.textLight),
                  ),
                  const Text(
                    '30',
                    style: TextStyle(fontSize: 8, color: AppColors.textLight),
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.only(left: 20.0, top: 2),
              child: Text(
                'Day',
                style: TextStyle(fontSize: 10, color: AppColors.textLight),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeartRateChart() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Heart rate label
            const Text(
              'Heart Rate',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark,
              ),
            ),

            const SizedBox(height: 8),

            // Chart with y-axis
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Y-axis labels
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'bpm',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textLight,
                        ),
                      ),
                      const Spacer(),
                      ...List.generate(4, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: Text(
                            '${(4 - index) * 50}',
                            style: const TextStyle(
                              fontSize: 8,
                              color: AppColors.textLight,
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 15),
                    ],
                  ),

                  const SizedBox(width: 4),

                  // Chart
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 15.0),
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          minX: 0,
                          maxX: 30,
                          minY: 0,
                          maxY: 200,
                          lineBarsData: [
                            // Heart rate line
                            LineChartBarData(
                              spots: [
                                const FlSpot(0, 50),
                                const FlSpot(5, 100),
                                const FlSpot(10, 150),
                                const FlSpot(15, 120),
                                const FlSpot(20, 180),
                                const FlSpot(25, 140),
                                const FlSpot(30, 200),
                              ],
                              isCurved: true,
                              color: Colors.red.shade400,
                              barWidth: 2,
                              isStrokeCapRound: true,
                              belowBarData: BarAreaData(
                                show: true,
                                color: Colors.red.shade100,
                              ),
                              dotData: const FlDotData(show: false),
                            ),
                          ],
                          lineTouchData: const LineTouchData(enabled: false),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // X-axis labels
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 10, top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '0',
                    style: TextStyle(fontSize: 8, color: AppColors.textLight),
                  ),
                  const Text(
                    '5',
                    style: TextStyle(fontSize: 8, color: AppColors.textLight),
                  ),
                  const Text(
                    '10',
                    style: TextStyle(fontSize: 8, color: AppColors.textLight),
                  ),
                  const Text(
                    '15',
                    style: TextStyle(fontSize: 8, color: AppColors.textLight),
                  ),
                  const Text(
                    '20',
                    style: TextStyle(fontSize: 8, color: AppColors.textLight),
                  ),
                  const Text(
                    '25',
                    style: TextStyle(fontSize: 8, color: AppColors.textLight),
                  ),
                  const Text(
                    '30',
                    style: TextStyle(fontSize: 8, color: AppColors.textLight),
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.only(left: 20.0, top: 2),
              child: Text(
                'min',
                style: TextStyle(fontSize: 10, color: AppColors.textLight),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
