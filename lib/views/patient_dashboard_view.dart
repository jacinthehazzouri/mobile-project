import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers/auth_controller.dart';
import '../controllers/patient_dashboard_controller.dart';
import '../models/dose_model.dart';
import '../models/profile_model.dart';
import '../theme/app_theme.dart';

import 'login_view.dart';
import 'manage_profile_view.dart';
import 'patient_detail_view.dart';
import 'medbot_view.dart';

class PatientDashboardView extends StatefulWidget {
  const PatientDashboardView({super.key});

  @override
  State<PatientDashboardView> createState() => _PatientDashboardViewState();
}

class _PatientDashboardViewState extends State<PatientDashboardView> {
  final PatientDashboardController patientDashboardController =
  PatientDashboardController();

  final AuthController authController = AuthController();

  String selectedDay = 'Mon';

  final List<String> weekDays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  Future<void> logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Center(
            child: Text(
              'Logout',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.logout, color: AppTheme.primary, size: 60),
              const SizedBox(height: 16),
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
                    width: 110,
                    height: 45,
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

  String formatTime(String value) {
    if (value.length >= 5) {
      return value.substring(0, 5);
    }

    return value;
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

  Widget dayFilterChips() {
    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: weekDays.length,
        itemBuilder: (context, index) {
          final day = weekDays[index];
          final isSelected = selectedDay == day;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(day),
              selected: isSelected,
              selectedColor: AppTheme.primary,
              backgroundColor: AppTheme.cardColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textDark,
                fontWeight: FontWeight.bold,
              ),
              onSelected: (_) {
                setState(() {
                  selectedDay = day;
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget nextDoseCard() {
    return FutureBuilder<DoseModel?>(
      future: patientDashboardController.getNextDose(selectedDay),
      builder: (context, snapshot) {
        final dose = snapshot.data;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.medication_liquid,
                color: Colors.white,
                size: 46,
              ),
              const SizedBox(height: 18),
              Text(
                'Next Dose on $selectedDay',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Text(
                  'Loading next dose...',
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                )
              else if (dose == null)
                Text(
                  'No doses scheduled for $selectedDay.',
                  style: const TextStyle(color: Colors.white70, fontSize: 15),
                )
              else
                Text(
                  '${dose.label} • ${dose.dosage ?? 'No dosage'} • ${formatTime(dose.scheduledTime)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 15),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget manageMedicinesButton(String patientId, String patientName) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.medical_services_outlined),
        label: const Text('Manage My Medicines & Medical Info'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) {
                return PatientDetailView(
                  patientId: patientId,
                  patientName: patientName,
                );
              },
            ),
          ).then((_) {
            setState(() {});
          });
        },
      ),
    );
  }

  Widget manageMedicinesButtonSection(String patientId, String patientName) {
    return FutureBuilder<bool>(
      future: patientDashboardController.isLinkedToCaregiver(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final linkedToCaregiver = snapshot.data ?? false;

        if (linkedToCaregiver) {
          return const SizedBox.shrink();
        }

        return manageMedicinesButton(patientId, patientName);
      },
    );
  }

  Widget medicationsList() {
    return FutureBuilder<List<DoseModel>>(
      future: patientDashboardController.getPatientDoses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return const Text(
            'Error loading medications.',
            style: TextStyle(color: Colors.red),
          );
        }

        final allDoses = snapshot.data ?? [];
        final doses = patientDashboardController.filterDosesByDay(
          allDoses,
          selectedDay,
        );

        if (doses.isEmpty) {
          return Text(
            'No medications scheduled for $selectedDay.',
            style: const TextStyle(
              color: AppTheme.textLight,
              fontSize: 15,
            ),
          );
        }

        return Column(
          children: doses.map((dose) {
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.medication_outlined,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          dose.label,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ),
                      Text(
                        formatTime(dose.scheduledTime),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Dosage: ${dose.dosage ?? 'No dosage'}',
                    style: const TextStyle(color: AppTheme.textLight),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Days: ${dose.days}',
                    style: const TextStyle(color: AppTheme.textLight),
                  ),
                  if (dose.instructions != null &&
                      dose.instructions!.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Instructions: ${dose.instructions}',
                      style: const TextStyle(color: AppTheme.textDark),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final patientId = patientDashboardController.getCurrentPatientId();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Patient Dashboard'),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MedBotView()),
        ),
        backgroundColor: AppTheme.primary,
        tooltip: 'Ask MedBot',
        child: const Icon(Icons.smart_toy_outlined, color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: FutureBuilder<ProfileModel>(
          future: patientDashboardController.getProfile(),
          builder: (context, profileSnapshot) {
            final patientName = profileSnapshot.hasData
                ? profileSnapshot.data!.name
                : 'My Profile';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patientName.isEmpty ? 'Hi 👋' : 'Hi $patientName 👋',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Share your Patient ID with your caregiver.',
                  style: TextStyle(
                    color: AppTheme.textLight,
                    fontSize: 16,
                  ),
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
                        'Your Patient ID',
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
                              patientId,
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
                                ClipboardData(text: patientId),
                              );

                              showToast('ID copied');
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                manageMedicinesButtonSection(patientId, patientName),
                const SizedBox(height: 24),
                dayFilterChips(),
                const SizedBox(height: 24),
                nextDoseCard(),
                const SizedBox(height: 28),
                Text(
                  '$selectedDay Medications',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 16),
                medicationsList(),
              ],
            );
          },
        ),
      ),
    );
  }
}