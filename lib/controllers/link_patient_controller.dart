import 'package:supabase_flutter/supabase_flutter.dart';

class LinkPatientController {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> linkPatient(String patientId) async {
    final caregiver = _supabase.auth.currentUser;

    if (caregiver == null) {
      throw Exception('No logged-in caregiver found');
    }

    final patient = await _supabase
        .from('profiles')
        .select()
        .eq('id', patientId)
        .eq('role', 'patient')
        .maybeSingle();

    if (patient == null) {
      throw Exception('No patient found with this ID');
    }

    await _supabase.from('caregiver_patients').insert({
      'caregiver_id': caregiver.id,
      'patient_id': patientId,
    });
  }
}