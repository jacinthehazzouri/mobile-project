import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import 'patient_detail_view.dart'; // ← new screen we create below

class PatientsListView extends StatefulWidget {
  const PatientsListView({super.key});

  @override
  State<PatientsListView> createState() => _PatientsListViewState();
}

class _PatientsListViewState extends State<PatientsListView> {
  final supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getLinkedPatients() async {
    final caregiver = supabase.auth.currentUser;
    if (caregiver == null) throw Exception('Not logged in');

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
      appBar: AppBar(title: const Text('My Patients')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: getLinkedPatients(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final patients = snapshot.data ?? [];

          if (patients.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline, size: 64,
                      color: AppTheme.textLight.withOpacity(0.4)),
                  const SizedBox(height: 16),
                  const Text('No linked patients yet.',
                      style: TextStyle(fontSize: 16, color: AppTheme.textLight)),
                  const SizedBox(height: 8),
                  const Text('Use "Link Patient" to add one.',
                      style: TextStyle(fontSize: 13, color: AppTheme.textLight)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: patients.length,
            itemBuilder: (context, index) {
              final patient = patients[index]['patient'];
              final patientId   = patient['id'] as String;
              final patientName = patient['name'] ?? 'Unknown';
              final patientPhone = patient['phone'] ?? 'No phone';

              return GestureDetector(
                // ── Tap → open patient detail screen ──────────
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PatientDetailView(
                        patientId:   patientId,
                        patientName: patientName,
                      ),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(22),
                    // Subtle shadow to indicate it's tappable
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppTheme.primary.withOpacity(0.1),
                        child: Text(
                          patientName.isNotEmpty
                              ? patientName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Name + phone
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(patientName,
                                style: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark,
                                )),
                            const SizedBox(height: 4),
                            Text(patientPhone,
                                style: const TextStyle(
                                    color: AppTheme.textLight, fontSize: 13)),
                          ],
                        ),
                      ),

                      // Arrow indicator — shows it's tappable
                      const Icon(Icons.arrow_forward_ios,
                          size: 16, color: AppTheme.textLight),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}