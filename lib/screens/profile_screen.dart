import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'create_account_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userName;
  final String userGender;
  final DateTime? userBirthday;
  final double userHeight;
  final double userWeight;

  const ProfileScreen({
    super.key,
    required this.userName,
    required this.userGender,
    this.userBirthday,
    required this.userHeight,
    required this.userWeight,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late String _selectedGender;
  late DateTime? _selectedDate;
  late double _height;
  late double _weight;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userName);
    _selectedGender = widget.userGender;
    _selectedDate = widget.userBirthday;
    _height = widget.userHeight;
    _weight = widget.userWeight;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 16.0),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).hintColor,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardDecoration = BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          spreadRadius: 1,
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        title: Text(
          'Profile',
          style: TextStyle(
            color: theme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const CreateAccountScreen(),
                ),
                (route) => false,
              );
            },
            icon: Icon(
              Icons.logout_rounded,
              color: theme.colorScheme.error,
              size: 20,
            ),
            label: Text(
              'Sign Out',
              style: TextStyle(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: cardDecoration,
                  child: Row(
                    children: [
                      Hero(
                        tag: 'profile-avatar',
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: theme.primaryColor.withOpacity(0.1),
                          child: Icon(
                            Icons.person_rounded,
                            size: 40,
                            color: theme.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.userName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Edit your personal details',
                              style: TextStyle(
                                color: theme.hintColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Personal Information Section
                _buildSectionHeader('Personal Information'),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: cardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFormField(
                        label: 'Name',
                        child: TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            hintText: 'Enter your name',
                            filled: true,
                            fillColor: theme.inputDecorationTheme.fillColor ?? 
                                theme.scaffoldBackgroundColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: theme.dividerColor,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: theme.primaryColor,
                                width: 2,
                              ),
                            ),
                            prefixIcon: Icon(
                              Icons.person_outline_rounded,
                              color: theme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                      _buildFormField(
                        label: 'Birthday',
                        child: InkWell(
                          onTap: () => _selectDate(context),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: theme.inputDecorationTheme.fillColor ?? 
                                  theme.scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: theme.dividerColor,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  color: theme.primaryColor,
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _selectedDate == null
                                      ? 'Select your birthdate'
                                      : DateFormat('MMMM d, yyyy').format(_selectedDate!),
                                  style: TextStyle(
                                    color: _selectedDate == null
                                        ? theme.hintColor
                                        : theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      _buildFormField(
                        label: 'Gender',
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: theme.dividerColor,
                              width: 1,
                            ),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _selectedGender,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              filled: true,
                              fillColor: theme.inputDecorationTheme.fillColor ?? 
                                  theme.scaffoldBackgroundColor,
                              border: InputBorder.none,
                              prefixIcon: Icon(
                                Icons.people_outline_rounded,
                                color: theme.primaryColor,
                              ),
                            ),
                            items: ['Male', 'Female', 'Other'].map((gender) {
                              return DropdownMenuItem(
                                value: gender,
                                child: Text(gender),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedGender = value;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Physical Information Section
                _buildSectionHeader('Physical Information'),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: cardDecoration,
                  child: Column(
                    children: [
                      // Height
                      _buildFormField(
                        label: 'Height',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('50 cm'),
                                Text(
                                  '${_height.round()} cm',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: theme.primaryColor,
                                  ),
                                ),
                                const Text('250 cm'),
                              ],
                            ),
                            SliderTheme(
                              data: SliderThemeData(
                                activeTrackColor: theme.primaryColor,
                                inactiveTrackColor: theme.primaryColor.withOpacity(0.2),
                                thumbColor: theme.primaryColor,
                                trackHeight: 4,
                                overlayColor: theme.primaryColor.withOpacity(0.2),
                              ),
                              child: Slider(
                                value: _height,
                                min: 50,
                                max: 250,
                                divisions: 200,
                                onChanged: (value) {
                                  setState(() {
                                    _height = value;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Weight
                      _buildFormField(
                        label: 'Weight',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('20 kg'),
                                Text(
                                  '${_weight.round()} kg',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: theme.primaryColor,
                                  ),
                                ),
                                const Text('200 kg'),
                              ],
                            ),
                            SliderTheme(
                              data: SliderThemeData(
                                activeTrackColor: theme.primaryColor,
                                inactiveTrackColor: theme.primaryColor.withOpacity(0.2),
                                thumbColor: theme.primaryColor,
                                trackHeight: 4,
                                overlayColor: theme.primaryColor.withOpacity(0.2),
                              ),
                              child: Slider(
                                value: _weight,
                                min: 20,
                                max: 200,
                                divisions: 180,
                                onChanged: (value) {
                                  setState(() {
                                    _weight = value;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Save Button
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, {
                        'userName': _nameController.text,
                        'userGender': _selectedGender,
                        'userBirthday': _selectedDate,
                        'userHeight': _height,
                        'userWeight': _weight,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(double.infinity, 54),
                    ),
                    child: const Text(
                      'SAVE CHANGES',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}