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

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'name': name,
        'role': role,
        'phone': phone,
      },
    );

    if (response.user == null) {
      throw Exception('Registration failed');
    }
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
  }
}