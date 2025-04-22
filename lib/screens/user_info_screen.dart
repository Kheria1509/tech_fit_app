import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../main.dart';

class UserInfoScreen extends StatefulWidget {
  const UserInfoScreen({super.key});

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  DateTime? _selectedDate;
  String _selectedGender = 'Male';
  double _height = 180;
  double _weight = 80;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'Give us some basic information',
          style: TextStyle(
            color: theme.textTheme.bodyLarge?.color,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            Text(
              'Birthday',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _selectDate(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedDate == null
                          ? 'Select Date'
                          : DateFormat('MMM dd, yyyy').format(_selectedDate!),
                      style: TextStyle(
                        fontSize: 16,
                        color: _selectedDate == null
                            ? theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.5)
                            : theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    Icon(Icons.calendar_today,
                        color: theme.textTheme.bodyMedium?.color
                            ?.withOpacity(0.5)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Gender',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            // Updated Gender Selection UI
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedGender = 'Male'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.transparent,
                        ),
                      ),
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.topRight,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: _selectedGender == 'Male'
                                      ? (isDarkMode
                                          ? const Color(0xFF2C2C2C)
                                          : Colors.grey.shade200)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.man_outlined,
                                      size: 32,
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Male',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_selectedGender == 'Male')
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF0E1B33),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedGender = 'Female'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.transparent,
                        ),
                      ),
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.topRight,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: _selectedGender == 'Female'
                                      ? (isDarkMode
                                          ? const Color(0xFF2C2C2C)
                                          : Colors.grey.shade200)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.woman_outlined,
                                      size: 32,
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Female',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_selectedGender == 'Female')
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF0E1B33),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Height',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                Text(
                  '${_height.round()}cm',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.height, size: 20, color: theme.iconTheme.color),
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 12,
                          ),
                          overlayShape: SliderComponentShape.noOverlay,
                          trackHeight: 2,
                        ),
                        child: Slider(
                          value: _height,
                          min: 50,
                          max: 500,
                          divisions: 450,
                          activeColor: const Color(0xFF0E1B33),
                          inactiveColor: Colors.grey.shade300,
                          onChanged: (value) {
                            setState(() {
                              _height = value;
                            });
                          },
                        ),
                      ),
                    ),
                    Icon(Icons.height, size: 24, color: theme.iconTheme.color),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '50cm',
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                    Text(
                      '500cm',
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Weight',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                Text(
                  '${_weight.round()}kg',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.person_outline,
                        size: 20, color: theme.iconTheme.color),
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 12,
                          ),
                          overlayShape: SliderComponentShape.noOverlay,
                          trackHeight: 2,
                        ),
                        child: Slider(
                          value: _weight,
                          min: 20,
                          max: 200,
                          divisions: 180,
                          activeColor: const Color(0xFF0E1B33),
                          inactiveColor: Colors.grey.shade300,
                          onChanged: (value) {
                            setState(() {
                              _weight = value;
                            });
                          },
                        ),
                      ),
                    ),
                    Icon(Icons.person_outline,
                        size: 24, color: theme.iconTheme.color),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '20kg',
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                    Text(
                      '200kg',
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Handle next step
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0E1B33),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Next',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// Custom Widgets for Height Icons
class _PersonIcon extends StatelessWidget {
  final bool small;

  const _PersonIcon({required this.small});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      child: Column(
        children: [
          Container(
            width: small ? 10 : 12,
            height: small ? 10 : 12,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF0E1B33),
            ),
          ),
          Container(
            width: small ? 2 : 3,
            height: small ? 14 : 22,
            color: const Color(0xFF0E1B33),
          ),
          Transform.translate(
            offset: const Offset(0, -4),
            child: Container(
              width: small ? 8 : 16,
              height: small ? 10 : 14,
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                      color: const Color(0xFF0E1B33), width: small ? 2 : 3),
                  right: BorderSide(
                      color: const Color(0xFF0E1B33), width: small ? 2 : 3),
                  bottom: BorderSide(
                      color: const Color(0xFF0E1B33), width: small ? 2 : 3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Widgets for Weight Icons
class _WeightIcon extends StatelessWidget {
  final bool small;

  const _WeightIcon({required this.small});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      child: small
          ? const Icon(
              Icons.person_outline,
              size: 20,
              color: Color(0xFF0E1B33),
            )
          : const Icon(
              Icons.person_outline,
              size: 24,
              color: Color(0xFF0E1B33),
            ),
    );
  }
}
