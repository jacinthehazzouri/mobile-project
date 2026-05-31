import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers/auth_controller.dart';
import '../controllers/caregiver_dashboard_controller.dart';
import '../models/profile_model.dart';
import '../theme/app_theme.dart';

import 'link_patient_view.dart';
import 'login_view.dart';
import 'manage_profile_view.dart';
import 'patients_list_view.dart';

class CaregiverDashboardView extends StatefulWidget {
  const CaregiverDashboardView({super.key});

  @override
  State<CaregiverDashboardView> createState() => _CaregiverDashboardViewState();
}

class _CaregiverDashboardViewState extends State<CaregiverDashboardView> {
  final CaregiverDashboardController caregiverDashboardController =
  CaregiverDashboardController();

  final AuthController authController = AuthController();

  Future<void> logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text(
            'Logout',
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Are you sure you want to logout?',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 100,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Logout'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (shouldLogout == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      await authController.logout();

      if (!context.mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginView()),
            (route) => false,
      );
    }
  }

  void showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  Drawer profileDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            const CircleAvatar(
              radius: 42,
              backgroundColor: AppTheme.primary,
              child: Icon(Icons.person, size: 46, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              'Profile',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 30),
            ListTile(
              leading: const Icon(Icons.manage_accounts_outlined),
              title: const Text('Manage Profile Info'),
              onTap: () async {
                Navigator.pop(context);

                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ManageProfileView(),
                  ),
                );

                setState(() {});
              },
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                  onPressed: () {
                    Navigator.pop(context);
                    logout(context);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: const Color(0xFFEFF6FF),
              child: Icon(icon, color: AppTheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textLight,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 18),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final caregiverId = caregiverDashboardController.getCurrentCaregiverId();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Caregiver Dashboard'),
        actions: [
          Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.account_circle_outlined),
                onPressed: () {
                  Scaffold.of(context).openEndDrawer();
                },
              );
            },
          ),
        ],
      ),
      endDrawer: profileDrawer(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<ProfileModel>(
              future: caregiverDashboardController.getProfile(),
              builder: (context, snapshot) {
                final name = snapshot.hasData ? snapshot.data!.name : '';

                return Text(
                  name.isEmpty ? 'Hi 👋' : 'Hi $name 👋',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            const Text(
              'Link patients and monitor their medicine activity.',
              style: TextStyle(color: AppTheme.textLight, fontSize: 16),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Caregiver ID',
                    style: TextStyle(
                      color: AppTheme.textLight,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          caregiverId,
                          style: const TextStyle(
                            color: AppTheme.textDark,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        tooltip: 'Copy ID',
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: caregiverId),
                          );

                          showToast('ID copied');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.people_alt_outlined, color: Colors.white, size: 46),
                  SizedBox(height: 18),
                  Text(
                    'Patients Overview',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Link existing patients by their Patient ID.',
                    style: TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            actionCard(
              icon: Icons.link,
              title: 'Link Patient',
              subtitle: 'Connect an existing patient by ID',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LinkPatientView(),
                  ),
                );
              },
            ),
            actionCard(
              icon: Icons.list_alt,
              title: 'Patients List',
              subtitle: 'View and manage linked patients',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PatientsListView(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}