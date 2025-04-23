import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/create_account_screen.dart';
import 'screens/dashboard_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Login App',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const CreateAccountScreen(),
          routes: {
            '/dashboard': (context) {
              final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
              return DashboardScreen(
                userName: args['userName'] ?? '',
                userGender: args['userGender'] ?? '',
                userBirthday: args['userBirthday'],
                userHeight: args['userHeight'] ?? 180.0,
                userWeight: args['userWeight'] ?? 80.0,
              );
            },
          },
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
