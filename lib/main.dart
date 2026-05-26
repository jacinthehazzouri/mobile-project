import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'theme/app_theme.dart';
import 'views/login_view.dart';
import 'views/patient_dashboard_view.dart';
import 'views/caregiver_dashboard_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://qhvbcjjlmgomvvpkdoba.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFodmJjampsbWdvbXZ2cGtkb2JhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkxODE1MzcsImV4cCI6MjA5NDc1NzUzN30.WHUAtcEA55D-DnbjpbrIYlXBcM3dhFzxA_wvorhyxtY',
  );

  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final role = prefs.getString('role');

  runApp(
    SmartMedBoxApp(
      isLoggedIn: isLoggedIn,
      role: role,
    ),
  );
}

class SmartMedBoxApp extends StatelessWidget {
  final bool isLoggedIn;
  final String? role;

  const SmartMedBoxApp({
    super.key,
    required this.isLoggedIn,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    Widget startPage;

    if (!isLoggedIn) {
      startPage = const LoginView();
    } else if (role == 'caregiver') {
      startPage = const CaregiverDashboardView();
    } else {
      startPage = const PatientDashboardView();
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart MedBox',
      theme: AppTheme.lightTheme,
      home: startPage,
    );
  }
}