import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'theme/app_theme.dart';
import 'views/login_view.dart';
import 'views/patient_dashboard_view.dart';
import 'views/caregiver_dashboard_view.dart';
import 'views/reset_password_view.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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

class SmartMedBoxApp extends StatefulWidget {
  final bool isLoggedIn;
  final String? role;

  const SmartMedBoxApp({
    super.key,
    required this.isLoggedIn,
    required this.role,
  });

  @override
  State<SmartMedBoxApp> createState() => _SmartMedBoxAppState();
}

class _SmartMedBoxAppState extends State<SmartMedBoxApp> {
  late final AppLinks appLinks;
  StreamSubscription<Uri>? linkSubscription;

  @override
  void initState() {
    super.initState();

    appLinks = AppLinks();
    listenToDeepLinks();
    listenToPasswordRecovery();
  }

  void listenToDeepLinks() {
    linkSubscription = appLinks.uriLinkStream.listen((uri) {
      if (uri.scheme == 'io.supabase.smartmedbox' &&
          uri.host == 'reset-password') {
        openResetPasswordPage();
      }
    });
  }

  void listenToPasswordRecovery() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        openResetPasswordPage();
      }
    });
  }

  void openResetPasswordPage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => const ResetPasswordView(),
        ),
      );
    });
  }

  @override
  void dispose() {
    linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget startPage;

    if (!widget.isLoggedIn) {
      startPage = const LoginView();
    } else if (widget.role == 'caregiver') {
      startPage = const CaregiverDashboardView();
    } else {
      startPage = const PatientDashboardView();
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart MedBox',
      theme: AppTheme.lightTheme,
      navigatorKey: navigatorKey,
      home: startPage,
    );
  }
}