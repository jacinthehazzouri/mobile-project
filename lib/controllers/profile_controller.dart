import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile_model.dart';

class ProfileController {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<ProfileModel> getProfile() async {
    final userId = _supabase.auth.currentUser!.id;

    final data = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();

    return ProfileModel.fromJson(data);
  }

  Future<void> updateProfile({
    required String name,
    required String phone,
  }) async {
    final userId = _supabase.auth.currentUser!.id;

    await _supabase.from('profiles').update({
      'name': name,
      'phone': phone,
    }).eq('id', userId);
  }
}