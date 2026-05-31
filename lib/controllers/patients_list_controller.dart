import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/patient_list_model.dart';

class PatientsListController {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<PatientListModel>> getPatients() async {
    final caregiverId = _supabase.auth.currentUser!.id;

    final response = await _supabase
        .from('caregiver_patients')
        .select(
      'patient_id, profiles!caregiver_patients_patient_id_fkey(id,name,phone)',
    )
        .eq('caregiver_id', caregiverId);

    return List<Map<String, dynamic>>.from(response).map((item) {
      return PatientListModel.fromMap(
        item['profiles'] as Map<String, dynamic>,
      );
    }).toList();
  }

  Future<void> removePatient(String patientId) async {
    final caregiverId = _supabase.auth.currentUser!.id;

    await _supabase
        .from('caregiver_patients')
        .delete()
        .eq('caregiver_id', caregiverId)
        .eq('patient_id', patientId);
  }
}