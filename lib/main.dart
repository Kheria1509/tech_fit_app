import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

// Auth
import 'services/auth_service.dart';
import 'providers/user_provider.dart';
import 'providers/dashboard_provider.dart';

// Screens
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/user_info_screen.dart';
import 'screens/home_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/exercise_screen.dart';
import 'screens/device_tracking_screen.dart';
import 'screens/previous_sessions_screen.dart';
import 'screens/session_detail_screen.dart';
import 'screens/bluetooth_device_screen.dart';
import 'screens/dashboard_screen.dart';

// Theme
import 'theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'your-api-key', // Replace with actual values
      appId: 'your-app-id',
      messagingSenderId: 'your-sender-id',
      projectId: 'your-project-id',
      storageBucket: 'your-project-id.appspot.com', // Added storage bucket
    ),
  );

  runApp(const TechFitApp());
}

class TechFitApp extends StatelessWidget {
  const TechFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provide the authentication service
        Provider<AuthService>(create: (_) => AuthService()),
        // Provide the user data
        ChangeNotifierProxyProvider<AuthService, UserProvider>(
          create: (context) => UserProvider(),
          update:
              (context, authService, userProvider) =>
                  userProvider!..update(authService.currentUser),
        ),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
      ],
      child: MaterialApp(
        title: 'TechFit',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6b53ff),
            primary: const Color(0xFF6b53ff),
            secondary: const Color(0xFF00C9B9),
          ),
          textTheme: GoogleFonts.poppinsTextTheme(),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/user_info': (context) => const UserInfoScreen(),
          '/home': (context) => const HomeScreen(),
          '/stats': (context) => const StatsScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/bluetooth': (context) => const BluetoothDeviceScreen(),
          '/device_tracking': (context) => const DeviceTrackingScreen(),
          '/previous_sessions': (context) => const PreviousSessionsScreen(),
          '/dashboard': (context) => const DashboardScreen(),
        },
      ),
    );
  }
}

// This widget determines whether to show onboarding or home screen
// based on authentication state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Demo mode - skip authentication and directly show the home screen
    // Remove or set to false when using real authentication
    const bool demoMode = true;

    if (demoMode) {
      // Instead of calling refreshUserData() during build which causes setState issues,
      // we'll create and show the HomeScreen directly
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Create a UserProvider instance with mock data
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        // Create mock user after build is complete
        userProvider.refreshUserData();
      });
      return const HomeScreen();
    }

    final authService = Provider.of<AuthService>(context);

    // Listen to authentication state changes
    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // If user is authenticated
        if (snapshot.hasData) {
          // Check if user has completed profile setup
          return FutureBuilder(
            future: authService.hasUserCompletedSetup(),
            builder: (context, setupSnapshot) {
              if (setupSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // If user has completed profile setup, show home screen
              if (setupSnapshot.data == true) {
                return const HomeScreen();
              } else {
                // If user has not completed profile setup, show user info screen
                return const UserInfoScreen();
              }
            },
          );
        }

        // If user is not authenticated, show onboarding screen
        return const OnboardingScreen();
      },
    );
  }
}
