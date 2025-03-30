import 'package:cloud_firestore/cloud_firestore.dart';

enum Gender { male, female, other }

class UserModel {
  final String uid;
  final String name;
  final String email;
  final DateTime birthDate;
  final Gender gender;
  final double height; // in cm
  final double weight; // in kg
  final double targetWeight; // in kg
  final String? profileImageUrl;

  // Fitness metrics
  final int? maxHeartRate; // calculated or measured
  final double? vo2Max; // ml/kg/min
  final double? anaerobicThreshold; // heart rate at AT

  // Exercise history
  final List<ExerciseSession>? sessions;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.birthDate,
    required this.gender,
    required this.height,
    required this.weight,
    this.targetWeight = 0.0,
    this.profileImageUrl,
    this.maxHeartRate,
    this.vo2Max,
    this.anaerobicThreshold,
    this.sessions,
  });

  // Get age from birthdate
  int get age {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  // Calculate BMI
  double get bmi {
    return weight / ((height / 100) * (height / 100));
  }

  // Calculate estimated max heart rate if not available
  int get estimatedMaxHeartRate {
    return maxHeartRate ?? 220 - age;
  }

  // Convert to Map for storing in Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'birthDate': birthDate,
      'gender': gender.toString().split('.').last,
      'height': height,
      'weight': weight,
      'targetWeight': targetWeight,
      'profileImageUrl': profileImageUrl,
      'maxHeartRate': maxHeartRate,
      'vo2Max': vo2Max,
      'anaerobicThreshold': anaerobicThreshold,
      'sessions': sessions?.map((session) => session.toMap()).toList(),
    };
  }

  // Create UserModel from Map (Firestore document)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      name: map['name'],
      email: map['email'],
      birthDate: (map['birthDate'] as Timestamp).toDate(),
      gender: Gender.values.firstWhere(
        (g) => g.toString().split('.').last == map['gender'],
        orElse: () => Gender.other,
      ),
      height: map['height']?.toDouble() ?? 0.0,
      weight: map['weight']?.toDouble() ?? 0.0,
      targetWeight: map['targetWeight']?.toDouble() ?? 0.0,
      profileImageUrl: map['profileImageUrl'],
      maxHeartRate: map['maxHeartRate'],
      vo2Max: map['vo2Max']?.toDouble(),
      anaerobicThreshold: map['anaerobicThreshold']?.toDouble(),
      sessions:
          map['sessions'] != null
              ? List<ExerciseSession>.from(
                map['sessions'].map((x) => ExerciseSession.fromMap(x)),
              )
              : null,
    );
  }

  // Create copy of UserModel with some fields updated
  UserModel copyWith({
    String? name,
    DateTime? birthDate,
    Gender? gender,
    double? height,
    double? weight,
    double? targetWeight,
    String? profileImageUrl,
    int? maxHeartRate,
    double? vo2Max,
    double? anaerobicThreshold,
    List<ExerciseSession>? sessions,
  }) {
    return UserModel(
      uid: this.uid,
      name: name ?? this.name,
      email: this.email,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      targetWeight: targetWeight ?? this.targetWeight,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      maxHeartRate: maxHeartRate ?? this.maxHeartRate,
      vo2Max: vo2Max ?? this.vo2Max,
      anaerobicThreshold: anaerobicThreshold ?? this.anaerobicThreshold,
      sessions: sessions ?? this.sessions,
    );
  }
}

// Exercise session model to store workout data
class ExerciseSession {
  final String id;
  final DateTime date;
  final Duration duration;
  final double caloriesBurned;
  final double avgSpeed; // km/h
  final double maxSpeed; // km/h
  final double avgIncline; // degrees
  final double maxIncline; // degrees
  final int avgHeartRate; // bpm
  final int maxHeartRate; // bpm
  final double vo2Max; // ml/kg/min
  final int? anaerobicThresholdHeartRate; // heart rate at AT
  final double? anaerobicThresholdVo2; // VO2 at AT
  final List<ExerciseDataPoint>? dataPoints; // time series data

  ExerciseSession({
    required this.id,
    required this.date,
    required this.duration,
    required this.caloriesBurned,
    required this.avgSpeed,
    required this.maxSpeed,
    required this.avgIncline,
    required this.maxIncline,
    required this.avgHeartRate,
    required this.maxHeartRate,
    required this.vo2Max,
    this.anaerobicThresholdHeartRate,
    this.anaerobicThresholdVo2,
    this.dataPoints,
  });

  // Convert to Map for storing in Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'duration': duration.inSeconds,
      'caloriesBurned': caloriesBurned,
      'avgSpeed': avgSpeed,
      'maxSpeed': maxSpeed,
      'avgIncline': avgIncline,
      'maxIncline': maxIncline,
      'avgHeartRate': avgHeartRate,
      'maxHeartRate': maxHeartRate,
      'vo2Max': vo2Max,
      'anaerobicThresholdHeartRate': anaerobicThresholdHeartRate,
      'anaerobicThresholdVo2': anaerobicThresholdVo2,
      'dataPoints': dataPoints?.map((point) => point.toMap()).toList(),
    };
  }

  // Create ExerciseSession from Map (Firestore document)
  factory ExerciseSession.fromMap(Map<String, dynamic> map) {
    return ExerciseSession(
      id: map['id'],
      date: (map['date'] as Timestamp).toDate(),
      duration: Duration(seconds: map['duration']),
      caloriesBurned: map['caloriesBurned']?.toDouble() ?? 0.0,
      avgSpeed: map['avgSpeed']?.toDouble() ?? 0.0,
      maxSpeed: map['maxSpeed']?.toDouble() ?? 0.0,
      avgIncline: map['avgIncline']?.toDouble() ?? 0.0,
      maxIncline: map['maxIncline']?.toDouble() ?? 0.0,
      avgHeartRate: map['avgHeartRate'] ?? 0,
      maxHeartRate: map['maxHeartRate'] ?? 0,
      vo2Max: map['vo2Max']?.toDouble() ?? 0.0,
      anaerobicThresholdHeartRate: map['anaerobicThresholdHeartRate'],
      anaerobicThresholdVo2: map['anaerobicThresholdVo2']?.toDouble(),
      dataPoints:
          map['dataPoints'] != null
              ? List<ExerciseDataPoint>.from(
                map['dataPoints'].map((x) => ExerciseDataPoint.fromMap(x)),
              )
              : null,
    );
  }
}

// Time series data point for detailed exercise analysis
class ExerciseDataPoint {
  final DateTime timestamp;
  final double heartRate;
  final double speed;
  final double? incline;
  final double? vo2;
  final double calories;

  ExerciseDataPoint({
    required this.timestamp,
    required this.heartRate,
    required this.speed,
    this.incline,
    this.vo2,
    required this.calories,
  });

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.millisecondsSinceEpoch,
      'heartRate': heartRate,
      'speed': speed,
      'incline': incline,
      'vo2': vo2,
      'calories': calories,
    };
  }

  factory ExerciseDataPoint.fromMap(Map<String, dynamic> map) {
    return ExerciseDataPoint(
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      heartRate: (map['heartRate'] as num).toDouble(),
      speed: (map['speed'] as num).toDouble(),
      incline:
          map['incline'] != null ? (map['incline'] as num).toDouble() : null,
      vo2: map['vo2'] != null ? (map['vo2'] as num).toDouble() : null,
      calories: (map['calories'] as num).toDouble(),
    );
  }
}
