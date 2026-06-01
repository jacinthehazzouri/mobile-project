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

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final user = _supabase.auth.currentUser;

    if (user == null || user.email == null) {
      throw Exception('User not logged in');
    }

    if (oldPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      throw Exception('Please fill all password fields');
    }

    if (newPassword.length < 6) {
      throw Exception('New password must be at least 6 characters');
    }

    if (newPassword != confirmPassword) {
      throw Exception('Passwords do not match');
    }

    await _supabase.auth.signInWithPassword(
      email: user.email!,
      password: oldPassword,
    );

    await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    if (email.trim().isEmpty) {
      throw Exception('Please enter your email');
    }

    if (!RegExp(r'^[^@]+@[^@]+\.com$').hasMatch(email.trim())) {
      throw Exception('Enter a valid email');
    }

    await _supabase.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: 'io.supabase.smartmedbox://reset-password',
    );
  }

  Future<void> updatePasswordAfterReset({
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      throw Exception('Please fill all password fields');
    }

    if (newPassword.length < 6) {
      throw Exception('Password must be at least 6 characters');
    }

    if (!RegExp(r'[A-Z]').hasMatch(newPassword)) {
      throw Exception('Password must contain at least one capital letter');
    }

    if (!RegExp(r'[0-9]').hasMatch(newPassword)) {
      throw Exception('Password must contain at least one number');
    }

    if (newPassword != confirmPassword) {
      throw Exception('Passwords do not match');
    }

    await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }
}