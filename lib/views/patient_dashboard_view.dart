import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_theme.dart';
import 'login_view.dart';
import 'manage_profile_view.dart';

class PatientDashboardView extends StatefulWidget {
  const PatientDashboardView({super.key});

  @override
  State<PatientDashboardView> createState() => _PatientDashboardViewState();
}

class _PatientDashboardViewState extends State<PatientDashboardView> {
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
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      await Supabase.instance.client.auth.signOut();

      if (!context.mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginView()),
            (route) => false,
      );
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;

    return await Supabase.instance.client
        .from('profiles')
        .select('name')
        .eq('id', userId)
        .single();
  }

  Future<List<Map<String, dynamic>>> getPatientDoses() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;

    final response = await Supabase.instance.client
        .from('doses')
        .select()
        .eq('patient_id', userId)
        .eq('active', true)
        .order('scheduled_time', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  List<Map<String, dynamic>> filterDosesByDay(
      List<Map<String, dynamic>> doses,
      ) {
    final filteredDoses = doses.where((dose) {
      final days = dose['days']?.toString() ?? '';
      return days.contains(selectedDay);
    }).toList();

    filteredDoses.sort((a, b) {
      return a['scheduled_time']
          .toString()
          .compareTo(b['scheduled_time'].toString());
    });

    return filteredDoses;
  }

  Future<Map<String, dynamic>?> getNextDose() async {
    final doses = await getPatientDoses();
    final filteredDoses = filterDosesByDay(doses);

    if (filteredDoses.isEmpty) return null;

    return filteredDoses.first;
  }

  String formatTime(dynamic value) {
    if (value == null) return 'N/A';

    final time = value.toString();

    if (time.length >= 5) {
      return time.substring(0, 5);
    }

    return time;
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
    return FutureBuilder<Map<String, dynamic>?>(
      future: getNextDose(),
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
                  '${dose['label'] ?? 'Medicine'} • ${dose['dosage'] ?? 'No dosage'} • ${formatTime(dose['scheduled_time'])}',
                  style: const TextStyle(color: Colors.white70, fontSize: 15),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget medicationsList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: getPatientDoses(),
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
          return Text(
            'Error loading medications: ${snapshot.error}',
            style: const TextStyle(color: Colors.red),
          );
        }

        final allDoses = snapshot.data ?? [];
        final doses = filterDosesByDay(allDoses);

        if (doses.isEmpty) {
          return Text(
            'No medications scheduled for $selectedDay.',
            style: const TextStyle(color: AppTheme.textLight, fontSize: 15),
          );
        }

        return Column(
          children: doses.map((dose) {
            final label = dose['label'] ?? 'Unnamed medicine';
            final dosage = dose['dosage'] ?? 'No dosage';
            final scheduledTime = formatTime(dose['scheduled_time']);
            final days = dose['days'] ?? 'No days';
            final instructions = dose['instructions'];

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
                          label,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ),
                      Text(
                        scheduledTime,
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
                    'Dosage: $dosage',
                    style: const TextStyle(color: AppTheme.textLight),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Days: $days',
                    style: const TextStyle(color: AppTheme.textLight),
                  ),
                  if (instructions != null &&
                      instructions.toString().trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Instructions: $instructions',
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
    final patientId =
        Supabase.instance.client.auth.currentUser?.id ?? 'Unknown';

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<Map<String, dynamic>>(
              future: getProfile(),
              builder: (context, snapshot) {
                final name = snapshot.hasData ? snapshot.data!['name'] : '';

                return Text(
                  name == '' ? 'Hi 👋' : 'Hi $name 👋',
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
              'Share your Patient ID with your caregiver.',
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
                    'Your Patient ID',
                    style: TextStyle(color: AppTheme.textLight, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    patientId,
                    style: const TextStyle(
                      color: AppTheme.textDark,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
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
        ),
      ),
    );
  }
}