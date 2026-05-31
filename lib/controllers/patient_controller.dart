import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/dose_model.dart';
import '../models/medical_info_model.dart';
import '../models/dose_event_model.dart';

class PatientController {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<List<DoseModel>> getDoses(String patientId) async {
    final data = await supabase
        .from('doses')
        .select()
        .eq('patient_id', patientId)
        .eq('active', true)
        .order('scheduled_time', ascending: true);

    return List<Map<String, dynamic>>.from(data)
        .map((map) => DoseModel.fromMap(map))
        .toList();
  }

  Future<void> addDose({
    required String patientId,
    required String label,
    required String dosage,
    required String time,
    required String days,
    required String instructions,
  }) async {
    await supabase.from('doses').insert({
      'patient_id': patientId,
      'label': label,
      'dosage': dosage.isNotEmpty ? dosage : null,
      'scheduled_time': time,
      'days': days,
      'instructions': instructions.isNotEmpty ? instructions : null,
      'active': true,
    });
  }

  Future<void> updateDose({
    required String doseId,
    required String label,
    required String dosage,
    required String time,
    required String days,
    required String instructions,
  }) async {
    await supabase.from('doses').update({
      'label': label,
      'dosage': dosage.isNotEmpty ? dosage : null,
      'scheduled_time': time,
      'days': days,
      'instructions': instructions.isNotEmpty ? instructions : null,
    }).eq('id', doseId);
  }

  Future<void> deleteDose(String doseId) async {
    await supabase.from('doses').update({
      'active': false,
    }).eq('id', doseId);
  }

  Future<MedicalInfoModel?> getMedicalInfo(String patientId) async {
    final data = await supabase
        .from('medical_info')
        .select()
        .eq('patient_id', patientId)
        .maybeSingle();

    if (data == null) return null;

    return MedicalInfoModel.fromMap(data);
  }

  Future<void> saveMedicalInfo({
    required String patientId,
    int? age,
    required String bloodType,
    required String allergies,
    required String conditions,
    required String emergencyName,
    required String emergencyPhone,
    required String notes,
  }) async {
    await supabase.from('medical_info').upsert(
      {
        'patient_id': patientId,
        'age': age,
        'blood_type': bloodType.isNotEmpty ? bloodType : null,
        'allergies': allergies.isNotEmpty ? allergies : null,
        'conditions': conditions.isNotEmpty ? conditions : null,
        'emergency_name': emergencyName.isNotEmpty ? emergencyName : null,
        'emergency_phone': emergencyPhone.isNotEmpty ? emergencyPhone : null,
        'notes': notes.isNotEmpty ? notes : null,
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'patient_id',
    );
  }

  Future<List<DoseEventModel>> getHistory(String patientId) async {
    final data = await supabase
        .from('dose_events')
        .select('*, dose:doses(label)')
        .eq('patient_id', patientId)
        .order('created_at', ascending: false)
        .limit(30);

    return List<Map<String, dynamic>>.from(data)
        .map((map) => DoseEventModel.fromMap(map))
        .toList();
  }

  double adherencePercent(List<DoseEventModel> events, int days) {
    if (events.isEmpty) return 0;

    final from = DateTime.now().subtract(Duration(days: days));

    final recent = events.where((event) {
      final date = DateTime.tryParse(event.createdAt);
      return date != null && date.isAfter(from);
    }).toList();

    if (recent.isEmpty) return 0;

    final taken = recent.where((event) => event.status == 'taken').length;

    return (taken / recent.length) * 100;
  }

  int streak(List<DoseEventModel> events) {
    int streak = 0;
    DateTime day = DateTime.now();

    for (int i = 0; i < 30; i++) {
      final dayEvents = events.where((event) {
        final date = DateTime.tryParse(event.createdAt);

        return date != null &&
            date.year == day.year &&
            date.month == day.month &&
            date.day == day.day;
      }).toList();

      if (dayEvents.isEmpty) break;

      final allTaken = dayEvents.every((event) => event.status == 'taken');

      if (!allTaken) break;

      streak++;
      day = day.subtract(const Duration(days: 1));
    }

    return streak;
  }
}