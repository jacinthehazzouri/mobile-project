import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/dose_model.dart';
import '../models/profile_model.dart';

class PatientDashboardController {
  final SupabaseClient _supabase = Supabase.instance.client;

  String getCurrentPatientId() {
    return _supabase.auth.currentUser?.id ?? 'Unknown';
  }

  Future<ProfileModel> getProfile() async {
    final userId = _supabase.auth.currentUser!.id;

    final data = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();

    return ProfileModel.fromJson(data);
  }

  Future<bool> isLinkedToCaregiver() async {
    final userId = _supabase.auth.currentUser!.id;

    final response = await _supabase
        .from('caregiver_patients')
        .select('caregiver_id')
        .eq('patient_id', userId)
        .limit(1);

    return response.isNotEmpty;
  }

  Future<List<DoseModel>> getPatientDoses() async {
    final userId = _supabase.auth.currentUser!.id;

    final response = await _supabase
        .from('doses')
        .select()
        .eq('patient_id', userId)
        .eq('active', true)
        .order('scheduled_time', ascending: true);

    return List<Map<String, dynamic>>.from(response)
        .map((map) => DoseModel.fromMap(map))
        .toList();
  }

  List<DoseModel> filterDosesByDay(List<DoseModel> doses, String selectedDay) {
    final filteredDoses = doses.where((dose) {
      return dose.days.contains(selectedDay);
    }).toList();

    filteredDoses.sort((a, b) {
      return a.scheduledTime.compareTo(b.scheduledTime);
    });

    return filteredDoses;
  }

  Future<DoseModel?> getNextDose(String selectedDay) async {
    final doses = await getPatientDoses();
    final filteredDoses = filterDosesByDay(doses, selectedDay);

    if (filteredDoses.isEmpty) return null;

    return filteredDoses.first;
  }
}