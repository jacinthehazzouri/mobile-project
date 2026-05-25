import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';

class AuthController {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<ProfileModel> login(String email, String password) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = response.user;

    if (user == null) {
      throw Exception('Login failed');
    }

    final profileData = await _supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

    return ProfileModel.fromJson(profileData);
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
  }
}