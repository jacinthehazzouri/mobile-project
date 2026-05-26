import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_theme.dart';

class PatientsListView extends StatefulWidget {
  const PatientsListView({super.key});

  @override
  State<PatientsListView> createState() => _PatientsListViewState();
}

class _PatientsListViewState extends State<PatientsListView> {
  final supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getLinkedPatients() async {
    final caregiver = supabase.auth.currentUser;

    if (caregiver == null) {
      throw Exception('No logged-in caregiver found');
    }

    final data = await supabase
        .from('caregiver_patients')
        .select('patient:profiles!caregiver_patients_patient_id_fkey(id, name, role, phone)')
        .eq('caregiver_id', caregiver.id);

    return List<Map<String, dynamic>>.from(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Patients List'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: getLinkedPatients(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final patients = snapshot.data ?? [];

          if (patients.isEmpty) {
            return const Center(
              child: Text(
                'No linked patients yet.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textLight,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: patients.length,
            itemBuilder: (context, index) {
              final patient = patients[index]['patient'];

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: Color(0xFFEFF6FF),
                      child: Icon(
                        Icons.person,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patient['name'] ?? 'Unknown Patient',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Phone: ${patient['phone'] ?? 'No phone'}',
                            style: const TextStyle(
                              color: AppTheme.textLight,
                            ),
                          ),
                          const SizedBox(height: 5),
                          SelectableText(
                            'ID: ${patient['id']}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}