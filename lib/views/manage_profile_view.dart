import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../controllers/profile_controller.dart';
import '../models/profile_model.dart';
import '../theme/app_theme.dart';
import 'change_password_view.dart';

class ManageProfileView extends StatefulWidget {
  const ManageProfileView({super.key});

  @override
  State<ManageProfileView> createState() => _ManageProfileViewState();
}

class _ManageProfileViewState extends State<ManageProfileView> {
  final ProfileController profileController = ProfileController();

  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  bool loading = true;
  bool saving = false;
  String role = '';

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  void showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      fontSize: 16,
    );
  }

  Future<void> loadProfile() async {
    try {
      final ProfileModel profile = await profileController.getProfile();

      nameController.text = profile.name;
      phoneController.text = profile.phone ?? '';
      role = profile.role;
    } catch (e) {
      if (!mounted) return;
      showToast('Failed to load profile');
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  Future<void> updateProfile() async {
    setState(() => saving = true);

    try {
      await profileController.updateProfile(
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
      );

      if (!mounted) return;

      showToast('Profile updated successfully');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      showToast('Failed to update profile');
    }

    if (mounted) {
      setState(() => saving = false);
    }
  }

  void openChangePasswordPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ChangePasswordView(),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Manage Profile'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Icon(
                  Icons.manage_accounts_outlined,
                  color: Colors.white,
                  size: 42,
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Update Profile Info',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Role: $role',
                style: const TextStyle(
                  color: AppTheme.textLight,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 30),

              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: saving ? null : updateProfile,
                  child: saving
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                      : const Text('Save Changes'),
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: openChangePasswordPage,
                  icon: const Icon(Icons.lock_reset_outlined),
                  label: const Text('Change Password'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}