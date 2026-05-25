import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'theme/app_theme.dart';
import 'views/home_view.dart';
import 'views/login_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://qhvbcjjlmgomvvpkdoba.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFodmJjampsbWdvbXZ2cGtkb2JhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkxODE1MzcsImV4cCI6MjA5NDc1NzUzN30.WHUAtcEA55D-DnbjpbrIYlXBcM3dhFzxA_wvorhyxtY',
  );

  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(
    SmartMedBoxApp(isLoggedIn: isLoggedIn),
  );
}

class SmartMedBoxApp extends StatelessWidget {
  final bool isLoggedIn;

  const SmartMedBoxApp({
    super.key,
    required this.isLoggedIn,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart MedBox',
      theme: AppTheme.lightTheme,
      home: isLoggedIn
          ? const HomeView()
          : const LoginView(),
    );
  }
}