import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile_model.dart';

class CaregiverDashboardController {
  final SupabaseClient _supabase = Supabase.instance.client;

  String getCurrentCaregiverId() {
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
}